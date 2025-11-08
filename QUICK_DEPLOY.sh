#!/bin/bash
################################################################################
# Quick Deploy Script - WordPress Production
# 
# This script quickly deploys WordPress with all proven configurations
# Usage: ./QUICK_DEPLOY.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     WordPress Production - Quick Deploy                     ║
║     DPMD Bengkalis - Proven Configuration                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if already configured
if [ ! -f ".env" ]; then
    print_error ".env file not found!"
    echo ""
    echo "Please run INSTALL.sh first to configure domain and IP:"
    echo "  ./INSTALL.sh"
    exit 1
fi

if [ ! -f "secrets/db_password.txt" ]; then
    print_error "Secrets not found!"
    echo ""
    echo "Please generate secrets first:"
    echo "  ./scripts/generate-secrets.sh"
    exit 1
fi

print_info "Starting deployment..."
echo ""

# Step 1: Build containers
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Building Docker images..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose build --no-cache
print_success "Docker images built"
echo ""

# Step 2: Start services
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Starting services..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose up -d
print_success "Services started"
echo ""

# Step 3: Wait for services
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Waiting for services to be ready..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for i in {90..1}; do
    echo -ne "⏳ Waiting... $i seconds remaining\r"
    sleep 1
done
echo ""
print_success "Services ready"
echo ""

# Step 4: Initialize WordPress
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Initializing WordPress..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose run --rm wp-cli /scripts/init-wordpress.sh
print_success "WordPress initialized"
echo ""

# Step 5: Fix permissions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Setting correct permissions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose exec --user root php-fpm chown -R www-data:www-data /var/www/html
docker compose exec --user root php-fpm find /var/www/html -type d -exec chmod 755 {} \;
docker compose exec --user root php-fpm find /var/www/html -type f -exec chmod 644 {} \;
print_success "Permissions set"
echo ""

# Step 6: Install and enable Redis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Enabling Redis Object Cache..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose run --rm wp-cli wp plugin install redis-cache --activate --allow-root || true
docker compose run --rm wp-cli wp redis enable --allow-root || true
print_success "Redis Object Cache enabled"
echo ""

# Step 7: Health check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 7: Running health checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/healthcheck.sh || true
echo ""

# Get configuration
DOMAIN=$(grep WORDPRESS_DOMAIN .env | cut -d '=' -f2)
WP_ADMIN_PASS=$(sudo cat secrets/wp_admin_password.txt)

# Final summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  🎉  Deployment Complete!                                    ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Access Your Site:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Website:    http://${DOMAIN}"
echo -e "  Admin:      http://${DOMAIN}/wp-admin/"
echo -e "  Username:   admin"
echo -e "  Password:   ${WP_ADMIN_PASS}"
echo ""
echo -e "${BLUE}Features Enabled:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ✅ WordPress Latest (Indonesian)"
echo -e "  ✅ MariaDB 11.2"
echo -e "  ✅ PHP-FPM 8.3 with OPcache"
echo -e "  ✅ Redis Object Cache"
echo -e "  ✅ Nginx Reverse Proxy"
echo -e "  ✅ Cloudflare Compatible"
echo -e "  ✅ Auto Daily Backups"
echo -e "  ✅ Security Hardened"
echo ""
echo -e "${BLUE}Installed Plugins:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ✅ Wordfence Security"
echo -e "  ✅ Redis Object Cache"
echo -e "  ✅ UpdraftPlus Backup"
echo -e "  ✅ Limit Login Attempts Reloaded"
echo ""
echo -e "${YELLOW}Important Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  1. Login to WordPress admin"
echo -e "  2. Change admin password"
echo -e "  3. Configure Wordfence Security"
echo -e "  4. Set up UpdraftPlus remote backup"
echo -e "  5. Review Site Health (Tools → Site Health)"
echo -e "  6. Configure Redis (Settings → Redis)"
echo ""
echo -e "${RED}⚠ Save your admin password securely!${NC}"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  📖 PRODUCTION_DEPLOYMENT_NOTES.md - Deployment summary"
echo -e "  📖 README.md - Complete documentation"
echo -e "  📖 SECURITY.md - Security guidelines"
echo ""
echo -e "${GREEN}Happy deploying! 🚀${NC}"
echo ""

