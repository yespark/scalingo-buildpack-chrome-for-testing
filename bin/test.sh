#!/usr/bin/env bash

set -euo pipefail

STACK_VERSION="${1:?'Error: The stack version number must be specified as the first argument.'}"

set -x

docker build --platform=linux/amd64 --progress=plain --build-arg="STACK_VERSION=${STACK_VERSION}" -t scalingo-buildpack-chrome-for-testing .

# Note: All of the container commands must be run via a login bash shell otherwise the profile.d scripts won't be run.

# # Check the profile.d scripts correctly added the binaries to PATH.
docker run --platform=linux/amd64 --rm scalingo-buildpack-chrome-for-testing bash -l -c 'chrome --version'
docker run --platform=linux/amd64 --rm scalingo-buildpack-chrome-for-testing bash -l -c 'chromedriver --version'

# # Check that there are no missing dynamically linked libraries.
docker run --platform=linux/amd64 --rm scalingo-buildpack-chrome-for-testing bash -l -c 'ldd $(which chrome)'
docker run --platform=linux/amd64 --rm scalingo-buildpack-chrome-for-testing bash -l -c 'ldd $(which chromedriver)'

# # Display a size breakdown of the directories added by the buildpack to the app.
docker run --platform=linux/amd64 --rm scalingo-buildpack-chrome-for-testing bash -l -c 'du --human-readable --max-depth=1 /app'
