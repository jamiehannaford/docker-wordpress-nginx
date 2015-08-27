#!/bin/bash
if [ ! -f /usr/src/wordpress/wp-config.php ]; then

  sed -e "s/database_name_here/$WORDPRESS_DB_NAME/
  s/username_here/$WORDPRESS_DB_USERNAME/
  s/password_here/$WORDPRESS_DB_PASSWORD/
  s/localhost/$WORDPRESS_DB_HOST/
  /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/src/wordpress/wp-config-sample.php > /usr/src/wordpress/wp-config.php

  # Download nginx helper plugin
  curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o nginx-helper.*.zip -d /usr/src/wordpress/wp-content/plugins

  # Install Redis cache
  curl -s -o /usr/src/wordpress/wp-content/object-cache.php https://raw.githubusercontent.com/ericmann/Redis-Object-Cache/master/object-cache.php

  # Install w3 plugin
  curl -O `curl -i -s https://wordpress.org/plugins/w3-total-cache/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o w3-total-cache.*.zip -d /usr/src/wordpress/wp-content/plugins

  # Correct permissions
  chown -R www-data:www-data /usr/src/wordpress/wp-content/plugins

  # Activate nginx plugin once logged in
  cat << ENDL >> /usr/src/wordpress/wp-config.php
\$plugins = get_option( 'active_plugins' );
if ( count( \$plugins ) === 0 ) {
  require_once(ABSPATH .'/wp-admin/includes/plugin.php');
  \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php', 'w3-total-cache/w3-total-cache.php' );
  foreach ( \$pluginsToActivate as \$plugin ) {
    if ( !in_array( \$plugin, \$plugins ) ) {
      activate_plugin( '/usr/src/wordpress/wp-content/plugins/' . \$plugin );
    }
  }
}
ENDL

  chown www-data:www-data /usr/src/wordpress/wp-config.php
fi

mkdir -p /usr/src/wordpress/wp-content/cache/tmp
chmod 777 /usr/src/wordpress/wp-content/cache/tmp
/usr/bin/php /set-config.php
chown -R www-data:www-data /usr/src/wordpress/wp-content/w3tc-config
chmod 777 /usr/src/wordpress/wp-content/w3tc-config/master.php
rm -rf /usr/src/wordpress/wp-content/cache/config

service php5-fpm start && nginx
