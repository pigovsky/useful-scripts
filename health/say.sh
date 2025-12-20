#!/bin/bash -x

# Replace 'username' with your actual Linux username
sudo -u pigovska XDG_RUNTIME_DIR=/run/user/$(id -u pigovska) spd-say "$1"

