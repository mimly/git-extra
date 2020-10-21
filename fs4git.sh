#!/bin/bash

gitBranchInfo() {
    local allCharacters=0
    local nonPrintableCharacters=0

    if isGitRepo ; then
        local branch
        branch=$(branch 2>/dev/null)
        local gitBranchInfo
        gitBranchInfo=$(colorize --fg-color 50 --fg-step 4 "on  $branch")

        allCharacters=$(( ${#gitBranchInfo} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))
        printf "%s " "$gitBranchInfo"
    fi

    echo $allCharacters >&7
    echo $nonPrintableCharacters >&7
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
        if [[ -z $gitStatus ]] ; then
            status="✔"
            statusColor=46
        else
            status="✘"
            statusColor=196
        fi

        local gitCommitInfo
        gitCommitInfo=$(colorize --fg-custom-scheme 0:238,1:$hashColor,2:239,4:240,6:$statusColor,7:241,8:242,10:243,12:244,14:245,16:246,18:247,20:248,22:249,24:250,26:251 "[#$hash$status $message]")

        allCharacters=$(( ${#gitCommitInfo} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))
        printf "%s " "$gitCommitInfo"
    fi

    echo $allCharacters >&7
    echo $nonPrintableCharacters >&7
}

gitPushInfo() {
    local allCharacters=0
    local nonPrintableCharacters=0

    if isGitRepo && isRemoteSetUp && ! isPushed ; then
        local branch
        branch=$(branch 2>/dev/null)
        local gitPushInfo
        gitPushInfo=$(colorize --fg-color 50 --fg-step 4 "➤ origin/$branch")

        allCharacters=$(( ${#gitPushInfo} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))
        printf "%s " "$gitPushInfo"
    fi

    echo $allCharacters >&7
    echo $nonPrintableCharacters >&7
}

gitSubmoduleInfo() {
    local allCharacters=0
    local nonPrintableCharacters=0

    if isGitRepo && hasAnySubmodules ; then
        local submodules
        submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }' ORS=' ')
        local submodulesArray
        IFS=' ' read -ra submodulesArray <<< "$submodules"
        local gitSubmoduleInfo
        gitSubmoduleInfo=$(colorize --fg-color 238 --fg-color-step 1 "🡶 ")
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))
        for (( i = 0; i < "${#submodulesArray[@]}"; ++i )) ; do
            local gitStatus
            gitStatus=$(git --git-dir "${submodulesArray[$i]}/.git" --work-tree "${submodulesArray[$i]}" status --porcelain 2>/dev/null)
            if [[ -n $gitStatus ]] ; then
                color=$(( 196 + i ))
            else
                color=$(( 238 + i * 3 ))
            fi

            gitSubmoduleInfo+=$(colorize --fg-color "$color" --fg-color-step 1 "${submodulesArray[$i]}")
            nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))

            if [[ $i -ne $(( ${#submodulesArray[@]} - 1 )) ]] ; then
                gitSubmoduleInfo+=$(colorize --fg-color "$(( 238 + i * 3 ))" --fg-color-step 1 "|")
                nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))
            fi
        done
        gitSubmoduleInfo+=$(colorize --fg-color "$(( 238 + ( ${#submodulesArray[@]} - 1 ) * 3 ))" --fg-color-step 1 " 🡶")
        allCharacters=$(( ${#gitSubmoduleInfo} + 1 ))
        nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))
        printf "%s " "$gitSubmoduleInfo"

        # A little bit simpler approach
        #gitSubmoduleInfo=$(colorize --fg-color 238 --fg-color-step 1 "🡶 $(IFS='|' ; echo "${submodulesArray[*]}") 🡶")

        #allCharacters=$(( ${#gitSubmoduleInfo} + 1 ))
        #nonPrintableCharacters=$(( nonPrintableCharacters + $(read -r -u 7 x ; echo "$x") ))
        #printf "%s " "$gitSubmoduleInfo"
    fi

    echo $allCharacters >&7
    echo $nonPrintableCharacters >&7
}

isGitRepo() {
    git status --porcelain >/dev/null 2>&1
}

hasAnySubmodules() {
    local submodules
    submodules=$(git config --file .gitmodules --get-regexp path)
    [[ -n $submodules ]]
}

isRemoteSetUp() {
    local remote
    remote=$(git remote -v 2>/dev/null)
    [[ -n $remote ]]
}

isPushed() {
    local branch
    branch=$(branch 2>/dev/null)
    [[ $(commitHash "$branch") == $(commitHash "origin/$branch") ]]
}

branch() {
    git branch | awk '{if ($1 == "*") { $1 = ""; gsub(/^[ ]+/, "", $0); gsub(/[ ]+$/, "", $0); print $0 }}'
}

isValidDate() {
    local date=$1
    date +%Y-%m-%dT%H:%M:%S --date="$date" >/dev/null 2>&1 && [[ $date =~ ^.{10}T.{8}$ ]]
}

totalNumberOfCommits() {
    git rev-list --count "$1" 2>/dev/null
}

isValidCommit() {
    commitHash "$1" >/dev/null 2>&1
}

commitHash() {
    if [[ $1 =~ ^[1-9][0-9]*$ && $1 -le $(totalNumberOfCommits HEAD) ]] ; then
        git rev-parse --verify --quiet HEAD~$(( $1 - 1 )) 2>/dev/null
    else
        git rev-parse --verify --quiet "$1" 2>/dev/null
    fi
}

commitMessage() {
    git rev-list --format=%s --max-count=1 "$(commitHash "$1")" 2>/dev/null | awk '{if (NR == 2) { print $0 }}'
}

commitDate() {
    local commitDate
    commitDate=$(git rev-list --format=%ci --max-count=1 "$(commitHash "$1")" 2>/dev/null | awk '{if (NR == 2) { print $0 }}')
    if [[ -n $commitDate ]] ; then
        date +%Y-%m-%dT%H:%M:%S --date="$commitDate"
    fi
}
