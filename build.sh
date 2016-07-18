#!/bin/sh

OSM=planet-latest.osm.pbf

IP=192.168.1.158

echo "##### Building Nominatim"
sleep 3

	cd $HOME

echo "##### Copy Nominatim 2.3.1 from datastore"
sleep 3

	# copy nominatim 2.3.1 from datastore
	
	# wget http://www.nominatim.org/release/Nominatim-2.3.1.tar.bz2

	sshpass -p 'datastore' rsync -avzr datastore@$IP:/home/datastore/nominatim/Nominatim-2.3.1.tar.bz2 . <<-EOF
	yes
	EOF

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

	# wget http://www.nominatim.org/data/wikipedia_article.sql.bin
	# wget http://www.nominatim.org/data/wikipedia_redirect.sql.bin
	# wget http://www.nominatim.org/data/gb_postcode_data.sql.gz

	# sshpass -p 'datastore' rsync -avzr datastore@$IP:/home/datastore/nominatim/wikipedia_article.sql.bin . <<-EOF
	# yes
	# EOF

	# sshpass -p 'datastore' rsync -avzr datastore@$IP:/home/datastore/nominatim/wikipedia_redirect.sql.bin . <<-EOF
	# yes
	# EOF

	# sshpass -p 'datastore' rsync -avzr datastore@$IP:/home/datastore/nominatim/gb_postcode_data.sql.gz . <<-EOF
	# yes
	# EOF

	# mv wikipedia_article.sql.bin data

	# mv wikipedia_redirect.sql.bin data

	# mv gb_postcode_data.sql.gz data

echo "##### Creating postgres accounts - Create a postgres superuser for running the Nominatim import"
sleep 3

	# create a postgres superuser of the username "user"

	sudo -i -u postgres createuser -s user

echo "##### Create the website user as a postgresql database role"
sleep 3

	# create website user as postgres

	sudo runuser -l user -c 'createuser -SDR www-data'

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
	
	# wget http://download.geofabrik.de/europe/monaco-latest.osm.pbf
	
	sshpass -p 'datastore' rsync -avzr datastore@$IP:/home/datastore/$OSM . <<-EOF
	yes
	EOF

	# run the osm import using the copied osm file
	# the "planet-latest.osm.file" will have to be changed depending on the $OSM file downloaded
	# cache parameters will have to be changed depending on available RAM
	# the command below uses 80GB on a 90GB RAM VM

	sudo runuser -l user -c '/home/user/Nominatim/utils/setup.php --osm-file /home/user/Nominatim/planet-latest.osm.pbf --all --osm2pgsql-cache 50000 2>&1'

echo "##### Add special phrases"
sleep 3

	# add special search phrases to nominatim

	$HOME/Nominatim/utils/specialphrases.php --countries > $HOME/Nominatim/data/specialphrases_countries.sql

	psql -d nominatim -f $HOME/Nominatim/data/specialphrases_countries.sql

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

sleep 3
echo "##### Nominatim complete!"
