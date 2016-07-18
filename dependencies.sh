#!/bin/sh

# bomb out if something goes wrong
#set -e

echo "##### Installing Nominatim Dependencies #####"
sleep 5

echo "##### Dependencies"
sleep 3

	# install dependencies	

	sudo yum install -y epel-release

	sudo yum update -y

echo "##### Download postgresql-9.3 rpm for centos"
sleep 3

	cd /etc/yum.repos.d/

	# download CentOS 9.3 RPM

	sudo rpm -ivh https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-2.noarch.rpm

echo "##### Install Postgresql-9.3"
sleep 3

	# install postgresql 9.3

	sudo yum install -y postgresql93 postgresql93-contrib postgresql93-devel postgresql93-server postgis2_93 postgis2_93-devel

	sudo yum remove -y libevent

	sudo yum update -y

echo "##### Initialize and start the postgresql-9.3 database"
sleep 3

	# initialize database

	sudo service postgresql-9.3 initdb

echo "##### Postgresql-9.3 configuration settings"
sleep 3

	# set the following configuration settings for postgresql

	sudo sed -i 's/shared_buffers = 128MB/shared_buffers = 4GB/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/#maintenance_work_mem = 16MB/maintenance_work_mem = 16GB/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/#work_mem = 1MB/work_mem = 50MB/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/#effective_cache_size = 128MB/effective_cache_size = 24GB/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/#synchronous_commit = on/synchronous_commit = off/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/#checkpoint_segments = 3/checkpoint_segments = 100/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/#checkpoint_timeout = 5min/checkpoint_timeout = 10min/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/#checkpoint_completion_target = 0.5/checkpoint_completion_target = 0.9/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/#fsync = on/fsync = off/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/#full_page_writes = on/full_page_writes = off/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/9.3/data/postgresql.conf

	sudo service postgresql-9.3 start

	sudo chkconfig postgresql-9.3 on

echo "##### Install the remaining dependencies"
sleep 3

	# install remaining dependencies

	sudo yum install -y git make automake gcc gcc-c++ libtool policycoreutils-python

	sudo yum install -y php-pgsql php php-pear php-pear-DB libpqxx-devel proj-epsg

	sudo yum install -y bzip2-devel bzip2 proj-devel geos-devel libxml2-devel protobuf-c-devel lua-devel boost-devel sshpass

sleep 3
echo "#### Dependencies finished installing"
