#!/bin/bash

# Exit on error
set -e

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"

# Display banner
display_banner "Terraform Infrastructure Setup" "Setting up service account and state bucket for Terraform"

# Check required commands
check_command "gcloud"
check_command "gsutil"
check_command "jq"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")
log_info "Using project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"

# ----- PART 1: Create Terraform Service Account -----
log_step "Creating Terraform Service Account"

# Define service account name
SA_NAME="terraform-admin"
SA_DISPLAY_NAME="Terraform Admin Service Account"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

log_info "Service Account Name: ${COLOR_BOLD}${SA_NAME}${COLOR_RESET}"
log_info "Service Account Email: ${COLOR_BOLD}${SA_EMAIL}${COLOR_RESET}"

# Check if service account already exists
if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
  log_success "Service account '$SA_EMAIL' already exists."
else
  log_info "Creating service account '$SA_NAME'..."
  
  # Create the service account
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="$SA_DISPLAY_NAME" \
    --description="Service Account for Terraform administration" \
    --project="$PROJECT_ID"
  
  log_success "Service account '$SA_EMAIL' created successfully."
fi

# Grant Owner role to the service account
log_info "Granting 'roles/owner' to service account '$SA_EMAIL'..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/owner" \
  --condition=None

log_success "Added 'roles/owner' role to service account '$SA_EMAIL'."

# Grant current user permission to impersonate the service account
USER_EMAIL=$(gcloud config get-value account 2>/dev/null)
log_info "Granting current user '$USER_EMAIL' permission to impersonate the service account..."

# Check if user already has Service Account Token Creator role
if gcloud projects get-iam-policy "$PROJECT_ID" --format=json | \
   jq -e --arg user "user:$USER_EMAIL" --arg sa "serviceAccount:$SA_EMAIL" \
      '.bindings[] | select(.role == "roles/iam.serviceAccountTokenCreator") | .members[] | select(. == $user)' &>/dev/null; then
  log_success "User '$USER_EMAIL' already has 'roles/iam.serviceAccountTokenCreator' role."
else
  # Grant Service Account Token Creator role
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="user:$USER_EMAIL" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --condition=None
  
  log_success "Granted 'roles/iam.serviceAccountTokenCreator' role to user '$USER_EMAIL'."
fi

# Save service account email to a file for later use
echo "export TF_SERVICE_ACCOUNT_EMAIL=${SA_EMAIL}" > tf_sa_env.sh
log_info "Service account email saved to tf_sa_env.sh for later use."

# ----- PART 2: Create Terraform State Bucket -----
log_step "Creating GCS bucket for Terraform state"

# Define GCS bucket location
GCS_LOCATION="US"

# Generate bucket name
BUCKET_NAME="terraform-state-${PROJECT_ID}"

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
echo "export TF_STATE_BUCKET=${BUCKET_NAME}" >> tf_sa_env.sh
log_info "Bucket name appended to tf_sa_env.sh for later use."

# Final message
log_step "Terraform Infrastructure Setup Completed!"
display_success "Terraform service account and state bucket are ready"
log_info "Service Account: ${COLOR_BOLD}${SA_EMAIL}${COLOR_RESET}"
log_info "State Bucket: ${COLOR_BOLD}gs://${BUCKET_NAME}${COLOR_RESET}"
log_info "You can now proceed to the next step of the deployment process."
