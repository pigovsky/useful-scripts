#!/bin/bash
set -euo pipefail

# Installs the latest AusweisApp release from Flathub, plus the PC/SC daemon
# needed for USB/NFC card readers (the Flatpak talks to the host's pcscd).
# Upstream: https://www.ausweisapp.bund.de/open-source-software

APP_ID=de.bund.ausweisapp.ausweisapp2

echo "Installing flatpak and PC/SC card reader support..."
sudo apt-get update
sudo apt-get install -y flatpak pcscd
sudo systemctl enable --now pcscd.socket

echo "Adding Flathub remote..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Installing AusweisApp from Flathub..."
sudo flatpak install -y --noninteractive flathub "$APP_ID"

echo "✅ Done. Start it from the app menu or run: flatpak run $APP_ID"
echo "   (If it doesn't show up in the menu, log out and back in once.)"
