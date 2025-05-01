# Prerequisites for Sync to Cloud Deployment

Before running the deployment script, please complete the following prerequisites:

## 1. Google Cloud Project Setup

- Create or select a Google Cloud project
- Enable billing for the project
- Ensure you have both Owner access AND Service Account Token Creator role for this project

## 2. OAuth Setup

You need to set up OAuth credentials in your Google Cloud project **before** running the deployment script.

### 2.1 Set Up OAuth Consent Screen

1. Go to [OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent) in your Google Cloud project
2. Select the appropriate user type (Internal or External)
3. Fill in the required application information:
   - App name: "Sync to Cloud"
   - User support email: Your email
   - Developer contact information: Your email
4. Add the following scopes:
   - `https://www.googleapis.com/auth/drive`
   - `https://www.googleapis.com/auth/userinfo.email`
   - `https://www.googleapis.com/auth/userinfo.profile`
5. Add authorized domain:
   - `sync-to-cloud-ui-{project_number}.us-central1.run.app`
6. Complete the consent screen setup process

### 2.2 Create OAuth Credentials

You need to create two sets of OAuth credentials:

#### API OAuth Client

1. Go to [Credentials](https://console.cloud.google.com/apis/credentials) in your Google Cloud project
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Desktop App" as the application type
4. Name: "Sync to Cloud API - Admin Transfers"
5. Click "Create"
6. **Write down the Client ID and Client Secret** - you'll need these during deployment

#### UI OAuth Client

1. Go to [Credentials](https://console.cloud.google.com/apis/credentials) in your Google Cloud project
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Web Application" as the application type
4. Name: "Sync to Cloud UI - IAP/Auth"
5. Add the following Authorized JavaScript origins:
   - `http://localhost`
   - `http://localhost:5001`
   - `https://sync-to-cloud-ui-{project_number}.us-central1.run.app`
6. Add the following Authorized redirect URIs:
   - Copy your Client ID and add it to this URI: `https://iap.googleapis.com/v1/oauth/clientIds/[Client ID HERE]:handleRedirect`
   - `https://sync-to-cloud-ui-{project_number}.us-central1.run.app`
7. Click "Create"
8. **Write down the Client ID and Client Secret** - you'll need these during deployment

## 3. Deployment

Once you've completed these prerequisites, you can run the deployment script:

```bash
./deploy.sh
```

During deployment, you'll be prompted to enter the OAuth client IDs and secrets that you created in step 2.2.