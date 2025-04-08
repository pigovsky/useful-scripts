#!/bin/bash -x

. ~/release-config.sh

cd "$PUB_REPO_DIR" || exit $?

LAST_PUB_VERSION="$(git describe --abbrev=0 --tags)"

cd "$PRI_REPO_DIR" || exit $?

LAST_PRI_VERSION="$1"

git diff "$LAST_PUB_VERSION..$LAST_PRI_VERSION" > /tmp/"$LAST_PRI_VERSION".diff

cd "$PUB_REPO_DIR" || exit $?

git apply /tmp/"$LAST_PRI_VERSION".diff || exit $?

git add . || exit $?

git commit -m "add $LAST_PRI_VERSION" || exit $?

git tag $LAST_PRI_VERSION || exit $?

git push --tags origin HEAD || exit $?

