#!/bin/bash

mkdir -p ~/work
echo $1 >> ~/work/log.md
sleep 15m
setxkbmap us
gnome-screensaver-command -l

