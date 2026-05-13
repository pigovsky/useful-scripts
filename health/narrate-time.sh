#!/bin/bash

spd-say -l de "Es ist jetzt $(date +'%H Uhr %M')"
sleep 5
spd-say -l de "Es ist jetzt $(date +'%H Uhr %M')"
sleep 5
spd-say -l de "Es ist jetzt $(date +'%H Uhr %M')"
sleep 5m
./narrate-time.sh &

