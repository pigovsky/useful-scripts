#!/bin/bash
#
sleep 10
playerctl pause
./volume.sh 1.3
mpg123 "$1"
./volume.sh 1
sudo poweroff

