# 🚀 Quick Start: GitHub Actions Deployment

This is the **fastest way** to deploy your Azure phone system using automated GitHub Actions.

## 📋 What You'll Need (5 minutes prep)

- [ ] Azure account ([get free trial](https://azure.microsoft.com/free/))
- [ ] Azure CLI installed ([install guide](https://docs.microsoft.com/cli/azure/install-azure-cli))
- [ ] GitHub account access to this repo
- [ ] 30 minutes of time

---

## ⚡ Two-Path Setup

### Path A: Automated Script (Easiest)

Run one script and follow the prompts:

```bash
# On your local machine
./deployment/setup-github-actions.sh
```

This script will:
- ✅ Create all Azure resources
- ✅ Generate all secrets
- ✅ Save everything to `github-secrets.txt`
- ✅ Tell you exactly what to do next

**Then follow the on-screen instructions!**

---

### Path B: Step-by-Step Manual (Full Control)

Follow the complete guide:

📖 **[GitHub Actions Setup Guide](./docs/GITHUB_ACTIONS_SETUP.md)**

---

## 🎯 The 4-Step Process

No matter which path, here's the flow:

```
┌─────────────────────────────────────────┐
│ Step 1: Create Azure Resources          │
│ (Automated script or manual commands)   │
│ • Resource Group                         │
│ • Communication Services                 │
│ • App Service (Backend)                  │
│ • Static Web App (Frontend)              │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ Step 2: Acquire Phone Number            │
│ (Must do via Azure Portal)               │
│ https://portal.azure.com                 │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ Step 3: Add GitHub Secrets               │
│ (Copy from github-secrets.txt)           │
│ https://github.com/[repo]/settings/      │
│ secrets/actions                          │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ Step 4: Push to Main Branch             │
│ git push origin main                     │
│ → GitHub Actions auto-deploys! 🚀       │
└─────────────────────────────────────────┘
```

---

## 📝 After Running the Automated Script

You'll see output like this:

```
========================================
SETUP COMPLETE!
========================================

📋 Resource Summary:
  Resource Group: acs-phone-system-rg
  Backend App: acs-phone-backend-1234567890
  Frontend App: acs-phone-frontend-1234567890

🌐 URLs:
  Backend: https://acs-phone-backend-1234567890.azurewebsites.net
  Frontend: https://acs-phone-frontend-1234567890.azurestaticapps.net

📄 All secret values saved to: github-secrets.txt
```

**Next, do these 3 things:**

### 1️⃣ Acquire Phone Number (5 minutes)

1. Open [Azure Portal](https://portal.azure.com)
2. Search for your ACS resource (name shown in output)
3. Click **Phone numbers** → **Get**
4. Select country, capabilities, search
5. Purchase number (~$1-2/month)
6. **Copy the number** (format: +12125551234)

### 2️⃣ Add GitHub Secrets (5 minutes)

1. Open the saved file:
   ```bash
   cat github-secrets.txt
   ```

2. Go to GitHub: https://github.com/aioseoassistant/AzureCallingPAYG/settings/secrets/actions

3. Click **"New repository secret"** and add **5 secrets**:

   | Secret Name | Where to Find |
   |-------------|---------------|
   | `AZURE_CREDENTIALS` | From `github-secrets.txt` |
   | `ACS_CONNECTION_STRING` | From `github-secrets.txt` |
   | `ACS_PHONE_NUMBER` | Your phone from step 1 |
   | `FRONTEND_URL` | From `github-secrets.txt` |
   | `AZURE_STATIC_WEB_APPS_API_TOKEN` | From `github-secrets.txt` |

4. **Verify all 5 are added** ✅

### 3️⃣ Update Workflow & Deploy (2 minutes)

```bash
# Edit .github/workflows/deploy.yml
# Update these lines (around line 8-10):

env:
  AZURE_BACKEND_APP_NAME: 'acs-phone-backend-XXXXXXXXXX'  # From script output
  AZURE_RESOURCE_GROUP: 'acs-phone-system-rg'             # From script output
```

Save the file, then:

```bash
# Commit the workflow update
git add .github/workflows/deploy.yml
git commit -m "Configure GitHub Actions with Azure resources"

# Push to main branch (this triggers deployment!)
git checkout main
git merge claude/azure-phone-system-01WUaAe5sjyqkee3HXGcfawt
git push origin main
```

**🎉 GitHub Actions will now deploy automatically!**

---

## 👀 Watch Your Deployment

1. **GitHub Actions:**
   - Go to: https://github.com/aioseoassistant/AzureCallingPAYG/actions
   - Watch the workflow run in real-time
   - All steps should turn green ✅

2. **Test Backend:**
   ```bash
   curl https://your-backend-url.azurewebsites.net/health
   # Should return: {"status":"healthy",...}
   ```

3. **Test Frontend:**
   - Open: `https://your-frontend-url.azurestaticapps.net`
   - You should see the phone dialer
   - Try making a test call!

---

## 🔧 If Something Goes Wrong

### Script Fails

**Error: "Azure CLI not found"**
```bash
# Install Azure CLI first
# Mac: brew install azure-cli
# Windows: https://aka.ms/installazurecliwindows
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Error: "Not logged in"**
```bash
az login
# Then re-run the script
```

### GitHub Actions Fails

**Check the logs:**
1. Go to Actions tab
2. Click the failed workflow
3. Expand the failing step
4. Read the error message

**Common fixes:**
- Verify all 5 secrets are added
- Check secret values (no extra spaces)
- Ensure workflow file has correct resource names
- Verify Azure resources exist in portal

### Need Help?

See the full troubleshooting guide:
📖 [GitHub Actions Setup Guide - Troubleshooting](./docs/GITHUB_ACTIONS_SETUP.md#troubleshooting)

---

## ✅ Success Checklist

After deployment, verify:

- [ ] GitHub Actions workflow completed (all green)
- [ ] Backend health check returns 200 OK
- [ ] Frontend loads in browser
- [ ] Can enter phone number
- [ ] "Call" button works
- [ ] Test call connects

**All checked? Congratulations! 🎉**

Your Azure phone system is live and ready to make calls!

---

## 🎯 What Happens on Every Push to Main?

Once set up, every `git push origin main` will:

1. ✅ Run tests (when you add them)
2. ✅ Build backend TypeScript → JavaScript
3. ✅ Deploy backend to Azure App Service
4. ✅ Build frontend React app
5. ✅ Deploy frontend to Static Web Apps
6. ✅ All automatic, no manual steps!

---

## 📚 Learn More

- **Full Setup Guide:** [docs/GITHUB_ACTIONS_SETUP.md](./docs/GITHUB_ACTIONS_SETUP.md)
- **Azure Setup:** [docs/AZURE_SETUP.md](./docs/AZURE_SETUP.md)
- **Deployment Options:** [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md)
- **API Reference:** [docs/API.md](./docs/API.md)

---

## 💡 Pro Tips

1. **Test Locally First:**
   - Follow [README.md Quick Start](./README.md#quick-start)
   - Make sure everything works before deploying

2. **Monitor Costs:**
   - Set up Azure cost alerts
   - B1 App Service = ~$13/month
   - Phone number = ~$1-2/month
   - Calls = $0.01-0.02/minute

3. **Security:**
   - Add authentication before production
   - Implement rate limiting
   - Never commit `github-secrets.txt`

4. **Custom Domain:**
   - Add custom domain to Static Web App
   - Free SSL certificate included
   - Follow Azure Portal wizard

---

**Ready? Run the script and get started! 🚀**

```bash
./deployment/setup-github-actions.sh
```
