#!/bin/bash

TEST_SUITE=$1
TEST_CASE=$2

sed -n -e '1,/^\@test/ {x; 1d; p;}' -e "/^\@test \".*${TEST_CASE}.*\" {/,/^}/ {s/^\(}\)/\1\n/; p;}" "${TEST_SUITE}" | sed -n -e '$!p'
