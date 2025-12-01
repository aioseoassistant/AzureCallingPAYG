#!/bin/bash

# Azure Communication Services Phone System - Frontend Deployment Script
# This script deploys the frontend to Azure Static Web Apps

set -e

# Configuration
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-acs-phone-system-rg}"
LOCATION="${AZURE_LOCATION:-eastus}"
STATIC_WEB_APP_NAME="${AZURE_STATIC_WEB_APP_NAME:-acs-phone-frontend-$RANDOM}"

echo "=========================================="
echo "Azure Communication Services Frontend Deployment"
echo "=========================================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Static Web App Name: $STATIC_WEB_APP_NAME"
echo "=========================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed."
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

# Create Static Web App
echo "Creating Static Web App..."
az staticwebapp create \
    --name "$STATIC_WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none

echo "✓ Static Web App created"

# Build the frontend
echo "Building frontend application..."
cd ../frontend
npm install
npm run build

# Get deployment token
echo "Getting deployment token..."
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
    --name "$STATIC_WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.apiKey" \
    --output tsv)

# Deploy using SWA CLI (if installed)
if command -v swa &> /dev/null; then
    echo "Deploying with SWA CLI..."
    swa deploy ./dist \
        --deployment-token "$DEPLOYMENT_TOKEN" \
        --env production
else
    echo "SWA CLI not found. Please install it or deploy via GitHub Actions."
    echo "Install: npm install -g @azure/static-web-apps-cli"
fi

# Get the app URL
APP_URL=$(az staticwebapp show \
    --name "$STATIC_WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "defaultHostname" \
    --output tsv)

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "Frontend URL: https://$APP_URL"
echo ""
echo "Next steps:"
echo "1. Update backend FRONTEND_URL environment variable"
echo "2. Update frontend VITE_API_URL to point to backend"
echo "=========================================="
