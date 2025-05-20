#!/bin/bash

PLATFORM_BIN_DISTRIB="$1"
PLATFROM_FOLDER="$2"

cd "$PLATFROM_FOLDER" || exit $?
tar zxvf "$PLATFORM_BIN_DISTRIB" || exit $?
./scripts/install-docker.sh || exit $?
