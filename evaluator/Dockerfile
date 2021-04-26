FROM google/dart

# Setup composer
# apt-get update; apt-get install curl
# curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Setup Pantheon's terminus

# Setup Dart and the sinfo script.
WORKDIR /app

ADD pubspec.* /app/
RUN pub get
ADD . /app
RUN pub get --offline

CMD []
ENTRYPOINT ["/usr/bin/dart", "./bin/main.dart"]