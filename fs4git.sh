#!/bin/bash

gitBranchInfo() {
    local allCharacters=0 nonPrintableCharacters=0

    if isGitRepo ; then
        local text prompt
        text="on  $(branch)"
        prompt=$(colorize --fg-color 50 --fg-step $(( ${#text} / 4 + 1 )) "${text}")

        allCharacters=$(( ${#prompt} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 cs ; echo "${cs}") ))
        printf "%s " "${prompt}"
    fi

    echo "${allCharacters}" >&7
    echo "${nonPrintableCharacters}" >&7
}

gitCommitInfo() {
    local allCharacters=0 nonPrintableCharacters=0

    if isGitRepo ; then
        local STATUS STATUS_COLOR HASH HASH_COLOR=230 MESSAGE text prompt

        if [[ -z $(git status --porcelain) ]] ; then
            STATUS="✔"
            STATUS_COLOR=46
        else
            STATUS="✘"
            STATUS_COLOR=196
        fi

        HASH=$(commitHash HEAD)
        MESSAGE=$(commitMessage HEAD)
        # Shorten hash and message if too long
        HASH=${HASH:0:4}
        [[ "${#MESSAGE}" -gt 14 ]] && MESSAGE="${MESSAGE:0:14}..."

        text="[#${HASH:-"????"}${STATUS} ${MESSAGE:-"..."}]"
        prompt=$(colorize --fg-style 3 --fg-custom-scheme "0:238,1:${HASH_COLOR},2:239,4:240,6:${STATUS_COLOR},7:241,8:242,10:243,12:244,14:245,16:246,18:247,20:248,22:249,24:250,26:251" "${text}")

        allCharacters=$(( ${#prompt} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 cs ; echo "${cs}") ))
        printf "%s " "${prompt}"
    fi

    echo "${allCharacters}" >&7
    echo "${nonPrintableCharacters}" >&7
}

gitSyncInfo() {
    local allCharacters=0 nonPrintableCharacters=0

    if isGitRepo && isUpstreamConfigured ; then
        # chars "↓↑▼▲"
        local PRIMARY_COLOR=49 SECONDARY_COLOR=238 UP="↑" DOWN="↓" AHEAD="-" BEHIND="-" REMOTE_BRANCH text prompt
        REMOTE_BRANCH=$(git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)")

        local UPSTREAM LOCAL REMOTE BASE
        UPSTREAM=${1:-'@{u}'}
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse "${UPSTREAM}")
        BASE=$(git merge-base @ "${UPSTREAM}")

        if [[ "${LOCAL}" = "${REMOTE}" ]] ; then # up-to-date
            text="${DOWN}${BEHIND}${UP}${AHEAD} ⎇  ${REMOTE_BRANCH}"
            prompt=$(colorize --fg-color "${SECONDARY_COLOR}" --fg-step ${#text} "${text}")
        elif [[ "${LOCAL}" = "${BASE}" ]] ; then # need to pull
            BEHIND=$(git branch -vv | sed -n -e '/^\*/ { p }' | sed -e 's/.*\[.*behind \([1-9][0-9]*\).*\].*/\1/')
            text="${DOWN}${BEHIND}${UP}${AHEAD}"
            prompt=$(colorize --fg-custom-scheme "0:${PRIMARY_COLOR},2:${SECONDARY_COLOR}" "${text}")
            nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))

            text=" ⎇  ${REMOTE_BRANCH}"
            prompt+=$(colorize --fg-color "${PRIMARY_COLOR}" --fg-step $(( ${#text} / 4 + 1 )) "${text}")
        elif [[ "${REMOTE}" = "${BASE}" ]] ; then # need to push
            AHEAD=$(git branch -vv | sed -n -e '/^\*/ { p }' | sed -e 's/.*\[.*ahead \([1-9][0-9]*\).*\].*/\1/')
            text="${DOWN}${BEHIND}${UP}${AHEAD}"
            prompt=$(colorize --fg-custom-scheme "0:${SECONDARY_COLOR},2:${PRIMARY_COLOR}" "${text}")
            nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))

            text=" ⎇  ${REMOTE_BRANCH}"
            prompt+=$(colorize --fg-color "${PRIMARY_COLOR}" --fg-step $(( ${#text} / 4 + 1 )) "${text}")
        else # diverged
            BEHIND=$(git branch -vv | sed -n -e '/^\*/ { p }' | sed -e 's/.*\[.*behind \([1-9][0-9]*\).*\].*/\1/')
            AHEAD=$(git branch -vv | sed -n -e '/^\*/ { p }' | sed -e 's/.*\[.*ahead \([1-9][0-9]*\).*\].*/\1/')
            text="${DOWN}${BEHIND}${UP}${AHEAD} ⎇  ${REMOTE_BRANCH}"
            prompt=$(colorize --fg-color "${PRIMARY_COLOR}" --fg-step $(( ${#text} / 4 + 1 )) "${text}")
        fi

        allCharacters=$(( ${#prompt} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 cs ; echo "${cs}") ))
        printf "%s " "${prompt}"
    fi

    echo "${allCharacters}" >&7
    echo "${nonPrintableCharacters}" >&7
}

#gitSubmoduleInfo() {
#    local allCharacters=0
#    local nonPrintableCharacters=0
#
#    if isGitRepo && hasAnySubmodules ; then
#        local submodules
#        submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }' ORS=' ')
#        local submodulesArray
#        IFS=' ' read -ra submodulesArray <<< "${submodules}"
#        local gitSubmoduleInfo
#        gitSubmoduleInfo=$(colorize --fg-color 238 --fg-color-step 1 "⚜ ")
#        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
#        for (( i = 0; i < "${#submodulesArray[@]}"; ++i )) ; do
#            local gitStatus
#            gitStatus=$(git --git-dir "${submodulesArray[${i}]}/.git" --work-tree "${submodulesArray[${i}]}" status --porcelain 2>/dev/null)
#            if [[ -n ${gitStatus} ]] ; then
#                color=$(( 196 + i ))
#            else
#                color=$(( 238 + i * 3 ))
#            fi
#
#            gitSubmoduleInfo+=$(colorize --fg-color "${color}" --fg-color-step 1 "${submodulesArray[${i}]}")
#            nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
#
#            if [[ ${i} -ne $(( ${#submodulesArray[@]} - 1 )) ]] ; then
#                gitSubmoduleInfo+=$(colorize --fg-color "$(( 238 + i * 3 ))" --fg-color-step 1 "|")
#                nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
#            fi
#        done
#        gitSubmoduleInfo+=$(colorize --fg-color "$(( 238 + ( ${#submodulesArray[@]} - 1 ) * 3 ))" --fg-color-step 1 " ⚜")
#        allCharacters=$(( ${#gitSubmoduleInfo} + 1 ))
#        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
#        printf "%s " "${gitSubmoduleInfo}"
#
#        # A little bit simpler approach
#        #gitSubmoduleInfo=$(colorize --fg-color 238 --fg-color-step 1 "🡶 $(IFS='|' ; echo "${submodulesArray[*]}") 🡶")
#
#        #allCharacters=$(( ${#gitSubmoduleInfo} + 1 ))
#        #nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))
#        #printf "%s " "$gitSubmoduleInfo"
#    fi
#
#    echo "${allCharacters}" >&7
#    echo "${nonPrintableCharacters}" >&7
#}

isGitRepo() {
    git status --porcelain >/dev/null 2>&1
}

hasAnySubmodules() {
    local submodules
    submodules=$(git config --file .gitmodules --get-regexp path)
    [[ -n ${submodules} ]]
}

isUpstreamConfigured() {
    local remoteBranch
    remoteBranch=$(git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)")
    [[ -n ${remoteBranch} ]]
}

branch() {
    git branch 2>/dev/null | awk '{if ($1 == "*") { $1 = ""; gsub(/^[ ]+/, "", $0); gsub(/[ ]+$/, "", $0); print $0 }}'
}

isValidDate() {
    local date=$1
    date +%Y-%m-%dT%H:%M:%S --date="${date}" >/dev/null 2>&1 && [[ ${date} =~ ^.{10}T.{8}$ ]]
}

### TODO Test how the functions work outside of a git repository.

##################################################
# Returns the total number of commits. Depends on the commitHash function.
#
# Globals:
#   None
# Arguments:
#   $1 - commit number or commit hash
# Outputs:
#   Writes the number of commits (or nothing at all) to stdout
#   and returns always exit code 0.
##################################################
totalNumberOfCommits() {
    local hash=$1
    hash=$(commitHash "${hash}")
    git rev-list --count --no-merges "${hash}" 2>/dev/null || return 0
}

##################################################
# Returns the number of commits between any two commits. Depends on the commitHash function.
#
# Globals:
#   None
# Arguments:
#   $1 - commit number or commit hash
#   $2 - commit number or commit hash
# Outputs:
#   Writes the number of commits between (or nothing at all) to stdout
#   and returns always exit code 0.
##################################################
numberOfCommitsBetween() {
    local from to number
    from=$(commitNumber "$(commitHash "$1")")
    to=$(commitNumber "$(commitHash "$2")")
    number=$(( to - from ))
    if [[ -n ${from} && -n ${to} ]] ; then
        printf "%s\n" "${number#-}" # abs
    fi
}

##################################################
# Checks whether the specified commit is valid or not. Depends on the commitHash function.
#
# Globals:
#   None
# Arguments:
#   $1 - commit number or commit hash
# Outputs:
#   Returns exit code 0 if the specified commit is valid and exit code 1 otherwise.
##################################################
isValidCommit() {
    [[ -n $(commitHash "$1") ]]
}

##################################################
# Returns the hash value of the specified commit.
#
# Globals:
#   None
# Arguments:
#   $1 - commit number or commit hash
# Outputs:
#   Writes commit hash (or nothing at all) to stdout
#   and returns always exit code 0.
##################################################
commitHash() {
    local hash=$1
    if [[ ${hash} =~ ^[1-9][0-9]*$ ]] && (( hash <= $(totalNumberOfCommits HEAD) )) ; then
        hash=HEAD~$(( hash - 1 ))
    fi
    git rev-parse --verify --quiet "${hash}" 2>/dev/null || true
}

##################################################
# Returns the order number of the specified commit. Depends on the commitHash function.
#
# Globals:
#   None
# Arguments:
#   $1 - commit number or commit hash
# Outputs:
#   Writes commit number (or nothing at all) to stdout
#   and returns always exit code 0.
##################################################
commitNumber() {
    git rev-list --count HEAD~$(( $(totalNumberOfCommits "$(commitHash "$1")") - 1 )) 2>/dev/null
}

##################################################
# Returns the message of the specified commit. Depends on the commitHash function.
#
# Globals:
#   None
# Arguments:
#   $1 - commit number or commit hash
# Outputs:
#   Writes commit message (or nothing at all) to stdout
#   and returns always exit code 0.
##################################################
commitMessage() {
    git rev-list --format=%s --max-count=1 "$(commitHash "$1")" 2>/dev/null | awk '{if (NR == 2) { print $0 }}'
}

##################################################
# Returns the date of the specified commit. Depends on the commitHash function.
#
# Globals:
#   None
# Arguments:
#   $1 - commit number or commit hash
# Outputs:
#   Writes commit date (or nothing at all) to stdout
#   and returns always exit code 0.
##################################################
commitDate() {
    local date
    date=$(git rev-list --format=%ci --max-count=1 "$(commitHash "$1")" 2>/dev/null | awk '{if (NR == 2) { print $0 }}')
    if [[ -n ${date} ]] ; then
        date +%Y-%m-%dT%H:%M:%S --date="${date}"
    fi
}
