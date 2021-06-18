#!/bin/bash

# This script builds the Docker container used to run the Dart
# script (evaluator) for gathering and then evaluating website
# information from Pantheon.

# Setup vars for our important paths.
BIN_PATH=$(cd "$(dirname "${BASH_SOURCE}")" ; pwd -P)
PROJECT_ROOT="$(dirname "${BIN_PATH}")"

docker build -t sinfo ${PROJECT_ROOT}
docker run -it sinfo