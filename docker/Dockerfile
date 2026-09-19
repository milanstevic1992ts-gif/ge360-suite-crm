FROM php:8.3-apache-bookworm

ARG SUITECRM_URL
ARG SUITECRM_SHA256

ENV APACHE_DOCUMENT_ROOT=/var/www/suitecrm/public
WORKDIR /var/www/suitecrm

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip \
      libcurl4-openssl-dev \
      libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
      libicu-dev libonig-dev libxml2-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
      curl gd intl mbstring mysqli pdo_mysql soap zip opcache \
    && a2enmod rewrite headers expires \
    && rm -rf /var/lib/apt/lists/*

RUN test -n "$SUITECRM_URL" \
    && test -n "$SUITECRM_SHA256" \
    && curl -fsSL --retry 5 --retry-delay 2 "$SUITECRM_URL" -o /tmp/suitecrm.zip \
    && echo "$SUITECRM_SHA256  /tmp/suitecrm.zip" | sha256sum -c - \
    && mkdir -p /tmp/suitecrm-unpack /var/www/suitecrm \
    && unzip -q /tmp/suitecrm.zip -d /tmp/suitecrm-unpack \
    && first="$(find /tmp/suitecrm-unpack -mindepth 1 -maxdepth 1 | head -n 1)" \
    && count="$(find /tmp/suitecrm-unpack -mindepth 1 -maxdepth 1 | wc -l)" \
    && if [ "$count" = "1" ] && [ -d "$first" ]; then cp -a "$first"/. /var/www/suitecrm/; else cp -a /tmp/suitecrm-unpack/. /var/www/suitecrm/; fi \
    && rm -rf /tmp/suitecrm.zip /tmp/suitecrm-unpack \
    && find /var/www/suitecrm -type d -exec chmod 2755 {} \; \
    && find /var/www/suitecrm -type f -exec chmod 0644 {} \; \
    && chmod +x /var/www/suitecrm/bin/console \
    && chown -R www-data:www-data /var/www/suitecrm

COPY docker/apache-vhost.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php-ge360.ini /usr/local/etc/php/conf.d/99-ge360-suitecrm.ini

HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD curl -fsS http://127.0.0.1/ >/dev/null || exit 1
