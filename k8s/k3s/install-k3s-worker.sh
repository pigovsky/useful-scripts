#!/bin/bash -x

curl -sfL https://get.k3s.io | K3S_URL=https://"$1":6443 K3S_TOKEN="$2" sh -

