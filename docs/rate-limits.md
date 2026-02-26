# Rate Limits & Best Practices

This connector uses an unofficial WhatsApp API. To minimize the risk of your number being restricted or banned, follow these guidelines.

## Recommended Limits

| Metric | Safe Limit | Notes |
|--------|-----------|-------|
| Messages per minute | 8 | Add random delays between messages |
| Messages per hour | 200 | Across all chats |
| Messages per day | 1,500 | Total outbound messages |
| New contacts per day | 20 | People who haven't messaged you first |

## What Triggers Bans

**High risk:**
- Sending bulk identical messages to many contacts
- Messaging large numbers of unsaved/unknown contacts
- Using VoIP or virtual phone numbers
- Sending messages immediately after setup (no warm-up)
- Very high message volume on a new number

**Medium risk:**
- Rapid automated responses (no human-like delays)
- Sending messages at unusual hours
- Large media files in high volume

**Low risk:**
- Responding to messages from people who contacted you first
- Group conversations with organic activity
- Varied, natural-looking message content

## Warm-Up Procedure for New Numbers

When setting up a new phone number for the bot:

1. **Day 1-3:** Use the number manually. Send messages to friends, join a few groups, respond to messages normally.
2. **Day 4-7:** Start automated responses but keep volume low (under 50 messages/day). Only respond to incoming messages.
3. **Week 2:** Gradually increase to normal bot volume.
4. **Week 3+:** Full operation, staying within the recommended limits above.

## Best Practices for Groups

- Only respond when @mentioned (this connector is configured this way by default)
- Keep responses concise (under 1,500 characters when possible)
- Add a small random delay (1-3 seconds) before responding to feel natural
- Don't send more than 2-3 messages in rapid succession in the same group

## If You Get Restricted

1. Stop all automated messaging immediately
2. Wait 24-48 hours
3. Check if restrictions are lifted by sending a manual message from the phone
4. If banned, you'll need a new phone number
5. Follow the warm-up procedure with the new number

## Dedicated Number

Always use a **dedicated phone number** for the bot -- never your personal number. Options:
- A second SIM card
- A prepaid SIM card
- An eSIM
