#!/bin/bash
yum install -y  python-pip gmp-devel libffi-devel mpfr-devel libmpc-devel git python-virtualenv python wget python-devel python-zope-interface unzip gnutls-devel gcc gcc-c++ curl python-requests
pip install twisted appdirs six ipwhois pycrypto pyasn1 pycurl service_identity ipwhois
yum install -y https://s3.amazonaws.com/aaronsilber/public/authbind-2.1.1-0.1.x86_64.rpm
adduser -s /bin/false cowrie
cd ~cowrie
su cowrie -c "git clone http://github.com/micheloosterhof/cowrie"
cd cowrie
su cowrie -c "virtualenv cowrie-env"
su cowrie -c "cp cowrie.cfg.dist cowrie.cfg"
source cowrie-env/bin/activate
pip install -r requirements.txt
cd data
su cowrie -c "ssh-keygen -t dsa -b 1024 -f ssh_host_dsa_key -N \"\""
cd ..
export PYTHONPATH=/home/cowrie/cowrie
sed -i 's/AUTHBIND_ENABLED=no/AUTHBIND_ENABLED=yes/g' start.sh
sed -i 's/#listen_port = 2222/listen_port = 22/g' cowrie.cfg
#sed -i 's/Port 22/Port 2222/g' /etc/ssh/sshd_config
#service ssh restart
touch /etc/authbind/byport/22
chown cowrie:cowrie /etc/authbind/byport/22
chmod 770 /etc/authbind/byport/22
su cowrie -c "./start.sh cowrie-env"
deactivate
service fail2ban stop
yum remove -y fail2ban
read -e -p "[?] Enter Sensor name: (example: hp-US-Las_Vegas-01) " HOST_NAME
SPLUNK_INDEXER="198.46.230.142:9997"
KIPPO_LOG_LOCATION='/home/cowrie/cowrie/log/'
execdir=`pwd`
wget -O /opt/splunkforwarder.tgz 'http://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=6.3.0&product=universalforwarder&filename=splunkforwarder-6.3.0-aa7d4b1ccb80-Linux-x86_64.tgz&wget=true'
groupadd splunk
useradd -g splunk splunk -d /home/splunk -s /bin/false
mkdir /home/splunk
chown -R splunk:splunk /home/splunk
cd /opt
tar -xzf splunkforwarder.tgz
chown -R splunk:splunk splunkforwarder 
sudo -u splunk /opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --auto-ports --no-prompt
/opt/splunkforwarder/bin/splunk enable boot-start -user splunk
cp -r "$execdir/tango_input" /opt/splunkforwarder/etc/apps
cd /opt/splunkforwarder/etc/apps/tango_input/default 
sed -i "s/test/$HOST_NAME/" inputs.conf
sed -i "s,/opt/cowrie/log/,${KIPPO_LOG_LOCATION}," inputs.conf
sed -i "s/test/$SPLUNK_INDEXER/" outputs.conf
chown -R splunk:splunk /opt/splunkforwarder
/opt/splunkforwarder/bin/splunk restart


