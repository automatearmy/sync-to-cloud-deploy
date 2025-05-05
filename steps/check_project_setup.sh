#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Source common utilities and environment variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/env.sh"

# Display banner
display_banner "Project Setup Verification" "Verifying your Google Cloud project setup for Sync to Cloud"

# Check required commands
check_command "gcloud"
check_command "jq"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")
USER_EMAIL=$(get_user_email)

log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "User: ${COLOR_BOLD}${USER_EMAIL}${COLOR_RESET}"

# Check permissions
log_step "Checking required permissions"

# Get IAM policy
policy_json=$(gcloud projects get-iam-policy "$PROJECT_ID" --format=json)

# Check for Owner role
has_owner=false
if echo "$policy_json" | jq -e --arg user "user:$USER_EMAIL" '.bindings[] | select(.role == "roles/owner") | .members[] | select(. == $user)' &>/dev/null; then
  log_success "User has 'roles/owner' role."
  has_owner=true
else
  log_error "User '$USER_EMAIL' does not have 'roles/owner' role on project '$PROJECT_ID'."
  log_info "Please grant the Owner role to '$USER_EMAIL' in the IAM settings:"
  log_info "https://console.cloud.google.com/iam-admin/iam?project=$PROJECT_ID"
  exit 1
fi

# Check for Service Account Token Creator role
has_token_creator=false
if $has_owner || echo "$policy_json" | jq -e --arg user "user:$USER_EMAIL" '.bindings[] | select(.role == "roles/iam.serviceAccountTokenCreator") | .members[] | select(. == $user)' &>/dev/null; then
  log_success "User has 'roles/iam.serviceAccountTokenCreator' role (or inherited via Owner)."
  has_token_creator=true
else
  log_error "User '$USER_EMAIL' does not have 'roles/iam.serviceAccountTokenCreator' role on project '$PROJECT_ID'."
  log_info "Please grant the Service Account Token Creator role to '$USER_EMAIL' in the IAM settings:"
  log_info "https://console.cloud.google.com/iam-admin/iam?project=$PROJECT_ID"
  exit 1
fi

# Check billing
log_step "Checking billing status"

# Check if billing is enabled
if gcloud billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null | grep -q "True"; then
  log_success "Billing is enabled for project '$PROJECT_ID'."
else
  log_error "Billing is not enabled for project '$PROJECT_ID'."
  log_info "Please enable billing for the project in the Cloud Console:"
  log_info "https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
  exit 1
fi

# Enable required APIs
log_step "Enabling required Google Cloud APIs"

# List of APIs to enable to create service accounts
apis=(
  "run.googleapis.com"
  "cloudidentity.googleapis.com"
  "cloudresourcemanager.googleapis.com"
  "compute.googleapis.com"
  "iam.googleapis.com"
  "iap.googleapis.com"
  "iamcredentials.googleapis.com"
  "secretmanager.googleapis.com"
  "serviceusage.googleapis.com"
)

log_info "Enabling ${#apis[@]} required APIs. This may take a few minutes..."

# Enable APIs
gcloud services enable "${apis[@]}" --project="$PROJECT_ID"

log_success "All required APIs enabled successfully."

# Final message
log_step "Project setup check completed successfully!"
log_info "Your project ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET} is ready for Google Sync to Cloud deployment."
log_info "You can now proceed to the next step."
