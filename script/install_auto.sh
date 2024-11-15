#!/bin/bash -eux
echo '==> Installing awx components'
dnf install ansible-core -y
dnf install conmon -y
dnf install rsync -y
cp /tmp/ansible-automation-platform-setup-bundle-2.2.0-7.tar.gz /home/vagrant/ansible-automation-platform-setup-bundle-2.2.0-7.tar.gz
cd /home/vagrant
tar -xvf /home/vagrant/ansible-automation-platform-setup-bundle-2.2.0-7.tar.gz
cd ansible-automation-platform-setup-bundle-2.2.0-7
cp inventory inventory.bak
ip4=$(/sbin/ip -o -4 addr list enp1s0 | awk '{print $4}' | cut -d/ -f1)
sed -i '1i192.168.1.249 dbserver' /etc/hosts
sed -i -e "s,\[automationcontroller\],\[automationcontroller\]\n${ip4} ansible_connection=local," inventory
sed -i -e "s,^admin_password=.*,admin_password='password'," inventory
sed -i -e "s,^pg_host='',pg_host='dbserver'," inventory
sed -i -e "s,^pg_password=.*,pg_password='password'," inventory
sed -i -e "s,\[all\:vars\],\[all\:vars\]\nproject_data_dir=/var/lib/awx/projects," inventory
ANSIBLE_BECOME_METHOD='sudo' ANSIBLE_BECOME=True ./setup.sh
# yum groupinstall "Server with GUI"
# systemctl set-default graphical.target
