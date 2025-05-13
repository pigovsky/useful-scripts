#!/bin/bash

VM_RAM=4096
VM_VCPUS=4
VM_DISK_SIZE="40G"
ISO_PATH="$HOME/Downloads/ubuntu-25.04-live-server-amd64.iso"
BRIDGE_NAME="virbr0" # Default libvirt bridge, or your custom bridge

export USER_PASSWORD='$6$FkOTB2dbfJoagdiM$Uhf8ZNT7XSuGboY7x7yOrhewj5Xko62RNvZvDniUngSyClkEov3APH5YlGuuSoLQEaAl57LwL8joBqlGFWOgS/'
export SSH_PUB="$(cat ~/.ssh/id_ed25519.pub)"
unset GTK_PATH
unset GIO_MODULE_DIR

cd "$(dirname "$0")" || exit $?

export VM_NAME="$1"
MOUNT_POINT="$(realpath mnt)"

envsubst < user-data.template > user-data

cloud-localds seed.iso user-data meta-data || exit $?

VM_DISK_PATH="$VM_NAME.img"

truncate -s "$VM_DISK_SIZE" "$VM_DISK_PATH"

sudo mount -r "$ISO_PATH" "$MOUNT_POINT" || exit $?
time kvm -no-reboot -m "$VM_RAM" \
    -drive file="$VM_DISK_PATH",format=raw,cache=none,if=virtio \
    -drive file=seed.iso,format=raw,cache=none,if=virtio \
    -netdev bridge,id=net0,br="$BRIDGE_NAME" \
    -device virtio-net-pci,netdev=net0 \
    -cdrom "$ISO_PATH" \
    -kernel "$MOUNT_POINT/casper/vmlinuz" \
    -initrd "$MOUNT_POINT/casper/initrd" \
    -append 'autoinstall' || exit $?

# time sudo virt-install \
#     --name "$VM_NAME" \
#     --memory "$VM_RAM" \
#     --vcpus "$VM_VCPUS" \
#     --disk path="$VM_DISK_PATH",format=raw,bus=virtio \
#     --disk path=seed.iso,format=raw,bus=virtio,device=disk \
#     --location "$ISO_PATH" \
#     --network bridge="$BRIDGE_NAME",model=virtio \
#     --graphics none \
#     --console pty,target_type=serial \
#     --os-variant ubuntu25.04 \
#     --extra-args "console=ttyS0 autoinstall ds=nocloud-net;s=http://_gateway:80/" \
#     --noautoconsole \
#     --wait -1 \
#     || { echo >&2 "Error: virt-install command failed."; exit 1; }

sudo umount "$MOUNT_POINT"
rm seed.iso
