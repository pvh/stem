#!/bin/bash

set -e
set -x


function userdata() {
        exec 2>&1

echo "--- BEGIN"
export DEBIAN_FRONTEND="noninteractive"
export DEBIAN_PRIORITY="critical"

echo "--- KUZUSHI"
apt-get update
apt-get install ruby rubygems ruby-dev irb libopenssl-ruby libreadline-ruby curl -y
gem install kuzushi --no-rdoc --no-ri
echo 'export PATH=`ruby -r rubygems -e "puts Gem.bindir"`:$PATH' >> /etc/profile ; . /etc/profile

# gotta get kuzushi the config.json
apt-get -y install git-core s3cmd
git clone https://pvh:temp@github.com/heroku/bifrost-judo.git
cd bifrost-judo/dedicated
export JUDO_FIRST_BOOT=true
kuzushi-setup

# this should be part of kuzushi
mdadm -Es >>/etc/mdadm/mdadm.conf
echo "/dev/md0          /database   xfs" >> /etc/fstab
echo "/dev/sde1         /wal        ext3   nodev,nosuid,noatime" >> /etc/fstab

echo "--- POSTGRESQL INSTALL"
apt-get -y install thin postgresql-8.4 postgresql-server-dev-8.4 libpq-dev libgeos-dev proj
service postgresql-8.4 stop

echo "--- POSTGRESQL VARS"
export DATA_DIR="/database"
export WAL_DIR="/wal"

echo "--- POSTGRESQL CONFIGURE"
cp files/pg_hba.conf /etc/postgresql/8.4/main/
kuzushi-erb templates/postgresql.conf-8.4.erb > /etc/postgresql/8.4/main/postgresql.conf
kuzushi-erb templates/shmmax.erb > /proc/sys/kernel/shmmax
kuzushi-erb templates/s3cfg.erb > /etc/s3cfg
chown postgres:postgres /etc/s3cfg

echo "--- POSTGRESQL CONFIGURE INIT CLUSTER"
mkdir -p $DATA_DIR
mkdir -p $WAL_DIR
chown postgres:postgres $DATA_DIR $WAL_DIR
chmod 700 $DATA_DIR $WAL_DIR
su - postgres -c "/usr/lib/postgresql/8.4/bin/initdb -D $DATA_DIR"
mv $DATA_DIR/pg_xlog/ $WAL_DIR
ln -s $WAL_DIR/pg_xlog $DATA_DIR/pg_xlog
ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem $DATA_DIR/server.crt
ln -s /etc/ssl/private/ssl-cert-snakeoil.key $DATA_DIR/server.key

echo "--- POSTGRESQL START"
service postgresql-8.4 start

echo "--- END"

}

userdata > /var/log/kuzushi.log

