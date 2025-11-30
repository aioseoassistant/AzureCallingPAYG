#!/bin/bash

# Azure Communication Services - Complete Resource Setup
# This script creates all required Azure resources for the phone system

set -e

# Configuration
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-acs-phone-system-rg}"
LOCATION="${AZURE_LOCATION:-eastus}"
ACS_RESOURCE_NAME="${ACS_RESOURCE_NAME:-acs-calling-resource-$RANDOM}"

echo "=========================================="
echo "Azure Communication Services - Resource Setup"
echo "=========================================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "ACS Resource: $ACS_RESOURCE_NAME"
echo "=========================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed."
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

# Create resource group
echo "Creating resource group..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none

echo "✓ Resource group created"

# Create Azure Communication Services resource
echo "Creating Azure Communication Services resource..."
az communication create \
    --name "$ACS_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "global" \
    --data-location "UnitedStates" \
    --output none

echo "✓ ACS resource created"

# Get connection string
echo "Retrieving connection string..."
CONNECTION_STRING=$(az communication list-key \
    --name "$ACS_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "primaryConnectionString" \
    --output tsv)

echo "✓ Connection string retrieved"

echo ""
echo "=========================================="
echo "Azure Communication Services Setup Complete!"
echo "=========================================="
echo "Resource Name: $ACS_RESOURCE_NAME"
echo "Resource Group: $RESOURCE_GROUP"
echo ""
echo "Connection String (save this securely):"
echo "$CONNECTION_STRING"
echo ""
echo "=========================================="
echo "IMPORTANT NEXT STEPS:"
echo "=========================================="
echo ""
echo "1. Acquire a Phone Number:"
echo "   - Go to Azure Portal"
echo "   - Navigate to your ACS resource: $ACS_RESOURCE_NAME"
echo "   - Go to 'Phone numbers' section"
echo "   - Click 'Get' to purchase a phone number"
echo "   - Select capabilities: 'Make calls' (outbound)"
echo "   - Note: Premium rate calling may require additional verification"
echo ""
echo "2. Configure Environment Variables:"
echo "   Create backend/.env with:"
echo "   ACS_CONNECTION_STRING=\"$CONNECTION_STRING\""
echo "   ACS_PHONE_NUMBER=\"+your-acquired-number\""
echo "   CALLBACK_URI=\"https://your-backend-url/api/callbacks\""
echo "   FRONTEND_URL=\"https://your-frontend-url\""
echo ""
echo "3. Enable Premium Rate Calling (if needed):"
echo "   - Premium rate calls may be blocked by default"
echo "   - Contact Azure support to enable premium rate destinations"
echo "   - Provide use case justification"
echo ""
echo "4. Deploy Backend and Frontend:"
echo "   ./deployment/deploy-backend.sh"
echo "   ./deployment/deploy-frontend.sh"
echo ""
echo "=========================================="
