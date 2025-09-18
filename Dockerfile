# syntax=docker/dockerfile:1-labs

ARG STACK_VERSION=24
ARG TARGETPLATFORM=linux/amd64

FROM --platform=$TARGETPLATFORM scalingo/scalingo-${STACK_VERSION}:latest AS build

# This ARG duplication is required since the lines before and after the 'FROM' are in different scopes.
ARG STACK_VERSION
ENV STACK="scalingo-${STACK_VERSION}"

# On Scalingo-24 and later the default user is not root.
USER appsdeck
RUN mkdir -p /tmp/build /tmp/cache /tmp/env
COPY --chown=appsdeck . /buildpack

# Sanitize the environment seen by the buildpack, to prevent reliance on
# environment variables that won't be present when it's run by Scalingo CI.
RUN env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/detect /tmp/build
RUN env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/compile /tmp/build /tmp/cache /tmp/env

# We must then test against the run image since that has fewer system libraries installed.
FROM --platform=$TARGETPLATFORM scalingo/scalingo-${STACK_VERSION}:latest
COPY --from=build --chown=appsdeck /tmp/build /app
USER appsdeck
# Emulate the platform which sources all .profile.d/ scripts on app boot.
RUN echo 'for f in /app/.profile.d/*; do source "${f}"; done' > /app/.profile
ENV HOME=/app
WORKDIR /app
# We have to use a login bash shell otherwise the .profile script won't be run.
CMD ["bash", "-l"]
