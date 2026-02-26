# Troubleshooting

## Common Issues

### Services won't start

```bash
# Check status of all services
docker compose ps

# View logs
docker compose logs

# If a service is restarting, check its specific logs
docker compose logs evolution-api
docker compose logs postgres
docker compose logs redis
```

**Common causes:**
- `.env` file missing or has invalid values
- Port 8080 already in use (change `EVOLUTION_API_PORT` in `.env`)
- Not enough disk space (`df -h` to check)
- Not enough memory (`free -m` to check, needs at least 512 MB free)

### QR code expired or won't scan

The QR code refreshes every ~20 seconds and has 30 attempts by default.

```bash
# Re-request the QR code
curl YOUR_SERVER_URL/instance/connect/bot \
  -H 'apikey: YOUR_API_KEY'
```

If it still fails:
```bash
# Delete and recreate the instance
curl -X DELETE YOUR_SERVER_URL/instance/delete/bot \
  -H 'apikey: YOUR_API_KEY'

curl -X POST YOUR_SERVER_URL/instance/create \
  -H 'apikey: YOUR_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"instanceName": "bot", "integration": "WHATSAPP-BAILEYS"}'

curl YOUR_SERVER_URL/instance/connect/bot \
  -H 'apikey: YOUR_API_KEY'
```

### Connection drops after ~24 hours

This is a known issue with the Baileys engine. Evolution API handles reconnection automatically, but if the connection doesn't recover:

```bash
# Check connection state
curl YOUR_SERVER_URL/instance/connectionState/bot \
  -H 'apikey: YOUR_API_KEY'

# If state is "close", restart the instance
curl -X PUT YOUR_SERVER_URL/instance/restart/bot \
  -H 'apikey: YOUR_API_KEY'
```

### Messages not being forwarded to the webhook

1. Check that `WEBHOOK_ENABLED=true` in your `.env`
2. Check that `WEBHOOK_URL` is correct and reachable from your server:
   ```bash
   curl -I YOUR_WEBHOOK_URL
   ```
3. Check Evolution API logs for webhook errors:
   ```bash
   docker compose logs evolution-api | grep -i webhook
   ```

### Phone shows "Linked device disconnected"

This can happen if:
- The server was offline for more than 14 days
- The phone's WhatsApp was reinstalled
- WhatsApp revoked the session

**Fix:** Re-scan the QR code (see steps above).

### "Instance already exists" error

```bash
# List all instances
curl YOUR_SERVER_URL/instance/fetchInstances \
  -H 'apikey: YOUR_API_KEY'

# Delete the existing one if needed
curl -X DELETE YOUR_SERVER_URL/instance/delete/bot \
  -H 'apikey: YOUR_API_KEY'
```

### WhatsApp account banned

If your number gets restricted or banned:
- This is a risk of using unofficial APIs
- Use a new dedicated phone number
- Follow the rate limiting guidelines in [rate-limits.md](rate-limits.md)
- Wait 24-48 hours before setting up the new number

## Health Check Endpoint

You can monitor the API health:

```bash
# Simple health check
curl http://localhost:8080

# Check specific instance
curl YOUR_SERVER_URL/instance/connectionState/bot \
  -H 'apikey: YOUR_API_KEY'
```

## Updating

```bash
cd codika-baileys-connector

# Check current version
docker compose images

# Update to a new version: edit EVOLUTION_API_VERSION in .env, then:
docker compose pull
docker compose up -d

# Verify after update
docker compose ps
curl http://localhost:8080
```

## Complete Reset

If all else fails, you can start fresh (this will require re-scanning the QR code):

```bash
docker compose down -v   # Stops services AND removes all data volumes
docker compose up -d     # Fresh start
# Then create a new instance and scan QR code again
```
