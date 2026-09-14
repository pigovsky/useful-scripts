#!/usr/bin/env bash
# Removes the passwordless-sudo drop-in for pigovsky from /etc/sudoers.d/.
set -euo pipefail

DEST="/etc/sudoers.d/010-pigovsky-nopasswd"

if [ -e "$DEST" ]; then
  sudo rm -f "$DEST"
  echo "Removed $DEST"
else
  echo "$DEST not present, nothing to do"
fi
