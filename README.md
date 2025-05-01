# Sync to Cloud Deployment

Deploy Sync to Cloud to your Google Cloud project with just a few steps.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/automatearmy/sync-to-cloud-deploy&cloudshell_tutorial=README.md)

## Overview

This repository provides a simple way to deploy Sync to Cloud to your Google Cloud project. It uses a Docker image containing Terraform configuration that has been pre-built and tested by the Sync to Cloud team.

## Prerequisites

- A Google Cloud project
- Owner access to the Google Cloud project
- Google Workspace admin access (for domain-wide delegation, if needed)

## Deployment Steps

1. Click the "Open in Cloud Shell" button above.
2. When Cloud Shell opens, the deployment script will guide you through the process.
3. You'll be asked to:
   - Log in to your Google Cloud account (if not already logged in)
   - Select your Google Cloud project
   - Set up OAuth credentials
   - Configure Terraform variables
   - Deploy the application

## Configuration

The deployment will prompt you for the following information:

- **Project ID**: Your Google Cloud project ID
- **Region**: The Google Cloud region to deploy to (default: us-central1)
- **API User Email**: Email address for domain-wide delegation (optional)

## Post-Deployment

After deployment is complete, you'll receive:

- The URL of the deployed UI application
- Instructions for setting up domain-wide delegation (if needed)
- Information on how to access and manage your Sync to Cloud instance

## Troubleshooting

If you encounter issues during deployment:

1. Check that you have the necessary permissions on your Google Cloud project
2. Make sure OAuth credentials are set up correctly
3. Review the error message in the Cloud Shell terminal

For additional help, contact team@automatearmy.com.

## About

Sync to Cloud is developed and maintained by Google & Automate Army.
