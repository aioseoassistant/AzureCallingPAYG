# GitHub Actions Deployment - Step-by-Step Guide

This guide walks you through setting up automated deployment using GitHub Actions.

## Overview

When complete, every push to the `main` branch will automatically:
1. Build your backend
2. Deploy to Azure App Service
3. Build your frontend
4. Deploy to Azure Static Web Apps

---

## Step 1: Verify Prerequisites

**On your local machine**, verify you have:

```bash
# Check Azure CLI
az --version

# If not installed, install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Check you're logged in
az login

# Verify your subscription
az account show
```

---

## Step 2: Create Azure Resources

### 2A: Create Resource Group

```bash
# Set variables (customize these)
RESOURCE_GROUP="acs-phone-system-rg"
LOCATION="eastus"

# Create resource group
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

echo "✅ Resource group created"
```

### 2B: Create Azure Communication Services Resource

```bash
# Set ACS resource name (must be unique)
ACS_RESOURCE_NAME="acs-calling-$(date +%s)"

# Create ACS resource
az communication create \
    --name $ACS_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --location "global" \
    --data-location "UnitedStates"

echo "✅ ACS resource created: $ACS_RESOURCE_NAME"

# Get connection string (SAVE THIS!)
ACS_CONNECTION_STRING=$(az communication list-key \
    --name $ACS_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "primaryConnectionString" \
    --output tsv)

echo ""
echo "🔑 ACS Connection String (save this securely):"
echo "$ACS_CONNECTION_STRING"
echo ""
```

**⚠️ IMPORTANT:** Copy the connection string - you'll need it for GitHub Secrets!

### 2C: Create App Service Plan and Web App (Backend)

```bash
# Set app names (must be globally unique)
APP_SERVICE_PLAN="acs-backend-plan"
BACKEND_APP_NAME="acs-phone-backend-$(date +%s)"

# Create App Service Plan (Linux, B1 tier)
az appservice plan create \
    --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku B1

echo "✅ App Service Plan created"

# Create Web App
az webapp create \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN \
    --runtime "NODE:18-lts"

echo "✅ Backend App created: $BACKEND_APP_NAME"
echo "Backend URL: https://${BACKEND_APP_NAME}.azurewebsites.net"

# Configure app settings
az webapp config appsettings set \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings \
        NODE_ENV=production \
        PORT=8080 \
        WEBSITES_PORT=8080

echo "✅ App settings configured"
```

### 2D: Create Static Web App (Frontend)

```bash
# Set Static Web App name (must be globally unique)
FRONTEND_APP_NAME="acs-phone-frontend-$(date +%s)"

# Create Static Web App
az staticwebapp create \
    --name $FRONTEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION

echo "✅ Static Web App created: $FRONTEND_APP_NAME"

# Get the deployment token (SAVE THIS!)
STATIC_WEB_APP_TOKEN=$(az staticwebapp secrets list \
    --name $FRONTEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "properties.apiKey" \
    --output tsv)

echo ""
echo "🔑 Static Web App Deployment Token (save this securely):"
echo "$STATIC_WEB_APP_TOKEN"
echo ""

# Get the frontend URL
FRONTEND_URL=$(az staticwebapp show \
    --name $FRONTEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "defaultHostname" \
    --output tsv)

echo "Frontend URL: https://$FRONTEND_URL"
```

### 2E: Summary of Created Resources

```bash
echo ""
echo "=========================================="
echo "Azure Resources Created"
echo "=========================================="
echo "Resource Group: $RESOURCE_GROUP"
echo "ACS Resource: $ACS_RESOURCE_NAME"
echo "Backend App: $BACKEND_APP_NAME"
echo "Frontend App: $FRONTEND_APP_NAME"
echo ""
echo "Backend URL: https://${BACKEND_APP_NAME}.azurewebsites.net"
echo "Frontend URL: https://$FRONTEND_URL"
echo "=========================================="
```

---

## Step 3: Acquire a Phone Number

**You must do this via Azure Portal:**

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your ACS resource (search for the name from Step 2B)
3. Click **Phone numbers** in the left menu
4. Click **Get** button
5. Select:
   - **Country/Region**: Your country (e.g., United States)
   - **Use case**: "Make calls" (outbound calling)
   - **Number type**: Toll-free or Geographic
   - **Calling capabilities**: Check "Outbound calling"
6. Search for available numbers
7. Select a number and complete purchase (~$1-2/month)
8. **Copy the phone number** in E.164 format (e.g., +12125551234)

**⚠️ SAVE THIS:** You'll need the phone number for GitHub Secrets!

---

## Step 4: Create Service Principal for GitHub Actions

This allows GitHub Actions to deploy to Azure:

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal
az ad sp create-for-rbac \
    --name "github-actions-acs-phone" \
    --role contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
    --sdk-auth

# This outputs JSON - COPY THE ENTIRE OUTPUT!
```

**Example output:**
```json
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "your-secret-here",
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

**⚠️ COPY THIS ENTIRE JSON OUTPUT** - you'll need it for GitHub Secrets!

---

## Step 5: Set Up GitHub Secrets

Now you'll add all the sensitive information to GitHub:

### 5A: Navigate to GitHub Secrets

1. Go to: https://github.com/aioseoassistant/AzureCallingPAYG
2. Click **Settings** (top menu)
3. Click **Secrets and variables** → **Actions** (left menu)
4. Click **New repository secret** button

### 5B: Add Each Secret

Add these secrets one by one (click "New repository secret" for each):

| Secret Name | Value | Where to Get It |
|-------------|-------|-----------------|
| `AZURE_CREDENTIALS` | Entire JSON from Step 4 | Copy entire JSON output |
| `ACS_CONNECTION_STRING` | Your ACS connection string | From Step 2B |
| `ACS_PHONE_NUMBER` | Your phone number | From Step 3 (e.g., +12125551234) |
| `FRONTEND_URL` | Your frontend URL | From Step 2D (e.g., https://xxx.azurestaticapps.net) |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Static Web App token | From Step 2D |

**Example: Adding AZURE_CREDENTIALS**

1. Click "New repository secret"
2. Name: `AZURE_CREDENTIALS`
3. Value: Paste the entire JSON from Step 4
4. Click "Add secret"

**Repeat for all 5 secrets.**

### 5C: Verify Secrets Added

You should see 5 secrets listed:
- ✅ AZURE_CREDENTIALS
- ✅ ACS_CONNECTION_STRING
- ✅ ACS_PHONE_NUMBER
- ✅ FRONTEND_URL
- ✅ AZURE_STATIC_WEB_APPS_API_TOKEN

---

## Step 6: Update GitHub Actions Workflow

Update the workflow file with your actual resource names:

```bash
# On your local machine, edit .github/workflows/deploy.yml
```

Find these lines and update with YOUR values:

```yaml
env:
  NODE_VERSION: '18.x'
  AZURE_BACKEND_APP_NAME: 'acs-phone-backend-1234567890'  # ← Your backend app name from Step 2C
  AZURE_RESOURCE_GROUP: 'acs-phone-system-rg'             # ← Your resource group from Step 2A
```

**Save the file.**

---

## Step 7: Commit and Push Workflow Changes

```bash
# Check what branch you're on
git branch

# If you're on the feature branch, commit the workflow update
git add .github/workflows/deploy.yml
git commit -m "Update GitHub Actions workflow with Azure resource names"
git push origin claude/azure-phone-system-01WUaAe5sjyqkee3HXGcfawt
```

---

## Step 8: Merge to Main and Deploy

Now merge your feature branch to main to trigger deployment:

```bash
# Switch to main branch
git checkout main

# Pull latest changes
git pull origin main

# Merge your feature branch
git merge claude/azure-phone-system-01WUaAe5sjyqkee3HXGcfawt

# Push to trigger GitHub Actions
git push origin main
```

**🚀 This will trigger the GitHub Actions workflow!**

---

## Step 9: Monitor Deployment

### Watch GitHub Actions:

1. Go to: https://github.com/aioseoassistant/AzureCallingPAYG/actions
2. You should see a workflow run starting
3. Click on the workflow to see progress
4. Watch each step execute:
   - ✅ Build backend
   - ✅ Deploy to Azure App Service
   - ✅ Build frontend
   - ✅ Deploy to Static Web App

**If everything is green ✅, deployment succeeded!**

### Check Azure Portal:

1. Go to your App Service: https://portal.azure.com
2. Navigate to your backend app
3. Click "Browse" to test: `https://your-backend.azurewebsites.net/health`

Should return:
```json
{
  "status": "healthy",
  "timestamp": "...",
  "environment": "production"
}
```

---

## Step 10: Verify Environment Variables in Azure

The workflow sets some variables, but you need to verify others:

```bash
# Check current app settings
az webapp config appsettings list \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --output table

# Verify these are set:
# - ACS_CONNECTION_STRING
# - ACS_PHONE_NUMBER
# - CALLBACK_URI
# - FRONTEND_URL
# - NODE_ENV
```

If any are missing, the workflow should have set them, but verify:

```bash
# Update CALLBACK_URI (should be your backend URL)
az webapp config appsettings set \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings \
        CALLBACK_URI="https://${BACKEND_APP_NAME}.azurewebsites.net/api/callbacks"

echo "✅ CALLBACK_URI updated"
```

---

## Step 11: Test Your Deployed Application

### Test Backend:

```bash
# Health check
curl https://${BACKEND_APP_NAME}.azurewebsites.net/health

# Should return: {"status":"healthy",...}
```

### Test Frontend:

1. Open: `https://$FRONTEND_URL` (from Step 2D)
2. You should see the phone dialer interface
3. Enter a phone number (e.g., +1234567890)
4. Click "📞 Call"
5. Verify the call is initiated

---

## Step 12: Set Up Continuous Deployment

Now every time you push to `main`, it will auto-deploy!

**Test it:**

```bash
# Make a small change
echo "# Test deployment" >> README.md

# Commit and push
git add README.md
git commit -m "Test automatic deployment"
git push origin main

# Check GitHub Actions - should trigger automatically!
# Go to: https://github.com/aioseoassistant/AzureCallingPAYG/actions
```

---

## Troubleshooting

### GitHub Actions Fails

**Check logs:**
1. Go to GitHub Actions tab
2. Click on the failed workflow
3. Click on the failed job
4. Expand each step to see errors

**Common issues:**

| Error | Solution |
|-------|----------|
| "Authentication failed" | Verify `AZURE_CREDENTIALS` secret is correct JSON |
| "Resource not found" | Check `AZURE_BACKEND_APP_NAME` in workflow matches actual app name |
| "Missing secret" | Verify all 5 secrets are added to GitHub |
| "Connection string invalid" | Check `ACS_CONNECTION_STRING` secret |

### Backend Returns 500

```bash
# Check logs
az webapp log tail \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP
```

### Frontend Not Loading

1. Check Static Web App deployment logs in Azure Portal
2. Verify build output location is `dist` in workflow
3. Check browser console for errors

---

## Next Steps After Successful Deployment

✅ **Your system is now live!**

1. **Test calling:**
   - Open frontend URL
   - Make test calls
   - Test DTMF functionality

2. **Set up monitoring:**
   - Enable Application Insights
   - Set up cost alerts
   - Monitor call logs

3. **Security:**
   - Add authentication
   - Set up API rate limiting
   - Configure custom domain with SSL

4. **Scaling:**
   - Monitor performance
   - Scale up App Service if needed
   - Set up auto-scaling rules

---

## Quick Reference Commands

```bash
# View all resources
az resource list --resource-group $RESOURCE_GROUP --output table

# View backend logs
az webapp log tail --name $BACKEND_APP_NAME --resource-group $RESOURCE_GROUP

# Restart backend
az webapp restart --name $BACKEND_APP_NAME --resource-group $RESOURCE_GROUP

# View deployment history
az webapp deployment list --name $BACKEND_APP_NAME --resource-group $RESOURCE_GROUP

# Delete everything (cleanup)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

---

## Summary Checklist

Before deploying, ensure you have:

- [ ] Azure CLI installed and logged in
- [ ] Resource group created
- [ ] ACS resource created and connection string saved
- [ ] Phone number acquired via Azure Portal
- [ ] Backend App Service created
- [ ] Frontend Static Web App created
- [ ] Service principal created for GitHub Actions
- [ ] All 5 GitHub secrets added
- [ ] Workflow file updated with resource names
- [ ] Changes committed and pushed to main
- [ ] GitHub Actions workflow successful
- [ ] Backend health check returns 200 OK
- [ ] Frontend loads and dialer works
- [ ] Test call successful

**If all checked ✅, you're ready to make calls!**

---

## Support

- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Azure App Service:** https://docs.microsoft.com/azure/app-service/
- **Azure Static Web Apps:** https://docs.microsoft.com/azure/static-web-apps/
- **Issues:** https://github.com/aioseoassistant/AzureCallingPAYG/issues
