#!/usr/bin/env bash
#
# Build the Phoenix application release locally
# to test it before deploying.
#
# Usage: bash build-release.sh
#

set -o errexit

# Set environment variables
export MIX_ENV=prod
export DATABASE_PATH=data/site_prod.db
export SECRET_KEY_BASE=hQfoaRcqPtdZitsdGwMeu45cu6yPK2XhHQxvDbhqsqBWsEtVxX1NETPw/JyLEu1d

# Clean previous builds
mix do deps.clean --all + clean

# Install dependencies and compile
mix deps.get --only $MIX_ENV
MIX_ENV=$MIX_ENV mix compile

# Compile assets
mix assets.deploy

# Build the release
mix release
