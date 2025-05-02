#!/bin/bash

# Exit on error
set -e

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"

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

# Configure Docker to use the service account credentials
log_info "Configuring Docker authentication..."
echo "$TOKEN" | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev

# Pull the Terraform Docker image
TERRAFORM_IMAGE="us-central1-docker.pkg.dev/sync-to-cloud-registry/sync-to-cloud-app/sync-to-cloud-terraform:latest"
log_info "Image: ${COLOR_BOLD}${TERRAFORM_IMAGE}${COLOR_RESET}"

if ! docker pull "${TERRAFORM_IMAGE}"; then
  log_error "Failed to pull the Terraform Docker image."
  log_info "Please confirm with the Sync to Cloud team that your project (${PROJECT_ID}) has access to the artifact registry."
  exit 1
fi

# Save the image name to a file for later use
echo "export TERRAFORM_IMAGE=${TERRAFORM_IMAGE}" > terraform_image_env.sh
log_success "Terraform Docker image pulled successfully and saved to terraform_image_env.sh"
log_info "You can now proceed to run Terraform commands using the run_terraform.sh script."