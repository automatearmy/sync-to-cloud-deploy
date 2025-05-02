# Welcome to Google Sync to Cloud Deployment

<walkthrough-tutorial-duration duration="60"></walkthrough-tutorial-duration>

Google Sync to Cloud is a powerful GCP-based tool that helps you seamlessly move files from Google Drive to Google Cloud Storage. This enables better data management, improved security, and integration with other Google Cloud services.

## Prerequisites

Before you begin, you'll need:

- A Google Cloud project with billing enabled
- **Owner** and **Service Account Token Creator** permissions on the project
- Google Workspace admin access (for domain-wide delegation)

**Is This Safe?**

All scripts in this tutorial are designed with security in mind:

- Scripts are transparent and explain each action they take
- No sensitive data is transmitted outside your Google Cloud project
- All resources are created within your project's security boundaries
- You'll have full control and visibility throughout the process

Click the **Next** button to begin setting up your project.

## Project Selection and Setup

Let's start by selecting the Google Cloud project where you'll deploy Google Sync to Cloud.

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

Your selected project is: **<walkthrough-project-id/>**

## Project and Script Setup

Let's configure your selected project and prepare all the scripts for this tutorial:

```sh
gcloud config set project <walkthrough-project-id/> && chmod +x steps/*.sh
```

This sets your current project and makes all deployment scripts executable.

## Project Permissions Check

Now, let's make sure you have the necessary permissions on this project and enable required APIs:

```sh
./steps/check_project_setup.sh
```

This script will:

1. Verify you have the required Owner and Service Account Token Creator permissions
2. Check that billing is enabled
3. Enable the necessary Google Cloud APIs for Google Sync to Cloud

<walkthrough-footnote>
If the script indicates any missing permissions or requirements, please address them before continuing. You must have Owner role and Service Account Token Creator role on the project.
</walkthrough-footnote>

## OAuth Consent Screen Configuration

Now we need to configure the OAuth consent screen and create OAuth credentials for Google Sync to Cloud.

First, let's configure the OAuth consent screen:

1. Open the [OAuth consent screen](https://console.cloud.google.com/auth/overview?project=<walkthrough-project-id/>) in the Google Cloud Console
2. Click "Get started"
3. Fill in the App Information:
   - App name: "Sync to Cloud"
   - User support email: Your personal email
4. Under Audience, select "Internal"
5. For Contact Information, enter your personal email
6. Check "I agree to the Google API Services: User Data Policy"
7. Click "Continue" and then "Create"

<walkthrough-footnote>
The OAuth consent screen must be configured before creating OAuth clients.
</walkthrough-footnote>

## Create OAuth Clients

Now that you've configured the OAuth consent screen, you need to create two OAuth clients and then store their credentials:

### 1. Create API OAuth Client (Desktop App)

1. Go to [Credentials](https://console.cloud.google.com/apis/credentials?project=<walkthrough-project-id/>) in the Google Cloud Console
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Desktop App" as the application type
4. Name: "Sync to Cloud API - Admin Transfers"
5. Click "Create"
6. **Copy and save the Client ID and Client Secret** - you'll need them in the next step

### 2. Create UI OAuth Client (Web App) 

1. Go to [Credentials](https://console.cloud.google.com/apis/credentials?project=<walkthrough-project-id/>) again
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Web Application" as the application type
4. Name: "Sync to Cloud UI - IAP/Auth"
5. Add the following Authorized JavaScript origins:
   * `http://localhost`
   * `http://localhost:5001`
   * `https://sync-to-cloud-ui-PROJECT_NUMBER.us-central1.run.app`
     (Replace PROJECT_NUMBER with your project number from this command:
     ```sh
     gcloud projects describe <walkthrough-project-id/> --format="value(projectNumber)"
     ```
     )
6. Add the following Authorized redirect URIs:
   * `https://sync-to-cloud-ui-PROJECT_NUMBER.us-central1.run.app`
   * (Use the same PROJECT_NUMBER as above)
7. Click "Create"
8. **Copy and save the Client ID and Client Secret** - you'll need them in the next step
9. **Important**: After creation, edit this client and add this additional redirect URI:
   * `https://iap.googleapis.com/v1/oauth/clientIds/CLIENT_ID:handleRedirect`
   * (Replace CLIENT_ID with the client ID you just received)

### 3. Store the OAuth credentials

Now, run the script to securely store your OAuth credentials in Secret Manager:

```sh
./steps/create_oauth_credentials.sh <walkthrough-project-id/>
```

The script will:
1. Prompt you to enter the Client ID and Client Secret for each OAuth client you created
2. Store these credentials securely in Secret Manager
3. Make them available for the deployment process

<walkthrough-footnote>
The OAuth clients you created will allow Google Sync to Cloud to securely authenticate with Google APIs and services. Keep your client secrets secure and do not share them.
</walkthrough-footnote>

## Setup Terraform Infrastructure

Now, let's set up the Terraform infrastructure needed for deployment. This includes creating a service account with the necessary permissions and a Cloud Storage bucket to store Terraform's state files.

```sh
./steps/setup_terraform_infra.sh <walkthrough-project-id/>
```

This script will:

1. Create a service account named `terraform-admin` with Owner permissions
2. Ensure you have permission to impersonate this service account
3. Create a Cloud Storage bucket named `terraform-state-<walkthrough-project-id/>`
4. Enable versioning on the bucket for state file history
5. Save the configuration for later use in the deployment process

<walkthrough-footnote>
The Terraform service account has elevated permissions to create all required resources, while the state bucket tracks what resources have been created and their current state. Together, they provide a secure and consistent deployment process.
</walkthrough-footnote>

## Create Terraform Configuration File

Now, let's create the Terraform configuration file that will be used for deployment:

```sh
./steps/create_terraform_tfvars.sh <walkthrough-project-id/>
```

This script will:

1. Create a `terraform.tfvars` file with your project settings
2. Configure the deployment region (default: us-central1)
3. Set up **required** domain-wide delegation
4. Configure BigQuery settings for inventory reporting

<walkthrough-footnote>
**IMPORTANT**: Domain-wide delegation is **required** for Google Sync to Cloud to function properly. You'll need to provide a service account email that will be granted permission to access Google Drive files. You'll also need to configure this delegation in your Google Workspace admin console.
</walkthrough-footnote>

## Request Access to Artifact Registry

Before running the final deployment, you need to request access to the Sync to Cloud artifact registry:

1. Contact the Sync to Cloud team at team@automatearmy.com
2. Provide them with your Google Cloud project ID: **<walkthrough-project-id/>**
3. Provide them with your project number (run this command to get it):
   ```sh
   gcloud projects describe <walkthrough-project-id/> --format="value(projectNumber)"
   ```
4. Wait for confirmation that your project has been granted access

<walkthrough-footnote>
The artifact registry contains the Terraform code and container images needed for deployment. Once you receive confirmation of access, you can proceed to the final step.
</walkthrough-footnote>

## Pull Terraform Docker Image

Once you've received confirmation of artifact registry access, you need to pull the Terraform Docker image:

```sh
./steps/pull_terraform_image.sh <walkthrough-project-id/>
```

This script will:

1. Authenticate to the artifact registry using your service account
2. Pull the Terraform Docker image
3. Save the image information for the deployment step

<walkthrough-footnote>
The Terraform image contains all the infrastructure-as-code that will deploy Google Sync to Cloud to your project. If this step fails, ensure that you've received confirmation that your project has been granted access to the artifact registry.
</walkthrough-footnote>

## Run Terraform Deployment

Now that you have the Terraform image, you can run the deployment:

```sh
./steps/run_terraform.sh <walkthrough-project-id/>
```

This script will:

1. Initialize Terraform with your state bucket
2. Generate a plan showing all resources to be created
3. Ask for confirmation before proceeding
4. Create all required resources (this may take 15-20 minutes)
5. Display the URL to access your Google Sync to Cloud application

<walkthrough-footnote>
The deployment process will create all necessary GCP resources, including GKE cluster, Cloud Storage buckets, IAM permissions, and Cloud Run services. Once completed, you'll receive URLs to access your deployed application.
</walkthrough-footnote>

## Congratulations!

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

You've successfully deployed Google Sync to Cloud to your Google Cloud project! Here's what you can do next:

1. Access your application using the URL provided in the deployment output
2. Sign in with your Google account
3. Begin setting up transfers from Google Drive to Cloud Storage

**For technical support or questions:**
- Email: team@automatearmy.com
- Documentation: https://docs.sync-to-cloud.dev

Thank you for using Google Sync to Cloud!
