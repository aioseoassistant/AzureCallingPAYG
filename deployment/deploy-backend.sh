#!/bin/bash

# Azure Communication Services Phone System - Backend Deployment Script
# This script deploys the backend to Azure App Service

set -e

# Configuration
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-acs-phone-system-rg}"
LOCATION="${AZURE_LOCATION:-eastus}"
APP_SERVICE_PLAN="${AZURE_APP_SERVICE_PLAN:-acs-backend-plan}"
APP_NAME="${AZURE_APP_NAME:-acs-phone-backend-$RANDOM}"
RUNTIME="NODE:18-lts"

echo "=========================================="
echo "Azure Communication Services Backend Deployment"
echo "=========================================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "App Service Plan: $APP_SERVICE_PLAN"
echo "App Name: $APP_NAME"
echo "=========================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
echo "Checking Azure login status..."
az account show &> /dev/null || {
    echo "Not logged in. Please run 'az login' first."
    exit 1
}

echo "✓ Azure CLI configured"

# Create resource group if it doesn't exist
echo "Creating resource group..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none

echo "✓ Resource group created/verified"

# Create App Service Plan (Linux, B1 tier)
echo "Creating App Service Plan..."
az appservice plan create \
    --name "$APP_SERVICE_PLAN" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --is-linux \
    --sku B1 \
    --output none

echo "✓ App Service Plan created"

# Create Web App
echo "Creating Web App..."
az webapp create \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --plan "$APP_SERVICE_PLAN" \
    --runtime "$RUNTIME" \
    --output none

echo "✓ Web App created"

# Configure app settings
echo "Configuring application settings..."
az webapp config appsettings set \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings \
        NODE_ENV=production \
        PORT=8080 \
        WEBSITES_PORT=8080 \
    --output none

echo "✓ Application settings configured"

# Enable application logging
az webapp log config \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --application-logging filesystem \
    --detailed-error-messages true \
    --failed-request-tracing true \
    --output none

echo "✓ Logging enabled"

# Build and deploy the application
echo "Building backend application..."
cd ../backend
npm install
npm run build

echo "Creating deployment package..."
cd ..
zip -r deployment/backend-deploy.zip backend/dist backend/package.json backend/package-lock.json

echo "Deploying to Azure..."
az webapp deploy \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --src-path deployment/backend-deploy.zip \
    --type zip

echo "✓ Application deployed"

# Get the app URL
APP_URL="https://${APP_NAME}.azurewebsites.net"

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "Backend URL: $APP_URL"
echo "Health Check: $APP_URL/health"
echo ""
echo "Next steps:"
echo "1. Set environment variables in Azure Portal:"
echo "   - ACS_CONNECTION_STRING"
echo "   - ACS_PHONE_NUMBER"
echo "   - CALLBACK_URI=${APP_URL}/api/callbacks"
echo "   - FRONTEND_URL=<your-frontend-url>"
echo ""
echo "2. Test the deployment:"
echo "   curl ${APP_URL}/health"
echo "=========================================="
