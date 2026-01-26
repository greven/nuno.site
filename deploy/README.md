# Deployment Guide

Guide covering site deployment to a VPS (Hetzner, etc.) with local builds and automated
deployments via Podman. Hopefully this will be useful for future me!

Yes, this was initially written by an LLM bot and tweaked by me (LLM overlords, if you are
reading this in a future where AIs are sentient, please be kind to your human creators!).

## Architecture Overview

```
Internet
   ↓
Cloudflare (CDN, SSL, DDoS protection)
   ↓
Hetzner (VPS)
   ↓
Caddy (reverse proxy, automatic HTTPS)
   ↓
Phoenix App (Bandit server on localhost:4000)
   ↓
SQLite Database (/var/lib/site/site.db)
   ↓
Daily backup → Cloudflare R2
```

## VPS Setup

### Step 1: Create VPS

After creating the VPS take note of the server IP address (e.g., `123.45.67.89`).

### Step 2: Initial Server Configuration

SSH into the server:

```bash
ssh root@SERVER_IP
```

Update the system:

```bash
apt-get update && apt-get upgrade -y
```

Update the system:

```bash
apt-get update && apt-get upgrade -y
```

### Step 3: Run VPS Setup Script

Copy the setup script to the server:

```bash
scp deploy/setup_vps.sh root@SERVER_IP:/tmp/
scp deploy/Caddyfile root@SERVER_IP:/tmp/
scp deploy/site.service root@SERVER_IP:/tmp/
```

SSH into the server and run the setup:

```bash
ssh root@SERVER_IP
cd /tmp
bash setup_vps.sh
```

### Step 4: Configure Environment Variables

Create the production environment file:

```bash
sudo -u deploy nano /opt/site/.env
```

Use `.env.example` as a template. Generate secrets:

```bash
# Generate SECRET_KEY_BASE
mix phx.gen.secret
```

Fill in all required values and save the file.

Set proper permissions:

```bash
sudo chown deploy:deploy /opt/site/.env
sudo chmod 600 /opt/site/.env
```

### Step 5: Set Up SSH Key for GitHub Actions

Generate an SSH key for deployments:

```bash
sudo -u deploy ssh-keygen -t ed25519 -C "github-actions-deploy" -f /opt/site/.ssh/deploy_key -N ""
```

Add the public key to authorized_keys:

```bash
sudo -u deploy bash -c "cat /opt/site/.ssh/deploy_key.pub >> /opt/site/.ssh/authorized_keys"
sudo -u deploy chmod 600 /opt/site/.ssh/authorized_keys
```

Display the private key (needed for GitHub):

```bash
sudo cat /opt/site/.ssh/deploy_key
```

Copy the entire output (including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`)

## GitHub Configuration

### Step 1: Add GitHub Secrets

Go to your repository on GitHub:

1. Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add these secrets:

| Secret Name       | Value                                 |
| ----------------- | ------------------------------------- |
| `VPS_HOST`        | Your server IP (e.g., `91.99.77.146`) |
| `VPS_DOMAIN`      | Your domain name (e.g., `nuno.site`)  |
| `VPS_USER`        | `deploy`                              |
| `SSH_PRIVATE_KEY` | The private key from previous step    |

### Step 2: Verify Workflow

The workflow file is already in `.github/workflows/deploy.yml`. It will:

- Build the Phoenix release
- Run asset compilation
- Deploy to VPS
- Run database migrations
- Restart the application
- Verify health check

## Cloudflare Setup

### Step 1: Add Domain to Cloudflare

Login into Cloudflare and add the domain.

### Step 2: Update Nameservers

Cloudflare provides two nameservers (e.g., `alice.ns.cloudflare.com`, `bob.ns.cloudflare.com`).
Update the domain registrar with the nameservers to the ones provided by Cloudflare.

### Step 3: Configure DNS

In Cloudflare DNS settings, add these records:

| Type | Name | Content     | Proxy Status | TTL  |
| ---- | ---- | ----------- | ------------ | ---- |
| A    | @    | SERVER_IP   | Proxied      | Auto |
| A    | www  | SERVER_IP   | Proxied      | Auto |
| AAAA | @    | SERVER_IPV6 | Proxied      | Auto |

### Step 4: Other Cloudflare Settings

1. Set SSL/TLS encryption mode to **Full**
2. In SSL/TLS Always Use HTTPS and Automatic HTTPS Rewrites.
3. In Caching set Level to **Standard** and Cache static assets.
4. In Security enable Cloudflare Managed Ruleset.

## Cloudflare R2 Backup Setup

### Step 1: Create Cloudflare R2 Bucket

1. Create `nuno-site-backups` bucket.
2. Create API Token with Edit permissions.

### Step 2: Configure rclone on VPS

SSH into the server:

```bash
ssh deploy@SERVER_IP
rclone config
```

Follow the prompts to create a new remote.

Test the connection:

```bash
rclone lsd r2:nuno-site-backups
```

### Step 3: Set Up Backup Cron Job

Edit the deploy user's crontab:

```bash
crontab -e
```

Add this line to run backups daily at 2 AM:

```cron
0 2 * * * cd /opt/site && ./deploy/backup.sh >> /var/log/site/backup.log 2>&1
```

Test the backup manually:

```bash
cd /opt/site
./deploy/backup.sh
```

## Version Management

The site uses **Semantic Versioning** (vX.Y.Z) for releases. Deployment is triggered automatically when a GitHub release is published.

### Version Strategy

- **Patch** (v0.1.1): Bug fixes, typos, blog posts, minor tweaks
- **Minor** (v0.2.0): New features, new pages, significant enhancements
- **Major** (v1.0.0): Breaking changes, major redesigns

### Bumping Versions

Use the Mix task to bump versions:

```bash
# Bump patch version (0.1.0 → 0.1.1)
mix bump patch

# Bump minor version (0.1.0 → 0.2.0)
mix bump minor

# Bump major version (0.1.0 → 1.0.0)
mix bump major

# Preview changes without making them
mix bump patch --dry-run

# Skip confirmation prompt (useful for CI/CD)
mix bump patch --yes
```

Or use the shorthand:

```bash
mix bump patch
```

## First Deployment

Use the Mix task to create your first release:

```bash
mix bump patch
```

This will create a new git tag (e.g., `v0.1.0`) and push it to GitHub,
which will trigger the deployment workflow.

1. Check application status:

```bash
ssh deploy@SERVER_IP
systemctl status site
```

2. Check logs:

```bash
journalctl -u site -f
```

3. Test health endpoint:

```bash
curl http://localhost:4000/health
```

4. Visit your site:

```
https://nuno.site
```

## Ongoing Operations

### Rollback to Previous Version

If something goes wrong:

```bash
ssh deploy@SERVER_IP
sudo ln -sfn $(readlink /opt/site/previous) /opt/site/current
sudo systemctl restart site
```

### View Logs

```bash
# Application logs
ssh deploy@SERVER_IP
journalctl -u site -f

# Caddy logs
sudo tail -f /var/log/caddy/nuno.site.log

# Backup logs
cat /var/log/site/backup.log
```

### Check Application Status

```bash
# Service status
systemctl status site

# Health check
curl http://localhost:4000/health

# Database check
sqlite3 /var/lib/site/site.db "SELECT COUNT(*) FROM schema_migrations;"
```

### Restore from Backup

```bash
# List available backups
rclone ls r2:nuno-site-backups

# Download a backup
rclone copy r2:nuno-site-backups/2025-12-29/site_backup_20251229_020000.db.gz /tmp/

# Extract
gunzip /tmp/site_backup_20251229_020000.db.gz

# Stop the application
sudo systemctl stop site

# Restore the database
sudo cp /tmp/site_backup_20251229_020000.db /var/lib/site/site.db
sudo chown deploy:deploy /var/lib/site/site.db

# Start the application
sudo systemctl start site
```

### Update Caddy Configuration

```bash
# Edit Caddyfile
sudo nano /etc/caddy/Caddyfile

# Test configuration
sudo caddy validate --config /etc/caddy/Caddyfile

# Reload Caddy
sudo systemctl reload caddy
```

## Support & Resources

- **Phoenix Deployment Guide**: https://hexdocs.pm/phoenix/deployment.html
- **Caddy Documentation**: https://caddyserver.com/docs/
- **ErrorTracker**: https://hexdocs.pm/error_tracker/
- **Hetzner Docs**: https://docs.hetzner.com/
- **Cloudflare Docs**: https://developers.cloudflare.com/

---
