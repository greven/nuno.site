#!/usr/bin/env bash
#
# VPS Setup Script for nuno.site
# This script configures a fresh Ubuntu/Debian VPS for Phoenix deployment
#
# Usage: bash setup_vps.sh
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="site"
APP_USER="deploy"
APP_DIR="/opt/${APP_NAME}"
DB_DIR="/var/lib/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
DOMAIN="nuno.site"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  nuno.site VPS Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (use sudo)${NC}"
  exit 1
fi

echo -e "${YELLOW}[1/10] Updating system packages...${NC}"
apt-get update
apt-get upgrade -y

echo -e "${YELLOW}[2/10] Installing required packages...${NC}"
apt-get install -y \
  curl \
  wget \
  git \
  build-essential \
  openssl \
  libssl-dev \
  libncurses5-dev \
  locales \
  sqlite3 \
  ufw \
  debian-keyring \
  debian-archive-keyring \
  apt-transport-https \
  ca-certificates

echo -e "${YELLOW}[3/10] Setting up locale...${NC}"
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

echo -e "${YELLOW}[4/10] Creating application user...${NC}"
if ! id "${APP_USER}" &>/dev/null; then
  useradd -r -s /bin/bash -d "${APP_DIR}" -m "${APP_USER}"
  echo -e "${GREEN}✓ User ${APP_USER} created${NC}"
else
  echo -e "${GREEN}✓ User ${APP_USER} already exists${NC}"
fi

echo -e "${YELLOW}[5/10] Creating application directories...${NC}"
mkdir -p "${APP_DIR}"/{releases,current}
mkdir -p "${DB_DIR}"
mkdir -p "${LOG_DIR}"

chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}"
chown -R "${APP_USER}:${APP_USER}" "${DB_DIR}"
chown -R "${APP_USER}:${APP_USER}" "${LOG_DIR}"

echo -e "${YELLOW}[6/10] Installing Caddy web server...${NC}"
if ! command -v caddy &> /dev/null; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
  apt-get update
  apt-get install -y caddy
  echo -e "${GREEN}✓ Caddy installed${NC}"
else
  echo -e "${GREEN}✓ Caddy already installed${NC}"
fi

echo -e "${YELLOW}[7/10] Installing rclone for backups...${NC}"
if ! command -v rclone &> /dev/null; then
  curl https://rclone.org/install.sh | bash
  echo -e "${GREEN}✓ rclone installed${NC}"
else
  echo -e "${GREEN}✓ rclone already installed${NC}"
fi

echo -e "${YELLOW}[8/10] Configuring firewall (UFW)...${NC}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw --force enable
echo -e "${GREEN}✓ Firewall configured${NC}"

echo -e "${YELLOW}[9/10] Copying Caddyfile...${NC}"
if [ -f "Caddyfile" ]; then
  cp Caddyfile /etc/caddy/Caddyfile
  chown root:root /etc/caddy/Caddyfile
  chmod 644 /etc/caddy/Caddyfile
  systemctl enable caddy
  echo -e "${GREEN}✓ Caddyfile installed${NC}"
else
  echo -e "${YELLOW}⚠ Caddyfile not found in current directory${NC}"
  echo -e "${YELLOW}  Please copy deploy/Caddyfile to /etc/caddy/Caddyfile manually${NC}"
fi

echo -e "${YELLOW}[10/11] Configuring sudoers for deploy user...${NC}"
# Auto-detect binary paths
SYSTEMCTL_PATH=$(command -v systemctl || echo "/usr/bin/systemctl")
CHOWN_PATH=$(command -v chown || echo "/usr/bin/chown")

echo -e "${YELLOW}  Detected systemctl at: ${SYSTEMCTL_PATH}${NC}"
echo -e "${YELLOW}  Detected chown at: ${CHOWN_PATH}${NC}"

# Create sudoers file for deploy user to allow specific commands without password
cat > /etc/sudoers.d/${APP_NAME}-deploy << EOF
# Allow ${APP_USER} user to manage the ${APP_NAME} systemd service with any arguments
${APP_USER} ALL=(ALL) NOPASSWD: ${SYSTEMCTL_PATH} * ${APP_NAME}
${APP_USER} ALL=(ALL) NOPASSWD: ${SYSTEMCTL_PATH} --version

# Allow ${APP_USER} user to run chown for any file operations
${APP_USER} ALL=(ALL) NOPASSWD: ${CHOWN_PATH} *
EOF

# Validate sudoers syntax
chmod 440 /etc/sudoers.d/${APP_NAME}-deploy
visudo -c -f /etc/sudoers.d/${APP_NAME}-deploy > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Sudoers configuration created${NC}"
else
  echo -e "${RED}✗ Sudoers configuration has syntax errors${NC}"
  rm -f /etc/sudoers.d/${APP_NAME}-deploy
  exit 1
fi

echo -e "${YELLOW}[11/11] Copying systemd service...${NC}"
if [ -f "site.service" ]; then
  cp site.service /etc/systemd/system/site.service
  chown root:root /etc/systemd/system/site.service
  chmod 644 /etc/systemd/system/site.service
  systemctl daemon-reload
  systemctl enable site
  echo -e "${GREEN}✓ Systemd service installed${NC}"
else
  echo -e "${YELLOW}⚠ site.service not found in current directory${NC}"
  echo -e "${YELLOW}  Please copy deploy/site.service to /etc/systemd/system/ manually${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "1. Create ${APP_DIR}/.env file with your environment variables"
echo -e "   Use .env.example as a template"
echo ""
echo -e "2. Configure rclone for Cloudflare R2 backups:"
echo -e "   sudo -u ${APP_USER} rclone config"
echo ""
echo ""
echo -e "3. Set up SSH key for GitHub Actions deployment:"
echo -e "   As ${APP_USER} user, generate SSH key:"
echo -e "     sudo -u ${APP_USER} mkdir -p ${APP_DIR}/.ssh"
echo -e "     sudo -u ${APP_USER} ssh-keygen -t ed25519 -C 'github-actions' -f ${APP_DIR}/.ssh/id_ed25519 -N ''"
echo -e "     sudo -u ${APP_USER} cat ${APP_DIR}/.ssh/id_ed25519.pub >> ${APP_DIR}/.ssh/authorized_keys"
echo -e "     sudo -u ${APP_USER} chmod 600 ${APP_DIR}/.ssh/authorized_keys"
echo -e "   Then add the private key to GitHub Secrets as SSH_PRIVATE_KEY:"
echo -e "     cat ${APP_DIR}/.ssh/id_ed25519"
echo ""
echo ""
echo -e "4. Copy the Caddyfile and service file if not already done:"
echo -e "   cp deploy/Caddyfile /etc/caddy/Caddyfile"
echo -e "   cp deploy/site.service /etc/systemd/system/site.service"
echo ""
echo -e "5. Test Caddy configuration:"
echo -e "   caddy validate --config /etc/caddy/Caddyfile"
echo ""
echo -e "6. Deploy your first release from GitHub Actions!"
echo ""
echo -e "${GREEN}Application paths:${NC}"
echo -e "  App directory:     ${APP_DIR}"
echo -e "  Database directory: ${DB_DIR}"
echo -e "  Log directory:     ${LOG_DIR}"
echo -e "  Current release:   ${APP_DIR}/current"
echo ""
