# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Scalingo buildpack that installs Google Chrome browser and chromedriver for automated testing environments. It follows Chrome for Testing strategy to keep Chrome & chromedriver versions in-sync.

## Architecture

This is a Scalingo buildpack with the standard buildpack structure:

- `bin/detect` - Always returns success to detect this buildpack
- `bin/compile` - Main buildpack logic that downloads and installs Chrome & chromedriver
- `bin/install-chrome-dependencies` - Installs system dependencies for Chrome
- `bin/test.sh` - Test script that builds Docker container and validates installation

### Key Components

- **Chrome Installation**: Downloads Chrome for Testing binaries from Google's CDN based on channel (Stable/Beta/Dev/Canary)
- **Chromedriver Installation**: Downloads matching chromedriver version automatically
- **PATH Setup**: Adds Chrome and chromedriver to PATH via `.profile.d/chrome-for-testing.sh`
- **Multi-stack Support**: Supports Scalingo stack versions 20, 22, and 24

## Common Commands

### Testing the Buildpack
```bash
./bin/test.sh <stack_version>
```
Where stack_version is 20, 22, or 24. This builds a Docker container and validates the Chrome installation.

### Manual Docker Testing
```bash
# Build container
docker build --progress=plain --build-arg="STACK_VERSION=24" -t scalingo-buildpack-chrome-for-testing .

# Test Chrome version
docker run --rm scalingo-buildpack-chrome-for-testing bash -l -c 'chrome --version'

# Test chromedriver version
docker run --rm scalingo-buildpack-chrome-for-testing bash -l -c 'chromedriver --version'

# Test Chrome functionality
docker run --rm scalingo-buildpack-chrome-for-testing bash -l -c 'chrome --no-sandbox --headless --screenshot https://google.com'
```

## Configuration

### Environment Variables
- `GOOGLE_CHROME_CHANNEL`: Controls Chrome release channel (Stable, Beta, Dev, Canary). Defaults to Stable.

### Required Chrome Flags for Scalingo
When running Chrome in Scalingo environments, these flags are typically required:
- `--headless`
- `--no-sandbox`

Additional flags that may be needed:
- `--disable-gpu`
- `--remote-debugging-port=9222`

## Installation Paths
- Chrome: `/app/.chrome-for-testing/chrome-linux64/chrome`
- Chromedriver: `/app/.chrome-for-testing/chromedriver-linux64/chromedriver`

These are added to PATH automatically, so `chrome` and `chromedriver` commands work directly.