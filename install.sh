#!/bin/bash

# Script to setup system for ansible:
#  - installs openssh-server and generates ssh private key
#  - sets up key auth for localhost (use: ssh 'yourhostname') 
#  - installs ansible and adds hostname to ansible inventory  


# make sure this script is not run as root
if [ "$EUID" -eq 0 ]; then
    echo "DO NOT run this script as root. You will be asked for sudo password."
    exit 1
fi

# stop and listen before delete ~/.ssh config
if [ -d $HOME/.ssh ]; then echo -e -n "~/.ssh folder found. If you continue this folder will be deleted. Continue? (yes/no): " 
    read answer
    case "$answer" in
        yes|Yes|YES|y)
            rm -r $HOME/.ssh/ 
            ;;
        no|No|NO|n)
            exit 2
            ;;
        *)
            echo "Type 'yes' or  'no'"
            exit 3
            ;;
    esac
fi    

# ask user for new ssh-passphrase
echo -e "Enter passphrase for your new ssh-key:"
read -s passphrase

# install ansible and ssh server 
#sudo apt-get install software-properties-common
#sudo apt-add-repository ppa:ansible/ansible -y
sudo apt-get update
sudo apt-get install openssh-server ansible -y  

# modify /etc/ansible/hosts file
if [ -e /etc/ansible/hosts ]; then
    echo 'Modifying ansible hosts file...'
    echo $HOSTNAME | sudo tee /etc/ansible/hosts > /dev/null
fi

# disable sudo password for 'sudo' group
sudo sed -i 's/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# generate ssh keys and enable key-auth locally 
ssh-keygen -t rsa -b 4096 -N "$passphrase" -f $HOME/.ssh/id_rsa
ssh-copy-id $HOSTNAME
ssh-add

# exec ansible-playbook
echo -e "Do you want to run site.yml playbook with ansible NOW? (y/n)"
read -s ansible
case "$ansible" in
    yes|Yes|YES|y)
        ansible-playbook site.yml
	;;
    no|No|NO|n)
        exit 2
        ;;
    *)
        echo "Type 'yes' or 'no'"
        exit 3
        ;;
esac

