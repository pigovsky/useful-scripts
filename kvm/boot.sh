#!/bin/bash

unset GTK_PATH
unset GIO_MODULE_DIR

kvm -no-reboot -m 2048 \
    -drive file="$1",format=raw,cache=none,if=virtio
