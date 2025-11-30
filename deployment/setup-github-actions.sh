#!/bin/bash

# GitHub Actions Setup Script
# This script automates Steps 1-4 of the GitHub Actions setup

set -e

echo "=========================================="
echo "GitHub Actions Deployment Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed.${NC}"
    echo "Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
echo "Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in. Please run 'az login' first.${NC}"
    az login
fi

echo -e "${GREEN}✓ Azure CLI configured${NC}"
echo ""

# Get configuration from user
echo "=========================================="
echo "Configuration"
echo "=========================================="
echo ""

read -p "Resource Group name (default: acs-phone-system-rg): " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-acs-phone-system-rg}

read -p "Azure region (default: eastus): " LOCATION
LOCATION=${LOCATION:-eastus}

# Generate unique names
TIMESTAMP=$(date +%s)
ACS_RESOURCE_NAME="acs-calling-${TIMESTAMP}"
BACKEND_APP_NAME="acs-phone-backend-${TIMESTAMP}"
FRONTEND_APP_NAME="acs-phone-frontend-${TIMESTAMP}"
APP_SERVICE_PLAN="acs-backend-plan"

echo ""
echo "Will create:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  ACS Resource: $ACS_RESOURCE_NAME"
echo "  Backend App: $BACKEND_APP_NAME"
echo "  Frontend App: $FRONTEND_APP_NAME"
echo ""

read -p "Continue? (y/n): " CONFIRM
if [[ $CONFIRM != "y" ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "=========================================="
echo "Step 1: Creating Resource Group"
echo "=========================================="

az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none

echo -e "${GREEN}✓ Resource group created${NC}"

echo ""
echo "=========================================="
echo "Step 2: Creating Azure Communication Services"
echo "=========================================="

az communication create \
    --name "$ACS_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "global" \
    --data-location "UnitedStates" \
    --output none

echo -e "${GREEN}✓ ACS resource created${NC}"

# Get connection string
ACS_CONNECTION_STRING=$(az communication list-key \
    --name "$ACS_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "primaryConnectionString" \
    --output tsv)

echo ""
echo "=========================================="
echo "Step 3: Creating App Service (Backend)"
echo "=========================================="

# Create App Service Plan
az appservice plan create \
    --name "$APP_SERVICE_PLAN" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --is-linux \
    --sku B1 \
    --output none

echo -e "${GREEN}✓ App Service Plan created${NC}"

# Create Web App
az webapp create \
    --name "$BACKEND_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --plan "$APP_SERVICE_PLAN" \
    --runtime "NODE:18-lts" \
    --output none

echo -e "${GREEN}✓ Backend App created${NC}"

# Configure app settings
az webapp config appsettings set \
    --name "$BACKEND_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings \
        NODE_ENV=production \
        PORT=8080 \
        WEBSITES_PORT=8080 \
    --output none

echo -e "${GREEN}✓ App settings configured${NC}"

BACKEND_URL="https://${BACKEND_APP_NAME}.azurewebsites.net"

echo ""
echo "=========================================="
echo "Step 4: Creating Static Web App (Frontend)"
echo "=========================================="

az staticwebapp create \
    --name "$FRONTEND_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none

echo -e "${GREEN}✓ Static Web App created${NC}"

# Get deployment token
STATIC_WEB_APP_TOKEN=$(az staticwebapp secrets list \
    --name "$FRONTEND_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.apiKey" \
    --output tsv)

# Get frontend URL
FRONTEND_URL=$(az staticwebapp show \
    --name "$FRONTEND_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "defaultHostname" \
    --output tsv)

echo ""
echo "=========================================="
echo "Step 5: Creating Service Principal"
echo "=========================================="

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

AZURE_CREDENTIALS=$(az ad sp create-for-rbac \
    --name "github-actions-acs-phone-${TIMESTAMP}" \
    --role contributor \
    --scopes "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" \
    --sdk-auth 2>/dev/null)

echo -e "${GREEN}✓ Service principal created${NC}"

echo ""
echo "=========================================="
echo "SETUP COMPLETE!"
echo "=========================================="
echo ""
echo -e "${GREEN}All Azure resources have been created!${NC}"
echo ""
echo "📋 Resource Summary:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  ACS Resource: $ACS_RESOURCE_NAME"
echo "  Backend App: $BACKEND_APP_NAME"
echo "  Frontend App: $FRONTEND_APP_NAME"
echo ""
echo "🌐 URLs:"
echo "  Backend: $BACKEND_URL"
echo "  Frontend: https://$FRONTEND_URL"
echo ""
echo "=========================================="
echo "⚠️  NEXT STEPS - IMPORTANT!"
echo "=========================================="
echo ""
echo "1. ACQUIRE A PHONE NUMBER:"
echo "   Go to Azure Portal: https://portal.azure.com"
echo "   Navigate to: $ACS_RESOURCE_NAME"
echo "   Click 'Phone numbers' → 'Get'"
echo "   Purchase a number and save it (e.g., +12125551234)"
echo ""
echo "2. ADD GITHUB SECRETS:"
echo "   Go to: https://github.com/aioseoassistant/AzureCallingPAYG/settings/secrets/actions"
echo "   Click 'New repository secret' and add each of these:"
echo ""

# Save secrets to a file for easy reference
SECRETS_FILE="github-secrets.txt"
cat > "$SECRETS_FILE" << EOF
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
[ENTER YOUR PHONE NUMBER FROM AZURE PORTAL, e.g., +12125551234]

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
EOF

echo -e "${YELLOW}   Secret values have been saved to: $SECRETS_FILE${NC}"
echo ""
echo "   Secret 1: AZURE_CREDENTIALS"
echo "   Secret 2: ACS_CONNECTION_STRING"
echo "   Secret 3: ACS_PHONE_NUMBER (you'll add after acquiring phone)"
echo "   Secret 4: FRONTEND_URL"
echo "   Secret 5: AZURE_STATIC_WEB_APPS_API_TOKEN"
echo ""
echo "3. UPDATE WORKFLOW FILE:"
echo "   Edit .github/workflows/deploy.yml"
echo "   Update these values:"
echo "     AZURE_BACKEND_APP_NAME: '$BACKEND_APP_NAME'"
echo "     AZURE_RESOURCE_GROUP: '$RESOURCE_GROUP'"
echo ""
echo "4. DEPLOY:"
echo "   git add .github/workflows/deploy.yml"
echo "   git commit -m 'Update workflow with Azure resources'"
echo "   git push origin main"
echo ""
echo "=========================================="
echo ""
echo -e "${GREEN}📄 All secret values saved to: $SECRETS_FILE${NC}"
echo -e "${YELLOW}⚠️  Keep this file secure and delete after setting up GitHub secrets!${NC}"
echo ""
