#!/usr/bin/env bash
# =============================================================================
# Enable HTTPS with Let's Encrypt
# Run this AFTER setup.sh has completed and services are running.
# Usage: ./enable-ssl.sh [--domain yourdomain.com] [--email you@example.com]
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}>>>${NC} $1"; }
success() { echo -e "${GREEN}>>>${NC} $1"; }
warn()    { echo -e "${YELLOW}>>>${NC} $1"; }
fail()    { echo -e "${RED}>>>${NC} $1"; exit 1; }

DOMAIN_NAME=""
EMAIL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --domain) DOMAIN_NAME="$2"; shift 2 ;;
        --email)  EMAIL="$2"; shift 2 ;;
        *) shift ;;
    esac
done

echo ""
echo -e "${BOLD}  Enable HTTPS (Let's Encrypt)${NC}"
echo "  ============================="
echo ""

# ---- 1. Checks ----
if [ ! -f .env ]; then
    fail "No .env file found. Run ./setup.sh first."
fi

if ! docker compose ps --status running | grep -q evolution_api; then
    fail "Services not running. Start them with: docker compose up -d"
fi

# ---- 2. Collect domain ----
if [ -z "$DOMAIN_NAME" ]; then
    echo -e "  Enter the domain name pointing to this server."
    echo -e "  ${YELLOW}Make sure DNS A record is set to this server's IP first.${NC}"
    echo ""
    read -p "  Domain: " DOMAIN_NAME
fi

if [ -z "$DOMAIN_NAME" ]; then
    fail "Domain name is required."
fi

if [ -z "$EMAIL" ]; then
    read -p "  Email (for Let's Encrypt notices): " EMAIL
fi

if [ -z "$EMAIL" ]; then
    fail "Email is required for Let's Encrypt."
fi

info "Domain: ${DOMAIN_NAME}"
info "Email: ${EMAIL}"

# ---- 3. Get certificate ----
# Port 80 is free (nginx runs on port 3000), so we use certbot standalone
info "Requesting certificate from Let's Encrypt..."

# Derive the compose project volume prefix
COMPOSE_PROJECT=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
CERT_VOL="${COMPOSE_PROJECT}_certbot_certs"
WWW_VOL="${COMPOSE_PROJECT}_certbot_www"

# Ensure volumes exist (they're created by docker compose up)
docker volume inspect "${CERT_VOL}" > /dev/null 2>&1 || docker volume create "${CERT_VOL}"
docker volume inspect "${WWW_VOL}" > /dev/null 2>&1 || docker volume create "${WWW_VOL}"

docker run --rm \
    -v "${CERT_VOL}:/etc/letsencrypt" \
    -v "${WWW_VOL}:/var/www/certbot" \
    -p 80:80 \
    certbot/certbot:v2.11.0 \
    certonly --standalone \
    -d "${DOMAIN_NAME}" \
    --email "${EMAIL}" \
    --agree-tos \
    --no-eff-email \
    --non-interactive \
    || fail "Certificate request failed. Ensure DNS points to this server and port 80 is accessible."

success "Certificate obtained"

# ---- 4. Write SSL nginx config ----
info "Enabling HTTPS in nginx..."

cat > setup-ui/nginx.conf << NGINX_SSL
server {
    listen 80;
    server_name ${DOMAIN_NAME};

    # Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${DOMAIN_NAME};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Serve the setup UI
    location = / {
        root /usr/share/nginx/html;
        try_files /index.html =404;
    }

    # Proxy all API requests to Evolution API
    location / {
        proxy_pass http://evolution-api:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX_SSL

# ---- 5. Update .env with domain ----
if ! grep -q "DOMAIN_NAME" .env; then
    echo "" >> .env
    echo "# SSL (added by enable-ssl.sh)" >> .env
    echo "DOMAIN_NAME=${DOMAIN_NAME}" >> .env
fi

# ---- 6. Update EVOLUTION_SERVER_URL to HTTPS ----
EVO_API_KEY=$(grep EVOLUTION_API_KEY .env | head -1 | cut -d= -f2)
sed -i.bak "s|EVOLUTION_SERVER_URL=http://.*|EVOLUTION_SERVER_URL=https://${DOMAIN_NAME}:3443|" .env
rm -f .env.bak

# ---- 7. Restart nginx and start certbot renewal ----
docker compose restart setup-ui
docker compose --profile ssl up -d certbot

success "HTTPS enabled!"
echo ""
echo -e "  ${BOLD}Management page:${NC}  https://${DOMAIN_NAME}:3443#key=${EVO_API_KEY}"
echo ""
echo -e "  ${YELLOW}Certificates auto-renew every 12 hours via certbot.${NC}"
echo ""
