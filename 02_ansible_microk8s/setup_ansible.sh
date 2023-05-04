#!/usr/bin/env bash
set -E

sudo mkdir -p /etc/ansible/k8s_playground

# Copy inventory & config
sudo cp inventory /etc/ansible/k8s_playground/inventory
sudo cp ansible.cfg /etc/ansible/ansible.cfg