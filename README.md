# Codika WhatsApp Group Connector

Connect your Codika bot to WhatsApp groups. One command setup.

## How it works

```
WhatsApp groups  <-->  This connector (your server)  <-->  Codika bot (cloud)
```

## Setup (5 minutes)

You need: a VPS with Ubuntu (see [hosting guide](docs/hosting-guide.md), ~$5/month) and your Codika webhook URL.

**SSH into your server, then:**

```bash
git clone https://github.com/codika-io/codika-baileys-connector.git
cd codika-baileys-connector
./setup.sh
```

The script will:
- Install Docker if needed
- Ask for your webhook URL (the only question)
- Auto-detect your server IP
- Auto-generate all passwords and keys
- Start everything
- Give you a URL to scan the QR code

**Open the URL in your browser, scan the QR code with WhatsApp, done.**

## After Setup

### Management page

Bookmark the URL from the setup output. It shows:
- Connection status
- QR code for (re)linking
- Disconnect/reconnect controls

### Common commands

```bash
# View logs
docker compose logs -f evolution-api

# Restart
docker compose restart

# Stop
docker compose down

# Re-run setup (if you need to change the webhook URL)
rm .env && ./setup.sh

# Update to latest version
# Edit EVOLUTION_API_VERSION in .env, then:
docker compose pull && docker compose up -d
```

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md).

**Quick check:** `docker compose ps` -- all 4 services should be "Up".

## Important

- Uses an unofficial WhatsApp API. Not endorsed by Meta. Use at your own risk.
- Use a **dedicated phone number** for the bot, not your personal one.
- Keep the phone online at least once every 14 days.
- See [docs/rate-limits.md](docs/rate-limits.md) for best practices.
