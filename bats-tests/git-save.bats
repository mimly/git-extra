#!/usr/bin/bats

. fs4bats.sh
. ../fs4git.sh

load '/usr/lib/bats-support/load.bash'
load '/usr/lib/bats-assert/load.bash'

COMMAND='git-save'

setup() {
    createTestRepository

    retrieveUpdatedRevisionInformation

    createUntrackedFiles 3 # u1, u2 and u3

    createUnstagedFiles 3 # a1, a2 and a3
}

teardown() {
    removeTestRepository
}

#####
### U P D A T E   C U R R E N T   R E V I S I O N
#####

@test 'no file(s) provided' {
    assertGit --command "$COMMAND" --args '' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'all untracked and/or modified file(s) provided' {
    assertGit --command "$COMMAND" --args 'u1 u2 u3 a1 a2 a3' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'multi-word filename(s) provided' {
    createMultiWordUntrackedFiles 3 # uu\ u1, uu\ u2 and uu\ u3

    assertGit --command "$COMMAND" --args 'uu\ u1' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '8' --assert-files-modified-or-untracked 'uu\ u2 uu\ u3 u1 u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a6 uu\ u1'

    assertGit --command "$COMMAND" --args 'uu\ u2 a2' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'uu\ u3 u1 u2 u3 a1 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'a6 uu\ u1 uu\ u2 a2'

    assertGit --command "$COMMAND" --args 'a3 uu\ u3' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u1 u2 u3 a1' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '6 by 1' --assert-files-included 'a6 uu\ u1 uu\ u2 uu\ u3 a2 a3'
}

@test 'unexisting file(s) provided' {
    local args arg
    args=(\
        'x'\
        'x y'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "$arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'untracked file(s) provided' {
    assertGit --command "$COMMAND" --args 'u1' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a6 u1'

    assertGit --command "$COMMAND" --args 'u2 u3' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'a6 u1 u2 u3'
}

@test 'unmodified file(s) provided' {
    local args arg
    args=(\
        'a4'\
        'a5 a6'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args 'a4' --assert-result 'success' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'unstaged file(s) provided' {
    assertGit --command "$COMMAND" --args 'a1' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u1 u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a6 a1'

    assertGit --command "$COMMAND" --args 'a2 a3' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'u1 u2 u3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'a6 a1 a2 a3'
}

@test 'unexisting and untracked file(s) provided' {
    local args arg
    args=(\
        'x u1'\
        'u1 x'\
        'x u2 y u3'\
        'u2 x u3 y'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "$arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'unexisting and unmodified file(s) provided' {
    local args arg
    args=(\
        'x a4'\
        'a4 x'\
        'x a5 y a6'\
        'a5 x a6 y'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "$arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'unexisting and unstaged file(s) provided' {
    local args arg
    args=(\
        'x a1'\
        'a1 x'\
        'x a2 y a3'\
        'a2 x a3 y'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "$arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'untracked and unmodified file(s) provided' {
    assertGit --command "$COMMAND" --args 'u1 a4' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a6 u1'

    assertGit --command "$COMMAND" --args 'u2 a5 u3 a6' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'a6 u1 u2 u3'
}

@test 'untracked and unstaged file(s) provided' {
    assertGit --command "$COMMAND" --args 'u1 a1' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '3 by 1' --assert-files-included 'a6 u1 a1'

    assertGit --command "$COMMAND" --args 'u2 a2 u3 a3' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'unmodified and unstaged file(s) provided' {
    assertGit --command "$COMMAND" --args 'a4 a1' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u1 u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a6 a1'

    assertGit --command "$COMMAND" --args 'a5 a2 a6 a3' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'u1 u2 u3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'a6 a1 a2 a3'
}

@test 'unexisting, untracked and unmodified file(s) provided' {
    local args arg
    args=(\
        'x u1 a4'\
        'a4 x u1'\
        'u1 a4 x'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "$arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'unexisting, untracked and unstaged file(s) provided' {
    local args arg
    args=(\
        'x u1 a1'\
        'a1 x u1'\
        'u1 a1 x'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "$arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'unexisting, unmodified and unstaged file(s) provided' {
    local args arg
    args=(\
        'x a4 a1'\
        'a1 x a4'\
        'a4 a1 x'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "$arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'untracked, unmodified and unstaged file(s) provided' {
    assertGit --command "$COMMAND" --args 'u1 a4 a1' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '3 by 1' --assert-files-included 'a6 u1 a1'

    assertGit --command "$COMMAND" --args 'u2 a5 a2 u3 a6 a3' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'unexisting, untracked, unmodified and unstaged file(s) provided' {
    local args arg
    args=(\
        'x u1 a4 a1'\
        'a1 x u1 a4'\
        'a4 a1 x u1'\
        'u1 a4 a1 x'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "$arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'last commit date provided (--then)' {
    assertGit --command "$COMMAND" --args '--then' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'last commit date and custom message provided (--then, -m/--message)' {
    assertGit --command "$COMMAND" --args '--then --message test\ commit' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision 'test\ commit == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'current date provided (--now)' {
    assertGit --command "$COMMAND" --args '--now' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'current date and custom message provided (--now, -m/--message)' {
    assertGit --command "$COMMAND" --args '--now --message test\ commit' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision 'test\ commit == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'custom date provided (-d/--date)' {
    assertGit --command "$COMMAND" --args '--date 1989-11-23T00:00:00' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '1989-11-23T00:00:00 == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'custom date and custom message provided (-d/--date, -m/--message)' {
    assertGit --command "$COMMAND" --args '--date 1989-11-23T00:00:00 --message test\ commit' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '1989-11-23T00:00:00 == $(commitDate HEAD)' \
        --assert-n-th-original-revision 'test\ commit == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}

@test 'custom date provided in a wrong format (-d/--date)' {
    assertGit --command "$COMMAND" --args '--date 1989-13-23T00:00:00' --assert-result 'failure' \
        --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
}

@test 'multiple dates provided (--then, --now, -d/--date)' {
    local args arg
    args=(\
        '--then --now'\
        '--now --then'\
        '--then --date="1989-11-23T00:00:00"'\
        '--date="1989-11-23T00:00:00" --then'\
        '--now --date="1989-11-23T00:00:00"'\
        '--date="1989-11-23T00:00:00" --now'\
        '--then --now --date="1989-11-23T00:00:00"'\
        '--then --date="1989-11-23T00:00:00" --now'\
        '--now --then --date="1989-11-23T00:00:00"'\
        '--now --date="1989-11-23T00:00:00" --then'\
        '--date="1989-11-23T00:00:00" --then --now'\
        '--date="1989-11-23T00:00:00" --now --then'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "$arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

#####
### U P D A T E   P A S T   R E V I S I O N
#####

@test 'wrong revision provided (--revision)' {
    local args arg
    args=(\
        '-1'\
        '0'\
        '6'\ # initial commit
        '7'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "--revision $arg" --assert-result 'failure' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'no file(s) provided (--revision)' {
    assertGit --command "$COMMAND" --args '--revision 3' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6' \
        --assert-n-th-original-revision '${r2[hash]} != $(commitHash HEAD~1)' \
        --assert-n-th-original-revision '${r2[date]} == $(commitDate HEAD~1)' \
        --assert-n-th-original-revision '${r2[message]} == $(commitMessage HEAD~1)' \
        --assert-included-by-n-th-revision '1 by 2' --assert-files-included 'a5' \
        --assert-n-th-original-revision '${r3[hash]} != $(commitHash HEAD~2)' \
        --assert-n-th-original-revision '${r3[date]} == $(commitDate HEAD~2)' \
        --assert-n-th-original-revision '${r3[message]} == $(commitMessage HEAD~2)' \
        --assert-included-by-n-th-revision '7 by 3' --assert-files-included 'a4 u1 u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r4[hash]} == $(commitHash HEAD~3)' \
        --assert-n-th-original-revision '${r4[date]} == $(commitDate HEAD~3)' \
        --assert-n-th-original-revision '${r4[message]} == $(commitMessage HEAD~3)' \
        --assert-included-by-n-th-revision '1 by 4' --assert-files-included 'a3' \
        --assert-n-th-original-revision '${r5[hash]} == $(commitHash HEAD~4)' \
        --assert-n-th-original-revision '${r5[date]} == $(commitDate HEAD~4)' \
        --assert-n-th-original-revision '${r5[message]} == $(commitMessage HEAD~4)' \
        --assert-included-by-n-th-revision '1 by 5' --assert-files-included 'a2' \
        --assert-n-th-original-revision '${r6[hash]} == $(commitHash HEAD~5)' \
        --assert-n-th-original-revision '${r6[date]} == $(commitDate HEAD~5)' \
        --assert-n-th-original-revision '${r6[message]} == $(commitMessage HEAD~5)' \
        --assert-included-by-n-th-revision '1 by 6' --assert-files-included 'a1'
}
