# Codika WhatsApp Group Connector

Self-hosted WhatsApp connector that enables your Codika bot to work in WhatsApp groups. Uses [Evolution API](https://github.com/EvolutionAPI/evolution-api) (Baileys engine) to connect to WhatsApp Web.

## How it works

```
Your WhatsApp groups ←→ This connector (your VPS) ←→ Codika bot (cloud)
```

1. This connector runs on your own server and connects to WhatsApp as a linked device
2. When someone @mentions the bot in a group, the message is forwarded to your Codika bot
3. The bot processes the message and sends a reply back through this connector

## Requirements

- A VPS or server with Docker installed (see [Hosting Guide](docs/hosting-guide.md))
- A phone number with WhatsApp installed (this will be your bot's number)
- Your Codika webhook URL (from your dashboard or support team)

## Quick Start

```bash
# 1. Clone this repository
git clone https://github.com/codika-io/codika-baileys-connector.git
cd codika-baileys-connector

# 2. Run the setup script
chmod +x setup.sh
./setup.sh

# 3. Follow the on-screen instructions to:
#    - Enter your Codika webhook URL
#    - Enter your server's IP or domain
#    - Create a WhatsApp instance and scan the QR code
```

## Manual Setup

If you prefer to configure manually:

```bash
# 1. Copy and edit the environment file
cp .env.example .env
nano .env  # Edit the required values

# 2. Start the services
docker compose up -d

# 3. Verify it's running
curl http://localhost:8080
```

## Connecting Your WhatsApp Number

After the services are running, create an instance and link your phone:

```bash
# Replace YOUR_API_KEY with the key from your .env file
# Replace YOUR_SERVER_URL with your server's address

# Step 1: Create an instance
curl -X POST YOUR_SERVER_URL/instance/create \
  -H 'apikey: YOUR_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"instanceName": "bot", "integration": "WHATSAPP-BAILEYS"}'

# Step 2: Get the QR code
curl YOUR_SERVER_URL/instance/connect/bot \
  -H 'apikey: YOUR_API_KEY'
# This returns a base64 QR code image

# Step 3: On your phone
# WhatsApp > Settings > Linked Devices > Link a Device
# Scan the QR code
```

## Verifying the Connection

```bash
# Check instance status
curl YOUR_SERVER_URL/instance/connectionState/bot \
  -H 'apikey: YOUR_API_KEY'

# Expected response when connected:
# {"instance":{"instanceName":"bot","state":"open"}}
```

## Adding the Bot to Groups

1. Open WhatsApp on the phone linked to this connector
2. Add the bot's phone number to any group (or use an existing group)
3. Members can interact with the bot by @mentioning it

## Management Commands

```bash
# View logs
docker compose logs -f evolution-api

# Restart services
docker compose restart

# Stop services
docker compose down

# Update to latest version
# Edit EVOLUTION_API_VERSION in .env, then:
docker compose pull
docker compose up -d
```

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for common issues.

**Quick checks:**
- `docker compose ps` -- are all 3 services running?
- `docker compose logs evolution-api` -- any error messages?
- `curl http://localhost:8080` -- does the API respond?

## Important Notes

- **This connector uses an unofficial WhatsApp API.** It is not endorsed by Meta. Use at your own risk.
- **Use a dedicated phone number** for the bot. Do not use your personal number.
- **Rate limits apply.** Avoid sending too many messages too quickly. See [docs/rate-limits.md](docs/rate-limits.md).
- **Session persistence:** The QR code only needs to be scanned once. Sessions survive container restarts.
- **Keep the phone online:** WhatsApp linked device sessions require the phone to connect to the internet at least once every 14 days.
