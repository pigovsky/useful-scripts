#!/bin/bash
#
# Ensures the xfce4-screensaver daemon is running so that screen locking
# (xflock4, <Super>+L, etc.) keeps working. xfce4-screensaver can silently
# die (e.g. on an X error) without restarting itself, which breaks locking
# until it's relaunched.
#
# Usage: run manually, or schedule periodically, e.g. via cron:
#   */5 * * * * DISPLAY=:0 /path/to/ensure-screensaver.sh >> ~/.cache/ensure-screensaver.log 2>&1

set -euo pipefail

export DISPLAY="${DISPLAY:-:0}"

if pgrep -f '(^|/)xfce4-screensaver$' >/dev/null 2>&1; then
    echo "$(date -Iseconds) xfce4-screensaver already running"
else
    echo "$(date -Iseconds) xfce4-screensaver not running, starting it"
    nohup xfce4-screensaver >/tmp/xfce4-screensaver.log 2>&1 &
    disown
fi
