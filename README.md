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

<!-- This file provides an overview of the Sync to Cloud deployment project and instructions for deployment -->

# Google Sync to Cloud Deployment

Deploy Google Sync to Cloud to your Google Cloud project with a streamlined, guided process.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/automatearmy/sync-to-cloud-deploy&cloudshell_tutorial=cloudshell_tutorial.md)

## Overview

Google Sync to Cloud is a powerful tool that helps you seamlessly move files from Google Drive to Google Cloud Storage. This repository provides a guided deployment process using Cloud Shell tutorials and automated scripts.

## Prerequisites

- A Google Cloud project with billing enabled
- **Owner** and **Service Account Token Creator** permissions on the project
- Google Workspace admin access (for domain-wide delegation)
- A admin user account email for domain-wide delegation

## Deployment Process

1. Click the "Open in Cloud Shell" button above.
2. The interactive tutorial will guide you through each step:
   - Select your Google Cloud project
   - Verify permissions and enable required APIs
   - Configure the OAuth consent screen
   - Create OAuth credentials for authentication
   - Set up Terraform infrastructure
   - Deploy the application

The entire process takes approximately 60 minutes to complete.

## What Gets Deployed

The deployment creates the following resources in your Google Cloud project:

- Google Kubernetes Engine (GKE) cluster for the application backend
- Cloud Run services for the user interface
- Cloud Storage buckets for file storage
- Secret Manager secrets for credentials
- IAM permissions for secure component communication

## Configuration Options

During deployment, you'll be prompted for:

- **Region**: Google Cloud region for resource deployment
- **User Account Email**: For domain-wide delegation
- **BigQuery Settings**: With Drive Inventory reporting enabled
  - Project ID
  - Dataset name
  - Table name

## Post-Deployment

After successful deployment, you'll receive:

- URL to access your Google Sync to Cloud application
- Instructions for configuring domain-wide delegation in Google Workspace
- Details about the deployed resources

## Troubleshooting

If you encounter issues during deployment:

1. Ensure you have both Owner and Service Account Token Creator roles
2. Verify billing is enabled for your project
3. Check that the OAuth consent screen is properly configured
4. Make sure your project has access to the Sync to Cloud artifact registry (only authorized universities)

For technical support, contact team@automatearmy.com.

## Security

All deployment scripts are designed with security in mind:
- Scripts are transparent and explain each action they take
- No sensitive data is transmitted outside your Google Cloud project
- All resources are created within your project's security boundaries

## About

Google Sync to Cloud is developed and maintained by Google & Automate Army.
