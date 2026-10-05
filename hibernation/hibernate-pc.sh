#!/bin/bash
set -euo pipefail

if ! grep -qw disk /sys/power/state; then
    echo "Hibernation is not supported by this kernel (no 'disk' in /sys/power/state)" >&2
    exit 1
fi

# The hibernation image must fit into free swap
mem_used_kb=$(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {print t-a}' /proc/meminfo)
swap_free_kb=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)
if (( swap_free_kb < mem_used_kb )); then
    echo "Not enough free swap: need ~$((mem_used_kb / 1024)) MiB, have $((swap_free_kb / 1024)) MiB" >&2
    exit 1
fi

echo "Hibernating $(hostname)..."
sync
systemctl hibernate
