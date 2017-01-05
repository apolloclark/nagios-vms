#!/usr/bin/env bash
# http://everythingshouldbevirtual.com/installing-nagios-on-ubuntu-12-04

# set the environment to be noninteractive
export DEBIAN_FRONTEND=noninteractive

# update and upgrade apt
apt-get update
apt-get upgrade -y



# install depedencies
apt-get -y -qq install build-essential apache2 apache2-utils php5 php5-gd \
	libapache2-mod-php5 libssl-dev libgd2-xpm-dev \
	xinetd daemon mrtg unzip openssl wget
apt-get -y -qq install sendmail > /dev/null 2>&1 # very noisey install...



# add Nagios users and group
useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios
usermod -a -G nagcmd www-data

# download, extract, configure, install Nagios
cd /tmp
wget -q http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-$NAGIOS_VER.tar.gz
tar xzf nagios-$NAGIOS_VER.tar.gz
cd ./nagios*
./configure --with-nagios-group=nagios --with-command-group=nagcmd
./configure --with-mail=/usr/bin/sendmail > /dev/null

# make and install
make -s all
make -s install
make -s install-init
make -s install-config
make -s install-commandmode

# fix issue with installer for 3x
# https://support.nagios.com/forum/viewtopic.php?f=7&t=3906
cp -R /tmp/nagios/html/includes/rss/extlib /usr/local/nagios/share/includes/rss

# configure Apache
cp ./sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf
chmod 644 /etc/apache2/sites-available/nagios.conf
ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/nagios.conf
htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin
a2enmod rewrite && a2enmod cgi

# setup event handlers
cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers

# setup checkresults folder
mkdir -p /usr/local/nagios/var/spool/checkresults
chown -R nagios:nagios /usr/local/nagios/

# verify the configuration
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# setup the systemd nagios service
cat << 'EOF' > /etc/systemd/system/nagios.service
[Unit]
Description=Nagios
BindTo=network.target

[Install]
WantedBy=multi-user.target

[Service]
User=nagios
Group=nagios
Type=simple
ExecStart=/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg

EOF
systemctl enable /etc/systemd/system/nagios.service

# enable auto-start
ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios





# download, extract, configure, install Nagios Plugins
cd /tmp
wget -q https://nagios-plugins.org/download/nagios-plugins-$NAGIOS_PLUGINS_VER.tar.gz
tar xzf nagios-plugins-$NAGIOS_PLUGINS_VER.tar.gz
cd ./nagios-plugins-$NAGIOS_PLUGINS_VER
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make -s
make -s install





# update /etc/hosts
echo "192.168.56.102 www.nagios.org" | sudo tee -a /etc/hosts
	
# restart
service nagios restart
service apache2 restart
updatedb
