#!/bin/bash

gitBranchInfo() {
    local nonPrintableCharacters=0

    if isGitRepo ; then
        local branch
        branch=$(branch 2>/dev/null)
        local gitBranchInfo
        gitBranchInfo=$(colorize --fg-color 50 --fg-step 4 "on  $branch")

        nonPrintableCharacters=$(( nonPrintableCharacters + $(cat ~/.non-printables) ))
        printf "%s " "$gitBranchInfo"
    fi

    echo $nonPrintableCharacters > ~/.non-printables
}

gitCommitInfo() {
    local nonPrintableCharacters=0

    if isGitRepo ; then
        local hash
        local hashColor=230
        hash=$(commitHash 1 2>/dev/null)
        local message
        message=$(commitMessage "$hash" 2>/dev/null)

        # Shorten hash and message if too long
        hash="${hash:0:4}"
        if [[ ${#message} -gt 14 ]] ; then
            message="${message:0:14}..."
        fi

        local status
        local statusColor
        local gitStatus
        gitStatus=$(git status --porcelain 2>/dev/null)
        if [[ -z $gitStatus ]] ; then
            status="✔"
            statusColor=46
        else
            status="✘"
            statusColor=196
        fi

        local gitCommitInfo
        gitCommitInfo=$(colorize --fg-custom-scheme 0:238,1:$hashColor,2:239,4:240,6:$statusColor,7:241,8:242,10:243,12:244,14:245,16:246,18:247,20:248,22:249,24:250,26:251 "[#$hash$status $message]")

        nonPrintableCharacters=$(( nonPrintableCharacters + $(cat ~/.non-printables) ))
        printf "%s " "$gitCommitInfo"
    fi

    echo $nonPrintableCharacters > ~/.non-printables
}

gitPushInfo() {
    local nonPrintableCharacters=0

    if isGitRepo && isRemoteSetUp && ! isPushed ; then
        local branch
        branch=$(branch 2>/dev/null)
        local gitPushInfo
        gitPushInfo=$(colorize --fg-color 50 --fg-step 4 "➤ origin/$branch")

        nonPrintableCharacters=$(( nonPrintableCharacters + $(cat ~/.non-printables) ))
        printf "%s " "$gitPushInfo"
    fi

    echo $nonPrintableCharacters > ~/.non-printables
}

gitSubmoduleInfo() {
    local nonPrintableCharacters=0

    if isGitRepo && hasAnySubmodules ; then
        local submodules
        submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }' ORS=' ')
        local submodulesArray
        IFS=' ' read -ra submodulesArray <<< "$submodules"
        local gitSubmoduleInfo
        gitSubmoduleInfo=$(colorize --fg-color 238 --fg-color-step 1 "🡶 ")
        nonPrintableCharacters=$(( nonPrintableCharacters + $(cat ~/.non-printables) ))
        for (( i = 0; i < "${#submodulesArray[@]}"; ++i )) ; do
            local gitStatus
            gitStatus=$(git --git-dir "${submodulesArray[$i]}/.git" --work-tree "${submodulesArray[$i]}" status --porcelain 2>/dev/null)
            if [[ -n $gitStatus ]] ; then
                color=$(( 196 + i ))
            else
                color=$(( 238 + i * 3 ))
            fi

            gitSubmoduleInfo+=$(colorize --fg-color "$color" --fg-color-step 1 "${submodulesArray[$i]}")
            nonPrintableCharacters=$(( nonPrintableCharacters + $(cat ~/.non-printables) ))

            if [[ $i -ne $(( ${#submodulesArray[@]} - 1 )) ]] ; then
                gitSubmoduleInfo+=$(colorize --fg-color "$(( 238 + i * 3 ))" --fg-color-step 1 "|")
                nonPrintableCharacters=$(( nonPrintableCharacters + $(cat ~/.non-printables) ))
            fi
        done
        gitSubmoduleInfo+=$(colorize --fg-color "$(( 238 + ( ${#submodulesArray[@]} - 1 ) * 3 ))" --fg-color-step 1 " 🡶")
        nonPrintableCharacters=$(( nonPrintableCharacters + $(cat ~/.non-printables) ))
        printf "%s " "$gitSubmoduleInfo"

        # A little bit simpler approach
        #gitSubmoduleInfo=$(colorize --fg-color 238 --fg-color-step 1 "🡶 $(IFS='|' ; echo "${submodulesArray[*]}") 🡶")

        #nonPrintableCharacters=$(( nonPrintableCharacters + $(cat ~/.non-printables) ))
        #printf "%s " "$gitSubmoduleInfo"
    fi

    echo $nonPrintableCharacters > ~/.non-printables
}

isGitRepo() {
    git status --porcelain >/dev/null 2>&1
}

hasAnySubmodules() {
    local submodules
    submodules=$(git config --file .gitmodules --get-regexp path)
    if [[ -n $submodules ]] ; then
        return 0
    fi
    return 1
}

isRemoteSetUp() {
    local remote
    remote=$(git remote -v 2>/dev/null)
    if [[ -n $remote ]] ; then
        return 0
    fi
    return 1
}

isPushed() {
    local branch
    branch=$(branch 2>/dev/null)
    if [[ $(git rev-parse "$branch" 2>/dev/null) == $(git rev-parse origin/"$branch" 2>/dev/null) ]] ; then
        return 0
    fi
    return 1
}

branch() {
    git branch | awk '{if ($1 == "*") { $1 = ""; gsub(/^[ ]+/, "", $0); gsub(/[ ]+$/, "", $0); print $0 }}'
}

isValidDate() {
    local date=$1
    date "+%FT%T" -d "$date" >/dev/null 2>&1
    local isValidDate=$?
    [[ $isValidDate -eq 0 && ${#date} -eq 19 ]]
}

totalNumberOfCommits() {
    git rev-list --count "$1"
}

commitHash() {
    git rev-parse HEAD~$(( $1 - 1 ))
}

commitMessage() {
    git rev-list --format=%s --max-count=1 "$1" | awk '{if (NR == 2) { print $0 }}'
}

commitDate() {
    git rev-list --format=%ci --max-count=1 "$1" | awk '{if (NR == 2) { print $0 }}'
}
