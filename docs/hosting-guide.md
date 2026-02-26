# Hosting Guide

This connector needs a small always-on server with Docker. Here are the recommended options, cheapest first.

## Requirements

- **RAM:** 512 MB minimum, 1 GB recommended
- **CPU:** 1 vCPU is sufficient
- **Storage:** 10 GB minimum
- **OS:** Ubuntu 22.04 or 24.04 (recommended), Debian 12, or any Linux with Docker support
- **Network:** Public IP address, port 8080 open (or use a reverse proxy)

## Option 1: Hetzner Cloud (Recommended)

**Cost:** EUR 3.49/month (CX22 - 2 vCPU, 4 GB RAM)

1. Go to [cloud.hetzner.com](https://cloud.hetzner.com)
2. Create an account and add a payment method
3. Click **Create Server**
4. Settings:
   - Location: Choose closest to your users
   - Image: **Ubuntu 24.04**
   - Type: **CX22** (cheapest shared, more than enough)
   - SSH Key: Add your SSH key (or use password auth)
5. Click **Create & Buy Now**
6. Note the IP address

**Connect and install Docker:**
```bash
ssh root@YOUR_SERVER_IP

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install the connector
git clone https://github.com/codika-io/codika-baileys-connector.git
cd codika-baileys-connector
chmod +x setup.sh
./setup.sh
```

## Option 2: Hostinger VPS

**Cost:** ~$5.99/month (KVM 1 - 1 vCPU, 4 GB RAM)

1. Go to [hostinger.com/vps-hosting](https://www.hostinger.com/vps-hosting)
2. Choose **KVM 1** plan
3. Select **Ubuntu 22.04** as the OS
4. Complete purchase
5. Note the IP address from your dashboard

**Connect and install Docker:**
```bash
ssh root@YOUR_SERVER_IP

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install the connector
git clone https://github.com/codika-io/codika-baileys-connector.git
cd codika-baileys-connector
chmod +x setup.sh
./setup.sh
```

## Option 3: DigitalOcean

**Cost:** $6/month (Basic Droplet - 1 vCPU, 1 GB RAM)

1. Go to [digitalocean.com](https://www.digitalocean.com)
2. Create a Droplet:
   - Image: **Ubuntu 24.04**
   - Plan: **Basic $6/mo**
   - Region: Choose closest to your users
3. Click **Create Droplet**

**Connect and install Docker:**
```bash
ssh root@YOUR_DROPLET_IP

curl -fsSL https://get.docker.com | sh

git clone https://github.com/codika-io/codika-baileys-connector.git
cd codika-baileys-connector
chmod +x setup.sh
./setup.sh
```

## Optional: Set Up a Domain with SSL

If you have a domain, you can add a reverse proxy with automatic HTTPS using Caddy:

```bash
# Install Caddy
apt install -y caddy

# Create Caddy config
cat > /etc/caddy/Caddyfile << 'EOF'
connector.yourdomain.com {
    reverse_proxy localhost:8080
}
EOF

# Restart Caddy (auto-obtains SSL certificate)
systemctl restart caddy
```

Then update your `.env`:
```
EVOLUTION_SERVER_URL=https://connector.yourdomain.com
```

## Firewall Configuration

If your VPS has a firewall enabled, open the required port:

```bash
# UFW (Ubuntu default)
ufw allow 8080/tcp    # Evolution API (or 80/443 if using Caddy)
ufw allow 22/tcp      # SSH
ufw enable

# Or on Hetzner, configure the firewall in the Cloud Console
```

## Keeping it Running

The Docker services are configured with `restart: unless-stopped`, so they automatically restart after crashes or server reboots. To also start Docker on boot:

```bash
systemctl enable docker
```
