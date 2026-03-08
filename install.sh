#!/usr/bin/env bash
# =============================================================================
# Codika WhatsApp Connector - One-Line Installer
# =============================================================================
#
# Usage (from Codika dashboard - pre-filled command):
#   curl -fsSL https://raw.githubusercontent.com/codika-io/codika-baileys-connector/main/install.sh | \
#     sudo bash -s -- --webhook "URL" --apikey "KEY"
#
# What this does:
#   1. Installs Docker + git if missing
#   2. Clones the connector repo
#   3. Runs setup (Docker containers + WhatsApp instance)
#   4. Configures firewall (SSH + API open, QR page temporary)
#   5. Opens QR page for scanning
#   6. Auto-closes QR page once WhatsApp connects (or after 15min timeout)
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}>>>${NC} $1"; }
success() { echo -e "${GREEN}>>>${NC} $1"; }
warn()    { echo -e "${YELLOW}>>>${NC} $1"; }
fail()    { echo -e "${RED}>>>${NC} $1"; exit 1; }

INSTALL_DIR="/opt/codika-whatsapp"
REPO_URL="https://github.com/codika-io/codika-baileys-connector.git"
QR_TIMEOUT=900  # 15 minutes

# ---- 0. Parse arguments ----
CODIKA_WEBHOOK_URL="${CODIKA_WEBHOOK_URL:-}"
CODIKA_API_KEY="${CODIKA_API_KEY:-}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --webhook) CODIKA_WEBHOOK_URL="$2"; shift 2 ;;
        --apikey)  CODIKA_API_KEY="$2"; shift 2 ;;
        --dir)     INSTALL_DIR="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [ -z "$CODIKA_WEBHOOK_URL" ]; then
    fail "Missing --webhook URL.\n  Usage: curl -fsSL URL | sudo bash -s -- --webhook 'URL' --apikey 'KEY'"
fi
if [ -z "$CODIKA_API_KEY" ]; then
    fail "Missing --apikey.\n  Usage: curl -fsSL URL | sudo bash -s -- --webhook 'URL' --apikey 'KEY'"
fi

# Root required on Linux for firewall + Docker + /opt
if [[ "$(uname)" == "Linux" ]] && [ "$(id -u)" -ne 0 ]; then
    fail "Root required. Run with: sudo bash -s -- --webhook '...' --apikey '...'"
fi

echo ""
echo -e "${BOLD}  Codika WhatsApp Connector${NC}"
echo "  ========================="
echo ""

# ---- 1. Install prerequisites ----
if ! command -v git &> /dev/null; then
    info "Installing git..."
    if command -v apt-get &> /dev/null; then
        apt-get update -qq && apt-get install -y -qq git > /dev/null
    elif command -v yum &> /dev/null; then
        yum install -y -q git > /dev/null
    else
        fail "git not found. Install git manually and retry."
    fi
    success "git installed"
fi

if ! command -v docker &> /dev/null; then
    info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker 2>/dev/null || true
    systemctl start docker 2>/dev/null || true
    success "Docker installed"
fi

if ! docker info &> /dev/null; then
    fail "Docker is not running. Start it and retry."
fi

# ---- 2. Clone or update repo ----
if [ -d "$INSTALL_DIR/.git" ]; then
    info "Existing installation found, updating..."
    cd "$INSTALL_DIR"
    git pull --quiet 2>/dev/null || true
    success "Repository updated"
else
    info "Downloading connector..."
    git clone --quiet --depth 1 "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    success "Downloaded to $INSTALL_DIR"
fi

chmod +x setup.sh reconnect.sh status.sh 2>/dev/null || true

# ---- 3. Run core setup (non-interactive) ----
info "Setting up services..."
export CODIKA_INSTALLER=1
bash setup.sh --webhook "$CODIKA_WEBHOOK_URL" --apikey "$CODIKA_API_KEY"
success "Services running"

# ---- 4. Configure firewall (Linux only) ----
if [[ "$(uname)" == "Linux" ]]; then
    info "Configuring firewall..."

    if ! command -v ufw &> /dev/null; then
        apt-get update -qq && apt-get install -y -qq ufw > /dev/null 2>&1
    fi

    # CRITICAL: Allow SSH first — before anything else.
    # Enabling UFW without this locks you out of the server permanently.
    ufw allow 22/tcp   > /dev/null 2>&1

    # Evolution API — must stay open for n8n to send replies.
    # Protected by API key in request headers.
    ufw allow 8080/tcp > /dev/null 2>&1

    # QR page — temporary, closed after WhatsApp connects.
    ufw allow 3000/tcp > /dev/null 2>&1

    # Enable UFW if not already active
    if ! ufw status | grep -q "Status: active"; then
        echo "y" | ufw enable > /dev/null 2>&1
    fi

    success "Firewall: SSH(22) + API(8080) open, QR(3000) temporary"
fi

# ---- 5. Wait for WhatsApp connection ----
EVO_API_KEY=$(grep EVOLUTION_API_KEY .env | head -1 | cut -d= -f2)
SERVER_IP=$(grep EVOLUTION_SERVER_URL .env | head -1 | sed 's|.*://||' | sed 's|:.*||')

echo ""
echo -e "${GREEN}  ==========================================${NC}"
echo -e "${GREEN}  Scan the QR code to connect WhatsApp${NC}"
echo -e "${GREEN}  ==========================================${NC}"
echo ""
echo -e "  Open this URL in your browser:"
echo ""
echo -e "  ${BOLD}${BLUE}http://${SERVER_IP}:3000#key=${EVO_API_KEY}${NC}"
echo ""
echo -e "  Then on your phone:"
echo -e "  WhatsApp > Settings > Linked Devices > Link a Device"
echo ""
echo -e "  ${DIM}Waiting for connection (timeout: 15 min)...${NC}"

SECONDS_ELAPSED=0
CONNECTED=false

while [ $SECONDS_ELAPSED -lt $QR_TIMEOUT ]; do
    STATE=$(curl -s -m 5 "http://localhost:8080/instance/connectionState/bot" \
        -H "apikey: ${EVO_API_KEY}" 2>/dev/null \
        | grep -o '"state":"[^"]*"' | cut -d'"' -f4 || echo "unknown")

    if [ "$STATE" = "open" ]; then
        CONNECTED=true
        break
    fi

    sleep 3
    SECONDS_ELAPSED=$((SECONDS_ELAPSED + 3))
done

# ---- 6. Close QR port ----
if [[ "$(uname)" == "Linux" ]] && command -v ufw &> /dev/null; then
    ufw delete allow 3000/tcp > /dev/null 2>&1
fi

if [ "$CONNECTED" = true ]; then
    echo ""
    echo -e "${GREEN}  ==========================================${NC}"
    echo -e "${GREEN}  WhatsApp connected!${NC}"
    echo -e "${GREEN}  QR page secured (port closed)${NC}"
    echo -e "${GREEN}  Your bot is live!${NC}"
    echo -e "${GREEN}  ==========================================${NC}"
else
    echo ""
    echo -e "${YELLOW}  ==========================================${NC}"
    echo -e "${YELLOW}  Timed out waiting for QR scan.${NC}"
    echo -e "${YELLOW}  QR page closed for security.${NC}"
    echo -e "${YELLOW}  ==========================================${NC}"
    echo ""
    echo -e "  Run ${BOLD}./reconnect.sh${NC} to try again."
fi

echo ""
echo -e "  ${BOLD}Commands:${NC}"
echo -e "    ./status.sh        Check bot health"
echo -e "    ./reconnect.sh     Re-scan QR code"
echo -e "    docker compose logs -f evolution-api   View logs"
echo -e "    docker compose down                    Stop bot"
echo ""
