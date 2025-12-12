#!/bin/bash

# Append the setting to the sysctl config file
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf

# Set the limit permanently to a much higher value
echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf

# Apply the changes without rebooting
sudo sysctl -p
