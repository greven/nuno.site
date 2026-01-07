#!/usr/bin/env bash
#
# Deployment Script for nuno.site
# This script is called by GitHub Actions to deploy a new release
#
# Usage: bash deploy_release.sh <version>
# Example: bash deploy_release.sh v1.0.0
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="site"
APP_DIR="/opt/${APP_NAME}"
RELEASES_DIR="${APP_DIR}/releases"
CURRENT_DIR="${APP_DIR}/current"
DB_DIR="/var/lib/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"

# Check if version argument is provided
if [ $# -eq 0 ]; then
  echo -e "${RED}Error: Version argument required${NC}"
  echo "Usage: $0 <version>"
  echo "Example: $0 v1.0.0"
  exit 1
fi

VERSION="$1"
RELEASE_DIR="${RELEASES_DIR}/${VERSION}"
TARBALL="/tmp/site-${VERSION}.tar.gz"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Deploying nuno.site ${VERSION}${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check required permissions
echo -e "${YELLOW}Checking deployment permissions...${NC}"
PERMISSION_ERRORS=0

# Check if we can use systemctl commands
if ! sudo -n systemctl --version &>/dev/null; then
  echo -e "${RED}✗ Cannot run systemctl commands. Missing sudo privileges.${NC}"
  PERMISSION_ERRORS=$((PERMISSION_ERRORS + 1))
else
  echo -e "${GREEN}✓ systemctl permissions OK${NC}"
fi

# Check if we can change ownership
if ! sudo -n chown --version &>/dev/null; then
  echo -e "${RED}✗ Cannot run chown commands. Missing sudo privileges.${NC}"
  PERMISSION_ERRORS=$((PERMISSION_ERRORS + 1))
else
  echo -e "${GREEN}✓ chown permissions OK${NC}"
fi

if [ $PERMISSION_ERRORS -gt 0 ]; then
  echo -e "${RED}========================================${NC}"
  echo -e "${RED}  Permission Check Failed${NC}"
  echo -e "${RED}========================================${NC}"
  echo ""
  echo -e "${YELLOW}This script requires sudo privileges for the following commands:${NC}"
  echo -e "  - systemctl (start, stop, restart, is-active, status, --version)"
  echo -e "  - chown"
  echo ""
  echo -e "${YELLOW}To fix this, run the following as root on your VPS:${NC}"
  echo ""
  echo -e "cat > /etc/sudoers.d/${APP_NAME}-deploy << 'SUDOERS_EOF'"
  echo -e "# Allow ${USER} user to manage the ${APP_NAME} systemd service with any arguments"
  echo -e "${USER} ALL=(ALL) NOPASSWD: /usr/bin/systemctl * ${APP_NAME}"
  echo -e "${USER} ALL=(ALL) NOPASSWD: /usr/bin/systemctl --version"
  echo -e ""
  echo -e "# Allow ${USER} user to run chown for any file operations"
  echo -e "${USER} ALL=(ALL) NOPASSWD: /usr/bin/chown *"
  echo -e "SUDOERS_EOF"
  echo ""
  echo -e "chmod 440 /etc/sudoers.d/${APP_NAME}-deploy"
  echo -e "visudo -c -f /etc/sudoers.d/${APP_NAME}-deploy"
  echo ""
  echo -e "${YELLOW}Note: Make sure the paths match your system. Run 'which systemctl' and 'which chown' to verify.${NC}"
  echo ""
  exit 1
fi

echo -e "${GREEN}✓ All required permissions available${NC}"
echo ""

# Check if tarball exists
if [ ! -f "${TARBALL}" ]; then
  echo -e "${RED}Error: Release tarball not found: ${TARBALL}${NC}"
  exit 1
fi

echo -e "${YELLOW}[1/8] Extracting release...${NC}"
mkdir -p "${RELEASE_DIR}"
tar -xzf "${TARBALL}" -C "${RELEASE_DIR}"
echo -e "${GREEN}✓ Release extracted to ${RELEASE_DIR}${NC}"

echo -e "${YELLOW}[2/8] Setting up environment...${NC}"
if [ -f "${APP_DIR}/.env" ]; then
  ln -sf "${APP_DIR}/.env" "${RELEASE_DIR}/.env"
  echo -e "${GREEN}✓ Environment file linked${NC}"
else
  echo -e "${RED}Warning: No .env file found at ${APP_DIR}/.env${NC}"
  echo -e "${YELLOW}Please create one before starting the application${NC}"
fi

echo -e "${YELLOW}[3/8] Linking database directory...${NC}"
mkdir -p "${DB_DIR}"
echo -e "${GREEN}✓ Database directory ready${NC}"

echo -e "${YELLOW}[4/8] Setting permissions...${NC}"
sudo chown -R deploy:deploy "${RELEASE_DIR}"
chmod +x "${RELEASE_DIR}/bin/site"
chmod +x "${RELEASE_DIR}/bin/server"
echo -e "${GREEN}✓ Permissions set${NC}"

echo -e "${YELLOW}[5/8] Stopping current application...${NC}"
if sudo systemctl is-active --quiet site; then
  sudo systemctl stop site
  echo -e "${GREEN}✓ Application stopped${NC}"
else
  echo -e "${YELLOW}⚠ Application was not running${NC}"
fi

echo -e "${YELLOW}[6/8] Running database migrations...${NC}"
cd "${RELEASE_DIR}"

# Load environment variables from .env file
if [ ! -f "${APP_DIR}/.env" ]; then
  echo -e "${RED}✗ Environment file not found: ${APP_DIR}/.env${NC}"
  exit 1
fi

# Run migrations as deploy user (if we're not already deploy, use sudo)
if [ "$(whoami)" = "deploy" ]; then
  # Load env vars and run migrations
  set -a  # automatically export all variables
  source "${APP_DIR}/.env"
  set +a
  ./bin/site eval 'Site.Release.migrate()'
else
  # Run as deploy user with env vars loaded
  sudo -u deploy bash -c "set -a; source ${APP_DIR}/.env; set +a; cd ${RELEASE_DIR} && ./bin/site eval 'Site.Release.migrate()'"
fi
echo -e "${GREEN}✓ Migrations completed${NC}"

echo -e "${YELLOW}[7/8] Updating current symlink...${NC}"
# Create a backup of the previous release
if [ -L "${CURRENT_DIR}" ] && [ -e "${CURRENT_DIR}" ]; then
  PREVIOUS=$(readlink "${CURRENT_DIR}")
  echo -e "${BLUE}  Previous release: ${PREVIOUS}${NC}"
  ln -sfn "${PREVIOUS}" "${APP_DIR}/previous"
fi

# Remove current if it exists as a directory (not a symlink)
if [ -d "${CURRENT_DIR}" ] && [ ! -L "${CURRENT_DIR}" ]; then
  echo -e "${YELLOW}  Removing old current directory...${NC}"
  rm -rf "${CURRENT_DIR}"
fi

# Update current symlink to new release
ln -sfn "${RELEASE_DIR}" "${CURRENT_DIR}"
echo -e "${GREEN}✓ Current symlink updated${NC}"

echo -e "${YELLOW}[8/8] Starting application...${NC}"
sudo systemctl start site

# Wait a moment for the application to start
sleep 3

# Check systemd service status
if sudo systemctl is-active --quiet site; then
  echo -e "${GREEN}✓ systemd reports service as active${NC}"
else
  echo -e "${YELLOW}⚠ systemd service check inconclusive${NC}"
  echo -e "${YELLOW}  Will verify via health endpoint instead${NC}"
fi

echo -e "${YELLOW}Verifying application health...${NC}"

# Get port from environment or default to 4000
HEALTH_PORT="${PORT:-4000}"
MAX_ATTEMPTS=10
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  if curl -f -s "http://localhost:${HEALTH_PORT}/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Application is healthy and responding${NC}"
    break
  fi

  if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}✗ Health check failed after ${MAX_ATTEMPTS} attempts (${MAX_ATTEMPTS}×5s = 60s)${NC}"
    echo -e "${YELLOW}Checking systemd status and logs...${NC}"
    sudo systemctl status site --no-pager || true
    echo ""
    echo -e "${YELLOW}Recent application logs:${NC}"
    journalctl -u site -n 50 --no-pager
    exit 1
  fi

  echo -e "${YELLOW}  Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: waiting for application to be ready...${NC}"
  sleep 5
  ATTEMPT=$((ATTEMPT + 1))
done

# Cleanup
echo -e "${YELLOW}Cleaning up...${NC}"
rm -f "${TARBALL}"
rm -f /tmp/deploy_release.sh

# Remove old releases (keep last 5)
cd "${RELEASES_DIR}"
ls -t | tail -n +6 | xargs -r rm -rf
echo -e "${GREEN}✓ Old releases cleaned up${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete! 🚀${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Release Info:${NC}"
echo -e "  Version:        ${VERSION}"
echo -e "  Release Path:   ${RELEASE_DIR}"
echo -e "  Current Path:   ${CURRENT_DIR}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  Check status:   sudo systemctl status site"
echo -e "  View logs:      journalctl -u site -f"
echo -e "  Restart app:    sudo systemctl restart site"
echo -e "  Rollback:       ln -sfn \$(readlink ${APP_DIR}/previous) ${CURRENT_DIR} && sudo systemctl restart site"
echo ""
