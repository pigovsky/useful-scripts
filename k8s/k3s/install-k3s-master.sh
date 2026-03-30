#!/bin/bash -x

curl -sfL https://get.k3s.io | sh -

mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

export KUBECONFIG=~/.kube/config

kubectl get node

sudo cat /var/lib/rancher/k3s/server/node-token

