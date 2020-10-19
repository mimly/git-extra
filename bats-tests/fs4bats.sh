#!/bin/bash

createTestRepo() {
    mkdir -p "$1" &&\
    cd repo &&\
    git init &&\
    for x in x{1..9} ; do
        touch "$x" &&\
        git revision "$x"
    done
}

removeTestRepo() {
    rm -rI "$1"
}
