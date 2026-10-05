#!/bin/bash

VM="${1:-qvantel-vm}"

echo "Hibernating $VM..."
virsh managedsave "$VM"
virsh domstate "$VM"
