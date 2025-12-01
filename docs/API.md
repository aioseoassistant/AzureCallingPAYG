# API Documentation

Backend API reference for the Azure Communication Services Phone System.

## Base URL

- **Local Development**: `http://localhost:3000/api`
- **Production**: `https://your-backend.azurewebsites.net/api`

## Authentication

Currently, no authentication is implemented. For production use, implement one of:
- Azure AD authentication
- API keys
- JWT tokens
- OAuth 2.0

## Endpoints

### Health Check

Check if the service is running.

```http
GET /health
```

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "environment": "production"
}
```

---

### Initiate Call

Make an outbound PSTN call.

```http
POST /api/calls
```

**Request Body**:
```json
{
  "targetPhoneNumber": "+12125551234",
  "sourceCallerId": "+19995551234"  // Optional, defaults to ACS_PHONE_NUMBER
}
```

**Parameters**:
- `targetPhoneNumber` (required): Phone number to call in E.164 format (+country code + number)
- `sourceCallerId` (optional): Caller ID to display. Must be a phone number you own via ACS.

**Success Response** (200 OK):
```json
{
  "callConnectionId": "abc123-def456-ghi789",
  "status": "success",
  "message": "Call initiated successfully"
}
```

**Error Response** (400 Bad Request):
```json
{
  "error": "Invalid phone number. Must include country code (e.g., +1234567890)"
}
```

**Error Response** (500 Internal Server Error):
```json
{
  "error": "Failed to initiate call",
  "message": "Detailed error message"
}
```

**Example**:
```bash
curl -X POST http://localhost:3000/api/calls \
  -H "Content-Type: application/json" \
  -d '{
    "targetPhoneNumber": "+12125551234"
  }'
```

---

### Send DTMF Tones

Send DTMF tones during an active call.

```http
POST /api/calls/:callConnectionId/dtmf
```

**URL Parameters**:
- `callConnectionId`: The call connection ID returned from the initiate call endpoint

**Request Body**:
```json
{
  "tones": "1234*#"
}
```

**Parameters**:
- `tones` (required): String of DTMF tones to send. Valid characters: 0-9, *, #, A-D

**Success Response** (200 OK):
```json
{
  "callConnectionId": "abc123-def456-ghi789",
  "status": "success",
  "message": "DTMF tones sent successfully"
}
```

**Error Response** (400 Bad Request):
```json
{
  "error": "Invalid DTMF tones. Must be a string of digits, *, #, or A-D"
}
```

**Error Response** (500 Internal Server Error):
```json
{
  "error": "Failed to send DTMF tones",
  "message": "Call connection not found or call may have ended"
}
```

**Example**:
```bash
curl -X POST http://localhost:3000/api/calls/abc123-def456-ghi789/dtmf \
  -H "Content-Type: application/json" \
  -d '{
    "tones": "1234"
  }'
```

---

### Hang Up Call

Terminate an active call.

```http
DELETE /api/calls/:callConnectionId
```

**URL Parameters**:
- `callConnectionId`: The call connection ID

**Success Response** (200 OK):
```json
{
  "callConnectionId": "abc123-def456-ghi789",
  "status": "success",
  "message": "Call ended successfully"
}
```

**Error Response** (500 Internal Server Error):
```json
{
  "error": "Failed to hang up call",
  "message": "Call connection not found"
}
```

**Example**:
```bash
curl -X DELETE http://localhost:3000/api/calls/abc123-def456-ghi789
```

---

### Get Call Status

Get the current status of a call.

```http
GET /api/calls/:callConnectionId/status
```

**URL Parameters**:
- `callConnectionId`: The call connection ID

**Success Response** (200 OK):
```json
{
  "callConnectionId": "abc123-def456-ghi789",
  "callState": "connected"
}
```

**Possible Call States**:
- `connecting`: Call is being established
- `connected`: Call is active
- `disconnecting`: Call is ending
- `disconnected`: Call has ended
- `transferring`: Call is being transferred
- `unknown`: State cannot be determined

**Error Response** (500 Internal Server Error):
```json
{
  "error": "Failed to get call status",
  "message": "Detailed error message"
}
```

**Example**:
```bash
curl http://localhost:3000/api/calls/abc123-def456-ghi789/status
```

---

## Webhook Endpoints

These endpoints receive events from Azure Communication Services.

### Call Events

Receives call state change events.

```http
POST /api/callbacks/events
```

**This endpoint is called by Azure Communication Services**, not your application.

**Event Types**:

#### Call Connected
```json
{
  "type": "Microsoft.Communication.CallConnected",
  "data": {
    "callConnectionId": "abc123-def456-ghi789"
  }
}
```

#### Call Disconnected
```json
{
  "type": "Microsoft.Communication.CallDisconnected",
  "data": {
    "callConnectionId": "abc123-def456-ghi789"
  }
}
```

#### DTMF Recognition Completed
```json
{
  "type": "Microsoft.Communication.RecognizeCompleted",
  "data": {
    "callConnectionId": "abc123-def456-ghi789",
    "recognitionResult": {
      "dtmfTones": ["1", "2", "3", "4"]
    }
  }
}
```

**Response**: Always returns 200 OK to acknowledge receipt.

---

## Error Handling

All endpoints follow a consistent error response format:

```json
{
  "error": "Error category",
  "message": "Detailed error message"
}
```

**HTTP Status Codes**:
- `200 OK`: Request succeeded
- `400 Bad Request`: Invalid request parameters
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

---

## Rate Limiting

Currently, no rate limiting is implemented. For production, consider:
- Implementing rate limiting middleware (e.g., `express-rate-limit`)
- Azure API Management for enterprise rate limiting
- Application-level throttling

**Example Rate Limit Implementation**:
```javascript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

---

## CORS Configuration

The backend is configured to accept requests from:
- `FRONTEND_URL` environment variable
- Default: `http://localhost:5173` (development)

**Production**: Update `FRONTEND_URL` to your deployed frontend URL.

---

## WebSocket Support

Currently not implemented. For real-time call updates, consider:
- WebSockets (Socket.io)
- Server-Sent Events (SSE)
- Polling the status endpoint

---

## Phone Number Format

All phone numbers must be in **E.164 format**:

```
+[country code][area code][local number]
```

**Examples**:
- US: `+12125551234`
- UK: `+442071234567`
- Australia: `+61212345678`

**Invalid Formats**:
- `2125551234` (missing country code)
- `+1 (212) 555-1234` (contains spaces/parentheses)
- `+1-212-555-1234` (contains hyphens)

---

## DTMF Tone Reference

**Standard DTMF Tones**:
- `0-9`: Numeric keys
- `*`: Star/asterisk
- `#`: Pound/hash

**Extended DTMF (A-D)**:
- `A`, `B`, `C`, `D`: Special function keys (rarely used)

**Common Use Cases**:
- IVR navigation: Press 1 for sales, 2 for support
- Voicemail access: Enter PIN followed by #
- Conference calls: Enter meeting ID + #

---

## Code Examples

### JavaScript (Fetch API)

```javascript
// Make a call
async function makeCall(phoneNumber) {
  const response = await fetch('http://localhost:3000/api/calls', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      targetPhoneNumber: phoneNumber,
    }),
  });

  const data = await response.json();
  return data.callConnectionId;
}

// Send DTMF
async function sendDtmf(callConnectionId, tones) {
  await fetch(`http://localhost:3000/api/calls/${callConnectionId}/dtmf`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ tones }),
  });
}

// Hang up
async function hangUp(callConnectionId) {
  await fetch(`http://localhost:3000/api/calls/${callConnectionId}`, {
    method: 'DELETE',
  });
}
```

### Python

```python
import requests

# Make a call
def make_call(phone_number):
    response = requests.post(
        'http://localhost:3000/api/calls',
        json={'targetPhoneNumber': phone_number}
    )
    return response.json()['callConnectionId']

# Send DTMF
def send_dtmf(call_connection_id, tones):
    requests.post(
        f'http://localhost:3000/api/calls/{call_connection_id}/dtmf',
        json={'tones': tones}
    )

# Hang up
def hang_up(call_connection_id):
    requests.delete(
        f'http://localhost:3000/api/calls/{call_connection_id}'
    )
```

### cURL

```bash
# Make a call
CALL_ID=$(curl -s -X POST http://localhost:3000/api/calls \
  -H "Content-Type: application/json" \
  -d '{"targetPhoneNumber": "+12125551234"}' \
  | jq -r '.callConnectionId')

# Send DTMF
curl -X POST http://localhost:3000/api/calls/$CALL_ID/dtmf \
  -H "Content-Type: application/json" \
  -d '{"tones": "1234"}'

# Get status
curl http://localhost:3000/api/calls/$CALL_ID/status

# Hang up
curl -X DELETE http://localhost:3000/api/calls/$CALL_ID
```

---

## Testing

### Unit Tests (Future)

```bash
cd backend
npm test
```

### Integration Tests

Use Postman or similar tools:

1. Import the API collection
2. Set environment variables
3. Run tests

**Example Postman Collection**:
```json
{
  "info": {
    "name": "ACS Phone System API"
  },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "url": "{{baseUrl}}/health"
      }
    },
    {
      "name": "Make Call",
      "request": {
        "method": "POST",
        "url": "{{baseUrl}}/api/calls",
        "body": {
          "mode": "raw",
          "raw": "{\"targetPhoneNumber\": \"{{testPhoneNumber}}\"}"
        }
      }
    }
  ]
}
```

---

## Changelog

### v1.0.0 (2024-01-15)
- Initial API release
- Basic call control endpoints
- DTMF support
- Webhook event handling
