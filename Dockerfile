FROM php:7.2-fpm-alpine
LABEL Maintainer="Steed Monteiro <steed@studiolabs.io>" \
      Description="Lightweight container with Nginx 1.14 & PHP-FPM 7.2 based on Alpine Linux with xDebug enabled & composer installed." \
      org.label-schema.name="startupstudio/php-alpine" \
      org.label-schema.description="Lightweight container with Nginx 1.14 & PHP-FPM 7.2 based on Alpine Linux with xDebug enabled & composer installed." \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/studioLabs/php-alpine" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0"

ARG BUILD_DATE
ARG VCS_REF

ENV COMPOSER_ALLOW_SUPERUSER 1 \
    PHP_XDEBUG_DEFAULT_ENABLE ${PHP_XDEBUG_DEFAULT_ENABLE:-0} \
    PHP_XDEBUG_REMOTE_ENABLE ${PHP_XDEBUG_REMOTE_ENABLE:-0} \
    PHP_XDEBUG_REMOTE_HOST ${PHP_XDEBUG_REMOTE_HOST:-"127.0.0.1"} \
    PHP_XDEBUG_REMOTE_PORT ${PHP_XDEBUG_REMOTE_PORT:-9900} \
    PHP_XDEBUG_REMOTE_AUTO_START ${PHP_XDEBUG_REMOTE_AUTO_START:-0} \
    PHP_XDEBUG_REMOTE_CONNECT_BACK ${PHP_XDEBUG_REMOTE_CONNECT_BACK:-0} \
    PHP_XDEBUG_IDEKEY ${PHP_XDEBUG_IDEKEY:-docker} \
    PHP_XDEBUG_PROFILER_ENABLE ${PHP_XDEBUG_PROFILER_ENABLE:-0} \
    PHP_XDEBUG_PROFILER_OUTPUT_DIR ${PHP_XDEBUG_PROFILER_OUTPUT_DIR:-"/tmp"} \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS ${PHP_OPCACHE_VALIDATE_TIMESTAMPS:-1} \
    PHP_OPCACHE_MAX_ACCELERATED_FILES ${PHP_OPCACHE_MAX_ACCELERATED_FILES:-10000} \
    PHP_OPCACHE_MEMORY_CONSUMPTION ${PHP_OPCACHE_MEMORY_CONSUMPTION:-128} \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE ${PHP_OPCACHE_MAX_WASTED_PERCENTAGE:-5}

# Install packages      
RUN apk add --no-cache ca-certificates \
    curl \
    pcre \
    nginx \
    supervisor \
    gettext

RUN set -ex	\
    && apk update \
    && apk add --no-cache git mysql-client curl openssh-client icu libpng freetype libjpeg-turbo gettext-dev postgresql-dev libffi-dev libsodium \
    && apk add --no-cache --virtual build-dependencies icu-dev libxml2-dev  freetype-dev libpng-dev libjpeg-turbo-dev g++ make autoconf libsodium-dev \
    && curl --location --output /usr/local/bin/phpunit https://phar.phpunit.de/phpunit.phar \
    && chmod +x /usr/local/bin/phpunit \
    && docker-php-source extract \
    && pecl install xdebug redis libsodium \
    && docker-php-ext-enable xdebug redis sodium \
    && docker-php-source delete \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure intl --enable-intl  \
    && docker-php-ext-install -j$(nproc) pdo pgsql pdo_mysql pdo_pgsql gettext intl zip gd  bcmath \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && cd  / && rm -fr /src \
    && apk del build-dependencies \
    && rm -rf /tmp/* 

COPY conf.d/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY conf.d/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY conf.d/php.ini /etc/php7/conf.d/zzz_custom.ini
COPY conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug-dev.ini
COPY conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Configure supervisord
COPY conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
# RUN chown -R nobody.nobody /run && \
#   chown -R nobody.nobody /var/lib/nginx && \
#   chown -R nobody.nobody /var/tmp/nginx && \
#   chown -R nobody.nobody /var/log/nginx

# Setup document root
RUN mkdir -p /var/www/html

# Switch to use a non-root user from here on
# USER nobody

# Add application
WORKDIR /var/www/html

# Expose the port nginx is reachable on
EXPOSE 8080
EXPOSE 9090
EXPOSE 9900

# Let supervisord start nginx & php-fpm

CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/ping