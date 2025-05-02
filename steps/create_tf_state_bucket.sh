#!/bin/bash

# Exit on error
set -e

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"

# Display banner
display_banner "Terraform State Bucket Creator" "Creating GCS bucket for Terraform state storage"

# Check required commands
check_command "gsutil"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")
log_info "Using project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"

# Define GCS bucket location
GCS_LOCATION="US"

# Generate bucket name
BUCKET_NAME="terraform-state-${PROJECT_ID}"

log_step "Creating GCS bucket for Terraform state"
log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Bucket Name: ${COLOR_BOLD}${BUCKET_NAME}${COLOR_RESET}"
log_info "Location: ${COLOR_BOLD}${GCS_LOCATION}${COLOR_RESET}"

# Check if bucket already exists
if gsutil ls -b "gs://${BUCKET_NAME}" &>/dev/null; then
  log_success "Bucket 'gs://${BUCKET_NAME}' already exists."
  
  # Ensure versioning is enabled
  log_info "Ensuring versioning is enabled on the existing bucket..."
  if gsutil versioning get "gs://${BUCKET_NAME}" | grep -q "Enabled"; then
    log_success "Versioning is already enabled on the bucket."
  else
    log_info "Enabling versioning on the bucket..."
    gsutil versioning set on "gs://${BUCKET_NAME}"
    log_success "Versioning enabled on the bucket."
  fi
else
  log_info "Creating new GCS bucket 'gs://${BUCKET_NAME}'..."
  
  # Create the bucket
  gsutil mb -p "${PROJECT_ID}" -l "${GCS_LOCATION}" "gs://${BUCKET_NAME}"
  log_success "Bucket 'gs://${BUCKET_NAME}' created successfully."
  
  # Enable versioning
  log_info "Enabling versioning on the bucket..."
  gsutil versioning set on "gs://${BUCKET_NAME}"
  log_success "Versioning enabled on the bucket."
fi

# Save bucket name to a file for later use
echo "export TF_STATE_BUCKET=${BUCKET_NAME}" > tf_state_env.sh
log_info "Bucket name saved to tf_state_env.sh for later use."

# Final message
log_step "Terraform state bucket setup completed!"
log_success "Your Terraform state will be stored in: gs://${BUCKET_NAME}"
log_info "This provides versioning and remote state storage for your Terraform deployment."
