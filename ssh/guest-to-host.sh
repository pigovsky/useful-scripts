#!/bin/bash
set -euo pipefail

# Run inside a KVM/libvirt guest: sets up key-based ssh from the guest to its host.
# With libvirt's default NAT network the host is the guest's default gateway (virbr0, usually 192.168.122.1).
# The host must run sshd (see install.sh in this directory).
# usage: guest-to-host.sh <host-user> [host-ip] [alias]
# afterwards: ssh <alias>   (default alias: kvm-host)

HOST_USER="${1:?usage: $0 <host-user> [host-ip] [alias]}"
HOST_IP="${2:-$(ip route show default | awk '/default/ {print $3; exit}')}"
ALIAS="${3:-kvm-host}"
KEY="$HOME/.ssh/id_ed25519"

if [ -z "$HOST_IP" ]; then
    echo "Could not detect host IP (no default route); pass it as the 2nd argument." >&2
    exit 1
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$KEY" ]; then
    echo "Generating ssh key $KEY..."
    ssh-keygen -t ed25519 -N "" -f "$KEY" -C "$USER@$(hostname)"
fi

# Asks for the host user's password once.
echo "Copying key to $HOST_USER@$HOST_IP..."
ssh-copy-id -i "$KEY.pub" -o StrictHostKeyChecking=accept-new "$HOST_USER@$HOST_IP"

CONFIG="$HOME/.ssh/config"
touch "$CONFIG"
chmod 600 "$CONFIG"
if ! grep -qE "^Host $ALIAS\$" "$CONFIG"; then
    cat >> "$CONFIG" <<EOF

Host $ALIAS
    HostName $HOST_IP
    User $HOST_USER
    IdentityFile $KEY
EOF
fi

echo "✅ Done. Connect with: ssh $ALIAS"
ssh "$ALIAS" 'echo "Hello from $(hostname)"'
