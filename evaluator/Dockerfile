# Setup a docker image with Terminus and Dart. 
# Base the image on an image that supports PHP and composer

# Setup a base Debian image that provides: PHP, composer, Pantheon's terminus, and Dart.
FROM php:8

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Pantheon's terminus
RUN apt-get update && apt-get install -y \
    git

RUN composer global require pantheon-systems/terminus
ENV PATH="/root/.composer/vendor/bin:${PATH}"
#ENV TERMINUS_USER_HOME=/tmp



# Install Dart
RUN apt-get install -y \
    apt-transport-https \
    wget \
    gnupg

RUN sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' \
    && sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'

RUN apt-get update && apt-get install -y \
    dart \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="$PATH:/usr/lib/dart/bin"

# CMD npm run build-prod