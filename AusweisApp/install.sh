#!/bin/bash
set -euo pipefail

# Installs AusweisApp (German eID client) on Ubuntu from the universe repo,
# plus the PC/SC daemon needed for USB/NFC card readers.
# Upstream: https://www.ausweisapp.bund.de/open-source-software
# (Upstream also publishes the newest release on Flathub as de.bund.ausweisapp.ausweisapp2.)

echo "Installing AusweisApp and PC/SC card reader support..."
sudo apt-get update
sudo apt-get install -y ausweisapp pcscd

echo "Enabling pcscd socket..."
sudo systemctl enable --now pcscd.socket

echo "✅ Done. Start it from the app menu or run: AusweisApp"
