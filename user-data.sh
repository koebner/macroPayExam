#!/bin/bash
yum update -y
yum -y remove httpd
yum -y remove httpd-tools
yum install -y nginx php72 mysql57-server php72-mysqlnd
service nginx start
chkconfig nginx on

usermod -a -G nginx ec2-user
chown -R ec2-user:nginx /usr/share/nginx/html
chmod 2775 /usr/share/nginx/html
find /usr/share/nginx/html -type d -exec chmod 2775 {} \;
find /usr/share/nginx/html -type f -exec chmod 0664 {} \;
cd /usr/share/nginx/html
echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/phpinfo.php
echo "<h1>MacroPay Examen</h1>" > /usr/share/nginx/html/index.html

# # Instalar Ansible

# Crear directorio para playbook
mkdir -p /etc/ansible/playbooks

# Descargar playbook desde GitHub (raw)
curl -L https://raw.githubusercontent.com/koebner/macroPayExam/refs/heads/master/provision.yml -o /etc/ansible/playbooks/playbook.yml
# O alternativamente usando wget:
# wget -O /etc/ansible/playbooks/playbook.yml https://raw.githubusercontent.com/koebner/macroPayExam/refs/heads/master/provision.yml

# Ejecutar playbook
cd /etc/ansible/playbooks
ansible-playbook playbook.yml