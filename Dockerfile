FROM alpine:3.5

ENV COMPOSER_ALLOW_SUPERUSER="1" \
    MYSQL_HOSTNAME="mariadb" \
    MYSQL_DATABASE="puyonexus" \
    MYSQL_USERNAME="puyonexus" \
    MYSQL_PASSWORD="puyonexus" \
    MEDIAWIKI_SITENAME="Puyo Nexus Wiki" \
    MEDIAWIKI_NAMESPACE="PuyoNexus" \
    MEDIAWIKI_CONTACT="support@puyonexus.com" \
    MEDIAWIKI_SECRETKEY="12356789abcdef" \
    MEDIAWIKI_UPGRADEKEY="123456789abcdef" \
    SENTRY_DSN="" \
    SITE_ROOT="http://localhost:8080" \
    WWW_ROOT="http://localhost:8081"

RUN apk add --no-cache curl tar

# Copy configuration.
RUN apk add --no-cache php7-curl php7-dom php7-gd php7-ctype php7-zip \
    php7-xml php7-iconv php7-sqlite3 php7-mysqli php7-pgsql php7-json \
    php7-phar php7-openssl php7-pdo php7-pdo_mysql php7-session \
    php7-mbstring php7-bcmath php7-zlib php7-fpm php7 curl tar \
 && ln -s /usr/bin/php7 /usr/bin/php \
 && curl --silent --show-error --fail --location \
      --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" -o - \
      "https://caddyserver.com/download/linux/amd64?plugins=${plugins}" \
    | tar --no-same-owner -C /usr/bin/ -xz caddy \
 && chmod 0755 /usr/bin/caddy \
 && /usr/bin/caddy -version \
 && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
 && sed -i -e "s/;clear_env = no/clear_env = no/g" /etc/php7/php-fpm.d/www.conf \
 && sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" /etc/php7/php.ini

# Run Composer. We want to run it separately from the remainder of the copying
# so Docker can cache these steps so as long as the Composer files don't change.
COPY forum/phpbb/phpBB/composer.json forum/phpbb/phpBB/composer.lock /www/forum/
RUN cd /www/forum && composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
COPY wiki/mediawiki/composer.json /www/mediawiki/
RUN cd /www/mediawiki && composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
COPY chainsim/puyosim/composer.json chainsim/puyosim/composer.lock /www/chainsim/
RUN cd /www/chainsim && composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader

# Copy source code.
COPY home/www /www/
COPY forum/phpbb/phpBB /www/forum
COPY forum/ext /www/forum/ext
COPY forum/styles /www/forum/styles
COPY wiki/mediawiki /www/mediawiki
COPY wiki/extensions /www/mediawiki/extensions
COPY wiki/skins /www/mediawiki/skins
COPY chainsim/puyosim /www/chainsim
COPY Caddyfile /etc/caddy/Caddyfile

# Configs.
COPY forum/config.php /www/forum/
COPY wiki/LocalSettings*.php /www/mediawiki/
COPY chainsim/localsettings.php /www/chainsim/config/localsettings.php

# Permissions.
RUN chmod 777 /www/forum/cache \
 && chmod 777 /www/mediawiki/cache \
 && chmod 777 /www/chainsim/temp \
 && mkdir /www/chainsim/temp/cache \
 && chmod 777 /www/chainsim/temp/cache \
 && rm -rf /www/forum/install

# Entrypoint.
ENTRYPOINT ["/usr/bin/caddy"]
CMD ["--conf", "/etc/caddy/Caddyfile", "--log", "stdout"]
