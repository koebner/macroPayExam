#!/bin/bash
# Agregar después del código existente:

# Instalar Ansible
yum install -y epel-release
yum install -y ansible

# Crear directorio para playbook
mkdir -p /etc/ansible/playbooks

# Descargar playbook desde GitHub (raw)
curl -L https://raw.githubusercontent.com/koebner/macroPayExam/refs/heads/master/provision.yml -o /etc/ansible/playbooks/playbook.yml
# O alternativamente usando wget:
# wget -O /etc/ansible/playbooks/playbook.yml https://raw.githubusercontent.com/koebner/macroPayExam/refs/heads/master/provision.yml

# Ejecutar playbook
cd /etc/ansible/playbooks
ansible-playbook playbook.yml