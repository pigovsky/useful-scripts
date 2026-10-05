#!/bin/bash
set -euo pipefail

# Installs and enables the OpenSSH server (sshd) on Ubuntu/Debian.

echo "Installing openssh-server..."
sudo apt update
sudo apt install -y openssh-server

# Ubuntu 22.10+ starts sshd on demand via ssh.socket; older releases use ssh.service.
echo "Enabling and starting sshd..."
if systemctl list-unit-files ssh.socket > /dev/null 2>&1; then
    sudo systemctl enable --now ssh.socket
else
    sudo systemctl enable --now ssh.service
fi

# Allow SSH through ufw if it's active.
if command -v ufw > /dev/null && sudo ufw status | grep -q "Status: active"; then
    echo "Allowing SSH through ufw..."
    sudo ufw allow OpenSSH
fi

echo "--- Installation Complete ---"
echo "✅ sshd is listening:"
sudo ss -tlnp | grep -E ':22\b' || true
echo "Connect with: ssh $USER@$(hostname -I | awk '{print $1}')"
