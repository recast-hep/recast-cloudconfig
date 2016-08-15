#!/bin/bash

# Update
yum -y update

# Install mongodb
cat <<EOT >>  /etc/yum.repos.d/mongodb-org-3.2.repo
[mongodb-org-3.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.2.asc
EOT


yum install -y mongodb-org


semanage port -a -t mongod_port_t -p tcp 27017
sed -i -- 's/enforcing/permissive/g' /etc/selinux/config
service mongod start
chkconfig mongod on


# Install python
yum groupinstall -y "Development tools"
yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel wget


cd /opt
wget https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tgz
tar xzf Python-2.7.12.tgz
cd /opt/Python-2.7.12
./configure
make -j2
make install

wget https://bootstrap.pypa.io/get-pip.py
/usr/local/bin/python get-pip.py
pip install virtualenv


# Install metasceheduler
mkdir /opt/metascheduler
cd /opt/metascheduler

virtualenv venv
source venv/bin/activate
pip install git+https://github.com/skygrid/metascheduler.git
pip install gunicorn

# Install supervisor
yum install -y supervisor
service supervisord start
chkconfig supervisord on

# Add robot
useradd robot-metascheduler

# Get and install configs
git clone https://github.com/recast-hep/recast-cloudconfig.git /opt/recast-cloudconfig/

cp /opt/recast-cloudconfig/skygrid-metascheduler/supervisor.cfg /etc/supervisord.d/metascheduler.ini
supervisorctl reread
supervisorctl update
