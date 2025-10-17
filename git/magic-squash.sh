#!/bin/bash -x

git fetch origin || exit $?

git merge $1 || exit $?

git reset $1 || exit $?

git add . || exit $?

git commit || exit $?

