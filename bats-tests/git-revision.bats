#!/usr/bin/bats

. fs4bats.sh
. ../fs4git.sh

load '/usr/lib/bats-support/load.bash'
load '/usr/lib/bats-assert/load.bash'

COMMAND='git-revision'

setup() {
    createTestRepository

    createUntrackedFiles 3 # u1, u2 and u3

    createUnstagedFiles 3 # a1, a2 and a3
}

teardown() {
    removeTestRepository
}

@test 'no message provided (-/--no-auto-indexing)' {
    local args arg
    args=(\
        ''\
        '--no-auto-indexing'
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

@test 'same message provided' {
    assertGit --command "$COMMAND" --args 'a6' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '6 by 1' --assert-files-included 'u1 u2 u3 a1 a2 a3'
}

@test 'same message provided (--no-auto-indexing)' {
    assertGit --command "$COMMAND" --args '--no-auto-indexing a6 u1 u2 u3 a1 a2 a3' --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '6 by 1' --assert-files-included 'u1 u2 u3 a1 a2 a3'
}

@test 'no file(s) provided' {
    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '6 by 1' --assert-files-included 'u1 u2 u3 a1 a2 a3'
}

@test 'no file(s) provided (--no-auto-indexing)' {
    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM" --assert-result 'failure' \
        --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
}

@test 'all untracked and/or modified file(s) provided' {
    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u1 u2 u3 a1 a2 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '6 by 1' --assert-files-included 'u1 u2 u3 a1 a2 a3'
}

@test 'all untracked and/or modified file(s) provided (--no-auto-indexing)' {
    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM u1 u2 u3 a1 a2 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '6 by 1' --assert-files-included 'u1 u2 u3 a1 a2 a3'
}

@test 'multi-word filename(s) provided' {
    createMultiWordUntrackedFiles 3 # uu\ u1, uu\ u2 and uu\ u3

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM uu\ u1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '8' --assert-files-modified-or-untracked 'uu\ u2 uu\ u3 u1 u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'uu\ u1'

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM uu\ u2 a2" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'uu\ u3 u1 u2 u3 a1 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'uu\ u2 a2'

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM a3 uu\ u3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u1 u2 u3 a1' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a3 uu\ u3'
}

@test 'multi-word filename(s) provided (--no-auto-indexing)' {
    createMultiWordUntrackedFiles 3 # uu\ u1, uu\ u2 and uu\ u3

    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM uu\ u1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '8' --assert-files-modified-or-untracked 'uu\ u2 uu\ u3 u1 u2 u3 a1 a2 a3'\
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'uu\ u1'

    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM uu\ u2 a2" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'uu\ u3 u1 u2 u3 a1 a3'\
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'uu\ u2 a2'

    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM a3 uu\ u3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u1 u2 u3 a1'\
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a3 uu\ u3'
}

@test 'unexisting file(s) provided (-/--no-auto-indexing)' {
    local args1 arg1 args2 arg2
    args1=(\
        ''\
        '--no-auto-indexing'\
    )
    args2=(\
        'x'\
        'x y'\
    )
    for arg1 in "${args1[@]}" ; do
        for arg2 in "${args2[@]}" ; do
            assertGit --command "$COMMAND" --args "$arg1 test\ commit\ $RANDOM $arg2" --assert-result 'failure' \
                --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
                --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
                --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
                --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
                --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
        done
    done
}

@test 'untracked file(s) provided' {
    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'u1'

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u2 u3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'u2 u3'
}

@test 'untracked file(s) provided (--no-auto-indexing)' {
    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM u1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'u1'

    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM u2 u3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'u2 u3'
}

@test 'unmodified file(s) provided (-/--no-auto-indexing)' {
    local args1 arg1 args2 arg2
    args1=(\
        ''\
        '--no-auto-indexing'\
    )
    args2=(\
        'a4'\
        'a5 a6'\
    )
    for arg1 in "${args1[@]}" ; do
        for arg2 in "${args2[@]}" ; do
            assertGit --command "$COMMAND" --args "$arg1 test\ commit\ $RANDOM $arg2" --assert-result 'failure' \
                --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
                --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
                --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
                --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
                --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
        done
    done
}

# extraordinary behaviour
@test 'unmodified file(s) provided (--amend)' {
    local args arg
    args=(\
        'a4'\
        'a5 a6'\
    )
    for arg in "${args[@]}" ; do
        assertGit --command "$COMMAND" --args "--amend test\ commit\ $RANDOM $arg" --assert-result 'success' \
            --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
            --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
            --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
            --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
            --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
    done
}

@test 'unstaged file(s) provided' {
    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u1 u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a1'

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM a2 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'u1 u2 u3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a2 a3'
}

@test 'unstaged file(s) provided (--no-auto-indexing)' {
    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u1 u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a1'

    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM a2 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'u1 u2 u3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a2 a3'
}

@test 'unexisting and untracked file(s) provided (-/--no-auto-indexing)' {
    local args1 arg1 args2 arg2
    args1=(\
        ''\
        '--no-auto-indexing'\
    )
    args2=(\
        'x u1'\
        'u1 x'\
        'x u2 y u3'\
        'u2 x u3 y'\
    )
    for arg1 in "${args1[@]}" ; do
        for arg2 in "${args2[@]}" ; do
            assertGit --command "$COMMAND" --args "$arg1 test\ commit\ $RANDOM $arg2" --assert-result 'failure' \
                --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
                --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
                --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
                --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
                --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
        done
    done
}

@test 'unexisting and unmodified file(s) provided (-/--no-auto-indexing)' {
    local args1 arg1 args2 arg2
    args1=(\
        ''\
        '--no-auto-indexing'\
    )
    args2=(\
        'x a4'\
        'a4 x'\
        'x a5 y a6'\
        'a5 x a6 y'\
    )
    for arg1 in "${args1[@]}" ; do
        for arg2 in "${args2[@]}" ; do
            assertGit --command "$COMMAND" --args "$arg1 test\ commit\ $RANDOM $arg2" --assert-result 'failure' \
                --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
                --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
                --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
                --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
                --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
        done
    done
}

@test 'unexisting and unstaged file(s) provided (-/--no-auto-indexing)' {
    local args1 arg1 args2 arg2
    args1=(\
        ''\
        '--no-auto-indexing'\
    )
    args2=(\
        'x a1'\
        'a1 x'\
        'x a2 y a3'\
        'a2 x a3 y'\
    )
    for arg1 in "${args1[@]}" ; do
        for arg2 in "${args2[@]}" ; do
            assertGit --command "$COMMAND" --args "$arg1 test\ commit\ $RANDOM $arg2" --assert-result 'failure' \
                --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
                --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
                --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
                --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
                --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
        done
    done
}

@test 'untracked and unmodified file(s) provided' {
    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u1 a4" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'u1'

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u2 a5 u3 a6" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'u2 u3'
}

@test 'untracked and unmodified file(s) provided (--no-auto-indexing)' {
    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u1 a4" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'u1'

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u2 a5 u3 a6" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'u2 u3'
}

@test 'untracked and unstaged file(s) provided' {
    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u1 a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'u1 a1'

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u2 a2 u3 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'u2 a2 u3 a3'
}

@test 'untracked and unstaged file(s) provided (--no-auto-indexing)' {
    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM u1 a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'u1 a1'

    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM u2 a2 u3 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'u2 a2 u3 a3'
}

@test 'unmodified and unstaged file(s) provided' {
    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM a4 a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u1 u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a1'

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM a5 a2 a6 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'u1 u2 u3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a2 a3'
}

@test "unmodified and unstaged file(s) provided (--no-auto-indexing)" {
    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM a4 a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '5' --assert-files-modified-or-untracked 'u1 u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a1'

    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM a5 a2 a6 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '3' --assert-files-modified-or-untracked 'u1 u2 u3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'a2 a3'
}

@test 'unexisting, untracked and unmodified file(s) provided (-/--no-auto-indexing)' {
    local args1 arg1 args2 arg2
    args1=(\
        ''\
        '--no-auto-indexing'\
    )
    args2=(\
        'x u1 a4'\
        'a4 x u1'\
        'u1 a4 x'\
    )
    for arg1 in "${args1[@]}" ; do
        for arg2 in "${args2[@]}" ; do
            assertGit --command "$COMMAND" --args "$arg1 test\ commit\ $RANDOM $arg2" --assert-result 'failure' \
                --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
                --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
                --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
                --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
                --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
        done
    done
}

@test 'unexisting, untracked and unstaged file(s) provided (-/--no-auto-indexing)' {
    local args1 arg1 args2 arg2
    args1=(\
        ''\
        '--no-auto-indexing'\
    )
    args2=(\
        'x u1 a1'\
        'a1 x u1'\
        'u1 a1 x'\
    )
    for arg1 in "${args1[@]}" ; do
        for arg2 in "${args2[@]}" ; do
            assertGit --command "$COMMAND" --args "$arg1 test\ commit\ $RANDOM $arg2" --assert-result 'failure' \
                --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
                --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
                --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
                --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
                --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
        done
    done
}

@test 'unexisting, unmodified and unstaged file(s) provided (-/--no-auto-indexing)' {
    local args1 arg1 args2 arg2
    args1=(\
        ''\
        '--no-auto-indexing'\
    )
    args2=(\
        'x a4 a1'\
        'a1 x a4'\
        'a4 a1 x'\
    )
    for arg1 in "${args1[@]}" ; do
        for arg2 in "${args2[@]}" ; do
            assertGit --command "$COMMAND" --args "$arg1 test\ commit\ $RANDOM $arg2" --assert-result 'failure' \
                --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
                --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
                --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
                --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
                --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
        done
    done
}

@test 'untracked, unmodified and unstaged file(s) provided' {
    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u1 a4 a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'u1 a1'

    assertGit --command "$COMMAND" --args "test\ commit\ $RANDOM u2 a5 a2 u3 a6 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'u2 a2 u3 a3'
}

@test 'untracked, unmodified and unstaged file(s) provided (--no-auto-indexing)' {
    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM u1 a4 a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'u1 a1'

    assertGit --command "$COMMAND" --args "--no-auto-indexing test\ commit\ $RANDOM u2 a5 a2 u3 a6 a3" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'u2 a2 u3 a3'
}

@test 'unexisting, untracked, unmodified and unstaged file(s) provided (-/--no-auto-indexing)' {
    local args1 arg1 args2 arg2
    args1=(\
        ''\
        '--no-auto-indexing'\
    )
    args2=(\
        'x u1 a4 a1'\
        'a1 x u1 a4'\
        'a4 a1 x u1'\
    )
    for arg1 in "${args1[@]}" ; do
        for arg2 in "${args2[@]}" ; do
            assertGit --command "$COMMAND" --args "$arg1 test\ commit\ $RANDOM $arg2" --assert-result 'failure' \
                --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
                --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
                --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
                --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
                --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
        done
    done
}

@test 'custom date provided (-/--no-auto-indexing, -d/--date)' {
    assertGit --command "$COMMAND" --args "--no-auto-indexing --date=1989-11-23T00:00:00 test\ commit\ $RANDOM u1 a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '2 by 1' --assert-files-included 'u1 a1'

    assertGit --command "$COMMAND" --args "--date=1989-11-23T00:00:00 test\ commit\ $RANDOM" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '4 by 1' --assert-files-included 'u2 u3 a2 a3'
}

@test 'custom date provided in a wrong format (-/--no-auto-indexing, -d/--date)' {
    assertGit --command "$COMMAND" --args "--no-auto-indexing --date=1989-13-23T00:00:00 test\ commit\ $RANDOM u1 a1" --assert-result 'failure' \
        --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'

    assertGit --command "$COMMAND" --args "--date=1989-13-23T00:00:00 test\ commit\ $RANDOM" --assert-result 'failure' \
        --assert-modified-or-untracked-in-working-tree '6' --assert-files-modified-or-untracked 'u1 u2 u3 a1 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} == $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} == $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '1 by 1' --assert-files-included 'a6'
}

@test 'amend last revision with custom date (-/--no-auto-indexing, --amend, -d/--date)' {
    assertGit --command "$COMMAND" --args "--no-auto-indexing --amend --date=1989-11-23T00:00:00 test\ commit\ $RANDOM u1 a1" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '4' --assert-files-modified-or-untracked 'u2 u3 a2 a3' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} != $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '3 by 1' --assert-files-included 'a6 u1 a1'

    assertGit --command "$COMMAND" --args "--amend --date=1989-11-23T00:00:00 test\ commit\ $RANDOM" --assert-result 'success' \
        --assert-modified-or-untracked-in-working-tree '0' --assert-files-modified-or-untracked '' \
        --assert-n-th-original-revision '${r1[hash]} != $(commitHash HEAD)' \
        --assert-n-th-original-revision '${r1[date]} == $(commitDate HEAD)' \
        --assert-n-th-original-revision '${r1[message]} != $(commitMessage HEAD)' \
        --assert-included-by-n-th-revision '7 by 1' --assert-files-included 'a6 u1 u2 u3 a1 a2 a3'
}
