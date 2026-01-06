#!/usr/bin/env bash
#
# Run the Phoenix application in production mode locally
# This script assumes you have already built the release.
#
# Usage: bash run-release.sh
#

set -o errexit

# Set environment variables
export MIX_ENV=prod
export DATABASE_PATH=data/site_prod.db
export SECRET_KEY_BASE=hQfoaRcqPtdZitsdGwMeu45cu6yPK2XhHQxvDbhqsqBWsEtVxX1NETPw/JyLEu1d
export PHX_HOST=localhost
export PHX_SERVER=true

# Start the Phoenix server
mix phx.server
