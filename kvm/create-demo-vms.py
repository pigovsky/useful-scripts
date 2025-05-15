import os
import shlex
import subprocess
import time


VMs = [
    'seqam-central',
    'app-server',
    'load-server',
    'load-client',
]


VM_IPs = {}


# Retrieve VM IP address via libvirt guest agent
def get_vm_ip(vm_name: str, timeout: int=300):
    start = time.time()
    while time.time() - start < timeout:
        result = subprocess.run(
            shlex.split(
                f'virsh domifaddr --domain "{vm_name}" --source agent'
            ), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        )
        for line in result.stdout.splitlines():
            if "ipv4" in line and 'lo' not in line:
                parts = line.split()
                ip = parts[-1].split("/")[0]
                return ip
        time.sleep(5)
    raise TimeoutError("Timed out waiting for VM IP")


if __name__ == '__main__':
    ROOT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__)))
    os.chdir(ROOT_PATH)
    for vm_name in VMs:
        subprocess.run(
            shlex.split(f'./gimme-ubuntu.sh "{vm_name}"')
        )
        vm_ip = get_vm_ip(vm_name)
        print(f'You can ssh to {vm_name} using ssh u@{vm_ip}')
        VM_IPs[vm_name] = vm_ip
    print(VM_IPs)
