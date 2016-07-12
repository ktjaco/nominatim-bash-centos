#!/bin/sh

#### Description: Nominatim 2.3.1 Install for CentOS 6.7

OSM=http://download.geofabrik.de/europe/monaco.html

# bomb out if something goes wrong
set -e

echo "##### Nominatim 2.3.1 Installation for Centos 6.3 #####"
sleep 3

echo "##### Dependencies"
sleep 3

	# install dependencies	

	sudo yum install -y epel-release

	sudo yum update -y

echo "##### Download postgresql-9.3 rpm for centos 9"
sleep 3

	cd /etc/yum.repos.d/

	# download CentOS 9.3 RPM

	sudo rpm -ivh https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-2.noarch.rpm

echo "##### Install Postgresql-9.3"
sleep 3

	# install postgresql 9.3

	sudo yum install -y postgresql93 postgresql93-contrib postgresql93-devel postgresql93-server postgis2_93 postgis2_93-devel

	sudo yum remove libevent
	
	sudo yum update -y

echo "##### Initialize and start the postgresql-9.3 database"
sleep 3

	# initialize database

	sudo service postgresql-9.3 initdb

	# start postgresql

	sudo service postgresql-9.3 start

echo "##### Install the remaining dependencies"
sleep 3

	# install remaining dependencies

	sudo yum install -y git make automake gcc gcc-c++ libtool policycoreutils-python

	sudo yum install -y php-pgsql php php-pear php-pear-DB libpqxx-devel proj-epsg

	sudo yum install -y bzip2-devel bzip2 proj-devel geos-devel libxml2-devel protobuf-c-devel lua-devel boost-devel sshpass

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

	sudo service postgresql-9.3 restart

echo "##### Nominatim 2.3.1 Installation"
sleep 3

	cd $HOME

echo "##### Copy Nominatim 2.3.1 from datastore"
sleep 3

	# copy nominatim 2.3.1 from datastore
	# this can be a wget
	wget http://www.nominatim.org/release/Nominatim-2.3.1.tar.bz2

echo "##### Extract and configure Nominatim 2.3.1"
sleep 3

	# extract nominatim	

	tar xvf Nominatim-2.3.1.tar.bz2

	# rename nominatim

	mv Nominatim-2.3.1 Nominatim

	cd Nominatim

	# configure nominatim with postgresql 9.3

	sudo ./configure --with-postgresql=/usr/pgsql-9.3/bin/pg_config

	sudo make

echo "##### Create a local.php configuration file in ../Nominatim/settings"
sleep 3

	echo "
		<?php
			// Paths
			@define('CONST_Postgresql_Version', '9.3');
			@define('CONST_Postgis_Version', '2.1');
			@define('CONST_Path_Postgresql_Contrib', '/usr/pgsql-9.3/share/contrib');
		   	// Website settings
		   	@define('CONST_Website_BaseURL', 'http://localhost/nominatim/');" > settings/local.php

echo "##### Copying optional data from datastore (wikipedia, GB postal code data)"
sleep 3

	# copy optional data from datastore
	# these can be wgets

	wget http://www.nominatim.org/data/wikipedia_article.sql.bin

	wget http://www.nominatim.org/data/wikipedia_redirect.sql.bin
	
	wget http://www.nominatim.org/data/gb_postcode_data.sql.gz

	mv wikipedia_article.sql.bin data

	mv wikipedia_redirect.sql.bin data

	mv gb_postcode_data.sql.gz data

echo "##### Creating postgres accounts - Create a postgres superuser for running the Nominatim import"
sleep 3

	# create a postgres superuser of the username "user"

	sudo -u postgres createuser -s user

echo "##### Create the website user as a postgresql database role"
sleep 3

	# create website user as postgres

	sudo runuser -l postgres -c 'createuser -SDR www-data'

echo "##### Nominatim module reading permissions"
sleep 3

	# set reading permissions

	sudo chmod +x $HOME

	sudo chmod +x $HOME/Nominatim

	sudo chmod +x $HOME/Nominatim/module

echo "##### Nominatim import process"
sleep 3

	# turn swap off

	cd $HOME/Nominatim
	swapoff -a

echo "##### Copying the .osm.pbf from datastore"
sleep 3

	# copy osm file from datastore
	# this can be wget

	wget $OSM

	# run the osm import using the copied osm file
	# the "planet-latest.osm.file" will have to be changed depending on the $OSM file downloaded
	# cache parameters will have to be changed depending on available RAM
	# the command below uses 80GB on a 90GB RAM VM

	sudo runuser -l user -c '/home/user/Nominatim/utils/setup.php --osm-file /home/user/Nominatim/planet-latest.osm.pbf --all --osm2pgsql-cache 15000 2>&1'

echo "##### Add special phrases"
sleep 3

	# add special search phrases to nominatim

	$HOME/Nominatim/utils/specialphrases.php --countries > $HOME/Nominatim/data/specialphrases_countries.sql

	psql -d nominatim -f $HOME/Nominatim/data/specialphrases_countries.psql

	$HOME/Nominatim/utils/specialphrases.php --wiki-import > $HOME/Nominatim/data/specialphrases.sql

	psql -d nominatim -f $HOME/Nominatim/data/specialphrases.sql

echo "##### Setup the website"
sleep 3

	# set up the webpage at localhost/nominatim/

	sudo mkdir -m 755 /var/www/html/nominatim

	# disable SELINUX

	sudo setenforce 0

	# change permissions for nominatim page

	sudo chown apache:apache /var/www/html/nominatim

	sudo chmod 755 -R /var/www/html/nominatim

	# ./utils/setup.php --create-website /var/www/html/nominatim

	cd $HOME/Nominatim

	sudo chown user /var/www/html/nominatim

	# permanently disable SELINUX

	sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

	# use symlinks to create a nominatim page

	./utils/setup.php --create-website /var/www/html/nominatim

echo "##### Configure for use with Apache"
sleep 3

	# configure for use with apache

	echo -e '<Directory "/var/www/html/nominatim/">
		    Options FollowSymLinks MultiViews
		    AddType text/html   .php
	</Directory>' | sudo tee -a /etc/httpd/conf/httpd.conf

	psql -d nominatim -c 'ALTER USER "www-data" RENAME TO "apache"'

	psql -d nominatim -c 'ALTER USER "apache" with superuser'

echo "##### Restart httpd and turn off iptables"
sleep 3

	# restart httpd

	sudo service httpd graceful

	sudo service httpd restart

	sudo service iptables stop

	sudo chkconfig iptables off

echo "##### Restart postgresql-9.3"
sleep 3

	sudo service postgresql-9.3 restart

echo "##### Check configuration to on for httpd and postgresql-9.3"
sleep 3

	sudo chkconfig --list httpd

	sudo chkconfig httpd on

	sudo chkconfig postgresql-9.3 on

echo "##### Switch back fsync and full_page_writes"
sleep 3

	sudo sed -i 's/fsync = off/fsync = on/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo sed -i 's/full_page_writes = off/full_page_writes = on/g' /var/lib/pgsql/9.3/data/postgresql.conf

	sudo service postgresql-9.3 restart


