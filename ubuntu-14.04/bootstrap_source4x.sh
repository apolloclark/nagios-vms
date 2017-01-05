#!/usr/bin/env bash
# https://www.linode.com/docs/uptime/monitoring/install-nagios-4-on-ubuntu-debian-8

# set the environment to be noninteractive
export DEBIAN_FRONTEND=noninteractive

# update and upgrade apt
apt-get update
apt-get upgrade -y



# install depedencies
	
apt-get install -y build-essential apache2 apache2-utils libapache2-mod-php5 \
	daemon unzip openssl libssl-dev libgd2-xpm-dev xinetd wget
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
make all >/dev/null 2>&1
make install >/dev/null 2>&1
make install-init >/dev/null 2>&1
make install-config >/dev/null 2>&1
make install-commandmode >/dev/null 2>&1

cp ./sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf
chmod 644 /etc/apache2/sites-available/nagios.conf
ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/nagios.conf
htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers

# enable systemd nagios service
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
systemctl start nagios





# download, extract, configure, install Nagion Plugins
cd /tmp
wget -q https://nagios-plugins.org/download/nagios-plugins-$NAGIOS_PLUGINS_VER.tar.gz
tar xzf nagios-plugins-$NAGIOS_PLUGINS_VER.tar.gz
cd ./nagios-plugins-$NAGIOS_PLUGINS_VER
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make -s
make -s install

ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios




# update /etc/hosts
echo "192.168.56.102 www.nagios.org" | sudo tee -a /etc/hosts
	
# restart
service nagios restart
a2enmod rewrite
a2enmod cgi
service apache2 restart
updatedb
