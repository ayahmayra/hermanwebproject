# 🚀 WordPress Docker Project - Installation Guide

## Overview

This is a production-ready WordPress Docker setup that can be easily configured for any domain and local IP address. The project includes:

- **WordPress Latest** - Stable version with Indonesian language support
- **MariaDB 11.2** - Optimized database
- **PHP-FPM 8.3** - With OPcache, APCu, Redis
- **Nginx 1.25** - Reverse proxy with security headers
- **Auto Backup** - Daily backup with 7-day retention
- **Security Hardened** - Government-grade security standards
- **Multi-domain Support** - Domain + IP local support
- **Cloudflare Ready** - Real IP forwarding configured

## Architecture

```
Internet
   ↓
Cloudflare (SSL/CDN/DDoS)
   ↓
NPM (Nginx Proxy Manager)
   ↓
Mikrotik NAT
   ↓
Your Server (Local IP)
   ↓
┌─────────────────────────────────┐
│  Docker Compose Stack           │
│  ┌───────────┐   ┌───────────┐ │
│  │   Nginx   │ → │  PHP-FPM  │ │
│  └───────────┘   └─────┬─────┘ │
│                        ↓         │
│                  ┌───────────┐  │
│                  │  MariaDB  │  │
│                  └───────────┘  │
│                        ↓         │
│                  ┌───────────┐  │
│                  │   Redis   │  │
│                  └───────────┘  │
│                                  │
│  ┌───────────┐   ┌───────────┐ │
│  │  Backup   │   │  WP-CLI   │ │
│  └───────────┘   └───────────┘ │
└─────────────────────────────────┘
```

## Prerequisites

Before you begin, ensure you have:

- ✅ Linux Server (minimum 4GB RAM recommended)
- ✅ Docker installed (version 20.10+)
- ✅ Docker Compose installed (version 2.0+)
- ✅ Port 80 available
- ✅ Root or sudo access
- ✅ Domain name configured in DNS
- ✅ Cloudflare account (optional but recommended)
- ✅ NPM (Nginx Proxy Manager) configured
- ✅ Network/Firewall configured

## Installation Steps

### Step 1: Clone or Download Project

```bash
cd /opt
git clone <repository-url> hermanwebproject
cd hermanwebproject
```

Or if you're extracting from a zip:

```bash
cd /opt
unzip hermanwebproject.zip
cd hermanwebproject
```

### Step 2: Make Scripts Executable

```bash
chmod +x scripts/*.sh php/docker-entrypoint.sh INSTALL.sh
```

### Step 3: Run Configuration Script

This is the **most important step**. It will configure your domain and IP settings:

```bash
./INSTALL.sh
```

The script will ask you for:

1. **Domain name** (e.g., `dpmd.bengkaliskab.go.id`)
2. **Local IP address** (e.g., `10.10.10.34`)
3. **Project title** (e.g., "DPMD Kabupaten Bengkalis")
4. **Admin email** (e.g., `admin@dpmd.bengkaliskab.go.id`)

Example interaction:

```
Enter your domain name: dpmd.bengkaliskab.go.id
✓ Domain: dpmd.bengkaliskab.go.id

Enter your local IP address: 10.10.10.34
✓ Local IP: 10.10.10.34

Enter project title [Default: WordPress Site]: DPMD Kabupaten Bengkalis
✓ Title: DPMD Kabupaten Bengkalis

Enter admin email: admin@dpmd.bengkaliskab.go.id
✓ Email: admin@dpmd.bengkaliskab.go.id
```

The script will automatically:
- ✅ Create `.env` file with your settings
- ✅ Generate nginx configuration
- ✅ Update docker-compose.yml
- ✅ Set correct container names

### Step 4: Generate Security Secrets

Generate secure passwords for database and WordPress:

```bash
./scripts/generate-secrets.sh
```

**⚠️ CRITICAL: Save the generated passwords in a secure location!**

The script will create three password files in the `secrets/` directory:
- `db_root_password.txt` - MariaDB root password
- `db_password.txt` - WordPress database password
- `wp_admin_password.txt` - WordPress admin password

### Step 5: Build Docker Images

```bash
docker compose build --no-cache
```

This will build the custom PHP-FPM image with all necessary extensions.

### Step 6: Start Services

```bash
docker compose up -d
```

Wait for all services to start (approximately 30-60 seconds).

### Step 7: Initialize WordPress

```bash
docker compose run --rm wp-cli /scripts/init-wordpress.sh
```

**⚠️ IMPORTANT: Save the WordPress admin credentials shown!**

The script will:
- Download and install WordPress
- Configure the database connection
- Create the admin user
- Install Indonesian language pack
- Configure permalinks
- Set up recommended plugins

### Step 8: Verify Installation

Run the health check script:

```bash
./scripts/healthcheck.sh
```

You should see all services marked as "healthy".

### Step 9: Access Your Site

After successful installation, access your site at:

- **Public Domain**: `http://your-domain.com`
- **Local IP**: `http://your-local-ip`
- **Admin Panel**: `http://your-domain.com/wp-admin/`

## Post-Installation

### 1. Login to WordPress Admin

Visit `http://your-domain.com/wp-admin/` and login with the admin credentials from Step 7.

### 2. Change Admin Password

For security, change the auto-generated admin password:
- Go to Users → Profile
- Scroll to "New Password"
- Generate a new strong password
- Click "Update Profile"

### 3. Install Security Plugins

Recommended security plugins:
- **Wordfence Security** - Firewall and malware scanner
- **UpdraftPlus** - Backup and restore
- **WP 2FA** - Two-factor authentication

### 4. Configure SSL (if using Cloudflare)

In WordPress admin:
- Go to Settings → General
- Change both URLs to use `https://`
- Save changes

### 5. Review Security Checklist

Read and follow the `SECURITY.md` file for additional hardening steps.

## Network Configuration

### Cloudflare Setup

1. Add your domain to Cloudflare
2. Point A record to your public IP (NPM server)
3. Enable "Proxied" (orange cloud)
4. SSL/TLS mode: "Full" or "Full (strict)"
5. Enable "Always Use HTTPS"

### NPM (Nginx Proxy Manager) Setup

1. Create a new Proxy Host
2. Domain Names: `your-domain.com`
3. Forward Hostname/IP: `your-local-ip`
4. Forward Port: `80`
5. Enable "Websockets Support"
6. SSL: Let's Encrypt or Cloudflare Origin Certificate

### Mikrotik NAT Setup

If using Mikrotik router:

```
/ip firewall nat
add chain=dstnat dst-address=<public-ip> dst-port=8089 \
    action=dst-nat to-addresses=<local-ip> to-ports=80 \
    protocol=tcp comment="WordPress NAT"
```

## Maintenance Commands

### Using Makefile

The project includes a Makefile for easy management:

```bash
# View all available commands
make help

# Start services
make start

# Stop services
make stop

# Restart services
make restart

# View logs
make logs

# Run health check
make health

# Manual backup
make backup

# Update WordPress
make update

# Optimize database
make optimize-db
```

### Manual Docker Commands

```bash
# View running containers
docker compose ps

# View logs
docker compose logs -f

# Stop services
docker compose stop

# Start services
docker compose up -d

# Restart a specific service
docker compose restart nginx

# Execute command in container
docker compose exec php-fpm bash
```

## Backup and Restore

### Automated Backups

Backups run automatically every day at 2 AM (Asia/Jakarta timezone).

Backups are stored in: `/var/lib/docker/volumes/<project-name>_backups/_data/`

### Manual Backup

```bash
make backup
```

Or:

```bash
docker compose exec backup /backup-db.sh
```

### Restore from Backup

```bash
./scripts/restore-backup.sh <backup-filename>
```

Example:

```bash
./scripts/restore-backup.sh wordpress_20241107_020000.sql.gz
```

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker compose logs

# Check individual service
docker compose logs mariadb
docker compose logs php-fpm
docker compose logs nginx

# Restart services
docker compose down
docker compose up -d
```

### Can't Access Website

```bash
# Check if nginx is running
docker compose ps nginx

# Test from inside server
curl http://localhost

# Check nginx logs
docker compose logs nginx

# Check network
ip addr show
ping <your-local-ip>
```

### Database Connection Error

```bash
# Check MariaDB logs
docker compose logs mariadb

# Restart MariaDB
docker compose restart mariadb

# Verify database credentials
cat secrets/db_password.txt

# Connect to database manually
docker compose exec mariadb mysql -u wpuser -p wordpress
```

### WordPress Shows Wrong URL

```bash
# Update site URL using WP-CLI
docker compose run --rm wp-cli wp option update siteurl "http://your-domain.com"
docker compose run --rm wp-cli wp option update home "http://your-domain.com"
```

### High Memory Usage

Check resource usage:

```bash
docker stats
```

For 2GB RAM servers, edit these files:
- `php/php-fpm.d/www.conf`: Set `pm.max_children = 25`
- `mariadb/my.cnf`: Set `innodb_buffer_pool_size = 256M`

Then rebuild:

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## Security Recommendations

1. ✅ **Keep secrets secure** - Never commit `secrets/` directory
2. ✅ **Enable Cloudflare** - DDoS protection and CDN
3. ✅ **Use strong passwords** - All generated passwords are 32+ characters
4. ✅ **Regular updates** - Run `make update` monthly
5. ✅ **Monitor logs** - Check logs weekly for suspicious activity
6. ✅ **Backup testing** - Test restore quarterly
7. ✅ **Two-factor authentication** - Enable for all admin users
8. ✅ **Limit login attempts** - Use Wordfence or similar
9. ✅ **SSL/TLS** - Always use HTTPS in production
10. ✅ **File permissions** - Never chmod 777

## Updating WordPress

### Update Everything

```bash
make update
```

This updates:
- WordPress core
- All plugins
- All themes

### Update Individual Components

```bash
# Update only WordPress core
docker compose run --rm wp-cli wp core update

# Update only plugins
docker compose run --rm wp-cli wp plugin update --all

# Update only themes
docker compose run --rm wp-cli wp theme update --all
```

## Uninstalling

### Remove Containers Only

```bash
docker compose down
```

### Remove Containers and Volumes

**⚠️ WARNING: This will delete all WordPress data!**

```bash
docker compose down -v
```

### Complete Cleanup

```bash
# Stop and remove everything
docker compose down -v

# Remove project directory
cd /opt
rm -rf hermanwebproject

# Clean Docker system
docker system prune -a
```

## Support

### Self-Help

1. Check this documentation
2. Review logs: `docker compose logs`
3. Run health check: `./scripts/healthcheck.sh`
4. Check `SECURITY.md` for security issues
5. Check `README.md` for detailed configuration

### Getting Help

- 📧 Email: Your IT support email
- 📚 Documentation: All `.md` files in this project
- 🔍 Logs: `docker compose logs -f`

## Project Structure

```
hermanwebproject/
├── docker-compose.yml          # Main Docker configuration
├── .env                        # Environment variables (created by INSTALL.sh)
├── INSTALL.sh                  # Configuration script
├── Makefile                    # Command shortcuts
├── nginx/
│   └── conf.d/                 # Nginx configurations
├── php/
│   ├── Dockerfile              # Custom PHP image
│   ├── php.ini                 # PHP configuration
│   └── php-fpm.d/              # PHP-FPM pool config
├── mariadb/
│   └── my.cnf                  # MariaDB configuration
├── scripts/
│   ├── generate-secrets.sh     # Generate passwords
│   ├── init-wordpress.sh       # Initialize WordPress
│   ├── backup-db.sh            # Backup script
│   ├── restore-backup.sh       # Restore script
│   └── healthcheck.sh          # Health monitoring
├── secrets/                    # Password files (git-ignored)
└── wordpress/
    └── wp-config.php.template  # WordPress config template
```

## FAQ

### Q: Can I use a different domain after installation?

A: Yes, but you need to:
1. Update `.env` file with new domain
2. Re-run configuration portions of INSTALL.sh, or manually update nginx config
3. Update WordPress URLs using WP-CLI
4. Restart containers

### Q: Can I change the local IP?

A: Yes, similar to changing domain:
1. Update `.env` file
2. Update nginx configuration
3. Update docker-compose.yml if needed
4. Restart containers

### Q: How do I migrate to a new server?

A:
1. On old server: Run backup
2. Copy `secrets/` directory
3. Copy latest backup file
4. On new server: Install project
5. Copy secrets and backup
6. Restore backup

### Q: Can I use this for multiple WordPress sites?

A: Yes! For each site:
1. Clone to different directory
2. Run INSTALL.sh with different domain/IP
3. Use different ports if on same server (edit docker-compose.yml)

### Q: Is this production-ready?

A: Yes! This setup is used in production for government websites with:
- Proper security hardening
- Automated backups
- Health monitoring
- Resource limits
- Rate limiting
- DDoS protection (via Cloudflare)

---

**Version**: 2.0.0  
**Updated**: November 2024  
**Project Name**: hermanwebproject

**Ready to deploy? Follow the installation steps above! 🚀**

