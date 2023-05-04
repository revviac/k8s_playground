# 1. Environment setup

This project uses 3 nodes (1 manager and 2 worker nodes) with the following IPs:
- manager: 192.168.50.16 [vbox16]
- worker1: 192.168.50.32 [vbox32]
- worker2: 192.168.50.48 [vbox48]

For this project the nodes are supposed to be actual virtual machines running Ubuntu 20.04 (`ubuntu-20.04-server-cloudimg-amd64`). The project wasn't tested on other
linux distributions.

---
## Setting up the VM in VirtualBox
1. Image: `ubuntu-20.04-server-cloudimg-amd64`
2. VM configuration:
    * display: vmsvga
    * storage: [ide controller] `ubuntu-cloud-init-data.iso`
3. Network configuration: configure netplan (`etc/netplan/01-netcfg.yaml`) as follows, and then apply it (`sudo netplan apply`):
```
network:
  version: 2
  renderer: networkd
  ethernets:
     enp0s3:
        dhcp4: yes
     enp0s8:
        dhcp4: no
        addresses: [192.168.50.XX/24]
```
4. Configure hostname to be manager/worker1/worker2 using `hostname`
---
## Setting up the SSH connection
Here all the keys are saved to `~/.ssh/vbox`. If this directory does not exist, create it using `mkdir -p ~/.ssh/vbox`. 
All nodes are going to be called `vboxXX`, where XX are the last digits of their IP address (i.e. vbox16, vbox32, vbox48)

1. Move to `~/.ssh/vbox` using `cd`
1. Create a key pair using ssh-keygen: `ssh-keygen -t rsa -f vboxXX`
1. Copy the generated key using ssh-copy-id: `ssh-copy-id -i vboxXX ubuntu@192.168.50.XX`
1. Create an entry in the SSH config file (`~/.ssh/config`) for each machine:
```
Host vboxXX:
  HostName: 192.168.50.XX
  UserName: ubuntu
  IdentityFile: ~/.ssh/vbox/vboxXX
```
