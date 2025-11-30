# Deployment Guide

This guide covers deploying the Azure Communication Services Phone System to Azure App Service and Azure Static Web Apps.

## Deployment Options

1. **Automated Scripts** - Bash scripts for quick deployment
2. **GitHub Actions** - CI/CD pipeline for automated deployments
3. **Manual Deployment** - Step-by-step Azure Portal deployment

## Prerequisites

- Completed [Azure Setup](./AZURE_SETUP.md)
- Azure CLI installed and logged in
- Resource group created
- Azure Communication Services resource created
- Phone number acquired

## Option 1: Automated Deployment (Recommended)

### Step 1: Deploy Backend

```bash
# Set environment variables (optional, script will use defaults)
export AZURE_RESOURCE_GROUP="acs-phone-system-rg"
export AZURE_LOCATION="eastus"
export AZURE_APP_NAME="acs-phone-backend-unique-name"

# Run deployment script
./deployment/deploy-backend.sh
```

The script will:
1. Create an App Service Plan (Linux, B1 tier)
2. Create a Web App with Node.js 18 runtime
3. Build the backend application
4. Deploy to Azure App Service
5. Configure application settings
6. Enable logging

**Save the backend URL** displayed at the end (e.g., `https://acs-phone-backend-123.azurewebsites.net`)

### Step 2: Configure Backend Environment Variables

Go to Azure Portal:
1. Navigate to your App Service
2. Go to "Configuration" → "Application settings"
3. Add/Update the following:

```
ACS_CONNECTION_STRING = endpoint=https://...;accesskey=...
ACS_PHONE_NUMBER = +1234567890
CALLBACK_URI = https://your-backend.azurewebsites.net/api/callbacks
FRONTEND_URL = https://your-frontend-url (update after frontend deployment)
NODE_ENV = production
PORT = 8080
```

4. Click "Save" → "Continue"

### Step 3: Deploy Frontend

```bash
# Set environment variables
export AZURE_RESOURCE_GROUP="acs-phone-system-rg"
export AZURE_STATIC_WEB_APP_NAME="acs-phone-frontend-unique-name"

# Run deployment script
./deployment/deploy-frontend.sh
```

**Note**: Static Web Apps deployment via script requires the `@azure/static-web-apps-cli` package. Alternatively, use GitHub Actions (Option 2) for frontend deployment.

### Step 4: Update CORS Configuration

Update backend's `FRONTEND_URL` environment variable:

```bash
az webapp config appsettings set \
    --name "your-backend-app-name" \
    --resource-group "acs-phone-system-rg" \
    --settings FRONTEND_URL="https://your-frontend-url.azurestaticapps.net"
```

## Option 2: GitHub Actions CI/CD

### Step 1: Set Up GitHub Secrets

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Add the following secrets:

#### Azure Credentials

Create a service principal:

```bash
az ad sp create-for-rbac \
    --name "acs-phone-system-sp" \
    --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/acs-phone-system-rg \
    --sdk-auth
```

Copy the entire JSON output and add as secret: `AZURE_CREDENTIALS`

#### Other Secrets

Add these secrets:
- `ACS_CONNECTION_STRING`: Your ACS connection string
- `ACS_PHONE_NUMBER`: Your acquired phone number (+1234567890)
- `FRONTEND_URL`: Your frontend URL (update after deployment)
- `AZURE_STATIC_WEB_APPS_API_TOKEN`: (See step 2)

### Step 2: Create Static Web App for Token

```bash
az staticwebapp create \
    --name "acs-phone-frontend" \
    --resource-group "acs-phone-system-rg" \
    --location "eastus"

# Get deployment token
az staticwebapp secrets list \
    --name "acs-phone-frontend" \
    --resource-group "acs-phone-system-rg" \
    --query "properties.apiKey" \
    --output tsv
```

Add the token as secret: `AZURE_STATIC_WEB_APPS_API_TOKEN`

### Step 3: Update Workflow Configuration

Edit `.github/workflows/deploy.yml`:

```yaml
env:
  NODE_VERSION: '18.x'
  AZURE_BACKEND_APP_NAME: 'your-backend-app-name'  # Change this
  AZURE_RESOURCE_GROUP: 'acs-phone-system-rg'      # Change this
```

### Step 4: Deploy

```bash
# Commit and push to main branch
git add .
git commit -m "Configure deployment"
git push origin main
```

GitHub Actions will automatically:
1. Build the backend
2. Deploy to Azure App Service
3. Build the frontend
4. Deploy to Azure Static Web Apps

Monitor the deployment in the "Actions" tab of your GitHub repository.

## Option 3: Manual Deployment

### Backend Deployment

#### Step 1: Create App Service Plan

```bash
az appservice plan create \
    --name "acs-backend-plan" \
    --resource-group "acs-phone-system-rg" \
    --location "eastus" \
    --is-linux \
    --sku B1
```

#### Step 2: Create Web App

```bash
az webapp create \
    --name "acs-phone-backend-unique" \
    --resource-group "acs-phone-system-rg" \
    --plan "acs-backend-plan" \
    --runtime "NODE:18-lts"
```

#### Step 3: Build Backend

```bash
cd backend
npm install
npm run build
```

#### Step 4: Deploy via ZIP

```bash
# Create deployment package
cd dist
zip -r ../deploy.zip .
cd ..
zip -r deploy.zip package.json package-lock.json

# Deploy
az webapp deploy \
    --name "acs-phone-backend-unique" \
    --resource-group "acs-phone-system-rg" \
    --src-path deploy.zip \
    --type zip
```

#### Step 5: Configure App Settings

See "Configure Backend Environment Variables" in Option 1.

### Frontend Deployment

#### Option A: Azure Static Web Apps

1. Go to Azure Portal
2. Create a resource → "Static Web App"
3. Configure:
   - **Resource Group**: acs-phone-system-rg
   - **Name**: acs-phone-frontend
   - **Plan type**: Free
   - **Deployment source**: Other (manual)
4. Create the resource
5. Build and deploy:

```bash
cd frontend
npm install
VITE_API_URL=https://your-backend.azurewebsites.net/api npm run build

# Install SWA CLI
npm install -g @azure/static-web-apps-cli

# Get deployment token from Portal: Settings → Deployment token
swa deploy ./dist --deployment-token "your-token"
```

#### Option B: Azure App Service (Alternative)

```bash
# Create app service for frontend
az webapp create \
    --name "acs-phone-frontend-unique" \
    --resource-group "acs-phone-system-rg" \
    --plan "acs-backend-plan" \
    --runtime "NODE:18-lts"

# Build frontend
cd frontend
npm install
VITE_API_URL=https://your-backend.azurewebsites.net/api npm run build

# Deploy
cd dist
zip -r ../frontend-deploy.zip .
cd ..

az webapp deploy \
    --name "acs-phone-frontend-unique" \
    --resource-group "acs-phone-system-rg" \
    --src-path frontend-deploy.zip \
    --type zip
```

## Post-Deployment Verification

### Test Backend

```bash
# Health check
curl https://your-backend.azurewebsites.net/health

# Should return: {"status":"healthy",...}
```

### Test Frontend

1. Open: `https://your-frontend-url`
2. Enter a phone number
3. Click "Call"
4. Verify call is initiated

### Check Logs

#### Backend Logs:

```bash
# Stream logs
az webapp log tail \
    --name "your-backend-app-name" \
    --resource-group "acs-phone-system-rg"

# Or via Portal: App Service → Log stream
```

#### Application Insights (Optional):

For production monitoring, enable Application Insights:

```bash
az monitor app-insights component create \
    --app "acs-phone-insights" \
    --location "eastus" \
    --resource-group "acs-phone-system-rg"

# Connect to Web App
az webapp config appsettings set \
    --name "your-backend-app-name" \
    --resource-group "acs-phone-system-rg" \
    --settings APPINSIGHTS_INSTRUMENTATIONKEY="your-key"
```

## Scaling and Performance

### App Service Scaling

#### Vertical Scaling (Change SKU):

```bash
az appservice plan update \
    --name "acs-backend-plan" \
    --resource-group "acs-phone-system-rg" \
    --sku S1  # Standard tier
```

#### Horizontal Scaling (Add Instances):

```bash
az appservice plan update \
    --name "acs-backend-plan" \
    --resource-group "acs-phone-system-rg" \
    --number-of-workers 3
```

### Auto-scaling (Production)

Enable auto-scaling based on:
- CPU percentage
- Memory percentage
- HTTP queue length
- Custom metrics

Configure via Azure Portal: App Service Plan → Scale out

## Custom Domain and SSL

### Backend:

```bash
# Add custom domain
az webapp config hostname add \
    --webapp-name "your-backend-app-name" \
    --resource-group "acs-phone-system-rg" \
    --hostname "api.yourdomain.com"

# Enable HTTPS (free SSL certificate)
az webapp config ssl bind \
    --name "your-backend-app-name" \
    --resource-group "acs-phone-system-rg" \
    --certificate-thumbprint auto \
    --ssl-type SNI
```

### Frontend (Static Web Apps):

Custom domains are configured via Azure Portal:
1. Go to Static Web App
2. Custom domains → Add
3. Follow DNS configuration steps

## Troubleshooting

### Deployment Fails

**Check**:
- Azure CLI is logged in: `az account show`
- Resource group exists
- App names are unique globally
- Sufficient Azure credits/subscription limits

### Backend Returns 500 Error

**Check**:
- Environment variables are set correctly
- Connection string is valid
- Phone number is acquired
- Check application logs

### CORS Errors

**Check**:
- `FRONTEND_URL` is set to actual frontend URL
- No trailing slashes in URLs
- HTTPS is used in production

### Webhooks Not Working

**Check**:
- `CALLBACK_URI` matches deployed backend URL
- Endpoint is publicly accessible
- No firewall blocking Azure IP ranges

## Cleanup

To delete all resources:

```bash
# Delete entire resource group (WARNING: This deletes everything!)
az group delete \
    --name "acs-phone-system-rg" \
    --yes \
    --no-wait
```

## Next Steps

- [API Documentation](./API.md) - Backend API reference
- [Monitoring Guide](./MONITORING.md) - Set up monitoring and alerts
- [Security Guide](./SECURITY.md) - Production security best practices
