#!/bin/bash

gitBranchInfo() {
    local allCharacters=0
    local nonPrintableCharacters=0

    if isGitRepo ; then
        local branch
        branch=$(branch)
        local branchInfo
        branchInfo="on  ${branch}"
        local gitBranchInfo
        gitBranchInfo=$(colorize --fg-color 50 --fg-step $(( ${#branchInfo} / 4 + 1 )) "${branchInfo}")

        allCharacters=$(( ${#gitBranchInfo} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
        printf "%s " "${gitBranchInfo}"
    fi

    echo "${allCharacters}" >&7
    echo "${nonPrintableCharacters}" >&7
}

gitCommitInfo() {
    local allCharacters=0
    local nonPrintableCharacters=0

    if isGitRepo ; then
        local hash
        local hashColor=230
        hash=$(commitHash HEAD)
        local message
        message=$(commitMessage HEAD)

        # Shorten hash and message if too long
        hash="${hash:0:4}"
        if [[ ${#message} -gt 14 ]] ; then
            message="${message:0:14}..."
        fi

        local status
        local statusColor
        local gitStatus
        gitStatus=$(git status --porcelain)
        if [[ -z ${gitStatus} ]] ; then
            status="✔"
            statusColor=46
        else
            status="✘"
            statusColor=196
        fi

        local gitCommitInfo
        gitCommitInfo=$(colorize --fg-style 3 --fg-custom-scheme "0:238,1:${hashColor},2:239,4:240,6:${statusColor},7:241,8:242,10:243,12:244,14:245,16:246,18:247,20:248,22:249,24:250,26:251" "[#${hash}${status} ${message}]")

        allCharacters=$(( ${#gitCommitInfo} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
        printf "%s " "${gitCommitInfo}"
    fi

    echo "${allCharacters}" >&7
    echo "${nonPrintableCharacters}" >&7
}

gitSyncInfo() {
    local allCharacters=0
    local nonPrintableCharacters=0

    if isGitRepo && isUpstreamConfigured ; then
        local UPSTREAM LOCAL REMOTE BASE
        UPSTREAM=${1:-'@{u}'}
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse "${UPSTREAM}")
        BASE=$(git merge-base @ "${UPSTREAM}")

        # chars "↓↑▼▲"
        local PRIMARY_COLOR=229 SECONDARY_COLOR=244 UP="↑" DOWN="↓" AHEAD="-" BEHIND="-" REMOTE_BRANCH syncInfo gitSyncInfo
        REMOTE_BRANCH=$(git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)")

        if [[ "${LOCAL}" = "${REMOTE}" ]] ; then # up-to-date
            syncInfo="${DOWN}${BEHIND}${UP}${AHEAD} ⎇  ${REMOTE_BRANCH}"
            gitSyncInfo=$(colorize --fg-color "${SECONDARY_COLOR}" --fg-step ${#syncInfo} "${syncInfo}")
        elif [[ "${LOCAL}" = "${BASE}" ]] ; then # need to pull
            BEHIND=$(git branch -vv | sed -n -e '/^\*/ { p }' | sed -e 's/.*\[.*behind \([1-9][0-9]*\).*\].*/\1/')
            syncInfo="${DOWN}${BEHIND}${UP}${AHEAD}"
            gitSyncInfo=$(colorize --fg-custom-scheme "0:${PRIMARY_COLOR},2:${SECONDARY_COLOR}" "${syncInfo}")
            nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))

            syncInfo=" ⎇  ${REMOTE_BRANCH}"
            gitSyncInfo+=$(colorize --fg-color "${PRIMARY_COLOR}" --fg-step $(( ${#syncInfo} / 4 + 1 )) "${syncInfo}")
        elif [[ "${REMOTE}" = "${BASE}" ]] ; then # need to push
            AHEAD=$(git branch -vv | sed -n -e '/^\*/ { p }' | sed -e 's/.*\[.*ahead \([1-9][0-9]*\).*\].*/\1/')
            syncInfo="${DOWN}${BEHIND}${UP}${AHEAD}"
            gitSyncInfo=$(colorize --fg-custom-scheme "0:${SECONDARY_COLOR},2:${PRIMARY_COLOR}" "${syncInfo}")
            nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))

            syncInfo=" ⎇  ${REMOTE_BRANCH}"
            gitSyncInfo+=$(colorize --fg-color "${PRIMARY_COLOR}" --fg-step $(( ${#syncInfo} / 4 + 1 )) "${syncInfo}")
        else # diverged
            BEHIND=$(git branch -vv | sed -n -e '/^\*/ { p }' | sed -e 's/.*\[.*behind \([1-9][0-9]*\).*\].*/\1/')
            AHEAD=$(git branch -vv | sed -n -e '/^\*/ { p }' | sed -e 's/.*\[.*ahead \([1-9][0-9]*\).*\].*/\1/')
            syncInfo="${DOWN}${BEHIND}${UP}${AHEAD} ⎇  ${REMOTE_BRANCH}"
            gitSyncInfo=$(colorize --fg-color "${PRIMARY_COLOR}" --fg-step $(( ${#syncInfo} / 4 + 1 )) "${syncInfo}")
        fi

        allCharacters=$(( ${#gitSyncInfo} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
        printf "%s " "${gitSyncInfo}"
    fi

    echo "${allCharacters}" >&7
    echo "${nonPrintableCharacters}" >&7
}

gitSubmoduleInfo() {
    local allCharacters=0
    local nonPrintableCharacters=0

    if isGitRepo && hasAnySubmodules ; then
        local submodules
        submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }' ORS=' ')
        local submodulesArray
        IFS=' ' read -ra submodulesArray <<< "${submodules}"
        local gitSubmoduleInfo
        gitSubmoduleInfo=$(colorize --fg-color 238 --fg-color-step 1 "⚜ ")
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
        for (( i = 0; i < "${#submodulesArray[@]}"; ++i )) ; do
            local gitStatus
            gitStatus=$(git --git-dir "${submodulesArray[${i}]}/.git" --work-tree "${submodulesArray[${i}]}" status --porcelain 2>/dev/null)
            if [[ -n ${gitStatus} ]] ; then
                color=$(( 196 + i ))
            else
                color=$(( 238 + i * 3 ))
            fi

            gitSubmoduleInfo+=$(colorize --fg-color "${color}" --fg-color-step 1 "${submodulesArray[${i}]}")
            nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))

            if [[ ${i} -ne $(( ${#submodulesArray[@]} - 1 )) ]] ; then
                gitSubmoduleInfo+=$(colorize --fg-color "$(( 238 + i * 3 ))" --fg-color-step 1 "|")
                nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
            fi
        done
        gitSubmoduleInfo+=$(colorize --fg-color "$(( 238 + ( ${#submodulesArray[@]} - 1 ) * 3 ))" --fg-color-step 1 " ⚜")
        allCharacters=$(( ${#gitSubmoduleInfo} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "${x}") ))
        printf "%s " "${gitSubmoduleInfo}"

        # A little bit simpler approach
        #gitSubmoduleInfo=$(colorize --fg-color 238 --fg-color-step 1 "🡶 $(IFS='|' ; echo "${submodulesArray[*]}") 🡶")

        #allCharacters=$(( ${#gitSubmoduleInfo} + 1 ))
        #nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))
        #printf "%s " "$gitSubmoduleInfo"
    fi

    echo "${allCharacters}" >&7
    echo "${nonPrintableCharacters}" >&7
}

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
    git rev-list --count "${hash}" 2>/dev/null || return 0
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
