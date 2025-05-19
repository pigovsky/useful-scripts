import os
import shlex
import subprocess
import time

DEPLOY_PLATFORM = True
PLATFORM_BIN_DISTRIB = 'seqam-bin-v0.30.0-20250515.tgz'
PLATFORM_BIN_DISTRIB_PATH = f'/tmp/{PLATFORM_BIN_DISTRIB}'
PLATFROM_FOLDER = 'seqam'
SSH_USER = 'u'


VMs = [
    'seqam-central',
    'app-server',
    'load-server',
    'load-client',
]


VM_IPs = {}


def run_cmd(cmd: str, **kwargs):
    return subprocess.run(
        shlex.split(
            cmd
        ), **kwargs
    )


def run_cmd_with_res(cmd: str):
    return run_cmd(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
    )


def get_vm_ip(vm_name: str) -> str | None:
    result = run_cmd_with_res(
        f'virsh domifaddr --domain "{vm_name}" --source agent'
    )
    for line in result.stdout.splitlines():
        if "ipv4" in line and 'lo' not in line:
            parts = line.split()
            ip = parts[-1].split("/")[0]
            return ip
    return None


# Retrieve VM IP address via libvirt guest agent
def get_vm_ip_with_retries(vm_name: str, timeout: int=300):
    start = time.time()
    while time.time() - start < timeout:
        vm_ip = get_vm_ip(vm_name)
        if vm_ip:
            return vm_ip
        time.sleep(5)
    raise TimeoutError("Timed out waiting for VM IP")


# Run a remote command via SSH
def run_ssh(vm_ip: str, command: str):
    run_cmd(
        f"ssh {SSH_USER}@{vm_ip} "
        "-o StrictHostKeyChecking=no "
        f'{command}', check=True
    )


def deploy_central_component(central_ip: str):
    run_ssh(central_ip, f'mkdir {PLATFROM_FOLDER}')
    run_cmd(f'scp {PLATFORM_BIN_DISTRIB_PATH} {SSH_USER}@{central_ip}:{PLATFROM_FOLDER}')
    run_cmd(f'scp deploy/deploy-central-component.sh {SSH_USER}@{central_ip}:')
    run_ssh(central_ip, './deploy-central-component.sh')


if __name__ == '__main__':
    ROOT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__)))
    os.chdir(ROOT_PATH)
    for vm_name in VMs:
        vm_ip = get_vm_ip(vm_name)
        if not vm_ip:
            run_cmd(
                f'./gimme-ubuntu.sh "{vm_name}"'
            )
            vm_ip = get_vm_ip_with_retries(vm_name)
        print(f'You can ssh to {vm_name} using ssh u@{vm_ip}')
        run_cmd(
            f'gnome-terminal -- ssh u@{vm_ip} -o StrictHostKeyChecking=no'
        )
        VM_IPs[vm_name] = vm_ip
    with open('machine-ips.txt', 'a') as file:
        for vm_name, vm_ip in VM_IPs.items():
            file.write(f"{vm_name}: {vm_ip}\n")
    print(VM_IPs)

    if DEPLOY_PLATFORM:
        central_ip = VM_IPs['seqam-central']
        deploy_central_component(central_ip)
