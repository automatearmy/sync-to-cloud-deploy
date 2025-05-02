#!/bin/bash

# Exit on error
set -e

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"

# Display banner
display_banner "Terraform Configuration Generator" "Creating terraform.tfvars for Google Sync to Cloud deployment"

# Get project ID from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")
PROJECT_NUMBER=$(get_project_number "$PROJECT_ID")

log_step "Creating Terraform configuration file (terraform.tfvars)"
log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Project Number: ${COLOR_BOLD}${PROJECT_NUMBER}${COLOR_RESET}"

# Load Terraform service account email if available
TF_SERVICE_ACCOUNT=""
if [[ -f "tf_sa_env.sh" ]]; then
  source tf_sa_env.sh
  TF_SERVICE_ACCOUNT="$TF_SERVICE_ACCOUNT_EMAIL"
else
  # If not available, construct it based on standard naming
  TF_SERVICE_ACCOUNT="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com"
  log_info "Service account environment file not found, using default: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"
fi

# Ask for region (required)
log_step "Region Configuration"
log_info "Specify the Google Cloud region to deploy the resources."
REGION=$(ask_with_default "Enter region" "us-central1" "Common regions: us-central1, us-east1, us-west1, europe-west1, asia-east1")
log_success "Region set to: ${COLOR_BOLD}${REGION}${COLOR_RESET}"

# Ask for domain-wide delegation email (REQUIRED)
log_step "Domain-wide Delegation Setup (REQUIRED)"
log_info "Google Sync to Cloud requires domain-wide delegation to access Google Drive files."
log_info "You need to provide a service account email that will be used for Drive access."
API_USER_EMAIL=$(ask_required "Enter service account email for domain-wide delegation: " "Domain-wide delegation email is required.")
log_success "API User Email set to: ${COLOR_BOLD}${API_USER_EMAIL}${COLOR_RESET}"
log_info "You will need to configure domain-wide delegation for this service account in Google Workspace."
log_info "Instructions: https://developers.google.com/admin-sdk/directory/v1/guides/delegation"

# Ask for BigQuery Configuration
log_step "BigQuery Configuration"
log_info "Configure BigQuery for Drive inventory reports."

# Ask for BigQuery project ID
BQ_PROJECT_ID=$(ask_with_default "Enter BigQuery project ID" "$PROJECT_ID" "Project where BigQuery dataset will be created (usually the same as your project ID).")
log_success "BigQuery project ID set to: ${COLOR_BOLD}${BQ_PROJECT_ID}${COLOR_RESET}"

# Ask for BigQuery dataset
BQ_DATASET=$(ask_required "Enter BigQuery dataset name: " "BigQuery dataset name is required.")
log_success "BigQuery dataset set to: ${COLOR_BOLD}${BQ_DATASET}${COLOR_RESET}"

# Ask for BigQuery table
BQ_TABLE=$(ask_required "Enter BigQuery table name: " "BigQuery table name is required.")
log_success "BigQuery table set to: ${COLOR_BOLD}${BQ_TABLE}${COLOR_RESET}"

# Create terraform.tfvars file
log_info "Creating terraform.tfvars file..."

cat > terraform.tfvars <<EOL
# Google Cloud Project Configuration
project_id = "${PROJECT_ID}"
terraform_sa = "${TF_SERVICE_ACCOUNT}"
region = "${REGION}"

# Registry settings - DO NOT CHANGE
registry_project = "sync-to-cloud-registry"
registry_region = "us-central1"
repository_name = "sync-to-cloud-app"

# Image names - DO NOT CHANGE
api_image_name = "sync-to-cloud-api"
ui_image_name = "sync-to-cloud-ui"
worker_image_name = "sync-to-cloud-worker"

# Domain-wide delegation
# Leave empty if not using domain-wide delegation
api_user_email = "${API_USER_EMAIL}"

# BigQuery Configuration
bigquery_project_id = "${BQ_PROJECT_ID}"
bigquery_dataset = "${BQ_DATASET}"
bigquery_table = "${BQ_TABLE}"
EOL

log_success "terraform.tfvars file created successfully."
log_info "Configuration file location: ${COLOR_BOLD}$(pwd)/terraform.tfvars${COLOR_RESET}"

# Explain what this file is for
log_step "Configuration Summary"
log_info "The terraform.tfvars file contains configuration values that will be used by Terraform to deploy Google Sync to Cloud."
log_info "Deployment will create the following main resources:"
log_info "1. Google Kubernetes Engine (GKE) cluster for the application"
log_info "2. Cloud Storage buckets for file storage"
log_info "3. Secret Manager entries for credentials"
log_info "4. IAM permissions for components to communicate"
log_info "5. Cloud Run services for the user interface"

# Final message
log_info "Please review the terraform.tfvars file before proceeding to the next step."
