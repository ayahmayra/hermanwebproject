#!/bin/bash

################################################################################
# WordPress Docker Project - Installation Configuration Script
# 
# This script configures the project with your domain and IP settings
# Run this BEFORE the first installation
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     WordPress Docker Project - Installation Setup           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓ ${NC}$1"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${NC}$1"
}

print_error() {
    echo -e "${RED}✗ ${NC}$1"
}

# Function to validate domain name
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$ ]] || \
       [[ $domain =~ ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.)+[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if ((octet > 255)); then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Check if already configured
if [ -f ".configured" ]; then
    print_warning "Project appears to be already configured."
    read -p "Do you want to reconfigure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Configuration cancelled."
        exit 0
    fi
fi

echo
print_info "This script will configure your WordPress installation."
print_info "You will be asked for:"
print_info "  1. Domain name (e.g., dpmd.bengkaliskab.go.id)"
print_info "  2. Local IP address (e.g., 10.10.10.34)"
print_info "  3. Project title"
print_info "  4. Admin email"
echo

# Get domain name
while true; do
    read -p "Enter your domain name: " DOMAIN
    if validate_domain "$DOMAIN"; then
        print_success "Domain: $DOMAIN"
        break
    else
        print_error "Invalid domain name. Please try again."
    fi
done

# Get local IP
while true; do
    read -p "Enter your local IP address: " LOCAL_IP
    if validate_ip "$LOCAL_IP"; then
        print_success "Local IP: $LOCAL_IP"
        break
    else
        print_error "Invalid IP address. Please try again."
    fi
done

# Get project title
read -p "Enter project title [Default: WordPress Site]: " PROJECT_TITLE
PROJECT_TITLE=${PROJECT_TITLE:-"WordPress Site"}
print_success "Title: $PROJECT_TITLE"

# Get admin email
while true; do
    read -p "Enter admin email: " ADMIN_EMAIL
    if [[ $ADMIN_EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_success "Email: $ADMIN_EMAIL"
        break
    else
        print_error "Invalid email address. Please try again."
    fi
done

# Extract project name from domain
PROJECT_NAME=$(echo "$DOMAIN" | cut -d'.' -f1)

echo
print_info "Configuration Summary:"
echo "  Domain:       $DOMAIN"
echo "  Local IP:     $LOCAL_IP"
echo "  Project Name: $PROJECT_NAME"
echo "  Title:        $PROJECT_TITLE"
echo "  Admin Email:  $ADMIN_EMAIL"
echo

read -p "Proceed with configuration? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_error "Configuration cancelled."
    exit 1
fi

echo
print_info "Configuring project..."

# 1. Create .env file
print_info "Creating .env file..."
cat > .env << EOF
# WordPress Configuration
WORDPRESS_DOMAIN=${DOMAIN}
WORDPRESS_LOCAL_IP=${LOCAL_IP}
WORDPRESS_TITLE="${PROJECT_TITLE}"
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_EMAIL=${ADMIN_EMAIL}

# Project Configuration
PROJECT_NAME=${PROJECT_NAME}

# Database Configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
# Passwords are stored in ./secrets/ directory (not in .env for security)

# Timezone
TZ=Asia/Jakarta

# Backup Configuration
BACKUP_RETENTION_DAYS=7

# Optional: Remote SFTP Backup
# SFTP_HOST=backup.example.com
# SFTP_PORT=22
# SFTP_USER=backup-user
# SFTP_PASSWORD=
# SFTP_REMOTE_PATH=/backups/${PROJECT_NAME}

# PHP Configuration
PHP_MEMORY_LIMIT=256M
PHP_MAX_EXECUTION_TIME=300
PHP_UPLOAD_MAX_FILESIZE=64M
PHP_POST_MAX_SIZE=64M

# PHP-FPM Pool Configuration (for 4GB RAM server)
PHP_FPM_PM_MAX_CHILDREN=50
PHP_FPM_PM_START_SERVERS=10
PHP_FPM_PM_MIN_SPARE_SERVERS=5
PHP_FPM_PM_MAX_SPARE_SERVERS=15
PHP_FPM_PM_MAX_REQUESTS=500

# OPcache Configuration
OPCACHE_MEMORY_CONSUMPTION=128
OPCACHE_INTERNED_STRINGS_BUFFER=16
OPCACHE_MAX_ACCELERATED_FILES=10000

# MariaDB Configuration
MYSQL_INNODB_BUFFER_POOL_SIZE=512M
MYSQL_MAX_CONNECTIONS=151
EOF
print_success ".env file created"

# 2. Create nginx config from template
print_info "Creating nginx configuration..."
mkdir -p nginx/conf.d
cat > "nginx/conf.d/${PROJECT_NAME}.conf" << 'EOF_NGINX'
# Nginx Configuration for WordPress
# Optimized for WordPress with security headers and performance tuning

# Rate limiting zones
limit_req_zone $binary_remote_addr zone=wp_login:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=wp_admin:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=general:10m rate=50r/s;

# Connection limiting
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

# Upstream PHP-FPM
upstream php {
    server php-fpm:9000;
    keepalive 32;
}

# Main server block
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    # Server names - domain and local IP
    server_name DOMAIN_PLACEHOLDER LOCAL_IP_PLACEHOLDER;
    
    root /var/www/html;
    index index.php index.html index.htm;
    
    # Access and error logs
    access_log /var/log/nginx/PROJECT_NAME_PLACEHOLDER-access.log;
    error_log /var/log/nginx/PROJECT_NAME_PLACEHOLDER-error.log warn;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    # Cloudflare real IP configuration
    # Set client IP from Cloudflare headers (if traffic comes through Cloudflare)
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 131.0.72.0/22;
    # IPv6
    set_real_ip_from 2400:cb00::/32;
    set_real_ip_from 2606:4700::/32;
    set_real_ip_from 2803:f800::/32;
    set_real_ip_from 2405:b500::/32;
    set_real_ip_from 2405:8100::/32;
    set_real_ip_from 2a06:98c0::/29;
    set_real_ip_from 2c0f:f248::/32;
    
    real_ip_header CF-Connecting-IP;
    real_ip_recursive on;
    
    # File upload limits
    client_max_body_size 64M;
    client_body_timeout 300s;
    
    # Connection limits
    limit_conn conn_limit_per_ip 20;
    
    # Rate limiting for general requests
    limit_req zone=general burst=100 nodelay;
    
    # Healthcheck endpoint for monitoring
    location = /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to WordPress sensitive files
    location ~* ^/(wp-config\.php|wp-config-sample\.php|readme\.html|license\.txt) {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to .git, .env, and other version control files
    location ~* /\.(git|svn|hg|htpasswd|env) {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Block access to xmlrpc.php to prevent DDoS attacks
    location = /xmlrpc.php {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Restrict wp-login.php access with rate limiting
    location = /wp-login.php {
        limit_req zone=wp_login burst=2 nodelay;
        
        # Only allow POST and GET
        limit_except GET POST {
            deny all;
        }
        
        fastcgi_pass php;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        
        # Security parameters
        fastcgi_param HTTPS off;
        fastcgi_param HTTP_PROXY "";
        
        # Cloudflare compatibility
        fastcgi_param HTTP_X_FORWARDED_FOR $http_x_forwarded_for;
        fastcgi_param HTTP_X_FORWARDED_PROTO $http_x_forwarded_proto;
        fastcgi_param HTTP_CF_CONNECTING_IP $http_cf_connecting_ip;
        
        # Performance tuning
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 180s;
        fastcgi_read_timeout 180s;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_intercept_errors on;
    }
    
    # Restrict wp-admin access with rate limiting
    location ~* ^/wp-admin/ {
        limit_req zone=wp_admin burst=20 nodelay;
        
        # Only allow safe HTTP methods
        limit_except GET POST HEAD {
            deny all;
        }
        
        try_files $uri $uri/ /index.php?$args;
        
        location ~ \.php$ {
            fastcgi_pass php;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
            
            # Security parameters
            fastcgi_param HTTPS off;
            fastcgi_param HTTP_PROXY "";
            
            # Cloudflare compatibility
            fastcgi_param HTTP_X_FORWARDED_FOR $http_x_forwarded_for;
            fastcgi_param HTTP_X_FORWARDED_PROTO $http_x_forwarded_proto;
            fastcgi_param HTTP_CF_CONNECTING_IP $http_cf_connecting_ip;
            
            # Performance tuning
            fastcgi_connect_timeout 60s;
            fastcgi_send_timeout 180s;
            fastcgi_read_timeout 180s;
            fastcgi_buffer_size 128k;
            fastcgi_buffers 256 16k;
            fastcgi_busy_buffers_size 256k;
            fastcgi_temp_file_write_size 256k;
            fastcgi_intercept_errors on;
        }
    }
    
    # Deny access to wp-content/uploads PHP files
    location ~* ^/wp-content/uploads/.*\.php$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|gif|png|webp|svg|ico|pdf|css|js|woff|woff2|ttf|eot|otf)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
        log_not_found off;
        
        # Security headers for static files
        add_header X-Content-Type-Options "nosniff" always;
    }
    
    # WordPress permalinks
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    # PHP files processing
    location ~ \.php$ {
        try_files $uri =404;
        
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        
        # Security parameters
        fastcgi_param HTTPS off;
        fastcgi_param HTTP_PROXY "";
        
        # Cloudflare compatibility - forward real client IP
        fastcgi_param HTTP_X_FORWARDED_FOR $http_x_forwarded_for;
        fastcgi_param HTTP_X_FORWARDED_PROTO $http_x_forwarded_proto;
        fastcgi_param HTTP_CF_CONNECTING_IP $http_cf_connecting_ip;
        fastcgi_param REMOTE_ADDR $remote_addr;
        
        # Performance tuning
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 300s;
        fastcgi_read_timeout 300s;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_intercept_errors on;
        
        # Enable fastcgi cache (optional - uncomment to enable)
        # fastcgi_cache_bypass $skip_cache;
        # fastcgi_no_cache $skip_cache;
        # fastcgi_cache WORDPRESS;
        # fastcgi_cache_valid 200 60m;
        # fastcgi_cache_valid 404 10m;
    }
    
    # Block dangerous HTTP methods
    if ($request_method !~ ^(GET|HEAD|POST)$ ) {
        return 405;
    }
    
    # Prevent information disclosure
    location = /readme.html {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location = /license.txt {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF_NGINX

# Replace placeholders in nginx config
sed -i.bak "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" "nginx/conf.d/${PROJECT_NAME}.conf"
sed -i.bak "s/LOCAL_IP_PLACEHOLDER/${LOCAL_IP}/g" "nginx/conf.d/${PROJECT_NAME}.conf"
sed -i.bak "s/PROJECT_NAME_PLACEHOLDER/${PROJECT_NAME}/g" "nginx/conf.d/${PROJECT_NAME}.conf"
rm "nginx/conf.d/${PROJECT_NAME}.conf.bak"
print_success "Nginx configuration created"

# 3. Update docker-compose.yml with env variables
print_info "Updating docker-compose.yml..."
# Backup original
cp docker-compose.yml docker-compose.yml.bak

# Update container names to use PROJECT_NAME
sed -i.tmp "s/container_name: bpkad-/container_name: ${PROJECT_NAME}-/g" docker-compose.yml

# Update extra_hosts in php-fpm
sed -i.tmp "s/- \"bpkad.bengkaliskab.go.id:10.10.10.31\"/- \"${DOMAIN}:${LOCAL_IP}\"/g" docker-compose.yml

# Update extra_hosts in wp-cli
sed -i.tmp "/wp-cli:/,/profiles:/ s/- \"bpkad.bengkaliskab.go.id:10.10.10.31\"/- \"${DOMAIN}:${LOCAL_IP}\"/g" docker-compose.yml

# Update volume names
sed -i.tmp "s/name: bpkad_/name: ${PROJECT_NAME}_/g" docker-compose.yml

rm docker-compose.yml.tmp
print_success "docker-compose.yml updated"

# 4. Mark as configured
echo "Configured on $(date)" > .configured
echo "Domain: $DOMAIN" >> .configured
echo "Local IP: $LOCAL_IP" >> .configured

# 5. Display next steps
echo
print_success "Configuration completed successfully!"
echo
print_info "Configuration saved:"
echo "  ✓ .env file created"
echo "  ✓ nginx/conf.d/${PROJECT_NAME}.conf created"
echo "  ✓ docker-compose.yml updated"
echo

print_info "Next steps:"
echo "  1. Make scripts executable:"
echo "     ${YELLOW}chmod +x scripts/*.sh php/docker-entrypoint.sh INSTALL.sh${NC}"
echo
echo "  2. Generate secrets:"
echo "     ${YELLOW}./scripts/generate-secrets.sh${NC}"
echo "     ${RED}⚠ IMPORTANT: Save the generated passwords!${NC}"
echo
echo "  3. Build and start containers:"
echo "     ${YELLOW}docker compose build${NC}"
echo "     ${YELLOW}docker compose up -d${NC}"
echo
echo "  4. Initialize WordPress:"
echo "     ${YELLOW}docker compose run --rm wp-cli /scripts/init-wordpress.sh${NC}"
echo "     ${RED}⚠ IMPORTANT: Save the admin credentials!${NC}"
echo
echo "  5. Verify installation:"
echo "     ${YELLOW}./scripts/healthcheck.sh${NC}"
echo
print_info "Access points after installation:"
echo "  Website:  http://${DOMAIN}"
echo "  Local:    http://${LOCAL_IP}"
echo "  Admin:    http://${DOMAIN}/wp-admin/"
echo

print_success "Ready to install! 🚀"

