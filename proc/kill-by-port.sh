#!/bin/bash

# Port number to check
PORT=$1

# Find the PID of the process listening on the specified port.
# The `awk` command extracts the second column (PID) from the lsof output.
PID=$(lsof -i :$PORT | grep LISTEN | awk '{print $2}')

# Check if a PID was found.
if [ -z "$PID" ]; then
  echo "No process found listening on port $PORT."
else
  # Kill the process with the found PID.
  # The -9 flag is a hard kill, which is often necessary for unresponsive processes.
  echo "Killing process with PID: $PID listening on port $PORT."
  kill $PID
  echo "Process killed."
fi

