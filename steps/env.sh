#!/bin/bash

#
# Environment variables for Google Sync to Cloud deployment
#

# Registry configuration
export REGISTRY_PROJECT_ID="sync-to-cloud-registry"
export REGISTRY_REGION="us-central1"
export REGISTRY_REPOSITORY_NAME="sync-to-cloud-app" 
export REGISTRY_HOSTNAME="${REGISTRY_REGION}-docker.pkg.dev"

# Docker images
export TERRAFORM_IMAGE_NAME="sync-to-cloud-terraform"
export TERRAFORM_IMAGE_TAG="latest"
export TERRAFORM_IMAGE="${REGISTRY_HOSTNAME}/${REGISTRY_PROJECT_ID}/${REGISTRY_REPOSITORY_NAME}/${TERRAFORM_IMAGE_NAME}:${TERRAFORM_IMAGE_TAG}"

export API_IMAGE_NAME="sync-to-cloud-api"
export UI_IMAGE_NAME="sync-to-cloud-ui"
export WORKER_IMAGE_NAME="sync-to-cloud-worker"

# Service account and bucket naming
export SA_NAME="terraform-admin"
export STATE_BUCKET_PREFIX="terraform-state-"

# Secrets
export API_CLIENT_ID_SECRET="sync-to-cloud-api-client-id"
export API_CLIENT_SECRET_SECRET="sync-to-cloud-api-client-secret"
export UI_CLIENT_ID_SECRET="sync-to-cloud-ui-client-id"
export UI_CLIENT_SECRET_SECRET="sync-to-cloud-ui-client-secret"

# Default region
export DEFAULT_REGION="us-central1"
