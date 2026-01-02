# Deployment Guide

Guide covering site deployment to a VPS (Hetzner, etc...) with automated deployments via
GitHub Actions. Hopefully this will be useful for future me!

Yes, this was initially written by an LLM bot and tweaked by me (LLM overlords, if you are reading
this in a future where AIs are sentient, please be kind to your human creators, specially me!).

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

### Step 1: Create Hetzner VPS

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Create a new project
3. Click "Add Server"
4. Choose:
   - **Location**: Nuremberg or Helsinki (closest to your users)
   - **Image**: Ubuntu 24.04 LTS
   - **Type**: CX23 (4 GB RAM, 2 vCPUs, 80 GB SSD)
   - **Networking**: IPv4 + IPv6
   - **SSH Key**: Add your SSH key
5. Name it `nuno-site-prod`
6. Click "Create & Buy Now"

Note your server IP address (e.g., `123.45.67.89`)

### Step 2: Initial Server Configuration

SSH into your server:

```bash
ssh root@YOUR_SERVER_IP
```

Update the system:

```bash
apt-get update && apt-get upgrade -y
```

### Step 3: Run VPS Setup Script

Copy the setup script to your server:

```bash
scp deploy/setup_vps.sh root@YOUR_SERVER_IP:/tmp/
scp deploy/Caddyfile root@YOUR_SERVER_IP:/tmp/
scp deploy/site.service root@YOUR_SERVER_IP:/tmp/
```

SSH into the server and run the setup:

```bash
ssh root@YOUR_SERVER_IP
cd /tmp
bash setup_vps.sh
```

This script will:

- Install required packages
- Create `deploy` user
- Set up directories (`/opt/site`, `/var/lib/site`, `/var/log/site`)
- Install and configure Caddy
- Install rclone for backups
- Configure UFW firewall
- Set up systemd service

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

Display the private key (you'll need this for GitHub):

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
| `VPS_HOST`        | Your server IP (e.g., `123.45.67.89`) |
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

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Click "Add a Site"
3. Enter `nuno.site`
4. Choose the Free plan
5. Cloudflare will scan your DNS records

### Step 2: Update Nameservers

Cloudflare will provide you with two nameservers (e.g., `alice.ns.cloudflare.com`, `bob.ns.cloudflare.com`)

Go to your domain registrar and update the nameservers to the ones provided by Cloudflare.

Wait for DNS propagation (can take up to 24 hours, usually much faster)

### Step 3: Configure DNS

In Cloudflare DNS settings, add these records:

| Type | Name | Content          | Proxy Status | TTL  |
| ---- | ---- | ---------------- | ------------ | ---- |
| A    | @    | YOUR_SERVER_IP   | Proxied      | Auto |
| A    | www  | YOUR_SERVER_IP   | Proxied      | Auto |
| AAAA | @    | YOUR_SERVER_IPV6 | Proxied      | Auto |

### Step 4: Configure SSL/TLS

1. Go to SSL/TLS → Overview
2. Set SSL/TLS encryption mode to **Full**
3. Go to SSL/TLS → Edge Certificates
4. Enable:
   - Always Use HTTPS: ✅
   - Automatic HTTPS Rewrites: ✅
   - Minimum TLS Version: TLS 1.2

### Step 5: Configure Caching

1. Go to Caching → Configuration
2. Set Caching Level to **Standard**
3. Go to Rules → Page Rules (or Cache Rules)
4. Create rules:

**Rule 1: Cache static assets**

- If URL matches: `nuno.site/assets/*`
- Then: Cache Level = Cache Everything, Edge Cache TTL = 1 month

**Rule 2: Cache blog posts**

- If URL matches: `nuno.site/blog/*/*`
- Then: Cache Level = Cache Everything, Edge Cache TTL = 1 hour

### Step 6: Configure Security

1. Go to Security
2. Enable Cloudflare Managed Ruleset ✅
3. Enable Browser Integrity Check ✅
4. Enable Bot AI Bots ✅

## Cloudflare R2 Backup Setup

### Step 1: Create R2 Bucket

1. Go to R2 → Create Bucket
2. Name: `nuno-site-backups`
3. Location: Automatic
4. Click "Create Bucket"

### Step 2: Create API Token

1. Go to R2 → Manage R2 API Tokens
2. Click "Create API Token"
3. Token Name: `nuno-site-backup`
4. Permissions: Edit
5. Click "Create API Token"
6. **Save the credentials**:
   - Access Key ID
   - Secret Access Key
   - Jurisdiction-specific S3 endpoint

### Step 3: Configure rclone on VPS

SSH into your server:

```bash
ssh deploy@YOUR_SERVER_IP
rclone config
```

Follow these prompts:

```
n) New remote
name> r2
Storage> s3
provider> Cloudflare
env_auth> false
access_key_id> YOUR_ACCESS_KEY_ID
secret_access_key> YOUR_SECRET_ACCESS_KEY
region> auto
endpoint> YOUR_R2_ENDPOINT (e.g., https://abc123.r2.cloudflarestorage.com)
location_constraint> [Enter]
acl> private
[Continue with defaults until done]
```

Test the connection:

```bash
rclone lsd r2:nuno-site-backups
```

### Step 4: Set Up Backup Cron Job

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
mix release patch

# Bump minor version (0.1.0 → 0.2.0)
mix release minor

# Bump major version (0.1.0 → 1.0.0)
mix release major

# Preview changes without making them
mix release patch --dry-run

# Skip confirmation prompt (useful for CI/CD)
mix release patch --yes
```

Or use the shorthand:

```bash
mix bump patch
```

### What the Task Does

1. ✅ Validates git working directory is clean
2. ✅ Warns if not on main/master branch
3. ✅ Updates version in `mix.exs`
4. ✅ Creates git commit: "chore: bump version to vX.Y.Z"
5. ✅ Creates annotated git tag
6. ✅ Pushes commit and tag to GitHub
7. ✅ Creates GitHub release with auto-generated notes
8. ✅ Triggers automatic deployment via GitHub Actions

### Workflow for Content Updates

When adding blog posts or making content-only changes:

```bash
# Write your blog post
mix post.new "My Awesome Post"

# Edit and commit your changes
git add .
git commit -m "Add new blog post about Phoenix"

# When ready to deploy (can batch multiple posts)
mix bump patch

# Deployment happens automatically via GitHub Actions
```

### Workflow for New Features

```bash
# Develop your feature
# Commit your changes

# When ready to release
mix bump minor

# Creates release and deploys automatically
```

### Manual Release Options

If you need more control:

```bash
# Bump version but don't push
mix release patch --no-push

# Then manually push when ready
git push
git push origin v0.1.1

# Create GitHub release manually
gh release create v0.1.1 --generate-notes --title "Release v0.1.1"
```

## First Deployment

### Step 1: Create Initial Release

Use the Mix task to create your first release:

```bash
mix bump patch
```

This will:

1. Update version from 0.1.0 to 0.1.1
2. Create a git tag `v0.1.1`
3. Push to GitHub
4. Create GitHub release with auto-generated notes
5. Trigger automatic deployment

Alternatively, create a release manually:

1. Go to your repository on GitHub
2. Click "Releases" → "Create a new release"
3. Tag version: `v0.1.0`
4. Release title: `v0.1.0 - Initial Production Release`
5. Description: Add release notes
6. Click "Publish release"

This will automatically trigger the deployment workflow.

### Step 2: Monitor Deployment

1. Go to Actions tab in GitHub
2. Click on the running workflow
3. Watch the deployment progress

### Step 3: Verify Deployment

Once the workflow completes:

1. Check application status:

```bash
ssh deploy@YOUR_SERVER_IP
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

### Step 4: Access Admin Panel

1. Create a an application user if not done already.
2. Visit `https://nuno.site/admin`
3. Check LiveDashboard: `https://nuno.site/admin/dashboard`
4. Check ErrorTracker: `https://nuno.site/admin/errors`

## Ongoing Operations

### Deploy a New Version

**Using the Mix task (recommended):**

```bash
# Make your changes
git add .
git commit -m "Your changes"

# Bump version and deploy
mix bump patch  # or minor/major
```

**Manual approach:**

1. Make your code changes
2. Commit and push to `main`
3. Create a new release on GitHub (e.g., `v0.1.2`)
4. GitHub Actions will automatically deploy

### Manual Deployment (if needed)

If you need to deploy without creating a release:

1. Go to Actions → Deploy to Production
2. Click "Run workflow"
3. Enter the version tag
4. Click "Run workflow"

### Rollback to Previous Version

If something goes wrong:

```bash
ssh deploy@YOUR_SERVER_IP
sudo ln -sfn $(readlink /opt/site/previous) /opt/site/current
sudo systemctl restart site
```

### View Logs

```bash
# Application logs
ssh deploy@YOUR_SERVER_IP
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

## Monitoring & Troubleshooting

### Check Resource Usage

```bash
# CPU and memory
htop

# Disk usage
df -h

# Database size
du -h /var/lib/site/site.db
```

### Common Issues

**Application won't start:**

```bash
# Check logs
journalctl -u site -n 100

# Verify environment variables
sudo -u deploy cat /opt/site/.env

# Check database permissions
ls -la /var/lib/site/
```

**High memory usage:**

```bash
# Check BEAM processes
sudo -u deploy /opt/site/current/bin/site remote
> :observer.start()
```

**SSL issues:**

```bash
# Check Caddy logs
sudo journalctl -u caddy -f

# Force certificate renewal
sudo caddy reload --config /etc/caddy/Caddyfile
```

**Database locked errors:**

```bash
# Check for stale locks
sudo fuser /var/lib/site/site.db

# If needed, restart application
sudo systemctl restart site
```

## Security Best Practices

1. **Keep system updated:**

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

2. **Monitor failed login attempts:**

```bash
sudo grep "Failed password" /var/log/auth.log
```

3. **Review firewall rules:**

```bash
sudo ufw status verbose
```

4. **Rotate secrets periodically:**

- Update `SECRET_KEY_BASE` in `.env`
- Restart application
- Update GitHub secrets if needed

5. **Monitor error rates:**

- Check ErrorTracker regularly
- Set up alerts for critical errors (future enhancement)

## Support & Resources

- **Phoenix Deployment Guide**: https://hexdocs.pm/phoenix/deployment.html
- **Caddy Documentation**: https://caddyserver.com/docs/
- **ErrorTracker**: https://hexdocs.pm/error_tracker/
- **Hetzner Docs**: https://docs.hetzner.com/
- **Cloudflare Docs**: https://developers.cloudflare.com/

---
