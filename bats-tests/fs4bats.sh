#!/bin/bash

BASE_PATH="$(pwd)"
REPO_NAME=$(echo "${RANDOM}" | sha512sum | head -c 10)
REPO_PATH="${BASE_PATH}/${REPO_NAME}"

createTestRepository() {
    # create test repo and make a few commits a1..a6
    # sleep 1 second to make sure the dates will be different
    mkdir -p "${REPO_PATH}" && cd "${REPO_PATH}" && git init && local i && for i in {1..6} ; do touch "a${i}" ; git add -A ; git commit -m "a${i}" ; sleep 1 ; done
}

removeTestRepository() {
    # remove test repo
    cd "${BASE_PATH}" && rm -rf "${REPO_PATH}"
}

createUntrackedFiles() {
    local i
    for (( i=1 ; i<=$1 ; ++i )) ; do touch "u${i}" ; done
}

createUnstagedFiles() {
    local i
    for (( i=1 ; i<=$1 ; ++i )) ; do echo test > "a${i}" ; done
}

createMultiWordUntrackedFiles() {
    local i
    for (( i=1 ; i<=$1 ; ++i )) ; do touch "uu u${i}" ; done
}

retrieveUpdatedRevisionInformation() {
    # represent all information regarding the existing commits as a matrix r1[hash/date/message]..rX[...]
    local revisions i hash date message
    revisions=()
    for i in {1..6} ; do
        hash=$(commitHash "${i}")
        date=$(commitDate "${i}")
        message=$(commitMessage "${i}")
        revisions+=("declare -Ag r${i}=( [hash]=${hash@Q} [date]=${date@Q} [message]=${message@Q} )")
    done
    for i in "${revisions[@]}"; do eval "${i}"; done
}

filesModifiedOrUntrackedInWorkingTree() {
    git ls-files -mo 2>/dev/null
}

modifiedOrUntrackedInWorkingTree() {
    filesModifiedOrUntrackedInWorkingTree | wc -l
}

isWorkingTreeClean() {
    [ -z "$(filesModifiedOrUntrackedInWorkingTree)" ]
}

filesIncludedByNthRevision() {
    if (( $1 >= $(totalNumberOfCommits HEAD) )) ; then
        git diff --name-only HEAD~$(( $1 - 1 )) "$(printf '' | git hash-object -t tree --stdin)" 2>/dev/null # inital commit
    else
        git diff --name-only HEAD~$(( $1 - 1 )) HEAD~"$1" 2>/dev/null
    fi
}

includedByNthRevision() {
    filesIncludedByNthRevision "$1" | wc -l
}

#################################################
######   B A T S   G I T   U T I L I T Y   ######
#################################################
assertGit() {
    # We use "$@" instead of $* to preserve argument-boundary information
    # Add : to suppress getopt error messages, i.e. getopt -o ':...'
    ARGS=$(getopt -o 'c:a:' --long 'command:,args:,assert-result:,assert-modified-or-untracked-in-working-tree:,assert-files-modified-or-untracked:,assert-n-th-original-revision:,assert-included-by-n-th-revision:,assert-files-included:' -- "$@") || { return 1 ; }
    eval "set -- ${ARGS}"

    local command args result modifiedOrUntracked modifiedOrUntrackedFiles assertionsX assertionsY assertionsZ
    while true; do
        case $1 in
            (-c|--command)
                command="$2" ; shift 2 ;;
            (-a|--args)
                # shellcheck disable=SC2162
                read -a args <<< "$2" ; shift 2 ;;
            (--assert-result)
                result="$2" ; shift 2 ;;
            (--assert-modified-or-untracked-in-working-tree)
                modifiedOrUntracked="$2" ; shift 2 ;;
            (--assert-files-modified-or-untracked)
                modifiedOrUntrackedFiles="$2" ; shift 2 ;;
            (--assert-n-th-original-revision)
                assertionsX+=("$2") ; shift 2 ;;
            (--assert-included-by-n-th-revision)
                assertionsY+=("$2") ; shift 2 ;;
            (--assert-files-included)
                assertionsZ+=("$2") ; shift 2 ;;
            (--)
                shift ; break ;;
            (*)
                return 1 ;;
        esac
    done

    retrieveUpdatedRevisionInformation

    # shellcheck disable=SC2068
    run "${command}" --verbose "${args[@]}"
    case ${result} in
        ("success")
            assert_success ;;
        ("failure")
            assert_failure ;;
        (*)
            echo "unknown result error" ; return 1 ;;
    esac

    if (( modifiedOrUntracked == 0 )) ; then
        assert isWorkingTreeClean
    else
        refute isWorkingTreeClean
    fi
    run modifiedOrUntrackedInWorkingTree
    assert_output "${modifiedOrUntracked}"
    # shellcheck disable=SC2162
    expectedFiles=$(read -a files <<< "${modifiedOrUntrackedFiles}" ; printf "%s\n" "${files[@]}")
    actualFiles=$(filesModifiedOrUntrackedInWorkingTree)
    assert [ -z "$(printf "%s\n%s" "${expectedFiles}" "${actualFiles}" | sort | uniq -u)" ]

    local i expectedData op actualData
    for (( i=0 ; i<${#assertionsX[@]} ; ++i )) {
        # shellcheck disable=SC2162
        read expectedData op actualData <<< "${assertionsX[${i}]}"
        expectedData=$(eval echo "${expectedData}")
        actualData=$(eval echo "${actualData}")
        assert [ "${expectedData}" "${op}" "${actualData}" ]
    }

    local i included by revision expectedFiles actualFiles
    for (( i=0 ; i<${#assertionsY[@]} ; ++i )) {
        # shellcheck disable=SC2034
        read -r included by revision <<< "${assertionsY[${i}]}"
        run includedByNthRevision "${revision}"
        assert_output "${included}"

        # shellcheck disable=SC2162
        expectedFiles=$(read -a files <<< "${assertionsZ[${i}]}" ; printf "%s\n" "${files[@]}")
        actualFiles=$(filesIncludedByNthRevision "${revision}")
        assert [ -z "$(printf "%s\n%s" "${expectedFiles}" "${actualFiles}" | sort | uniq -u)" ]
    }

    # sleep 1 second to make sure the dates will be different
    sleep 1
}
#################################################
#################################################
#################################################
