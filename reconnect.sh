#!/usr/bin/env bash
# =============================================================================
# Codika WhatsApp Connector - Reconnect
# =============================================================================
# Temporarily opens the management page, waits for WhatsApp to connect
# (via QR code or pairing code), then closes the page automatically.
#
# Usage: ./reconnect.sh
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

QR_TIMEOUT=900  # 15 minutes

# ---- 1. Validate environment ----
if [ ! -f .env ]; then
    fail "No .env found. Run setup.sh or install.sh first."
fi

EVO_API_KEY=$(grep EVOLUTION_API_KEY .env | head -1 | cut -d= -f2)
SERVER_IP=$(grep EVOLUTION_SERVER_URL .env | head -1 | sed 's|.*://||' | sed 's|:.*||')

if [ -z "$EVO_API_KEY" ]; then
    fail "EVOLUTION_API_KEY not found in .env"
fi

echo ""
echo -e "${BOLD}  Codika WhatsApp Connector - Reconnect${NC}"
echo "  ======================================="
echo ""

# ---- 2. Ensure Docker is running ----
if ! docker compose ps --format json 2>/dev/null | grep -q "running"; then
    info "Starting services..."
    docker compose up -d
    info "Waiting for Evolution API..."
    attempts=0
    until docker exec evolution_api wget --spider -q http://localhost:8080 2>/dev/null; do
        attempts=$((attempts + 1))
        if [ $attempts -ge 30 ]; then
            fail "Evolution API did not start. Run: docker compose logs evolution-api"
        fi
        sleep 2
    done
    success "Services running"
fi

# ---- 3. Check if already connected ----
STATE=$(curl -s -m 5 "http://localhost:8080/instance/connectionState/bot" \
    -H "apikey: ${EVO_API_KEY}" 2>/dev/null \
    | grep -o '"state":"[^"]*"' | cut -d'"' -f4 || echo "unknown")

if [ "$STATE" = "open" ]; then
    success "WhatsApp is already connected!"
    echo ""
    exit 0
fi

# ---- 4. Logout old session so a fresh QR is generated ----
info "Resetting session for new connection..."
curl -s -o /dev/null -m 5 \
    -X DELETE "http://localhost:8080/instance/logout/bot" \
    -H "apikey: ${EVO_API_KEY}" 2>/dev/null || true

# Give Evolution API a moment to reset
sleep 3

# Restart the instance connection to trigger QR generation
curl -s -o /dev/null -m 5 \
    -X GET "http://localhost:8080/instance/connect/bot" \
    -H "apikey: ${EVO_API_KEY}" 2>/dev/null || true

# ---- 5. Open QR port temporarily (Linux only) ----
FIREWALL_MANAGED=false
if [[ "$(uname)" == "Linux" ]] && command -v ufw &> /dev/null; then
    ufw allow 3000/tcp > /dev/null 2>&1
    FIREWALL_MANAGED=true
    info "Management page opened temporarily"
fi

# ---- 6. Show URL and wait ----
echo ""
echo -e "  Open this URL in your browser:"
echo ""
echo -e "  ${BOLD}${BLUE}http://${SERVER_IP}:3000#key=${EVO_API_KEY}${NC}"
echo ""
echo -e "  Then choose QR Code or Pairing Code to link your device."
echo -e "  On your phone: WhatsApp > Settings > Linked Devices > Link a Device"
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

# ---- 7. Close QR port ----
if [ "$FIREWALL_MANAGED" = true ]; then
    ufw delete allow 3000/tcp > /dev/null 2>&1
fi

if [ "$CONNECTED" = true ]; then
    echo ""
    success "WhatsApp connected! Management page secured."
else
    echo ""
    warn "Timed out. Management page closed for security."
    echo -e "  Run ${BOLD}./reconnect.sh${NC} to try again."
fi
echo ""
