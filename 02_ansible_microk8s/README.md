# 2. Setting up ansible & microk8s

1. Create the inventory file (see `inventory` for INI format)
2. Create ansible SSH-key: `ssh-keygen –t rsa –f ~/.ssh/ansible`
3. Set up the ansible configuration (run `setup_ansible.sh` or the following commands manually):
    * Create a folder for the inventory file: `sudo mkdir -p /etc/ansible/k8s_playground`
    * Copy the inventory file to the new directory: `sudo cp inventory /etc/ansible/k8s_playground/inventory`
    * Copy the configuration file to /etc/ansible: `sudo cp ansible.cfg /etc/ansible/ansible.cfg`
4. (Optional) Ensure the ansible setup has been done correctly: `ansible all -m ping`
5. Install the microk8s on all nodes: `ansible-playbook playbooks/install_k8s.yaml`
6. Setup the hosts (`/etc/hosts`) on the control plane (192.168.50.16 or manager):
```
192.168.50.32 worker1
192.168.50.48 worker2
```
7. Configure cluster: `ansible-playbook playbooks/configure_cluster.yaml`
8. Install plugins: `ansible-playbook playbooks/install_plugins.yaml`