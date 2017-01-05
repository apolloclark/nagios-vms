#!/usr/bin/env bash

# set the environment to be noninteractive
export DEBIAN_FRONTEND=noninteractive

# update and upgrade apt
apt-get update
apt-get upgrade -y



# install nagios3
apt-get install -y nagios3

# set the admin password
htpasswd -bc /etc/nagios3/htpasswd.users nagiosadmin nagiosadmin

# update /etc/hosts
echo "192.168.56.102 www.nagios.org" | sudo tee -a /etc/hosts
