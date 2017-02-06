FROM php:5.6-apache

RUN apt-get update && apt-get install -y \
        libmcrypt-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng12-dev && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install mcrypt mysqli gd


RUN apt-get install -y curl unzip mailutils ssmtp

WORKDIR /var/www/html

# COPY doma/ /var/www/html

RUN curl -SL http://www.matstroeng.se/doma/download.php?version=3.0.6 > doma.zip && \
   unzip doma && \
   rm doma.zip

COPY php.ini /usr/local/etc/php/

RUN rm config_original.php
COPY config.php config.php

