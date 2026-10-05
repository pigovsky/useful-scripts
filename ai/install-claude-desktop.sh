#!/bin/bash
set -euo pipefail

# Installs Claude Desktop on Linux (Ubuntu 22.04+ / Debian 12+, x86_64 or arm64)
# via Anthropic's official apt repository (beta).
# Source: https://support.claude.com/en/articles/10065433-install-claude-desktop

KEYRING=/usr/share/keyrings/claude-desktop-archive-keyring.asc
EXPECTED_FINGERPRINT="31DD DE24 DDFA B679 F42D  7BD2 BAA9 29FF 1A7E CACE"

# --- 1. Add Anthropic's signing key ---
echo "Adding Claude Desktop signing key..."
sudo curl -fsSLo "$KEYRING" https://downloads.claude.ai/claude-desktop/key.asc

echo "Verifying key fingerprint..."
ACTUAL_FINGERPRINT=$(gpg --show-keys --with-colons "$KEYRING" | awk -F: '/^fpr:/ { print $10; exit }')
if [ "${ACTUAL_FINGERPRINT// /}" != "${EXPECTED_FINGERPRINT// /}" ]; then
    echo "❌ ERROR: Key fingerprint mismatch."
    echo "   Expected: $EXPECTED_FINGERPRINT"
    echo "   Got:      $ACTUAL_FINGERPRINT"
    exit 1
fi
echo "✅ Fingerprint verified."

# --- 2. Add the apt repository ---
echo "Adding Claude Desktop apt repository..."
echo "deb [signed-by=$KEYRING] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
    | sudo tee /etc/apt/sources.list.d/claude-desktop.list > /dev/null

# --- 3. Install ---
echo "Updating package lists and installing claude-desktop..."
sudo apt update
sudo apt install -y claude-desktop

# --- 4. Done ---
echo "--- Installation Complete ---"
echo "✅ Claude Desktop installed."
echo "Launch it from your applications menu or run 'claude-desktop'."
echo ""
echo "Note: this is a Linux beta — Computer Use and voice dictation aren't"
echo "available yet; use the CLI for those. Updates arrive via"
echo "'sudo apt update && sudo apt upgrade', not an in-app updater."
