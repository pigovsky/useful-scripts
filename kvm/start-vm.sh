#!/bin/bash

VM="${1:-qvantel-vm}"

echo "Starting $VM..."
virsh start "$VM"
virsh domstate "$VM"
