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

# This script pulls the Terraform Docker image from the artifact registry
# It handles authentication with service account impersonation for secure access

# Exit on error
set -e

# Source common utilities and environment variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/env.sh"

# Display banner
display_banner "Terraform Image Puller" "Pulling the Terraform Docker image from artifact registry"

# Check required commands
check_command "gcloud"
check_command "docker"
check_command "jq"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")

# Get terraform service account email from file or use default
TF_SERVICE_ACCOUNT=""
if [[ -f "tf_sa_env.sh" ]]; then
  source tf_sa_env.sh
  TF_SERVICE_ACCOUNT="$TF_SERVICE_ACCOUNT_EMAIL"
else
  # If not available, construct it based on standard naming
  TF_SERVICE_ACCOUNT="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com"
  log_info "Service account environment file not found, using default: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"
fi

log_step "Pulling Terraform Docker Image"
log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Service Account: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"

# Verify access to artifact registry
log_step "Checking access to artifact registry"
log_info "Verifying you have access to the Sync to Cloud artifact registry..."

# Get short-lived access token for the Terraform service account
log_info "Generating access token for service account impersonation..."
TOKEN=$(gcloud auth print-access-token --impersonate-service-account="${TF_SERVICE_ACCOUNT}")

if [[ -z "$TOKEN" ]]; then
  log_error "Failed to generate access token for service account impersonation."
  log_info "Please ensure you have the Service Account Token Creator role and try again."
  exit 1
fi

# Configure Docker to use the service account credentials via isolated config
log_info "Configuring Docker authentication with temporary config..."
export DOCKER_CONFIG=$(mktemp -d)
echo "$TOKEN" | docker --config "$DOCKER_CONFIG" login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev

# Pull the Terraform Docker image
log_info "Image: ${COLOR_BOLD}${TERRAFORM_IMAGE}${COLOR_RESET}"

if ! docker --config "$DOCKER_CONFIG" pull "${TERRAFORM_IMAGE}"; then
  log_error "Failed to pull the Terraform Docker image."
  log_info "Please confirm with the Sync to Cloud team that your project (${PROJECT_ID}) has access to the artifact registry."
  rm -rf "$DOCKER_CONFIG"
  exit 1
fi

# Clean up Docker config
rm -rf "$DOCKER_CONFIG"


log_success "Terraform Docker image pulled successfully"
log_info "You can now proceed to run Terraform commands using the run_terraform.sh script."
