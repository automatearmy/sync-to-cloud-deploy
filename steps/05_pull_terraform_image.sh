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
PROJECT_NUMBER=$(get_project_number "$PROJECT_ID")
TF_SERVICE_ACCOUNT="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com"

log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Project Number: ${COLOR_BOLD}${PROJECT_NUMBER}${COLOR_RESET}"
log_info "Terraform Service Account: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"

# Verify access to docker and service account impersonation
log_step "Authenticating with Docker and Service Account"
log_info "Verifying Docker installation and generating credentials for ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"

# Get short-lived access token for the Terraform service account
log_info "Generating access token for service account impersonation..."
TOKEN=$(gcloud auth print-access-token --impersonate-service-account="${TF_SERVICE_ACCOUNT}" 2>/dev/null)

if [[ -n "$TOKEN" ]]; then
  log_success "Successfully generated access token for service account impersonation."
else
  log_error "Failed to generate access token for service account impersonation."
  log_info "Please ensure you have the Service Account Token Creator role and try again."
  exit 1
fi

# Verify access to docker
log_step "Authenticating with Docker"
log_info "Logging into Docker and with service account credentials"

# Configure Docker to use the service account credentials via isolated config
log_info "Configuring Docker authentication with temporary config..."
export DOCKER_CONFIG=$(mktemp -d)
if ! echo "$TOKEN" | docker --config "$DOCKER_CONFIG" login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev >/dev/null 2>&1; then
  log_error "Failed to authenticate with docker registry"
  exit 1
fi
log_success "Successfully authenticated with docker registry"

# Pull Terraform image
log_step "Pulling Terraform Image"
log_info "Pulling Terraform image from Sync to Cloud artifact registry"

# Pull the Terraform Docker image
log_info "Image: ${COLOR_BOLD}${TERRAFORM_IMAGE}${COLOR_RESET}"

if docker --config "$DOCKER_CONFIG" pull "${TERRAFORM_IMAGE}"; then
  log_success "Successfully pulled Terraform Docker image"
else
  log_error "Failed to pull the Terraform Docker image."
  log_info "Please confirm with the Sync to Cloud team that your project (${PROJECT_ID}) has access to the artifact registry."
  rm -rf "$DOCKER_CONFIG"
  exit 1
fi

# Pull Terraform image
log_step "Cleaning Docker Configuration"
log_info "Cleaning up temporary Docker configuration"

# Clean up Docker config
rm -rf "$DOCKER_CONFIG"
log_success "Cleaned Docker configuration files"

log_step "Docker image pull completed successfully!"
log_info "Image: ${COLOR_BOLD}${TERRAFORM_IMAGE}${COLOR_RESET}"
log_info "You can now proceed to the next step."