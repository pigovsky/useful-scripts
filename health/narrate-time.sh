#!/usr/bin/env bash

# Source - https://stackoverflow.com/a/3355423
# Posted by ndim, modified by community. See post 'Timeline' for change history
# Retrieved 2026-08-25, License - CC BY-SA 4.0

cd "$(dirname "$0")"

spd-say -l de "Es ist jetzt $(date +'%H Uhr %M')"
sleep 5
spd-say -l de "Es ist jetzt $(date +'%H Uhr %M')"
sleep 5
spd-say -l de "Es ist jetzt $(date +'%H Uhr %M')"
sleep 5m
./narrate-time.sh &

