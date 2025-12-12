#!/bin/bash

mkdir -p ~/bin

HOST_KUBECTL_PATH=~/bin/kubectl

# Copy the file from the container to your current directory
docker cp kind-control-plane:/usr/bin/kubectl $HOST_KUBECTL_PATH

# Make the copied binary executable
chmod +x $HOST_KUBECTL_PATH

# Verify it works
kubectl version
