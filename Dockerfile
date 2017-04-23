# docker-php-fpm
#
# Dockerfile for PHP-FPM on Debian 9.0 (stretch).
#
# Copyright (c) 2017 Jari Jokinen. MIT License.
#
# USAGE:
#
#   docker build -t php-fpm .
#   docker run -d -p 127.0.0.1:9000:9000 php-fpm

FROM debian:stretch-slim
MAINTAINER Jari Jokinen <info@jarijokinen.com>

# Install required packages
RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/01recommends \
	&& apt-get update \
  && apt-get install -y \
    curl \
    gcc \
    libcurl3 \
    libcurl4-openssl-dev \
    libjpeg62-turbo \
    libjpeg62-turbo-dev \
    libmcrypt4 \
    libmcrypt-dev \
    libpng16-16 \
    libpng-dev \
    libxml2 \
    libxml2-dev \
    libssl1.1 \
    libssl-dev \
    make \
    pkg-config \
    wget \
    zlib1g \
    zlib1g-dev \
  && ln -s  /usr/include/x86_64-linux-gnu/curl  /usr/include/curl

# Get the latest php tarball and extract it
RUN wget https://php.net$( \
    curl -s http://php.net/downloads.php | grep .tar.gz \
    | grep -oP '/get/php.+?.tar.gz' | head -1 \
  )/from/this/mirror --no-check-certificate -O /tmp/php.tar.gz \
  && mkdir /tmp/php \
  && tar -xzvf /tmp/php.tar.gz -C /tmp/php --strip-components=1

# Configure, compile and install php
WORKDIR /tmp/php
RUN ./configure \
    --enable-fpm \
    --enable-mbstring \
    --with-curl \
    --with-gd \
    --with-jpeg-dir=/usr/lib/x86_64-linux-gnu \
    --with-mcrypt \
    --with-mysqli \
    --with-openssl \
    --with-zlib \
  && make \
  && make install
WORKDIR /

# Configure php
RUN cp /tmp/php/php.ini-production /usr/local/lib/php.ini \
  && cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf \
  && cp /usr/local/etc/php-fpm.d/www.conf.default \
    /usr/local/etc/php-fpm.d/www.conf \
  && sed -i 's|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|' /usr/local/lib/php.ini \
  && sed -i 's|expose_php = On|expose_php = Off|' /usr/local/lib/php.ini \
  && sed -i 's|NONE|/usr/local|' /usr/local/etc/php-fpm.conf \
  && sed -i 's|nobody|php|' /usr/local/etc/php-fpm.d/www.conf \
  && sed -i 's|127.0.0.1:9000|0.0.0.0:9000|' /usr/local/etc/php-fpm.d/www.conf \
  && touch /usr/local/var/log/php-fpm.log

# Clean up
RUN apt-get purge -y --auto-remove \
    curl \
    gcc \
    libcurl4-openssl-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libxml2-dev \
    libssl-dev \
    make \
    pkg-config \
    wget \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd -r php \
  && useradd -r -g php php \
  && chown php:php /usr/local/var/log/php-fpm.log
USER php

EXPOSE 9000
CMD ["/usr/local/sbin/php-fpm", "-F"]
