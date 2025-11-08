#!/bin/bash
################################################################################
# Save Working Configuration Script
# 
# This script saves the current working wp-config.php as a backup template
# Usage: ./scripts/save-working-config.sh
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Save Working Configuration${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if docker compose is running
if ! docker compose ps | grep -q "php-fpm.*running"; then
    echo -e "${YELLOW}Warning: PHP-FPM container is not running${NC}"
    echo "Start containers first: docker compose up -d"
    exit 1
fi

# Create backup directory
BACKUP_DIR="backups/configs"
mkdir -p "$BACKUP_DIR"

# Timestamp for backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Saving current working configuration..."

# Save wp-config.php
docker compose exec php-fpm cat /var/www/html/wp-config.php > "$BACKUP_DIR/wp-config-${TIMESTAMP}.php"
echo -e "${GREEN}✓${NC} Saved wp-config.php to $BACKUP_DIR/wp-config-${TIMESTAMP}.php"

# Save as latest
cp "$BACKUP_DIR/wp-config-${TIMESTAMP}.php" "$BACKUP_DIR/wp-config-latest.php"
echo -e "${GREEN}✓${NC} Saved as wp-config-latest.php"

# Save .htaccess if exists
if docker compose exec php-fpm test -f /var/www/html/.htaccess; then
    docker compose exec php-fpm cat /var/www/html/.htaccess > "$BACKUP_DIR/htaccess-${TIMESTAMP}.txt"
    echo -e "${GREEN}✓${NC} Saved .htaccess to $BACKUP_DIR/htaccess-${TIMESTAMP}.txt"
fi

# Save plugin list
echo "Saving active plugins list..."
docker compose run --rm wp-cli wp plugin list --status=active --format=json --allow-root > "$BACKUP_DIR/plugins-active-${TIMESTAMP}.json"
echo -e "${GREEN}✓${NC} Saved active plugins list"

# Save WordPress options
echo "Saving WordPress options..."
docker compose run --rm wp-cli wp option get siteurl --allow-root > "$BACKUP_DIR/options-${TIMESTAMP}.txt"
docker compose run --rm wp-cli wp option get home --allow-root >> "$BACKUP_DIR/options-${TIMESTAMP}.txt"
echo -e "${GREEN}✓${NC} Saved WordPress options"

# Save Redis status if plugin exists
if docker compose run --rm wp-cli wp plugin is-installed redis-cache --allow-root 2>/dev/null; then
    docker compose run --rm wp-cli wp redis status --allow-root > "$BACKUP_DIR/redis-status-${TIMESTAMP}.txt" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Saved Redis status"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Configuration saved successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Backup location: $BACKUP_DIR/"
echo "Files saved:"
echo "  - wp-config-${TIMESTAMP}.php"
echo "  - wp-config-latest.php"
echo "  - plugins-active-${TIMESTAMP}.json"
echo "  - options-${TIMESTAMP}.txt"
echo ""
