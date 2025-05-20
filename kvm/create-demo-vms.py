import os
import shlex
import subprocess
import time


HOME = os.getenv('HOME')
UBUNTU_SERVER_ISO = f'{HOME}/Downloads/soft/ubuntu-25.04-live-server-amd64.iso'
UBUNTU_DESKTOP_ISO = f'{HOME}/Downloads/soft/ubuntu-25.04-desktop-amd64.iso'
PLATFORM_BIN_DISTRIB = 'seqam-bin-v0.30.0-20250515.tgz'
PLATFORM_BIN_DISTRIB_PATH = f'{HOME}/{PLATFORM_BIN_DISTRIB}'
PLATFROM_FOLDER = 'seqam'
SSH_USER = 'u'


def deploy_central_component(central_ip: str):
    run_ssh(central_ip, f'mkdir -p {PLATFROM_FOLDER}')
    run_scp(PLATFORM_BIN_DISTRIB_PATH, central_ip, PLATFROM_FOLDER)
    run_scp('deploy/deploy-central-component-0.sh', central_ip)
    run_ssh(central_ip, f'./deploy-central-component-0.sh "{PLATFORM_BIN_DISTRIB}" "{PLATFROM_FOLDER}"')
    run_scp('deploy/deploy-central-component-1.sh', central_ip)
    run_ssh(central_ip, f'./deploy-central-component-1.sh "{central_ip}" "{PLATFROM_FOLDER}"')


def deploy_app_client(vm_ip: str):
    central_ip = install_docker_on_vm(vm_ip)
    install_distributed_manager_on_vm(central_ip, vm_ip)
    start_component(central_ip, vm_ip, 'ue', 'app-client')
    # run_ssh(vm_ip, 'git clone ')


def deploy_app_server(vm_ip: str):
    central_ip = install_docker_on_vm(vm_ip)
    install_distributed_manager_on_vm(central_ip, vm_ip)
    start_component(central_ip, vm_ip, 'server', 'app-server')
    run_scp(
        f'{SSH_USER}@{central_ip}:{PLATFROM_FOLDER}/bare-composes/rome-demo/',
        vm_ip
    )
    run_ssh(vm_ip, './load-image.sh rome-demo/rome-demo.tar.gz')
    run_ssh(vm_ip, 'cd rome-demo; docker compose up -d')



def deploy_load_server(vm_ip: str):
    central_ip = install_docker_on_vm(vm_ip)
    install_network_manager_on_vm(central_ip, vm_ip)
    start_component(central_ip, vm_ip, 'server', 'load-server')


def deploy_load_client(vm_ip: str):
    central_ip = install_docker_on_vm(vm_ip)
    install_network_manager_on_vm(central_ip, vm_ip)
    start_component(central_ip, vm_ip, 'ue', 'load-client')


def start_component(central_ip, vm_ip, device_type, device_name):
    run_scp(
        f'{SSH_USER}@{central_ip}:{PLATFROM_FOLDER}/bare-composes/seqam-docker-compose-tree/{device_type}/{device_name}',
        vm_ip
    )
    run_ssh(vm_ip, f"cd {device_name}; docker compose up -d")


def install_distributed_manager_on_vm(central_ip, vm_ip):
    run_scp(
        f'{SSH_USER}@{central_ip}:{PLATFROM_FOLDER}/bare-composes/seqam-distributed-event-manager',
        vm_ip
    )
    run_ssh(vm_ip, './load-image.sh seqam-distributed-event-manager/seqam-distributed-event-manager.tar.gz')


def install_network_manager_on_vm(central_ip: str, vm_ip: str):
    run_scp(
        f'{SSH_USER}@{central_ip}:{PLATFROM_FOLDER}/bare-composes/seqam-network-event-manager',
        vm_ip
    )
    run_ssh(vm_ip, './load-image.sh seqam-network-event-manager/seqam-network-event-manager.tar.gz')


def install_docker_on_vm(vm_ip: str):
    central_ip = VM_IPs['seqam-central']
    run_scp(
        f'{SSH_USER}@{central_ip}:{PLATFROM_FOLDER}/scripts/install-docker.sh',
        vm_ip
    )
    run_ssh(vm_ip, './install-docker.sh')
    run_scp(
        f'{SSH_USER}@{central_ip}:{PLATFROM_FOLDER}/bare-composes/load-image.sh',
        vm_ip
    )
    return central_ip


VMs = {
    'seqam-central': {
        'deploy': deploy_central_component,
        'os': UBUNTU_SERVER_ISO,
        'disk': '80G'
    },
    'app-client': {
        'deploy': deploy_app_client,
        'os': UBUNTU_DESKTOP_ISO,
        'disk': '40G'
    },
    'app-server': {
        'deploy': deploy_app_server,
        'os': UBUNTU_SERVER_ISO,
        'disk': '40G'
    },
    'load-server': {
        'deploy': deploy_load_server,
        'os': UBUNTU_SERVER_ISO,
        'disk': '40G',
    },
    'load-client': {
        'deploy': deploy_load_client,
        'os': UBUNTU_SERVER_ISO,
        'disk': '40G',
    },
}


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


def run_ssh(vm_ip: str, command: str):
    run_cmd(
        f"ssh {SSH_USER}@{vm_ip} "
        "-o StrictHostKeyChecking=no "
        f'{command}', check=True
    )


def run_scp(source: str, vm_ip: str, destination: str = ''):
    run_cmd(
        "scp -o StrictHostKeyChecking=no -r "
        f"{source} {SSH_USER}@{vm_ip}:{destination}", 
        check=True
    )


if __name__ == '__main__':
    ROOT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__)))
    os.chdir(ROOT_PATH)
    for vm_name, details in VMs.items():
        vm_ip = get_vm_ip(vm_name)
        if not vm_ip:
            os_iso = details['os']
            disk_size = details['disk']
            run_cmd(
                f'./gimme-ubuntu.sh "{vm_name}" "{os_iso}" "{disk_size}"'
            )
            vm_ip = get_vm_ip_with_retries(vm_name)
        print(f'You can ssh to {vm_name} using ssh u@{vm_ip}')
        run_cmd(
            f'gnome-terminal -- ssh {SSH_USER}@{vm_ip} -o StrictHostKeyChecking=no'
        )
        VM_IPs[vm_name] = vm_ip
        deploy_fun = details['deploy']
        if deploy_fun:
            deploy_fun(vm_ip)
    with open('machine-ips.txt', 'a') as file:
        for vm_name, vm_ip in VM_IPs.items():
            file.write(f"{vm_name}: {vm_ip}\n")
    print(VM_IPs)
