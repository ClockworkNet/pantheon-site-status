#!/bin/bash

# This script builds the Docker container used to run the Dart
# script (evaluator) for gathering and then evaluating website
# information from Pantheon.

# Setup vars for our important paths.
BIN_PATH=$(cd "$(dirname "${BASH_SOURCE}")" ; pwd -P)
BUILD_ROOT="$(dirname "${BIN_PATH}")"
PROJECT_ROOT="$(dirname "${BUILD_ROOT}")"

docker build -t sinfo ${PROJECT_ROOT}/evaluator
docker run -it sinfo