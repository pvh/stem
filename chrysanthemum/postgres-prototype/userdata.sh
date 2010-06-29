#!/bin/bash

set -e
set -x

function userdata() {
        exec 2>&1

echo "--- BEGIN"
export DEBIAN_FRONTEND="noninteractive"
export DEBIAN_PRIORITY="critical"

# you only need this part if you're using volumes
echo "--- KUZUSHI"
apt-get update
apt-get install ruby rubygems ruby-dev irb libopenssl-ruby libreadline-ruby curl -y
gem install kuzushi --no-rdoc --no-ri
echo 'export PATH=`ruby -r rubygems -e "puts Gem.bindir"`:$PATH' >> /etc/profile ; . /etc/profile

# gotta get kuzushi the config.json
apt-get -y install s3cmd

# ugggg
cat > config.json <<CONFIG
{
  "ami32":"ami-714ba518", // public ubuntu 10.04 ami - 32 bit
  "availability_zone" : "us-east-1a",

  "volumes" : [
    { "device" : "/dev/sde1", "media" : "ebs", "size" : 64, "format" : "ext3", "scheduler" : "deadline", "label" : "/wal", "mount": "/wal", "mount_options" : "nodev,nosuid,noatime" },
    { "device" : "/dev/sdf1", "media" : "ebs", "size" : 128, "scheduler" : "deadline" },
    { "device" : "/dev/sdf2", "media" : "ebs", "size" : 128, "scheduler" : "deadline" },
    { "device" : "/dev/sdf3", "media" : "ebs", "size" : 128, "scheduler" : "deadline" },
    { "device" : "/dev/sdf4", "media" : "ebs", "size" : 128, "scheduler" : "deadline" },
    { "device" : "/dev/sdf5", "media" : "ebs", "size" : 128, "scheduler" : "deadline" },
    { "device" : "/dev/sdf6", "media" : "ebs", "size" : 128, "scheduler" : "deadline" },
    { "device" : "/dev/sdf7", "media" : "ebs", "size" : 128, "scheduler" : "deadline" },
    { "device" : "/dev/sdf8", "media" : "ebs", "size" : 128, "scheduler" : "deadline" },
    { "device" : "/dev/md0",
      "media" : "raid",
      "label" : "/database",
      "mount" : "/database",
      "drives" : [ "/dev/sdf1", "/dev/sdf2", "/dev/sdf3", "/dev/sdf4", "/dev/sdf5", "/dev/sdf6", "/dev/sdf7", "/dev/sdf8" ],
      "level" : 0,
      "chunksize" : 256,
      "readahead" : 65536,
      "format" : "xfs"  // implies xfsprogs package
    }
   ]
}
CONFIG

export JUDO_FIRST_BOOT=true
kuzushi-setup

service udev stop
mdadm --create /dev/md0 -n 8 -l 0 -c 256 /dev/sdf{1..8}
service udev start
blockdev --setra 65535 /dev/md0

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

ONE_THIRD_OF_RAM=$(cat /proc/meminfo | awk '/MemTotal/ { printf("%d", $2 / 3 * 1024) }')
echo "kernel.shmmax=$ONE_THIRD_OF_RAM" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

kuzushi-erb templates/s3cfg.erb > /etc/s3cfg
chown postgres:postgres /etc/s3cfg

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

echo "--- END, SHUTTING DOWN"
shutdown -h now

}

userdata > /var/log/kuzushi.log

