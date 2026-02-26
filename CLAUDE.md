# Codika Baileys Connector

Self-hosted WhatsApp group connector using Evolution API (Baileys engine). This is a **GitHub template repository** that clients clone and deploy on their own VPS.

## What This Is

A pre-configured Docker setup for Evolution API that:
- Connects to WhatsApp via the Baileys (WebSocket) protocol
- Forwards incoming messages to a Codika webhook URL
- Exposes a REST API for sending messages back
- Runs on any VPS with Docker (~$5-8/month)

## Architecture

```
Client's VPS                           Codika Infrastructure
┌─────────────────────┐               ┌─────────────────────┐
│ Evolution API       │──webhook──>   │ n8n bot workflows   │
│ (Baileys + REST)    │<──REST────    │ (handler logic)     │
└─────────────────────┘               └─────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Evolution API + PostgreSQL + Redis |
| `.env.example` | Configuration template |
| `setup.sh` | Interactive setup script |
| `docs/hosting-guide.md` | VPS setup instructions |
| `docs/troubleshooting.md` | Common issues |
| `docs/rate-limits.md` | Anti-ban best practices |

## Conventions

- Keep the docker-compose minimal -- no extra integrations
- All webhook events are disabled except messages, groups, connection, and errors
- Default engine is Baileys (not WhatsApp Cloud API)
- The setup.sh must remain interactive and beginner-friendly
- Never commit actual `.env` files (secrets)

## Related Repositories

- `satellites/wat-community-dashboard` -- The bot's dashboard and n8n workflows
- `platform/codika-processes-lib` -- Process definitions including wat-bot handlers
