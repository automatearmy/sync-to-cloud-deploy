<!--
Copyright 2025 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

<!-- This file contains the step-by-step tutorial for deploying the Sync to Cloud application to Google Cloud -->

<!-- #################### WELCOME #################### -->
<!-- #################### WELCOME #################### -->

# Welcome to Google Sync to Cloud Deployment

<walkthrough-tutorial-duration duration="60"></walkthrough-tutorial-duration>

Google Sync to Cloud is a powerful GCP-based tool that helps you seamlessly move files from Google Drive to Google Cloud Storage. This enables better data management, improved security, and integration with other Google Cloud services.

## Prerequisites

Before you begin, you'll need:

- A Google Cloud project with billing enabled
- **Owner** and **Service Account Token Creator** permissions on the project
- Google Workspace admin access

**Is This Safe?**

All scripts in this tutorial are designed with security in mind:

- Scripts are transparent and explain each action they take
- No sensitive data is transmitted outside your Google Cloud project
- All resources are created within your project's security boundaries
- You'll have full control and visibility throughout the process

Click the **Next** button to begin setting up your project.

<!-- #################### STEP 1 #################### -->
<!-- #################### STEP 1 #################### -->

## Project Selection and Setup

Let's start by selecting the Google Cloud project where you'll deploy Google Sync to Cloud.

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

Your selected project is: **<walkthrough-project-id/>**

<walkthrough-footnote>
Selecting the right project is crucial as it will contain all the resources for Google Sync to Cloud. Make sure you choose a project where billing is enabled to ensure successful deployment.
</walkthrough-footnote>

<!-- #################### STEP 2 #################### -->
<!-- #################### STEP 2 #################### -->

## Project Configuration

Let's configure your selected project:

```sh
gcloud config set project <walkthrough-project-id/>
```

This command configures your Cloud Shell environment to use your selected project. All subsequent commands and deployments will target this project.

<walkthrough-footnote>
If you switch between multiple projects, you'll need to run this command again to target the correct project.
</walkthrough-footnote>

<!-- #################### STEP 3 #################### -->
<!-- #################### STEP 3 #################### -->

## Script Preparation

Let's prepare the deployment scripts by making them executable:

```sh
chmod +x steps/*.sh
```

This command makes all shell scripts (\*.sh files) in the steps/ directory executable by adding the execute (+x) permission.

<walkthrough-footnote>
These scripts are part of the deployment process and will help set up your Google Sync to Cloud environment. 
Each script is designed to be idempotent, meaning it's safe to run multiple times if needed.
</walkthrough-footnote>

<!-- #################### STEP 4 #################### -->
<!-- #################### STEP 4 #################### -->

## Project Permissions Check

Now, let's make sure you have the necessary permissions on this project and enable required APIs:

```sh
./steps/01_check_project_setup.sh
```

This script will:

1. Verify you have the required Owner and Service Account Token Creator permissions
2. Check that billing is enabled
3. Enable the necessary Google Cloud APIs for Google Sync to Cloud

<walkthrough-footnote>
If the script indicates any missing permissions or requirements, please address them before continuing. 
You must have BOTH the Owner role AND Service Account Token Creator role on the project. While the Owner role gives you access to most GCP resources, the Service Account Token Creator role is a separate permission that may still fail even with Owner access.
</walkthrough-footnote>

<!-- #################### STEP 6 #################### -->
<!-- #################### STEP 6 #################### -->

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

<!-- #################### STEP 7 #################### -->
<!-- #################### STEP 7 #################### -->

## Create API OAuth Client

First, let's create the OAuth client for the API service:

1. Go to [Credentials](https://console.cloud.google.com/apis/credentials?project=<walkthrough-project-id/>) in the Google Cloud Console
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Desktop App" as the application type
4. Name: "Sync to Cloud API"
5. Click "Create"
6. **Copy and save the Client ID and Client Secret** - you'll need them in a later step

<walkthrough-footnote>
The API OAuth client will be used by the backend services to authenticate with Google APIs. 
Make sure to keep the client secret secure and never commit it to version control.
</walkthrough-footnote>

<!-- #################### STEP 8 #################### -->
<!-- #################### STEP 8 #################### -->

## Create UI OAuth Client

Next, let's create the OAuth client for the web UI:

1. Go to [Credentials](https://console.cloud.google.com/apis/credentials?project=<walkthrough-project-id/>) in the Google Cloud Console
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Web Application" as the application type
4. Name: "Sync to Cloud UI - IAP/Auth"
5. Get your project number by running:
   ```sh
   gcloud projects describe <walkthrough-project-id/> --format="value(projectNumber)"
   ```
6. Using your project number from above, add the following URL as both the Authorized JavaScript origin and Authorized redirect URI:
   - `https://sync-to-cloud-ui-PROJECT_NUMBER.us-central1.run.app`
     (Replace PROJECT_NUMBER with the number from step 5)
7. Click "Create"
8. **Copy and save the Client ID and Client Secret** - you'll need them in the next step

<walkthrough-footnote>
The UI OAuth client will be used by the frontend services to authenticate with Google APIs and to IAP. 
Make sure to keep the client secret secure and never commit it to version control.
</walkthrough-footnote>

<!-- #################### STEP 9 #################### -->
<!-- #################### STEP 9 #################### -->

## Store the OAuth credentials

Now, run the script to securely store your OAuth credentials in Secret Manager:

```sh
./steps/02_create_oauth_credentials.sh <walkthrough-project-id/>
```

The script will:

1. Prompt you to enter the Client ID and Client Secret for each OAuth client you created
2. Store these credentials securely in Secret Manager
3. Make them available for the deployment process

<walkthrough-footnote>
The OAuth clients you created will allow Google Sync to Cloud to securely authenticate with Google APIs and services. Keep your client secrets secure and do not share them.
</walkthrough-footnote>

<!-- #################### STEP 10 #################### -->
<!-- #################### STEP 10 #################### -->

## Setup Terraform Infrastructure

Now, let's set up the Terraform infrastructure needed for deployment. This includes creating a service account with the necessary permissions and a Cloud Storage bucket to store Terraform's state files.

```sh
./steps/03_setup_terraform_infra.sh <walkthrough-project-id/>
```

This script will:

1. Create a service account named `terraform-admin` with Owner permissions
2. Ensure you have permission to impersonate this service account
3. Create a Cloud Storage bucket named `<walkthrough-project-id/>-terraform-state`
4. Enable versioning on the bucket for state file history
5. Save the configuration for later use in the deployment process

<walkthrough-footnote>
The Terraform service account has elevated permissions to create all required resources, while the state bucket tracks what resources have been created and their current state. Together, they provide a secure and consistent deployment process.
</walkthrough-footnote>

<!-- #################### STEP 11 #################### -->
<!-- #################### STEP 11 #################### -->

## Create Terraform Configuration File and Secret

Now, let's create the Terraform configuration file (`terraform.tfvars`) and also store these variables securely in Google Cloud Secret Manager.

Run the following script:
```sh
./steps/04_create_terraform_tfvars.sh <walkthrough-project-id/>
```

This script will:

1.  Prompt you for necessary configuration values such as region, environment name, and BigQuery connection details.
2.  Create a `terraform.tfvars` file locally in your Cloud Shell environment.
3.  Create (or update if it already exists) a secret named `sync-to-cloud-terraform-tfvars` in Secret Manager and store the `terraform.tfvars` content in it.

<walkthrough-footnote>
The script automates the creation of both the local `terraform.tfvars` file needed for the immediate deployment and a secure copy in Secret Manager. This ensures your configuration is safely stored and versioned.
</walkthrough-footnote>

<!-- #################### STEP 12 #################### -->
<!-- #################### STEP 12 #################### -->

## Request Access to Artifact Registry

Before running the final deployment, you need to request access to the Sync to Cloud artifact registry:

1. Contact the Sync to Cloud team at zach.zimbler@automatearmy.com or via deployment call
2. Provide them with your Google Cloud project ID: **<walkthrough-project-id/>**
3. Provide them with your project number (run this command to get it):
   ```sh
   gcloud projects describe <walkthrough-project-id/> --format="value(projectNumber)"
   ```
4. Wait for confirmation that your project has been granted access

<walkthrough-footnote>
The artifact registry contains the Terraform code and container images needed for deployment. 
Once you receive confirmation of access, you can proceed to the final step.
</walkthrough-footnote>

<!-- #################### STEP 13 #################### -->
<!-- #################### STEP 13 #################### -->

## Pull Terraform Docker Image

Once you've received confirmation of artifact registry access, you need to pull the Terraform Docker image:

```sh
./steps/05_pull_terraform_image.sh <walkthrough-project-id/>
```

This script will:

1. Authenticate to the artifact registry using your service account
2. Pull the Terraform Docker image
3. Save the image information for the deployment step

<walkthrough-footnote>
The Terraform image contains all the infrastructure-as-code that will deploy Google Sync to Cloud to your project. If this step fails, ensure that you've received confirmation that your project has been granted access to the artifact registry.
</walkthrough-footnote>

<!-- #################### STEP 14 #################### -->
<!-- #################### STEP 14 #################### -->

## Run Terraform Deployment

Now that you have the Terraform image, you can run the deployment:

```sh
./steps/06_run_terraform.sh <walkthrough-project-id/>
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

<!-- #################### STEP 15 #################### -->
<!-- #################### STEP 15 #################### -->

## Create Initial User

Now that the infrastructure is deployed, let's create the initial user who will have access to the application:

```sh
./steps/07_create_user.sh <walkthrough-project-id/>
```

This script will:

1. Prompt you for the user's email and name
2. Create a user document in the database
3. Grant the user Cloud Run Invoker permissions
4. Grant the user IAP-secured Web App User permissions

<walkthrough-footnote>
This user will have access to the Sync to Cloud application and will be able to sign in and use all features. You can create additional users later by running this script again with different email addresses.
</walkthrough-footnote>

<!-- #################### STEP 16 #################### -->
<!-- #################### STEP 16 #################### -->

## Grant Domain-wide Delegation for Rclone Service Account

Now, you need to grant domain-wide delegation to the service accounts created by Terraform:

1. First, locate the service account information:

   - Go to [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts?project=<walkthrough-project-id/>) in the Google Cloud Console
   - Find and click on the service account named `sa-sync-to-cloud-rclone@<walkthrough-project-id/>.iam.gserviceaccount.com`
   - Note or copy the Client ID (a numeric value) for this service account

2. Then configure domain-wide delegation:
   - Navigate to the Google Admin Console's [Domain-wide Delegation page](https://admin.google.com/ac/owl/domainwidedelegation)
   - Click "Add new"
   - Enter the service account details:
     - Client ID: Paste the numeric Client ID you copied from the service account
     - OAuth Scopes: `https://www.googleapis.com/auth/drive`
   - Click "Authorize"

<walkthrough-footnote>
The Drive scope (`https://www.googleapis.com/auth/drive`) grants the Rclone Service Account full access to manage files in Google Drive, including creating, editing, moving, and deleting files and folders. This broad access is needed so Rclone can fully handle file transfers and move operations.
</walkthrough-footnote>

<!-- #################### STEP 18 #################### -->
<!-- #################### STEP 18 #################### -->

## Grant Domain-wide Delegation for Worker Service Account

Next, configure domain-wide delegation for the Worker Service Account:

1. First, locate the service account information:
   - Return to [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts?project=<walkthrough-project-id/>) in the Google Cloud Console
   - Find and click on the service account named `sa-sync-to-cloud-worker@<walkthrough-project-id/>.iam.gserviceaccount.com`
   - Note or copy the Client ID for this service account

2. Then configure domain-wide delegation:
   - Return to the [Domain-wide Delegation page](https://admin.google.com/ac/owl/domainwidedelegation)
   - Click "Add new"
   - Enter the service account details:
     - Client ID: Paste the numeric Client ID you copied from the worker service account
     - OAuth Scopes: `https://www.googleapis.com/auth/drive`
   - Click "Authorize"

<walkthrough-footnote>
The Worker Service Account needs the Drive scope (`https://www.googleapis.com/auth/drive`) to access and manage files in Google Drive, including reading files, updating metadata and labels, managing transfers, and coordinating with the Rclone service for efficient file processing.
</walkthrough-footnote>

<!-- #################### STEP 19 #################### -->
<!-- #################### STEP 19 #################### -->

## Grant Domain-wide Delegation for API Service Account

Configure domain-wide delegation for the API Service Account:

1. First, locate the service account information:
   - Return to [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts?project=<walkthrough-project-id/>) in the Google Cloud Console
   - Find and click on the service account named `sa-sync-to-cloud-api@<walkthrough-project-id/>.iam.gserviceaccount.com`
   - Note or copy the Client ID for this service account

2. Then configure domain-wide delegation:
   - Return to the [Domain-wide Delegation page](https://admin.google.com/ac/owl/domainwidedelegation)
   - Click "Add new"
   - Enter the service account details:
     - Client ID: Paste the numeric Client ID you copied from the API service account
     - OAuth Scopes:
       - `https://www.googleapis.com/auth/drive.labels.readonly`
       - `https://www.googleapis.com/auth/cloud-platform`
   - Click "Authorize"

<walkthrough-footnote>
The API Service Account uses these scopes to enable user impersonation for enhanced security:
- `drive.labels.readonly`: Allows users to see only the labels they are permitted to apply
- `cloud-platform`: Allows users to see only the Cloud Storage buckets they have write access to
</walkthrough-footnote>

<!-- #################### STEP 20 #################### -->
<!-- #################### STEP 20 #################### -->

## Assign Storage Admin Role to Worker Service Account

You need to assign the Storage Admin role to the worker service account:

1. Navigate to the [Google Workspace Admin Roles page](https://admin.google.com/ac/roles)
2. Click on "Storage Admin"
3. Click on "Admins"
4. Click on "Assign service accounts"
5. Add the worker service account:
   ```
   sa-sync-to-cloud-worker@<walkthrough-project-id/>.iam.gserviceaccount.com
   ```

<walkthrough-footnote>
This service account permission will be used to access shared drives and give the "organizer" role to the rclone service account when transferring files, ensuring the service account has proper access to the shared drive to move files.
</walkthrough-footnote>

<!-- #################### STEP 21 #################### -->
<!-- #################### STEP 21 #################### -->

## Grant BigQuery Permissions for Drive Inventory Report

The Sync to Cloud application uses BigQuery Drive Inventory Report to identify and process files. You must grant specific permissions to the Worker and API Service Accounts in the Google Cloud project where your BigQuery Drive inventory dataset is located.

1.  **Identify the Project ID**: Determine the Google Cloud Project ID that hosts your BigQuery Drive Inventory Report dataset.
2.  **Navigate to IAM**: Go to the IAM & Admin page of the project containing the BigQuery dataset.
3.  **Grant Access**:
   - Click on "**GRANT ACCESS**".
   - In the "**New principals**" field, add the Worker Service Account: `sa-sync-to-cloud-worker@<walkthrough-project-id/>.iam.gserviceaccount.com`
   - In the "**New principals**" field, add the API Service Account: `sa-sync-to-cloud-api@<walkthrough-project-id/>.iam.gserviceaccount.com`
   - Assign the role "**BigQuery Job User**" (`roles/bigquery.jobUser`). This role must be granted at the **project level**.
   - Click "**ADD ANOTHER ROLE**".
   - Assign the role "**BigQuery Data Viewer**" (`roles/bigquery.dataViewer`). This role can be granted at the **project level** or, for more fine-grained control, directly on the **dataset** containing your Drive inventory report.
   - Click "**SAVE**".

<walkthrough-footnote>
These permissions allow the Worker Service Account to query and read data from your Drive inventory report in BigQuery.
</walkthrough-footnote>

<!-- #################### FINAL STEP #################### -->
<!-- #################### FINAL STEP #################### -->

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

<walkthrough-footnote>
If you need to redeploy or make changes in the future, you can always return to the Cloud Shell and run the deployment scripts again. 
All resources will be managed by Terraform, ensuring consistent and repeatable deployments.
</walkthrough-footnote>
