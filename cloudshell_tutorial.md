# Sync to Cloud Deployment Tutorial

## Welcome to Sync to Cloud Deployment

This tutorial will guide you through deploying Sync to Cloud to your Google Cloud project.

<walkthrough-info-message>
This process will take about 15-20 minutes to complete.
</walkthrough-info-message>

## Prerequisites

Before you begin, make sure you have:

- Owner access to a Google Cloud project
- Google Workspace admin access (for domain-wide delegation, if needed)
- The ability to create OAuth credentials in Google Cloud

## Step 1: Set Up Your Google Cloud Project

First, let's make sure you're using the right Google Cloud project:

<walkthrough-project-setup></walkthrough-project-setup>

Set your project ID:

```bash
gcloud config set project {{project-id}}
```

## Step 2: Start the Deployment

Run the deployment script:

```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
1. Check your gcloud login status
2. Enable required APIs
3. Create Secret Manager secrets for OAuth credentials
4. Create a terraform.tfvars file
5. Run the Terraform Docker image to deploy Sync to Cloud

## Step 3: Enter OAuth Credentials

During the deployment, you'll be prompted to enter OAuth credentials:

1. The script will create four secrets in Secret Manager:
   - sync-to-cloud-ui-client-id
   - sync-to-cloud-ui-client-secret
   - sync-to-cloud-api-client-id
   - sync-to-cloud-api-client-secret

2. If you don't have OAuth credentials yet:
   - Go to the [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - Create an OAuth client ID (Web application type)
   - Add authorized redirect URIs (the script will provide guidance)

## Step 4: Configure Terraform Variables

You'll be asked to configure:

- Google Cloud region (default: us-central1)
- API user email for domain-wide delegation (optional)

## Step 5: Review and Apply

The script will show you the Terraform plan. After reviewing:

1. Confirm to proceed with the deployment
2. Wait for the deployment to complete
3. Note the URLs provided in the outputs

## Step 6: Post-Deployment

After deployment:

1. Update your OAuth credentials with the deployed URLs
2. Set up domain-wide delegation (if needed)
3. Access your Sync to Cloud instance

## Congratulations!

You've successfully deployed Sync to Cloud to your Google Cloud project.

For help, contact team@automatearmy.com.

<walkthrough-conclusion-message>
Thank you for deploying Sync to Cloud!
</walkthrough-conclusion-message>
