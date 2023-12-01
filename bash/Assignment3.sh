#!/bin/bash

# Execute via SSH on target1-mgmt
function ssh_target1 {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_ed25519 remoteadmin@172.16.1.10 "$@"
}
# Execute via SSH on target2-mgmt
function ssh_target2 {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_ed25519 remoteadmin@172.16.1.11 "$@"
}

function update_upgrade {
	sudo apt update
	sudo apt upgrade -y
}

# Update and upgrade the system
 update_upgrade
# Exit if any command returns a non-zero status
set -e

# Check  configurations on target1-mgmt  already applied
ssh_target1 'grep loghost /etc/hosts' && {
    echo "Configurations on target1-mgmt already applied. Skipping..."
} || {
    # Execute commands on target1-mgmt
    ssh_target1 '
       	update_upgrade
	sudo hostnamectl set-hostname loghost
        sudo sed -i "s/target1/loghost/g" /etc/hosts

        sudo sed -i "s/172.16.1.10/172.16.1.3/g" /etc/netplan/*.yaml
        sudo netplan apply

        echo "172.16.1.4 webhost" | sudo tee -a /etc/hosts > /dev/null

        sudo apt update
        sudo apt install ufw -y
        sudo ufw allow from 172.16.1.0/24 to any port 514/udp

        sudo sed -i "/^#module(load=\"imudp\"/s/^#//g" /etc/rsyslog.conf
        sudo sed -i "/^#input(type=\"imudp\"/s/^#//g" /etc/rsyslog.conf
        sudo systemctl restart rsyslog
    ' || { echo "Error occurred on target1-mgmt"; exit 1; }
}

# Check configurations on target2-mgmt already applied
ssh_target2 'grep webhost /etc/hosts' && {
    echo "Configurations on target2-mgmt already applied. Skipping..."
} || {
    # Execute commands on target2-mgmt
    ssh_target2 '
	update_upgrade
        sudo hostnamectl set-hostname webhost
        sudo sed -i "s/target2/webhost/g" /etc/hosts

        sudo sed -i "s/172.16.1.11/172.16.1.4/g" /etc/netplan/*.yaml
        sudo netplan apply

        echo "172.16.1.3 loghost" | sudo tee -a /etc/hosts > /dev/null

        sudo apt update
        sudo apt install ufw -y
        sudo ufw allow 80/tcp

        sudo apt install apache2 -y

        echo ". @loghost" | sudo tee -a /etc/rsyslog.conf > /dev/null
        sudo systemctl restart rsyslog
    ' || { echo "Error occurred on target2-mgmt"; exit 1; }
}

# Reset the set -e option to not exit immediately
set +e

# Update NMS /etc/hosts file
sudo sed -i '/loghost/d' /etc/hosts
sudo sed -i '/webhost/d' /etc/hosts
echo "172.16.1.3 loghost" | sudo tee -a /etc/hosts > /dev/null
echo "172.16.1.4 webhost" | sudo tee -a /etc/hosts > /dev/null

# Verify configurations using curl
curl -IsS http://webhost >/dev/null 2>&1

# Check if configurations were successful
if [ $? -eq 0 ]; then
    echo "Configuration update succeeded. Web server is accessible."
else
    echo "Configuration update failed or web server is not accessible."
fi

# Check logs on loghost
ssh_target1 'grep webhost /var/log/syslog'

