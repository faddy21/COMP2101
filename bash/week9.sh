#!/bin/bash


#this will check to see if the required package is installed
installation_check() {
	dpkg-query --show --showformat='${db:Status-Status}\n' "$1" |grep -q "installed"
}

echo "---Checking and configuring required software--- "

#will check and install openssh server if not installed
echo "installing openssh-server "
if ! installation_check "openssh-server"; then
	echo "Installing Openssh server"
	apt-get update > /dev/null
	apt-get install -y openssh-server > /dev/null
else
	echo "Openssh server is allready installed "
fi

#check and configure openssh for key authentication 
echo "Configuring OpenSSH to allow key authentication and deny password authentication"
if ! grep -q "PasswordAuthentication no" /etc/ssh/sshd_config; then
	#configure openssh to allow key authentication and not password authentication
	echo -e "\n# SSH Key Authentication Configuration\nPasswordAuthentication no" >> /etc/ssh/sshd_config
	systemctl restart ssh
	echo "Openssh configured to allow key authentication"
else 
	echo "Openssh is already configured to allow key authentication"
fi

#will check and install apache2 if not installed
echo "installing apache2"
if ! installation_check "apache2"; then
        echo "Installing apache2"
        apt-get update > /dev/null
        apt-get install -y apache2 > /dev/null
else
        echo "Apache2 is allready installed "
fi

#check and configure  apache to listen on port 80 and 443
echo "configuring apache to listen on port 80 and 443"
if ! grep -q "Listen 80\nListen 443" /etc/apache2/apache2.conf; then
	echo -e "\n# Apache Configuration\nListen 80\nListen 443" >> /etc/apache2/apache2.conf
	systemctl restart apache2
	echo "apache configured to listen on ports 80 and 443"
else 
	echo "apache is already configured to listen on ports 80 and 443"
fi

#check and install squid if not installed 
echo "installing squid"
if ! installation_check "squid"; then
	echo "Installing squid"
        apt-get update > /dev/null
        apt-get install -y squid  >/dev/null
else
        echo "Squid is allready installed "
fi

if ! grep -q "http_port 3128" /etc/squid/squid.conf; then
	#configure squid
	sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf
	systemctl restart squid
	echo "squid is configured to listen on port 3128"
else
	echo "squid  is already listening on port 3128"
fi

#check and configure ufw
echo  "configuring ufw"
if  installation_check "ufw"; then
	echo "installing ufw"
	apt-get update  > /dev/null
	apt-get install -y ufw >/dev/null

	#enable ufw
	ufw enable
	#allow  ssh on port 22
	ufw allow 22
	#allow  http on port 80
        ufw allow 80
	#allow  https on port 443
        ufw allow 443
	#allow web proxy on port 3128
	ufw allow 3128
	#apply changes 
	ufw reload
	echo "firewall configured"
fi

#user account list 
account_users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

#user check
for user in "${account_users[@]}"; do
	if id "$user" > /dev/null; then
		echo "user $user already exits."
	else
		#creating users with home directory and bash as default shell
		useradd -m -s /bin/bash "$user"

		#SSH key for users
		mkdir -p /home/"$user"/.ssh
		touch /home/"$user"/.ssh/authorized_keys
		chown -R "$user":"$user"/home/"$user"/.ssh
		chmod 700 /home/"$user"/.ssh
		chmod 600 /home/"$user".ssh/authorized_keys
	fi
done

#add public keys to authorized_keys file for each of the users 
for user in "${account_users[@]}"; do
	echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> /home/dennis/.ssh/authorized_keys
done

echo "giving user dennis sudo acces"
usermod -aG sudo dennis
echo "dennis was given sudo acces "
echo "goodbye"
