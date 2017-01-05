# Nagios

Nagios VM builder in Vagrant, using either Ubuntu 12.04, or Ubuntu 14.04, with
various version of Nagios available to be installed. I originally created this
to test for various Nagios vulnerabilities.

Run the exploit:
```shell
# startup vulnerable VM instance
cd ./ubuntu-12.04/nagios-3.5.1
vagrant up

# in vulnerable VM
http://127.0.0.1:8080/nagios3/
http://127.0.0.1:8080/nagios/
# nagiosadmin, nagiosadmin

# shutdown VM
vagrant halt

# delete various .vagrant folders
find . -name ".vagrant" -type d -exec rm -r "{}" \;
```


## Log Files
```shell
nano /usr/local/nagios/var/nagios.log
nano /var/log/nagios3/nagios.log

sudo watch -n 1 tail -32 /var/log/apache2/error.log
/var/log/apache2/access.log
/var/log/apache2/other_vhosts_access.log
```