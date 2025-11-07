# ⚡ Quick Start Guide - WordPress Docker Project

## For Experienced Users (15-20 Minutes)

This guide is for users familiar with Docker who want to deploy quickly.

---

## Prerequisites Check

```bash
# Check Docker
docker --version

# Check Docker Compose
docker compose version

# Check available RAM
free -h

# Check port 80 is free
sudo netstat -tulpn | grep :80
```

---

## Installation Steps

### 1. Navigate to Project Directory

```bash
cd /opt/hermanwebproject
```

### 2. Configure Domain and IP

**⚠️ IMPORTANT: Run this first!**

```bash
./INSTALL.sh
```

You will be asked:
- Domain name (e.g., `dpmd.bengkaliskab.go.id`)
- Local IP (e.g., `10.10.10.34`)
- Project title
- Admin email

### 3. Generate Secrets

```bash
./scripts/generate-secrets.sh
```

**💾 SAVE THE PASSWORDS!**

### 4. Build & Start

```bash
docker compose build --no-cache
docker compose up -d
```

### 5. Initialize WordPress

```bash
docker compose run --rm wp-cli /scripts/init-wordpress.sh
```

**💾 SAVE THE ADMIN CREDENTIALS!**

### 6. Verify

```bash
./scripts/healthcheck.sh
```

---

## Access Your Site

- **Domain**: http://your-domain.com
- **Local**: http://your-local-ip
- **Admin**: http://your-domain.com/wp-admin/

---

## Using Makefile (Recommended)

Instead of step 3-6, you can use:

```bash
# After running INSTALL.sh
make install
```

This will:
- ✅ Generate secrets
- ✅ Build images
- ✅ Start containers
- ✅ Initialize WordPress
- ✅ Run health check

---

## Common Commands

```bash
# Start services
make start

# Stop services
make stop

# View logs
make logs

# Manual backup
make backup

# Update WordPress
make update

# Health check
make health

# View all commands
make help
```

---

## Post-Installation

1. ✅ Login to `/wp-admin/`
2. ✅ Change admin password
3. ✅ Install Wordfence Security
4. ✅ Configure UpdraftPlus
5. ✅ Enable SSL (if using Cloudflare)

---

## Troubleshooting

### Services won't start?

```bash
docker compose logs
docker compose down
docker compose up -d
```

### Can't access website?

```bash
curl http://localhost
docker compose ps
./scripts/healthcheck.sh
```

### Forgot to run INSTALL.sh?

```bash
./INSTALL.sh
docker compose down
docker compose up -d
```

---

## Architecture

```
Cloudflare → NPM → Mikrotik NAT → Server
                                     ↓
                    ┌────────────────────────────┐
                    │  Docker Stack              │
                    │  Nginx → PHP-FPM → MariaDB │
                    │           ↓                │
                    │         Redis              │
                    └────────────────────────────┘
```

---

## Need More Details?

- 📖 Full guide: `INSTALLATION_GUIDE.md`
- 🔒 Security: `SECURITY.md`
- 📚 Main docs: `README.md`
- 🏗️ Structure: `PROJECT_STRUCTURE.md`

---

**Version**: 2.0.0  
**Last Updated**: November 2024

**Happy Deploying! 🚀**

