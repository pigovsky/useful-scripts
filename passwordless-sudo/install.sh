#!/usr/bin/env bash
# Installs the passwordless-sudo drop-in for pigovsky into /etc/sudoers.d/,
# validating it with visudo before activating it.
set -euo pipefail

SRC="$(dirname "$0")/010-pigovsky-nopasswd"
DEST="/etc/sudoers.d/010-pigovsky-nopasswd"

sudo visudo -cf "$SRC"
sudo install -o root -g root -m 0440 "$SRC" "$DEST"
sudo visudo -c
echo "Installed $DEST"
