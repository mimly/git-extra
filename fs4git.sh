#!/bin/bash

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
