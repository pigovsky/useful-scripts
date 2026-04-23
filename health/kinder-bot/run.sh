#!/bin/bash -x

. ~/.kinder-bot.pigovsky.com/env.sh

export KB_SSH_USER
export KB_BOT_TOKEN
export KB_SECRET_PASSWORD

docker compose up -d
