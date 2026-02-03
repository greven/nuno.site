#!/usr/bin/env bash
#
# Build the Phoenix application release locally using a container (Docker or Podman).
#
# Usage: bash build-release-docker.sh [tag] [tool]I
#

set -o errexit

# Optional argument for container tool (docker or podman)
tag=${1:-latest}
tool=${2:-docker}

# Set environment variables
export DATABASE_PATH=data/site_prod.db
export SECRET_KEY_BASE=hQfoaRcqPtdZitsdGwMeu45cu6yPK2XhHQxvDbhqsqBWsEtVxX1NETPw/JyLEu1d

echo "Building the release builder image using $tool..."

cmd="-t site:$tag --platform linux/amd64 -f Dockerfile ."

# Special handling for Apple Silicon (arm64) Macs
if [[ $(uname -m) == "arm64" ]] && [[ $(uname) == "Darwin" ]]; then
  echo "Detected Apple Silicon (arm64) Mac as host."
  $tool build --build-arg ERL_FLAGS="+JMsingle true" $cmd
else
  $tool build $cmd
fi
