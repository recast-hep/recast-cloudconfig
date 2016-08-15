#!/bin/bash

# Update
yum -y update


# Install docker
tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

yum install -y docker-engine
service docker start
chkconfig docker on

useradd robot-worker
usermod -aG docker robot-worker
usermod -aG wheel robot-worker


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
mkdir /opt/skygrid-worker
cd /opt/skygrid-worker
mkdir workdir

virtualenv venv
source venv/bin/activate
pip install git+https://github.com/skygrid/libscheduler.git
pip install git+https://github.com/sashabaranov/easywebdav.git
pip install git+https://github.com/skygrid/docker-worker.git

# Install supervisor
yum install -y supervisor
service supervisord start
chkconfig supervisord on

# Add robot
useradd robot-worker

# Get and install configs
git clone https://github.com/recast-hep/recast-cloudconfig.git /opt/recast-cloudconfig/

cp /opt/recast-cloudconfig/skygrid-worker/supervisor.cfg /etc/supervisord.d/docker_worker.ini
chown -R robot-worker /opt/skygrid-worker

echo "METASCHEDULER_URL = \"$METASCHEDULER_URL\"" >> /opt/recast-cloudconfig/skygrid-worker/worker.cfg
echo "WORK_QUEUE = \"$WORK_QUEUE\"" >> /opt/recast-cloudconfig/skygrid-worker/worker.cfg
echo "SLEEP_TIME = 60. # seconds" >> /opt/recast-cloudconfig/skygrid-worker/worker.cfg
echo "CONTAINER_CHECK_INTERVAL = 10. # seconds" >> /opt/recast-cloudconfig/skygrid-worker/worker.cfg

echo "robot-worker ALL=(ALL) NOPASSWD:/opt/recast-cloudconfig/skygrid-worker/fix-docker-output-ownership" >> /etc/sudoers

# Start service
supervisorctl reread
supervisorctl update
