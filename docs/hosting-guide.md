# Set Up Your WhatsApp Connector (10 minutes)

You need a small server that stays on 24/7 so your WhatsApp bot can receive and send messages. We recommend **Hostinger** -- it's beginner-friendly and costs $5.99/month.

---

## Step 1: Create a Hostinger account

1. Go to **https://www.hostinger.com/vps-hosting**
2. Choose the cheapest VPS plan (KVM 1 -- $4.99/month, 1 vCPU + 4GB RAM, way more than enough)
3. Create an account and complete payment

---

## Step 2: Create your server

After purchase, Hostinger walks you through a setup wizard:

**Screen 1 -- Choose a server location**
- Pick the location closest to you (e.g. **France** if you're in Europe)
- Click **Next**

**Screen 2 -- Choose what to install**
- Select **Ubuntu** (the most common Linux, our setup script is built for it)
- Pick the latest version (24.04 or 22.04)
- Click **Next**

**Screen 3 -- Choose a plan**
- Select **KVM 1** ($4.99/mo) -- the cheapest one, 1 vCPU + 4GB RAM is more than enough

**Screen 4 -- Additional features**
- **Malware scanner**: Leave enabled (free)
- **Daily auto-backups**: Optional (paid) -- not needed for this
- **Docker manager**: Enable it -- this pre-installs Docker so you don't have to
- Click **Next**

**Screen 5 -- Set a root password**
- Use the **generated password** (click the generate button) and save it in your password manager
- Click **Complete Setup**

**Wait 1-2 minutes** for the server to be ready. Then in your VPS dashboard, note the **IP address** (e.g. `85.214.123.456`).

---

## Step 3: Connect to your server

Open a terminal (Terminal on Mac, PowerShell on Windows):

```bash
ssh root@YOUR_SERVER_IP
```

Replace `YOUR_SERVER_IP` with the IP from step 2. Enter the root password when prompted.

> First time connecting? Type `yes` when asked about the fingerprint.

---

## Step 4: Install the connector

### Option A: One command (recommended)

Copy this **single command** from your Codika dashboard and paste it in the terminal:

```bash
curl -sSL https://raw.githubusercontent.com/codika-io/codika-baileys-connector/main/install.sh | bash -s -- \
  --webhook "YOUR_WEBHOOK_URL" \
  --apikey "YOUR_API_KEY"
```

> Your Codika dashboard gives you a ready-to-paste version with your actual webhook URL and API key filled in. Just copy and paste -- no editing needed.

This single command installs Docker, downloads the connector, configures everything, and starts the services. It takes 2-3 minutes.

### Option B: Step by step

If you prefer to run commands one at a time:

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker

# Download the connector
git clone https://github.com/codika-io/codika-baileys-connector.git
cd codika-baileys-connector

# Run the setup (it will ask for your webhook URL and API key)
./setup.sh
```

---

## Step 5: Scan the QR code

When setup finishes, it shows a URL like:

```
http://YOUR_SERVER_IP:3000#key=abc123...
```

1. Open that URL in your browser
2. You'll see a QR code
3. On your phone: **WhatsApp → Settings → Linked Devices → Link a Device**
4. Scan the QR code

**Done.** Your WhatsApp connector is live.

**Bookmark the management URL** -- use it anytime to check status or re-link your phone.

---

## Common commands

Connect to your server anytime with `ssh root@YOUR_SERVER_IP`, then:

```bash
cd codika-baileys-connector

# Check status (all 4 services should say "Up")
docker compose ps

# View logs
docker compose logs -f evolution-api

# Restart
docker compose restart

# Change webhook URL or API key
rm .env && ./setup.sh
```

---

## Troubleshooting

**Management page doesn't load?**
The firewall might be blocking port 3000. On Hostinger, go to your VPS dashboard → Firewall → add a rule to allow TCP port 3000. Or run:
```bash
ufw allow 3000/tcp && ufw allow 22/tcp && ufw enable
```

**QR code expired?**
Refresh the management page. A new QR code generates automatically.

**Bot stopped responding?**
Run `docker compose restart` on the server. If the phone was offline for 14+ days, you'll need to re-scan the QR code.

---

## Alternative providers

| Provider | Price | Link |
|----------|-------|------|
| **Hostinger VPS** (recommended) | $4.99/mo | https://www.hostinger.com/vps-hosting |
| Hetzner Cloud | €3.49/mo | https://console.hetzner.cloud |
| DigitalOcean | $6/mo | https://cloud.digitalocean.com |

The install commands are the same on all providers. Just create an Ubuntu server, SSH in, and paste the one-liner from Step 4.
