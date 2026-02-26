#!/usr/bin/env bash
# =============================================================================
# Codika WhatsApp Connector - One-Command Remote Install
#
# Usage (from Codika dashboard - personalized command):
#   curl -sSL https://raw.githubusercontent.com/codika-io/codika-baileys-connector/main/install.sh | bash -s -- \
#     --webhook "https://your-webhook-url" \
#     --apikey "ck_your_api_key"
#
# Usage (interactive - prompts for webhook URL and API key):
#   curl -sSL https://raw.githubusercontent.com/codika-io/codika-baileys-connector/main/install.sh | bash
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}>>>${NC} $1"; }
success() { echo -e "${GREEN}>>>${NC} $1"; }
fail()    { echo -e "${RED}>>>${NC} $1"; exit 1; }

INSTALL_DIR="$HOME/codika-baileys-connector"
REPO_URL="https://github.com/codika-io/codika-baileys-connector.git"

echo ""
echo -e "${BOLD}  Codika WhatsApp Connector - Quick Install${NC}"
echo "  ==========================================="
echo ""

# ---- 1. Install Docker if needed ----
if ! command -v docker &> /dev/null; then
    info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker 2>/dev/null || true
    systemctl start docker 2>/dev/null || true
    success "Docker installed"
fi

if ! docker info &> /dev/null; then
    fail "Docker is not running. Start it and try again."
fi

# ---- 2. Install git if needed ----
if ! command -v git &> /dev/null; then
    info "Installing git..."
    apt-get update -qq && apt-get install -y -qq git > /dev/null 2>&1
    success "git installed"
fi

# ---- 3. Clone or update the repo ----
if [ -d "$INSTALL_DIR" ]; then
    info "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull --quiet
else
    info "Downloading connector..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

chmod +x setup.sh

# ---- 4. Run setup (passes through any --webhook / --apikey arguments) ----
info "Running setup..."
echo ""
./setup.sh "$@"
