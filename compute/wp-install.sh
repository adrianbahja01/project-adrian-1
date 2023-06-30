#!/bin/bash
export DB_PASS="${db_pass}"
export DB_NAME="${db_name}"
export DB_USER="${db_user}"
export DB_HOST="${db_host}"

sudo apt update
sudo apt install -y apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mysql-server \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip
sudo mkdir -p /srv/www
sudo chown www-data: /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www

sudo touch /etc/apache2/sites-available/wordpress.conf

sudo cat > "/etc/apache2/sites-available/wordpress.conf" <<EOF
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF

sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default
sudo service apache2 reload

# Configuration file of wordpress
file=/srv/www/wordpress/wp-config.php

# Set the configs for the connection to remote DB
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php $file
sudo -u www-data sed -i "s/database_name_here/$DB_NAME/" $file
sudo -u www-data sed -i "s/username_here/$DB_USER/" $file
sudo -u www-data sed -i "s/password_here/$DB_PASS/" $file
sudo -u www-data sed -i "s/localhost/$DB_HOST/" $file

# Remove lines with this structure
sed -i "/define(.*put your unique phrase here/d" $file

# Add new lines with keys from wordpress site
new_keys=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
awk -v keys="$new_keys" '/** Database charset to use in creating database tables. */ { print keys } 1' $file > temp.php
# Remove the carriage return character (CR)
sed -i "s/\r$//" temp.php && mv temp.php $file

# Reload apache service to reload latest configs
sudo service apache2 reload
