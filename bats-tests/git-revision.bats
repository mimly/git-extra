#!/usr/bin/bats

. fs4bats.sh

load '/usr/lib/bats-support/load.bash'
load '/usr/lib/bats-assert/load.bash'

BASE_PATH="$(pwd)"
REPO_NAME="xxx"
REPO_PATH="$BASE_PATH/$REPO_NAME"
GIT_REVISION="git-revision"

setup() {
    # create test repo and make few commits a1..aX
    mkdir -p "$REPO_PATH" && cd "$REPO_PATH" && git init && for i in {1..3} ; do touch "a$i" ; git add -A ; git commit -m "a$i" ; done
}

teardown() {
    # remove test repo
    cd "$BASE_PATH" && rm -rf "$REPO_PATH"
}

@test "no message provided" {
    run $GIT_REVISION
    assert_failure
}

@test "no file(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message"
    assert_failure
}

@test "unexisting file provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" x
    assert_failure
}

@test "unexisting files provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" x y
    assert_failure
}

@test "staged file(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 && echo a1 > a1
    run $GIT_REVISION --no-auto-indexing "message" a1 a2
    assert_failure
}

@test "untracked file(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" u1 u2
    assert_success
}

@test "multi-word filename(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2\ 2u u3
    run $GIT_REVISION --no-auto-indexing "message" u1 u2\ 2u u3
    assert_success && assert_equal $(git status --porcelain | wc -l) 0
}

@test "mix of staged and unexisting file(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" a1 x
    assert_failure
}

@test "mix of unexisting and staged file(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" x a1
    assert_failure
}

@test "mix of untracked and unexisting file(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" u1 x
    assert_failure
}

@test "mix of unexisting and untracked file(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" x u1
    assert_failure
}

@test "mix of untracked and staged file(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" u1 a1
    assert_success
}

@test "mix of staged and untracked file(s) provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" a1 u1
    assert_success
}

@test "mix of all kinds of files provided (--no-auto-indexing)" {
    # create some untracked files
    touch u1 u2 u3
    run $GIT_REVISION --no-auto-indexing "message" x u1 a1
    assert_failure
}

@test "no params2" {
    assert_equal "$(echo 1+1 | bc)" 2
    assert_success
}
