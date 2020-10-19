#!/usr/bin/bats

. fs4bats.sh

@test "no params" {
    createTestRepo "$HOME/Scripts/git-extra/bats-tests/repo"
    touch newFile
    git save
    [[ -z $(git status --porcelain) ]]
}

@test "all params" {
    :
}
