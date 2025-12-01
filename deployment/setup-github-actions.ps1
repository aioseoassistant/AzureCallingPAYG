# ========================================
# Azure Communication Services Setup - PowerShell Version
# Run this script in PowerShell to create all Azure resources
# ========================================

# Set variables
$RESOURCE_GROUP = "acs-phone-system-rg"
$LOCATION = "uksouth"  # Change to your preferred region
$TIMESTAMP = Get-Date -Format 'yyyyMMddHHmmss'
$ACS_RESOURCE_NAME = "acs-calling-$TIMESTAMP"
$BACKEND_APP_NAME = "acs-phone-backend-$TIMESTAMP"
$FRONTEND_APP_NAME = "acs-phone-frontend-$TIMESTAMP"
$APP_SERVICE_PLAN = "acs-backend-plan"

Write-Host "=========================================="
Write-Host "Azure Communication Services Setup"
Write-Host "=========================================="
Write-Host ""

# Check if logged in
try {
    az account show | Out-Null
    Write-Host "✓ Azure CLI configured"
} catch {
    Write-Host "Not logged in. Running az login..."
    az login
}

Write-Host ""
Write-Host "Configuration:"
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  Location: $LOCATION"
Write-Host "  ACS Resource: $ACS_RESOURCE_NAME"
Write-Host "  Backend App: $BACKEND_APP_NAME"
Write-Host "  Frontend App: $FRONTEND_APP_NAME"
Write-Host ""

$confirmation = Read-Host "Continue with setup? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Setup cancelled."
    exit
}

# Step 1: Create Resource Group
Write-Host ""
Write-Host "Step 1: Creating Resource Group..."
az group create `
    --name $RESOURCE_GROUP `
    --location $LOCATION `
    --output none

Write-Host "✅ Resource group created"

# Step 2: Create Azure Communication Services
Write-Host ""
Write-Host "Step 2: Creating Azure Communication Services..."
az communication create `
    --name $ACS_RESOURCE_NAME `
    --resource-group $RESOURCE_GROUP `
    --location "global" `
    --data-location "UnitedStates" `
    --output none

Write-Host "✅ ACS resource created"

# Get connection string
$ACS_CONNECTION_STRING = az communication list-key `
    --name $ACS_RESOURCE_NAME `
    --resource-group $RESOURCE_GROUP `
    --query "primaryConnectionString" `
    --output tsv

# Step 3: Create App Service Plan
Write-Host ""
Write-Host "Step 3: Creating App Service Plan..."
az appservice plan create `
    --name $APP_SERVICE_PLAN `
    --resource-group $RESOURCE_GROUP `
    --location $LOCATION `
    --is-linux `
    --sku B1 `
    --output none

Write-Host "✅ App Service Plan created"

# Step 4: Create Backend Web App
Write-Host ""
Write-Host "Step 4: Creating Backend Web App..."
az webapp create `
    --name $BACKEND_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --plan $APP_SERVICE_PLAN `
    --runtime "NODE:18-lts" `
    --output none

Write-Host "✅ Backend App created"

# Configure app settings
az webapp config appsettings set `
    --name $BACKEND_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --settings NODE_ENV=production PORT=8080 WEBSITES_PORT=8080 `
    --output none

Write-Host "✅ App settings configured"

$BACKEND_URL = "https://$BACKEND_APP_NAME.azurewebsites.net"

# Step 5: Create Static Web App
Write-Host ""
Write-Host "Step 5: Creating Static Web App..."
az staticwebapp create `
    --name $FRONTEND_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --location $LOCATION `
    --output none

Write-Host "✅ Static Web App created"

# Get deployment token
$STATIC_WEB_APP_TOKEN = az staticwebapp secrets list `
    --name $FRONTEND_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --query "properties.apiKey" `
    --output tsv

# Get frontend URL
$FRONTEND_URL = az staticwebapp show `
    --name $FRONTEND_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --query "defaultHostname" `
    --output tsv

# Step 6: Create Service Principal
Write-Host ""
Write-Host "Step 6: Creating Service Principal..."
$SUBSCRIPTION_ID = az account show --query id -o tsv

$AZURE_CREDENTIALS = az ad sp create-for-rbac `
    --name "github-actions-acs-phone-$TIMESTAMP" `
    --role contributor `
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" `
    --sdk-auth 2>$null

Write-Host "✅ Service principal created"

# Save everything to a file
$SECRETS_FILE = "github-secrets.txt"
@"
========================================
GitHub Secrets Configuration
========================================

Add these secrets to your GitHub repository:
https://github.com/aioseoassistant/AzureCallingPAYG/settings/secrets/actions

Secret Name: AZURE_CREDENTIALS
Value:
$AZURE_CREDENTIALS

---

Secret Name: ACS_CONNECTION_STRING
Value:
$ACS_CONNECTION_STRING

---

Secret Name: ACS_PHONE_NUMBER
Value:
[ENTER YOUR PHONE NUMBER FROM AZURE PORTAL, e.g., +447123456789]

---

Secret Name: FRONTEND_URL
Value:
https://$FRONTEND_URL

---

Secret Name: AZURE_STATIC_WEB_APPS_API_TOKEN
Value:
$STATIC_WEB_APP_TOKEN

========================================
Workflow Configuration
========================================

Update .github/workflows/deploy.yml:

env:
  AZURE_BACKEND_APP_NAME: '$BACKEND_APP_NAME'
  AZURE_RESOURCE_GROUP: '$RESOURCE_GROUP'

========================================
Resource Summary
========================================

Resource Group: $RESOURCE_GROUP
ACS Resource: $ACS_RESOURCE_NAME
Backend App: $BACKEND_APP_NAME
Frontend App: $FRONTEND_APP_NAME

Backend URL: $BACKEND_URL
Frontend URL: https://$FRONTEND_URL

========================================
"@ | Out-File -FilePath $SECRETS_FILE -Encoding UTF8

Write-Host ""
Write-Host "=========================================="
Write-Host "SETUP COMPLETE!"
Write-Host "=========================================="
Write-Host ""
Write-Host "📋 Resource Summary:"
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  ACS Resource: $ACS_RESOURCE_NAME"
Write-Host "  Backend App: $BACKEND_APP_NAME"
Write-Host "  Frontend App: $FRONTEND_APP_NAME"
Write-Host ""
Write-Host "🌐 URLs:"
Write-Host "  Backend: $BACKEND_URL"
Write-Host "  Frontend: https://$FRONTEND_URL"
Write-Host ""
Write-Host "=========================================="
Write-Host "⚠️  NEXT STEPS - IMPORTANT!"
Write-Host "=========================================="
Write-Host ""
Write-Host "1. ACQUIRE A PHONE NUMBER:"
Write-Host "   Go to Azure Portal: https://portal.azure.com"
Write-Host "   Navigate to: $ACS_RESOURCE_NAME"
Write-Host "   Click 'Phone numbers' → 'Get'"
Write-Host "   Purchase a UK number (format: +447123456789)"
Write-Host ""
Write-Host "2. ADD GITHUB SECRETS:"
Write-Host "   Open file: $SECRETS_FILE"
Write-Host "   Copy each secret to GitHub"
Write-Host ""
Write-Host "3. UPDATE WORKFLOW:"
Write-Host "   Edit .github/workflows/deploy.yml"
Write-Host "   Update resource names (shown in $SECRETS_FILE)"
Write-Host ""
Write-Host "4. DEPLOY:"
Write-Host "   git push origin main"
Write-Host ""
Write-Host "=========================================="
Write-Host ""
Write-Host "📄 All secrets saved to: $SECRETS_FILE"
Write-Host "⚠️  Keep this file secure!"
Write-Host ""
