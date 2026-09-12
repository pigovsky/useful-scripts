#!/bin/bash

# ssh to a host and attach to a named tmux session, creating it if missing.
# usage: tmux-ssh.sh <host> [session-name]

HOST="$1"
SESSION="${2:-work}"

ssh -t "$HOST" "tmux new -A -s $SESSION"
