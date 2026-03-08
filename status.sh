#!/usr/bin/env bash
# =============================================================================
# Codika WhatsApp Connector - Status Check
# =============================================================================
# Shows the health of all connector components.
#
# Usage: ./status.sh
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo -e "${BOLD}  Codika WhatsApp Connector - Status${NC}"
echo "  ===================================="
echo ""

# ---- .env ----
if [ ! -f .env ]; then
    echo -e "  Config:     ${RED}Not configured${NC} (run setup.sh)"
    echo ""
    exit 1
fi
echo -e "  Config:     ${GREEN}OK${NC}"

# ---- Docker containers ----
DOCKER_OK=true
for svc in evolution_api evolution_postgres evolution_redis connector_ui; do
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${svc}$"; then
        echo -e "  ${svc}: ${GREEN}running${NC}"
    else
        echo -e "  ${svc}: ${RED}stopped${NC}"
        DOCKER_OK=false
    fi
done

if [ "$DOCKER_OK" = false ]; then
    echo ""
    echo -e "  ${YELLOW}Some services are stopped. Run: docker compose up -d${NC}"
    echo ""
    exit 1
fi

# ---- Evolution API health ----
EVO_API_KEY=$(grep EVOLUTION_API_KEY .env | head -1 | cut -d= -f2)

if curl -s -m 3 "http://localhost:8080" > /dev/null 2>&1; then
    echo -e "  API:        ${GREEN}responding${NC}"
else
    echo -e "  API:        ${RED}not responding${NC}"
    echo ""
    echo -e "  ${YELLOW}Check logs: docker compose logs evolution-api${NC}"
    echo ""
    exit 1
fi

# ---- WhatsApp connection ----
CONN_RESPONSE=$(curl -s -m 5 "http://localhost:8080/instance/connectionState/bot" \
    -H "apikey: ${EVO_API_KEY}" 2>/dev/null || echo "{}")

STATE=$(echo "$CONN_RESPONSE" | grep -o '"state":"[^"]*"' | cut -d'"' -f4 || echo "unknown")

case "$STATE" in
    open)
        echo -e "  WhatsApp:   ${GREEN}connected${NC}"
        ;;
    close)
        echo -e "  WhatsApp:   ${RED}disconnected${NC}"
        echo ""
        echo -e "  ${YELLOW}Run ./reconnect.sh to re-scan the QR code${NC}"
        ;;
    connecting)
        echo -e "  WhatsApp:   ${YELLOW}connecting...${NC}"
        ;;
    *)
        echo -e "  WhatsApp:   ${YELLOW}${STATE}${NC}"
        ;;
esac

# ---- Firewall (Linux only) ----
if command -v ufw &> /dev/null; then
    echo ""
    echo -e "  ${BOLD}Firewall:${NC}"
    if ufw status 2>/dev/null | grep -q "Status: active"; then
        PORT_22=$(ufw status 2>/dev/null | grep "22/tcp" | head -1 | awk '{print $NF}')
        PORT_3000=$(ufw status 2>/dev/null | grep "3000/tcp" | head -1 | awk '{print $NF}')
        PORT_8080=$(ufw status 2>/dev/null | grep "8080/tcp" | head -1 | awk '{print $NF}')

        echo -e "  SSH (22):   ${PORT_22:-${RED}not set${NC}}"
        echo -e "  API (8080): ${PORT_8080:-${RED}not set${NC}}"
        if [ -n "$PORT_3000" ]; then
            echo -e "  QR (3000):  ${YELLOW}${PORT_3000} (should be closed after setup)${NC}"
        else
            echo -e "  QR (3000):  ${GREEN}closed${NC}"
        fi
    else
        echo -e "  ${YELLOW}UFW not active${NC}"
    fi
fi

# ---- Webhook config ----
WEBHOOK_URL=$(grep CODIKA_WEBHOOK_URL .env | cut -d= -f2)
echo ""
echo -e "  ${BOLD}Webhook:${NC}"
echo -e "  ${DIM}${WEBHOOK_URL}${NC}"

echo ""
