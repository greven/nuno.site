#!/usr/bin/env bash
#
# Database Backup Script for nuno.site
# Backs up SQLite database to Cloudflare R2
#
# Usage: bash backup.sh
# 
# This script should be run as a cron job:
# 0 2 * * * /opt/site/backup.sh >> /var/log/site/backup.log 2>&1
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_NAME="site"
DB_DIR="/var/lib/${APP_NAME}"
DB_FILE="${DB_DIR}/site.db"
BACKUP_DIR="/tmp/site-backups"
RCLONE_REMOTE="r2:nuno-site-backups"  # Configure with: rclone config
RETENTION_DAYS=10

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y-%m-%d)
BACKUP_NAME="site_backup_${TIMESTAMP}.db.gz"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  nuno.site Database Backup${NC}"
echo -e "${BLUE}  $(date)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if database exists
if [ ! -f "${DB_FILE}" ]; then
  echo -e "${RED}Error: Database file not found: ${DB_FILE}${NC}"
  exit 1
fi

# Check if rclone is configured
if ! rclone listremotes | grep -q "r2:"; then
  echo -e "${RED}Error: rclone remote 'r2' not configured${NC}"
  echo -e "${YELLOW}Run: rclone config${NC}"
  echo -e "${YELLOW}Then set up a Cloudflare R2 remote named 'r2'${NC}"
  exit 1
fi

echo -e "${YELLOW}[1/5] Creating backup directory...${NC}"
mkdir -p "${BACKUP_DIR}"
echo -e "${GREEN}✓ Backup directory ready${NC}"

echo -e "${YELLOW}[2/5] Creating SQLite backup...${NC}"
# Use SQLite's backup command for a consistent snapshot
sqlite3 "${DB_FILE}" ".backup '${BACKUP_DIR}/site_backup_${TIMESTAMP}.db'"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Database backup created${NC}"
else
  echo -e "${RED}✗ Failed to create database backup${NC}"
  exit 1
fi

echo -e "${YELLOW}[3/5] Compressing backup...${NC}"
gzip "${BACKUP_DIR}/site_backup_${TIMESTAMP}.db"

if [ $? -eq 0 ]; then
  BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)
  echo -e "${GREEN}✓ Backup compressed (${BACKUP_SIZE})${NC}"
else
  echo -e "${RED}✗ Failed to compress backup${NC}"
  exit 1
fi

echo -e "${YELLOW}[4/5] Uploading to Cloudflare R2...${NC}"
rclone copy "${BACKUP_DIR}/${BACKUP_NAME}" "${RCLONE_REMOTE}/${DATE}/" --progress

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Backup uploaded to R2${NC}"
else
  echo -e "${RED}✗ Failed to upload backup to R2${NC}"
  exit 1
fi

echo -e "${YELLOW}[5/5] Cleaning up old backups...${NC}"
# Remove local backups
rm -f "${BACKUP_DIR}/${BACKUP_NAME}"
echo -e "${GREEN}✓ Local backup removed${NC}"

# Remove backups older than retention period from R2
CUTOFF_DATE=$(date -d "${RETENTION_DAYS} days ago" +%Y-%m-%d 2>/dev/null || date -v-${RETENTION_DAYS}d +%Y-%m-%d)
echo -e "${BLUE}  Removing R2 backups older than ${CUTOFF_DATE}${NC}"

# List all backup directories and remove old ones
rclone lsf "${RCLONE_REMOTE}" --dirs-only | while read -r backup_date; do
  backup_date_clean="${backup_date%/}"
  if [[ "${backup_date_clean}" < "${CUTOFF_DATE}" ]]; then
    echo -e "${YELLOW}  Removing old backup: ${backup_date_clean}${NC}"
    rclone purge "${RCLONE_REMOTE}/${backup_date_clean}"
  fi
done

echo -e "${GREEN}✓ Old backups cleaned up (retention: ${RETENTION_DAYS} days)${NC}"

# Get backup statistics
TOTAL_BACKUPS=$(rclone lsf "${RCLONE_REMOTE}" --dirs-only | wc -l)
TOTAL_SIZE=$(rclone size "${RCLONE_REMOTE}" --json | grep -o '"bytes":[0-9]*' | cut -d: -f2)
TOTAL_SIZE_MB=$((TOTAL_SIZE / 1024 / 1024))

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Backup Complete! ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Backup Info:${NC}"
echo -e "  File:         ${BACKUP_NAME}"
echo -e "  Size:         ${BACKUP_SIZE}"
echo -e "  Location:     ${RCLONE_REMOTE}/${DATE}/"
echo -e "  Timestamp:    $(date)"
echo ""
echo -e "${BLUE}R2 Storage Stats:${NC}"
echo -e "  Total backups: ${TOTAL_BACKUPS}"
echo -e "  Total size:    ${TOTAL_SIZE_MB} MB"
echo -e "  Retention:     ${RETENTION_DAYS} days"
echo ""

# Optional: Send notification on failure (uncomment if you have a notification system)
# if [ $? -ne 0 ]; then
#   curl -X POST "https://your-notification-service.com/notify" \
#     -d "message=Database backup failed for nuno.site"
# fi
