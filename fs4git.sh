#!/bin/bash

gitInfo() {
    local usedColorSequences=6
    # Each color is 13 characters long
    local bColor="[1;38;5;046m"
    local cColor="[1;38;5;240m"

    local branch=`branch 2>/dev/null`
    local hash=`commitHash 1 2>/dev/null`
    local message=`commitMessage $hash 2>/dev/null`

    # Shorten hash and message if too long
    local gitStatus=`git status --porcelain 2>/dev/null`
    if [[ -z $gitStatus ]] ; then
        hash="[1;38;5;045m#$cColor${hash:0:4}[1;38;5;046m✔$cColor"
    else
        hash="[1;38;5;045m#$cColor${hash:0:4}[1;38;5;196m✘$cColor"
    fi
    if [[ ${#message} -gt 10 ]] ; then
        message="${message:0:10}..."
    fi

    # In order to wrap lines correctly
    if [[ $# -eq 1 ]] ; then
        local gitInfo=`gitInfo`
        for (( i = 0; i < ${#gitInfo} - 13 * $usedColorSequences; ++i )) ; do
            printf "%s" ""
        done
        exit 0
    fi

    if ! [[ -z $branch ]] ; then
        printf "${bColor}on %s $cColor[%s %s] " "$branch" "$hash" "$message"
    fi
}

branch() {
    git branch | awk '{if ($1 == "*") { $1 = ""; print $0 }}'
}

isInvalidDate() {
  date "+%FT%T" -d "$1" 2>&1 >/dev/null
  if [[ $? != 0 ]] ; then
      return 0 
  fi
  return 1
}

totalNumberOfCommits() {
    git rev-list --count $1
}

commitHash() {
    git rev-parse HEAD~$(( $1 - 1 ))
}

commitMessage() {
    git rev-list --format=%s --max-count=1 $1 | awk '{if (NR == 2) { print $0 }}'
}

commitDate() {
    git rev-list --format=%ci --max-count=1 $1 | awk '{if (NR == 2) { print $0 }}'
}
