#!/bin/bash

VM_RAM=4096
VM_VCPUS=4
VM_DISK_SIZE="80G"
ISO_PATH="$HOME/Downloads/ubuntu-25.04-live-server-amd64.iso"
BRIDGE_NAME="virbr0" # Default libvirt bridge, or your custom bridge

export USER_PASSWORD='$6$FkOTB2dbfJoagdiM$Uhf8ZNT7XSuGboY7x7yOrhewj5Xko62RNvZvDniUngSyClkEov3APH5YlGuuSoLQEaAl57LwL8joBqlGFWOgS/'
export SSH_PUB="$(cat ~/.ssh/id_ed25519.pub)"

unset GTK_PATH
unset GIO_MODULE_DIR

cd "$(dirname "$0")" || exit $?

export VM_NAME="$1"
MOUNT_POINT="$(realpath mnt)"

envsubst < user-data.template > www/user-data

cd www
python3 -m http.server 3003 &
WWW_PID="$(ps aux | grep python | grep http.server | grep 3003 |  awk '{print $2}')"
echo WWW_PID $WWW_PID
cd -

# cloud-localds seed.iso user-data meta-data || exit $?

VM_DISK_PATH="$VM_NAME.img"

# truncate -s "$VM_DISK_SIZE" "$VM_DISK_PATH"

# sudo mount -r "$ISO_PATH" "$MOUNT_POINT" || exit $?
# time kvm -no-reboot -m "$VM_RAM" \
#     -drive file="$VM_DISK_PATH",format=raw,cache=none,if=virtio \
#     -drive file=seed.iso,format=raw,cache=none,if=virtio \
#     -netdev bridge,id=net0,br="$BRIDGE_NAME" \
#     -device virtio-net-pci,netdev=net0 \
#     -cdrom "$ISO_PATH" \
#     -kernel "$MOUNT_POINT/casper/vmlinuz" \
#     -initrd "$MOUNT_POINT/casper/initrd" \
#     -append 'autoinstall' || exit $?

time virt-install \
  --name "${VM_NAME}" \
  --ram "${VM_RAM}" \
  --vcpus "${VM_VCPUS}" \
  --os-variant ubuntu25.04 \
  --disk path="${VM_DISK_PATH}",format=qcow2,size=${VM_DISK_SIZE%G} \
  --network bridge="${BRIDGE_NAME}" \
  --graphics none \
  --console pty,target_type=serial \
  --location "${ISO_PATH}",kernel=casper/vmlinuz,initrd=casper/initrd \
  --extra-args "console=ttyS0,115200n8 autoinstall ds=nocloud-net;s=http://_gateway:3003/" \
  --autostart \
  --noautoconsole \
  --wait -1 \
    || { echo >&2 "Error: virt-install command failed."; exit 1; }

echo kill "$WWW_PID"
kill "$WWW_PID"
# sudo umount "$MOUNT_POINT"
# rm seed.iso
