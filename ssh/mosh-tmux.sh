#!/bin/bash

# mosh to a host and attach to a named tmux session, creating it if missing.
# survives network changes/sleep better than plain ssh.
# usage: mosh-tmux.sh <host> [session-name]

HOST="$1"
SESSION="${2:-work}"

mosh "$HOST" -- tmux new -A -s "$SESSION"
