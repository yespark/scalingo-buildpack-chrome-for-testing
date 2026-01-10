#!/usr/bin/env bash

set -euo pipefail

STACK_VERSION="${1:?'Error: The stack version number must be specified as the first argument.'}"
TEST_CACHE="${2:-false}"

set -x

if [ "$TEST_CACHE" = "true" ]; then
  # Test caching by running compile twice with a persistent cache volume
  echo "=== Testing cache functionality ==="

  # Create a temporary directory for cache
  CACHE_VOLUME="buildpack-cache-test-${STACK_VERSION}"
  docker volume rm "$CACHE_VOLUME" 2>/dev/null || true
  docker volume create "$CACHE_VOLUME"

  # Build base image without running compile
  docker build --platform=linux/amd64 --progress=plain --build-arg="STACK_VERSION=${STACK_VERSION}" --target=build -t scalingo-buildpack-chrome-base -f - . <<'DOCKERFILE'
# syntax=docker/dockerfile:1-labs
ARG STACK_VERSION=24
ARG TARGETPLATFORM=linux/amd64
FROM --platform=$TARGETPLATFORM scalingo/scalingo-${STACK_VERSION}:latest AS build
ARG STACK_VERSION
ENV STACK="scalingo-${STACK_VERSION}"
USER appsdeck
RUN mkdir -p /tmp/build /tmp/cache /tmp/env
COPY --chown=appsdeck . /buildpack
DOCKERFILE

  # First run - should download everything
  echo "=== First run (should download) ==="
  docker run --platform=linux/amd64 --rm \
    -v "$CACHE_VOLUME:/tmp/cache" \
    -e STACK="scalingo-${STACK_VERSION}" \
    scalingo-buildpack-chrome-base \
    bash -c 'env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/compile /tmp/build /tmp/cache /tmp/env'

  # Second run - should use cache
  echo "=== Second run (should use cache) ==="
  docker run --platform=linux/amd64 --rm \
    -v "$CACHE_VOLUME:/tmp/cache" \
    -e STACK="scalingo-${STACK_VERSION}" \
    scalingo-buildpack-chrome-base \
    bash -c 'env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/compile /tmp/build /tmp/cache /tmp/env' 2>&1 | tee /tmp/cache-test-output.txt

  # Verify cache was used
  if grep -q "Using cached Chrome" /tmp/cache-test-output.txt && \
     grep -q "Using cached Chromedriver" /tmp/cache-test-output.txt && \
     grep -q "Using cached APT package index" /tmp/cache-test-output.txt; then
    echo "=== Cache test PASSED ==="
  else
    echo "=== Cache test FAILED - expected cache hits not found ==="
    cat /tmp/cache-test-output.txt
    exit 1
  fi

  # Cleanup
  docker volume rm "$CACHE_VOLUME"

else
  # Standard build test
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
fi
