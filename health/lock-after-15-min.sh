#!/bin/bash

mkdir -p ~/work
echo "$1,$(date -Iseconds)" >> ~/work/log.csv
sleep 15m
setxkbmap us
xflock4
gnome-screensaver-command -l &

