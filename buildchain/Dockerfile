# Setup a docker image with Pantheon's Terminus and Google's Dart. 
# We are using a base the image on an image that supports PHP and composer
# so we can more easily work with Terminus.
FROM php:7.4

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Pantheon's terminus
RUN apt-get update && apt-get install -y \
    git

RUN composer global require pantheon-systems/terminus

ENV PATH="/root/.composer/vendor/bin:${PATH}"

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

# Install the evaluator
COPY ../evaluator /usr/src/evaluator
WORKDIR /usr/src/evaluator

RUN dart pub get

CMD ["dart", "./bin/main.dart", "-h"]