#!/bin/bash -x

cd "$(dirname "$0")" || exit $?

. ~/.kinder-bot.pigovsky.com/env.sh

VERSION=$(cat .kinder-bot.pigovsky.com/VERSION | tr -d '[:space:]')
export VERSION
KB_SSH_USER="$(whoami)"
export KB_SSH_USER
export KB_BOT_TOKEN
export KB_SECRET_PASSWORD

nohup docker compose up -d &
