# Azure Communication Services - Complete Setup Guide

This guide walks you through setting up Azure Communication Services from scratch with an empty Azure subscription.

## Prerequisites

- Azure subscription (free tier works for testing)
- Azure CLI installed: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
- Node.js 18+ installed
- Git installed

## Step 1: Azure CLI Login

```bash
# Login to Azure
az login

# Verify your subscription
az account show

# (Optional) Set a specific subscription if you have multiple
az account set --subscription "Your Subscription Name or ID"
```

## Step 2: Create Azure Communication Services Resource

You can use the automated script or follow manual steps:

### Option A: Automated Setup (Recommended)

```bash
# Run the setup script
./deployment/setup-azure-resources.sh

# The script will:
# 1. Create a resource group
# 2. Create an Azure Communication Services resource
# 3. Retrieve the connection string
# 4. Display next steps
```

### Option B: Manual Setup via Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Click "Create a resource"
3. Search for "Communication Services"
4. Click "Create"
5. Fill in the details:
   - **Subscription**: Your subscription
   - **Resource Group**: Create new (e.g., `acs-phone-system-rg`)
   - **Resource Name**: Unique name (e.g., `acs-calling-resource-123`)
   - **Data Location**: United States (or your preferred region)
6. Click "Review + Create" → "Create"

## Step 3: Get Connection String

### Via Azure CLI:

```bash
# List keys for your ACS resource
az communication list-key \
    --name "your-acs-resource-name" \
    --resource-group "acs-phone-system-rg"

# Copy the primaryConnectionString value
```

### Via Azure Portal:

1. Navigate to your Communication Services resource
2. Go to "Keys" under Settings
3. Copy the "Primary key" → "Connection string"

## Step 4: Acquire a Phone Number

### Important Notes:
- Phone numbers are required for making outbound calls
- You'll be charged for the phone number (typically $1-2/month)
- Premium rate calling may require additional verification

### Via Azure Portal:

1. Navigate to your Communication Services resource
2. Click "Phone numbers" in the left menu
3. Click "Get" to acquire a new number
4. Select:
   - **Country/Region**: Your country
   - **Use case**: "Make calls" (outbound calling)
   - **Number type**: Toll-free or Geographic
   - **Calling capabilities**: Check "Outbound calling"
5. Search for available numbers
6. Select a number and complete purchase
7. **Save the phone number** (format: +1234567890)

## Step 5: Premium Rate Calling Configuration

### Understanding Premium Rate Calling

Premium rate numbers are typically:
- Numbers starting with specific prefixes (e.g., 1-900 in US)
- International premium rate services
- Often used for adult services, competitions, or paid information lines

### Azure Default Policy

- **Azure blocks premium rate calls by default** for fraud prevention
- You must explicitly request access

### Enabling Premium Rate Calls

1. **Contact Azure Support**:
   - Go to Azure Portal → Support → New Support Request
   - Issue type: Technical
   - Service: Communication Services
   - Problem type: Calling
   - Subject: "Request to enable premium rate calling"

2. **Provide Required Information**:
   ```
   Subject: Enable Premium Rate Number Calling

   Resource Details:
   - Subscription ID: [Your subscription ID]
   - Resource Group: [Your resource group name]
   - ACS Resource Name: [Your ACS resource name]

   Request:
   I am requesting access to make outbound calls to premium rate numbers.

   Use Case:
   [Describe your legitimate use case, e.g.,]
   - Testing calling features for development
   - Legitimate business requirement to call premium rate services
   - Integration with third-party premium rate IVR systems

   Countries/Number Prefixes:
   [List the countries or specific prefixes you need access to]

   Verification:
   I acknowledge that premium rate calls will incur higher per-minute charges
   and I will implement appropriate security measures to prevent fraud.
   ```

3. **Wait for Approval**:
   - Typically takes 1-3 business days
   - Azure will verify your use case
   - You may need to provide additional documentation

### Alternative: Testing Without Premium Rate

For development/testing, you can:
- Use standard geographic numbers
- Use toll-free numbers
- Test with your own mobile numbers

## Step 6: Configure Environment Variables

Create `backend/.env` file:

```bash
# Copy the example file
cp backend/.env.example backend/.env
```

Edit `backend/.env`:

```env
# Azure Communication Services
ACS_CONNECTION_STRING=endpoint=https://your-resource.communication.azure.com/;accesskey=your-key
ACS_PHONE_NUMBER=+1234567890

# Server Configuration
PORT=3000
NODE_ENV=development

# Webhook Configuration (use ngrok for local development)
CALLBACK_URI=https://your-ngrok-url.ngrok.io/api/callbacks

# CORS Configuration
FRONTEND_URL=http://localhost:5173
```

## Step 7: Local Development with Webhooks

Azure Communication Services sends event callbacks to your backend. For local development:

### Install ngrok:

```bash
# macOS
brew install ngrok

# Windows
choco install ngrok

# Or download from https://ngrok.com/download
```

### Start ngrok tunnel:

```bash
# Terminal 1: Start ngrok
ngrok http 3000

# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
# Update CALLBACK_URI in backend/.env
```

### Start the backend:

```bash
# Terminal 2: Start backend
cd backend
npm install
npm run dev
```

### Start the frontend:

```bash
# Terminal 3: Start frontend
cd frontend
npm install
npm run dev
```

## Step 8: Verify Setup

### Test the Backend:

```bash
# Health check
curl http://localhost:3000/health

# Should return:
# {"status":"healthy","timestamp":"...","environment":"development"}
```

### Test the Frontend:

Open browser to: http://localhost:5173

You should see the phone dialer interface.

## Step 9: Make Your First Call

1. Enter a phone number in E.164 format: `+1234567890`
2. Click "Call"
3. The backend will initiate the call via Azure Communication Services
4. When connected, you can use the DTMF pad to send tones

## Troubleshooting

### "Failed to make call" Error

**Check**:
- Connection string is correct
- Phone number is acquired and active
- Phone number format is E.164 (+1234567890)
- ngrok tunnel is running (for local development)
- CALLBACK_URI is set correctly

### "Premium rate calls blocked" Error

**Solution**:
- Contact Azure Support to enable premium rate calling
- Or test with standard geographic numbers

### Webhooks Not Received

**Check**:
- ngrok is running and CALLBACK_URI is updated
- Backend is running on port 3000
- Check ngrok web interface: http://127.0.0.1:4040

### "Invalid phone number" Error

**Check**:
- Number must start with `+` (E.164 format)
- Include country code
- No spaces or special characters
- Example: `+12125551234`

## Cost Considerations

### Azure Communication Services Pricing:

- **Phone Number**: ~$1-2/month
- **Outbound Calls**: $0.01-0.02/minute (standard)
- **Premium Rate Calls**: $0.10-2.00/minute (varies by destination)
- **Data Transfer**: Minimal costs

### Cost Management:

- Set up Azure Cost Alerts
- Monitor usage in Azure Portal
- Implement call duration limits in your app
- Use authentication to prevent unauthorized use

## Security Best Practices

1. **Never commit `.env` files** to version control
2. **Rotate connection strings** periodically
3. **Implement authentication** on your frontend/backend
4. **Set up rate limiting** to prevent abuse
5. **Monitor call logs** for suspicious activity
6. **Use managed identities** in production (instead of connection strings)

## Next Steps

- [Deployment Guide](./DEPLOYMENT.md) - Deploy to Azure
- [API Documentation](./API.md) - Backend API reference
- [Architecture Guide](./ARCHITECTURE.md) - System architecture

## Resources

- [Azure Communication Services Documentation](https://docs.microsoft.com/azure/communication-services/)
- [Call Automation Quickstart](https://docs.microsoft.com/azure/communication-services/quickstarts/call-automation/)
- [DTMF Documentation](https://docs.microsoft.com/azure/communication-services/concepts/call-automation/recognize-action)
- [Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
