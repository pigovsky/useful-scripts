Is it possible to

1. ssh to a machine, start an interactive console app there.
2. Work a little. Then detach the interactive app and close the ssh connection.
3. After a while, connect back to the machine and resume the work in the interactive console app.

Yes, via tmux (or screen) running on the remote machine.

- `Ctrl-b d` detaches; closing/dropping the ssh connection doesn't kill the session.
- `tmux new -A -s <name>` creates the session if missing, attaches if it already exists —
  same command works for the first connect and every resume.

See `tmux-ssh.sh` (plain ssh) and `mosh-tmux.sh` (mosh, better over flaky/roaming networks)
in this directory.
