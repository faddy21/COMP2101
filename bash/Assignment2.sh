#!/bin/bash

# Function to check if a package is installed
is_package_installed() {
    dpkg-query --show --showformat='${db:Status-Status}\n' "$1" 2>/dev/null | grep -q "installed"
}

# Function to configure UFW
configure_ufw() {
    if ! ufw status | grep -q "Status: active"; then
        echo "Enabling and configuring UFW"
        ufw allow 22
        ufw allow 80
        ufw allow 443
        ufw allow 3128
        ufw --force enable
    else
        echo "UFW is already active with required rules"
    fi
}

# Function to create user and configure SSH keys
create_user() {
    local username=$1
    local sudo_user=$2

    if id "$username" &>/dev/null; then
        echo "User $username already exists."
    else
        echo "Creating user $username"
        useradd -m -s /bin/bash "$username"
    fi

    local user_ssh_dir="/home/$username/.ssh"
    local auth_keys="$user_ssh_dir/authorized_keys"

    mkdir -p "$user_ssh_dir"
    touch "$auth_keys"
    chown -R "$username:$username" "$user_ssh_dir"
    chmod 700 "$user_ssh_dir"
    chmod 600 "$auth_keys"

    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "$auth_keys"

    if [ "$username" == "$sudo_user" ]; then
        usermod -aG sudo "$username"
        echo "User $username given sudo access"
    fi
}

# Check and install OpenSSH server if not installed
if ! is_package_installed "openssh-server"; then
    echo "Installing OpenSSH server..."
    apt-get update > /dev/null
    apt-get install -y openssh-server > /dev/null
else
    echo "OpenSSH server is already installed. Skipping installation."
fi

# Check and configure OpenSSH for key authentication
if ! grep -q "PasswordAuthentication no" /etc/ssh/sshd_config; then
    # Backup sshd_config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # Configure OpenSSH server for key authentication
    echo -e "\n# SSH Key Authentication Configuration\nPasswordAuthentication no" >> /etc/ssh/sshd_config
    systemctl restart ssh
    echo "OpenSSH configured for key authentication."
else
    echo "OpenSSH is already configured for key authentication. Skipping configuration."
fi

# Check and install Apache2 if not installed
if ! is_package_installed "apache2"; then
    echo "Installing Apache2..."
    apt-get update > /dev/null
    apt-get install -y apache2 > /dev/null
else
    echo "Apache2 is already installed. Skipping installation."
fi

# Check and configure Apache to listen on port 80 and 443
if ! grep -E -q "^\s*Listen\s+80\s*$|^\s*Listen\s+443\s*$" /etc/apache2/apache2.conf; then
    # Configure Apache
    echo -e "\n# Apache Configuration\nListen 80\nListen 443" >> /etc/apache2/apache2.conf
    systemctl restart apache2
    echo "Apache configured to listen on ports 80 and 443."
else
    echo "Apache is already configured to listen on ports 80 and 443. Skipping configuration."
fi

# Check and install Squid if not installed
if ! is_package_installed "squid"; then
    echo "Installing Squid..."
    apt-get update > /dev/null
    apt-get install -y squid > /dev/null
else
    echo "Squid is already installed. Skipping installation."
fi

# Check and configure Squid to listen on port 3128
if ! grep -q "http_port 3128" /etc/squid/squid.conf; then
    # Backup squid.conf
    cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

    # Configure Squid
    sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf
    systemctl restart squid
    echo "Squid configured to listen on port 3128."
else
    echo "Squid is already configured to listen on port 3128. Skipping configuration."
fi

echo "Setup complete. OpenSSH, Apache, and Squid are installed and configured."

# Check and configure UFW
configure_ufw

# Create user accounts
user_list=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for user in "${user_list[@]}"; do
    create_user "$user" "dennis"
done
echo "good bye ?"
