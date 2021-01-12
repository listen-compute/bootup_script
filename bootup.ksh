#!/bin/bash

# Installs updates
dnf update -y

# Installs wget, php, and php to connect to an Amazon RDS instance of MySQL
dnf install wget php php-json php-mysqlnd -y

# This line makes a quick edit to the httpd config file to allow override
sed -i "154s/AllowOverride None/AllowOverride All/" /etc/httpd/conf/httpd.conf

# The following block of code does the following:
# - changes to the /var/www/html where WordPress will be installed
# - downloads the latest WordPress build
# - extracts the zipped file that was downloaded.
# - recursively copies the contents of the uncompressed folder to /var/www/html
# - removes the wordpress latest.tar.gz file
# - copies the sample config file to a new file, wp-config.php
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -R wordpress/* . 
rm -rf wordpress latest.tar.gz
cp wp-config-sample.php wp-config.php

# Here we create some variables that will be used to edit the wp-config.php file 
db_name="toastmasters"
db_user="***REDACTED***"
db_pass="***REDACTED***"
db_host="***REDACTED***"
wp_conf="/var/www/html/wp-config.php"

# In this block of code we search and replace specific lines and text in the wp-config.php file
# This will allow WordPress to connect to the data
sed -i "23s/database_name_here/${db_name}/" ${wp_conf}
sed -i "26s/username_here/${db_user}/" ${wp_conf}
sed -i "29s/password_here/${db_pass}/" ${wp_conf}
sed -i "32s/localhost/${db_host}/" ${wp_conf}
sed -i "80s/false/true/" ${wp_conf}

# This changes the owner and group recursively to apache for all files and directories in /var/www/
chown -R apache:apache /var/www

# Change permissions to 2775 on the /var/www/ directory to allow access as the apache user.
chmod 2775 /var/www

# Change all directories under www to 2775 to be accessible by the apache group
find /var/www -type d -exec chmod 2775 {} \;

# Change all file permission under www to 0664
find /var/www -type f -exec chmod 0664 {} \;

# Runs a search and replace on the selinux file to disable SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

# This will start the Apache2 Web Server
systemctl start httpd
