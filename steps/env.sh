#!/bin/bash

# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script defines environment variables used across the Sync to Cloud deployment scripts
# Contains configuration for registry settings, image names, and secret identifiers

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
export STATE_BUCKET_SUFIX="terraform-state"

# Secrets
export API_CLIENT_ID_SECRET="sync-to-cloud-api-client-id"
export API_CLIENT_SECRET_SECRET="sync-to-cloud-api-client-secret"
export UI_CLIENT_ID_SECRET="sync-to-cloud-ui-client-id"
export UI_CLIENT_SECRET_SECRET="sync-to-cloud-ui-client-secret"

# Default region
export DEFAULT_REGION="us-central1"
