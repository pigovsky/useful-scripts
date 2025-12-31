#!/bin/bash

# --- 1. Check Hardware Virtualization Support ---
echo "Checking hardware virtualization support..."
# Checks if the count of vmx (Intel) or svm (AMD) flags is greater than 0
VIRT_SUPPORT=$(egrep -c '(vmx|svm)' /proc/cpuinfo)

if [ "$VIRT_SUPPORT" -eq 0 ]; then
    echo "❌ ERROR: Hardware virtualization (VT-x/AMD-V) is not enabled in your BIOS/UEFI."
    echo "Please enable it before proceeding."
    exit 1
else
    echo "✅ Virtualization support detected."
fi

# --- 2. Update System Packages ---
echo "Updating package lists..."
sudo apt update

# --- 3. Install KVM and Management Tools ---
echo "Installing KVM, Libvirt, and Virt-Manager..."
# qemu-kvm: The backend emulator
# libvirt-daemon-system: Configuration files to run libvirt as a system service
# libvirt-clients: Command-line tools to manage virtualization (virsh)
# bridge-utils: Tools for configuring network bridges
# virt-manager: GUI interface for managing VMs
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager

# --- 4. Verify Libvirt Daemon Status ---
echo "Checking libvirtd service status..."
sudo systemctl is-active --quiet libvirtd
if [ $? -eq 0 ]; then
    echo "✅ libvirtd is running."
else
    echo "Starting and enabling libvirtd..."
    sudo systemctl enable --now libvirtd
fi

# --- 5. Add User to Required Groups ---
echo "Adding current user ($USER) to libvirt and kvm groups..."
# This allows you to manage VMs without using 'sudo' every time.
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# --- 6. Final Verification ---
echo "--- Installation Complete ---"
echo "Verifying KVM installation via virsh:"
virsh list --all

echo ""
echo "******************************************************************"
echo "⚠️  IMPORTANT: For the group changes to take effect, you MUST:"
echo "   1. Log out and log back in, OR"
echo "   2. Restart your computer."
echo "******************************************************************"
echo "After logging back in, you can launch 'Virtual Machine Manager' from your app menu."

