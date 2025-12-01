# Azure Communication Services - Phone System with DTMF Support

A complete pay-as-you-go telephone system built with Azure Communication Services, featuring outbound calling, DTMF tone support, and a modern web-based dialer interface.

## Features

✅ **Outbound PSTN Calling** - Make calls to any phone number worldwide
✅ **DTMF Support** - Send touch-tone signals during active calls
✅ **Premium Rate Calling** - Support for premium rate numbers (requires Azure approval)
✅ **Web Dialer Interface** - Modern React-based dialer with touch-tone pad
✅ **Real-time Call Control** - Initiate, manage, and terminate calls
✅ **Event Webhooks** - Receive real-time call status updates
✅ **TypeScript** - Full type safety across frontend and backend
✅ **Azure Native** - Fully integrated with Azure services

## Architecture

```
┌─────────────────────────────────────┐
│  React Frontend                      │
│  - Phone dialer interface           │
│  - DTMF pad                          │
│  - Call controls                     │
│  (Azure Static Web Apps)             │
└──────────────┬──────────────────────┘
               │ HTTPS/REST
┌──────────────▼──────────────────────┐
│  Node.js/Express Backend             │
│  - Call management API               │
│  - DTMF control                      │
│  - Webhook handling                  │
│  (Azure App Service)                 │
└──────────────┬──────────────────────┘
               │ SDK
┌──────────────▼──────────────────────┐
│  Azure Communication Services        │
│  - PSTN Calling                      │
│  - Call Automation API               │
└──────────────────────────────────────┘
```

## Tech Stack

**Backend:**
- Node.js 18+ with TypeScript
- Express.js
- Azure Communication Services SDK (`@azure/communication-call-automation`)
- CORS, Helmet for security

**Frontend:**
- React 18 with TypeScript
- Vite for build tooling
- Axios for API calls
- Modern CSS with responsive design

**Deployment:**
- Azure App Service (Backend)
- Azure Static Web Apps (Frontend)
- GitHub Actions for CI/CD

## Quick Start

### Prerequisites

- Azure subscription ([create free account](https://azure.microsoft.com/free/))
- Node.js 18+
- Azure CLI
- Git

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/AzureCallingPAYG.git
cd AzureCallingPAYG
```

### 2. Set Up Azure Resources

```bash
# Login to Azure
az login

# Run automated setup script
./deployment/setup-azure-resources.sh

# This creates:
# - Resource group
# - Azure Communication Services resource
# - Retrieves connection string
```

**Important:** After running the script:
1. Note the connection string
2. Acquire a phone number via Azure Portal (see [Azure Setup Guide](./docs/AZURE_SETUP.md))

### 3. Configure Environment

```bash
# Backend configuration
cp backend/.env.example backend/.env
```

Edit `backend/.env`:
```env
ACS_CONNECTION_STRING=endpoint=https://...;accesskey=...
ACS_PHONE_NUMBER=+1234567890
CALLBACK_URI=https://your-ngrok-url.ngrok.io/api/callbacks  # For local dev
FRONTEND_URL=http://localhost:5173
```

### 4. Run Locally

**Terminal 1 - Start ngrok (for webhook callbacks):**
```bash
ngrok http 3000
# Copy the HTTPS URL and update CALLBACK_URI in .env
```

**Terminal 2 - Start backend:**
```bash
cd backend
npm install
npm run dev
```

**Terminal 3 - Start frontend:**
```bash
cd frontend
npm install
npm run dev
```

Open browser to: **http://localhost:5173**

### 5. Make Your First Call

1. Enter a phone number in E.164 format: `+12125551234`
2. Click "📞 Call"
3. When connected, use the DTMF pad to send tones

## Deployment to Azure

### Option 1: Automated Scripts

```bash
# Deploy backend
./deployment/deploy-backend.sh

# Deploy frontend
./deployment/deploy-frontend.sh
```

### Option 2: GitHub Actions

1. Configure GitHub secrets (see [Deployment Guide](./docs/DEPLOYMENT.md))
2. Push to main branch
3. GitHub Actions automatically deploys

### Option 3: Manual Deployment

See [Deployment Guide](./docs/DEPLOYMENT.md) for detailed instructions.

## Documentation

- **[Azure Setup Guide](./docs/AZURE_SETUP.md)** - Complete Azure resource setup from scratch
- **[Deployment Guide](./docs/DEPLOYMENT.md)** - Deployment instructions for Azure
- **[API Documentation](./docs/API.md)** - Backend API reference

## Project Structure

```
AzureCallingPAYG/
├── backend/                    # Node.js/Express backend
│   ├── src/
│   │   ├── config/            # Configuration management
│   │   ├── controllers/       # Request handlers
│   │   ├── routes/            # API routes
│   │   ├── services/          # Business logic (ACS integration)
│   │   ├── types/             # TypeScript types
│   │   └── index.ts           # Application entry point
│   ├── package.json
│   └── tsconfig.json
├── frontend/                   # React frontend
│   ├── src/
│   │   ├── components/        # React components
│   │   │   ├── Dialer.tsx    # Main dialer interface
│   │   │   └── DtmfPad.tsx   # DTMF keypad
│   │   ├── services/          # API client
│   │   ├── styles/            # CSS stylesheets
│   │   ├── types/             # TypeScript types
│   │   └── App.tsx            # Application root
│   ├── package.json
│   └── vite.config.ts
├── deployment/                 # Deployment scripts
│   ├── setup-azure-resources.sh
│   ├── deploy-backend.sh
│   └── deploy-frontend.sh
├── docs/                       # Documentation
└── .github/workflows/          # CI/CD workflows
```

## API Endpoints

### Call Management

```http
POST   /api/calls                          # Initiate a call
POST   /api/calls/:id/dtmf                 # Send DTMF tones
DELETE /api/calls/:id                      # Hang up call
GET    /api/calls/:id/status               # Get call status
```

### Webhooks

```http
POST   /api/callbacks/events               # Azure event callbacks
```

See [API Documentation](./docs/API.md) for detailed reference.

## Premium Rate Calling

Azure Communication Services **blocks premium rate calls by default**. To enable:

1. Contact Azure Support via Azure Portal
2. Request premium rate calling access
3. Provide legitimate use case justification
4. Wait for approval (1-3 business days)

See [Azure Setup Guide](./docs/AZURE_SETUP.md#premium-rate-calling-configuration) for details.

## Cost Estimation

**Azure Communication Services:**
- Phone number: ~$1-2/month
- Outbound calls (standard): $0.01-0.02/minute
- Outbound calls (premium rate): $0.10-2.00/minute

**Azure App Service (B1 tier):**
- ~$13/month

**Azure Static Web Apps:**
- Free tier available

**Total Estimated Cost:** ~$15-20/month + per-minute calling costs

[Use Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for precise estimates.

## Security Considerations

⚠️ **This is a development template** - Implement these for production:

- [ ] Authentication/Authorization (Azure AD, OAuth 2.0)
- [ ] API rate limiting
- [ ] Input validation and sanitization
- [ ] Secrets management (Azure Key Vault)
- [ ] Call duration limits
- [ ] Usage monitoring and alerts
- [ ] IP whitelisting
- [ ] DDoS protection

## Troubleshooting

### "Failed to make call"
- Verify ACS connection string is correct
- Ensure phone number is acquired and active
- Check phone number format (must be E.164: +1234567890)
- Verify ngrok is running for local development

### "Webhooks not received"
- Check CALLBACK_URI matches your deployed/ngrok URL
- Ensure backend is publicly accessible
- Verify no firewall blocking Azure IPs

### "Premium rate calls blocked"
- Contact Azure Support to enable premium rate destinations
- Or test with standard geographic numbers

See [Azure Setup Guide](./docs/AZURE_SETUP.md#troubleshooting) for more solutions.

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/AzureCallingPAYG/issues)
- **Azure Docs:** [Azure Communication Services Documentation](https://docs.microsoft.com/azure/communication-services/)
- **Azure Support:** [Azure Portal Support](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)

## Acknowledgments

- Built with [Azure Communication Services](https://azure.microsoft.com/services/communication-services/)
- Frontend powered by [React](https://react.dev/) and [Vite](https://vitejs.dev/)
- Backend powered by [Express](https://expressjs.com/)

---

**Ready to make calls?** Follow the [Quick Start](#quick-start) guide above!