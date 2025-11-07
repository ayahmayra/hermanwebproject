# Herman Web Project - WordPress Docker

## 🎯 Overview

Production-ready WordPress Docker setup dengan konfigurasi domain dan IP yang fleksibel. Proyek ini dirancang untuk deployment pemerintahan dan organisasi dengan standar keamanan tinggi.

## ✨ Key Features

- ✅ **Configurable Domain & IP** - Setup sekali untuk semua konfigurasi
- ✅ **Production Ready** - Sudah digunakan di production untuk website pemerintah
- ✅ **Security Hardened** - Standar keamanan pemerintahan
- ✅ **Auto Backup** - Daily backup dengan 7-day retention
- ✅ **Cloudflare Ready** - Real IP forwarding pre-configured
- ✅ **Multi-domain Support** - Domain public + IP lokal
- ✅ **Resource Optimized** - Tuned untuk server 4GB RAM

## 🚀 Quick Start

### 1. Clone Repository

```bash
cd /opt
git clone <repository-url> hermanwebproject
cd hermanwebproject
```

### 2. Configure

```bash
chmod +x INSTALL.sh scripts/*.sh php/docker-entrypoint.sh
./INSTALL.sh
```

Masukkan:
- Domain (contoh: `dpmd.bengkaliskab.go.id`)
- IP Lokal (contoh: `10.10.10.34`)
- Judul Project
- Email Admin

### 3. Install

```bash
make install
```

Atau manual:

```bash
./scripts/generate-secrets.sh
docker compose build --no-cache
docker compose up -d
docker compose run --rm wp-cli /scripts/init-wordpress.sh
```

### 4. Access

- Website: `http://your-domain.com`
- Admin: `http://your-domain.com/wp-admin/`

## 📚 Documentation

- **[00-START-HERE.md](00-START-HERE.md)** - Mulai di sini!
- **[QUICK_START.md](QUICK_START.md)** - Quick deploy 15-20 menit
- **[INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)** - Panduan lengkap
- **[SECURITY.md](SECURITY.md)** - Security checklist
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Struktur project

## 🏗️ Architecture

```
Internet → Cloudflare → NPM → Mikrotik NAT → Server
                                                ↓
                              ┌──────────────────────────┐
                              │  Docker Stack            │
                              │  - Nginx (Web Server)    │
                              │  - PHP-FPM 8.3           │
                              │  - MariaDB 11.2          │
                              │  - Redis (Cache)         │
                              │  - Auto Backup           │
                              └──────────────────────────┘
```

## 🔧 Tech Stack

- **Web Server**: Nginx 1.25
- **PHP**: PHP-FPM 8.3 (OPcache, APCu, Redis)
- **Database**: MariaDB 11.2
- **Cache**: Redis 7
- **CMS**: WordPress (Latest)
- **Container**: Docker + Docker Compose

## 📦 What's Included

### Services (6)
1. **nginx** - Web server dengan security headers
2. **php-fpm** - PHP processor
3. **mariadb** - Database server
4. **redis** - Object cache
5. **backup** - Automated backup service
6. **wp-cli** - WordPress CLI tools

### Scripts (9)
- `INSTALL.sh` - Configuration wizard (NEW!)
- `generate-secrets.sh` - Generate passwords
- `init-wordpress.sh` - Initialize WordPress
- `backup-db.sh` - Database backup
- `restore-backup.sh` - Restore backup
- `healthcheck.sh` - Health monitoring
- `update-wordpress.sh` - Update WordPress
- `cleanup.sh` - Resource cleanup
- `fix-permissions.sh` - Fix file permissions

### Documentation (10+)
- Installation guides
- Security checklist
- Troubleshooting guides
- Best practices
- Configuration references

## 🔐 Security Features

- Docker secrets for passwords
- Rate limiting (login, admin, general)
- Security headers (X-Frame-Options, CSP, etc.)
- XML-RPC disabled
- File editor disabled
- Dangerous PHP functions disabled
- Cloudflare real IP forwarding
- Fail2ban compatible
- Regular security updates

## ⚡ Performance Features

- OPcache enabled (128MB)
- PHP-FPM optimized pools
- MariaDB query cache
- Redis object caching
- Static file caching (30 days)
- Gzip compression
- Keep-alive connections
- APCu support

## 💾 Backup & Recovery

- **Automated**: Daily backup at 2 AM (Asia/Jakarta)
- **Retention**: 7 days
- **Format**: Compressed SQL (gzip)
- **Manual**: `make backup`
- **Restore**: `./scripts/restore-backup.sh <filename>`

## 📊 System Requirements

### Minimum
- 2GB RAM
- 2 CPU cores
- 20GB disk space
- Ubuntu 20.04+ or similar

### Recommended
- 4GB RAM (default config)
- 4 CPU cores
- 50GB disk space
- Ubuntu 22.04 LTS

### For High Traffic
- 8GB+ RAM
- 8+ CPU cores
- 100GB+ disk space
- Adjust PHP-FPM pool settings

## 🌐 Network Setup

### Cloudflare
1. Add domain to Cloudflare
2. Point A record to your public IP
3. Enable "Proxied" (orange cloud)
4. SSL/TLS: "Full" or "Full (strict)"

### NPM (Nginx Proxy Manager)
1. Create Proxy Host
2. Domain: your-domain.com
3. Forward to: your-local-ip:80
4. Enable WebSockets
5. Add SSL certificate

### Mikrotik (if needed)
```
/ip firewall nat
add chain=dstnat dst-address=<public-ip> dst-port=8089 \
    action=dst-nat to-addresses=<local-ip> to-ports=80 \
    protocol=tcp
```

## 🛠️ Common Commands

```bash
# Start services
make start

# Stop services
make stop

# View logs
make logs

# Health check
make health

# Manual backup
make backup

# Update WordPress
make update

# Optimize database
make optimize-db

# Clear cache
make clear-cache

# All commands
make help
```

## 🐛 Troubleshooting

### Services won't start
```bash
docker compose logs
docker compose down
docker compose up -d
```

### Can't access website
```bash
curl http://localhost
docker compose ps
./scripts/healthcheck.sh
```

### Database error
```bash
docker compose logs mariadb
docker compose restart mariadb
```

### Wrong domain/IP
```bash
./INSTALL.sh  # Re-run configuration
docker compose down
docker compose up -d
```

## 📝 Configuration

### For 2GB RAM Server
Edit `php/php-fpm.d/www.conf`:
```
pm.max_children = 25
```

Edit `mariadb/my.cnf`:
```
innodb_buffer_pool_size = 256M
```

### For 8GB RAM Server
Edit `php/php-fpm.d/www.conf`:
```
pm.max_children = 100
```

Edit `mariadb/my.cnf`:
```
innodb_buffer_pool_size = 1G
```

Then rebuild:
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## 🔄 Updates

### Update WordPress Core + Plugins
```bash
make update
```

### Update Docker Images
```bash
docker compose pull
docker compose up -d
```

## 🗂️ Project Structure

```
hermanwebproject/
├── docker-compose.yml      # Main config (uses env vars)
├── .env                    # Created by INSTALL.sh
├── INSTALL.sh              # Configuration wizard
├── Makefile                # Command shortcuts
├── nginx/
│   └── conf.d/
│       └── *.conf          # Generated by INSTALL.sh
├── php/
│   ├── Dockerfile
│   ├── php.ini
│   └── php-fpm.d/
├── mariadb/
│   └── my.cnf
├── scripts/
│   └── *.sh
├── secrets/                # Git-ignored
│   ├── db_root_password.txt
│   ├── db_password.txt
│   └── wp_admin_password.txt
└── wordpress/
    └── wp-config.php.template
```

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

MIT License - see LICENSE file

## 👤 Author

Herman Web Project Team

## 📞 Support

- 📧 Email: [Your support email]
- 📚 Documentation: Check all `.md` files
- 🐛 Issues: Create issue in repository

## 🎓 Use Cases

Perfect for:
- ✅ Government websites
- ✅ Organization websites
- ✅ Company websites
- ✅ Blog platforms
- ✅ News portals
- ✅ E-commerce sites

Already used in production for:
- BPKAD Kabupaten Bengkalis
- Multiple government agencies
- Organizations and companies

## ⚠️ Important Notes

1. **Always run INSTALL.sh first** before installation
2. **Save all passwords** generated by generate-secrets.sh
3. **Save admin credentials** from init-wordpress.sh
4. **Enable SSL** in production (via Cloudflare/NPM)
5. **Regular backups** are automated, but test restore quarterly
6. **Security updates** - run `make update` monthly
7. **Monitor logs** - check `make logs` weekly

## 🌟 What Makes This Special

- **Zero Hardcoding**: Domain dan IP tidak hardcoded
- **One-Command Setup**: `INSTALL.sh` untuk semua konfigurasi
- **Production Tested**: Sudah jalan di production
- **Government Grade**: Security standar pemerintahan
- **Full Documentation**: Dokumentasi lengkap dalam Bahasa Indonesia
- **Easy Maintenance**: Makefile untuk command yang mudah
- **Flexible Architecture**: Support Cloudflare, NPM, Mikrotik
- **Automated Backup**: Daily backup otomatis

---

**Version**: 2.0.0  
**Last Updated**: November 2024  
**Project**: hermanwebproject

**Ready to deploy? Read [00-START-HERE.md](00-START-HERE.md)! 🚀**

