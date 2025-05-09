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

# This script creates the terraform.tfvars configuration file for Sync to Cloud deployment
# It prompts for necessary configuration values and generates the file with proper settings

# Exit on error
set -e

# Source common utilities and environment variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/env.sh"

# Display banner
display_banner "Terraform Configuration Generator" "Creating terraform.tfvars for Google Sync to Cloud deployment"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")
PROJECT_NUMBER=$(get_project_number "$PROJECT_ID")
TF_SERVICE_ACCOUNT="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com"

log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Project Number: ${COLOR_BOLD}${PROJECT_NUMBER}${COLOR_RESET}"
log_info "Terraform Service Account: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"

log_step "Creating terraform.tfvars"

# Ask for region (required)
log_step "Region Configuration"
log_info "Specify the Google Cloud region to deploy the resources."
REGION=$(ask_with_default "Enter region" "us-central1" "Common regions: us-central1, us-east1, us-west1, europe-west1, asia-east1")
log_success "Region set to: ${COLOR_BOLD}${REGION}${COLOR_RESET}"

# Ask for workspace admin user
log_step "Workspace Admin User Configuration"
log_info "Google Sync to Cloud requires a Google Workspace admin user account."
log_info "This should be a regular user email (like user@domain.edu) with admin privileges in your Google Workspace."
log_info "The API will use this account to access and list labels across your entire organization."
WORKSPACE_ADMIN_USER_EMAIL=$(ask_required "Enter user account email for listing labels: " "E-mail is required.")
log_success "Workspace Admin User set to: ${COLOR_BOLD}${API_USER_EMAIL}${COLOR_RESET}"

# Ask for environment name
log_step "Environment Configuration"
log_info "Specify the deployment environment name."
ENVIRONMENT=$(ask_with_default "Enter environment name" "production" "Common environments: development, staging, production")
log_success "Environment set to: ${COLOR_BOLD}${ENVIRONMENT}${COLOR_RESET}"

# Ask for BigQuery Configuration
log_step "BigQuery Configuration"
log_info "Google Sync to Cloud requires access to a BigQuery project where your Drive inventory report is configured and running."
log_info "This allows the application to pull file metadata and run transfer operations."

# Ask for BigQuery project ID
BQ_PROJECT_ID=$(ask_required "Enter BigQuery project ID: " "BigQuery project ID is required.")
log_success "BigQuery project ID set to: ${COLOR_BOLD}${BQ_PROJECT_ID}${COLOR_RESET}"
echo ""

# Ask for BigQuery dataset
BQ_DATASET=$(ask_required "Enter BigQuery dataset name: " "BigQuery dataset name is required.")
log_success "BigQuery dataset set to: ${COLOR_BOLD}${BQ_DATASET}${COLOR_RESET}"
echo ""

# Ask for BigQuery table
BQ_TABLE=$(ask_required "Enter BigQuery table name: " "BigQuery table name is required.")
log_success "BigQuery table set to: ${COLOR_BOLD}${BQ_TABLE}${COLOR_RESET}"
echo ""

# Create terraform.tfvars file
log_info "Creating terraform.tfvars file..."

cat > terraform.tfvars <<EOL
# -------------------- Project Variables --------------------
project_id = "${PROJECT_ID}"
terraform_sa = "${TF_SERVICE_ACCOUNT}"
region = "${REGION}"
environment = "${ENVIRONMENT}"

# -------------------- Registry Variables --------------------
registry_project = "${REGISTRY_PROJECT_ID}"
registry_region = "${REGISTRY_REGION}"
repository_name = "${REGISTRY_REPOSITORY_NAME}"

# -------------------- Image Variables --------------------
api_image_name = "${API_IMAGE_NAME}"
ui_image_name = "${UI_IMAGE_NAME}"
worker_image_name = "${WORKER_IMAGE_NAME}"

# -------------------- API/Service Configuration --------------------
workspace_admin_user_email = "${WORKSPACE_ADMIN_USER_EMAIL}"

# -------------------- BigQuery Configuration --------------------
bigquery_project_id = "${BQ_PROJECT_ID}"
bigquery_dataset = "${BQ_DATASET}"
bigquery_table = "${BQ_TABLE}"
EOL

# Verify the file was created
if [[ -f "terraform.tfvars" ]]; then
  log_success "terraform.tfvars file created locally."
else
  log_error "Failed to create terraform.tfvars file locally."
  exit 1
fi

# Create or update the secret in Secret Manager
log_step "Storing terraform.tfvars in Secret Manager"
if gcloud secrets describe "${TF_VARS_SECRET_NAME}" --project="${PROJECT_ID}" &>/dev/null; then
  log_info "Secret ${TF_VARS_SECRET_NAME} already exists. Adding a new version..."
  gcloud secrets versions add "${TF_VARS_SECRET_NAME}" --data-file="terraform.tfvars" --project="${PROJECT_ID}"
  log_success "New version added to secret ${TF_VARS_SECRET_NAME}."
else
  log_info "Secret ${TF_VARS_SECRET_NAME} does not exist. Creating new secret..."
  gcloud secrets create "${TF_VARS_SECRET_NAME}" --replication-policy="automatic" --data-file="terraform.tfvars" --project="${PROJECT_ID}"
  log_success "Secret ${TF_VARS_SECRET_NAME} created and initial version added."
fi

log_step "Terraform variables configuration completed successfully!"
log_info "Local configuration file: ${COLOR_BOLD}$(pwd)/terraform.tfvars${COLOR_RESET}"
log_info "Configuration also stored in Secret Manager: ${COLOR_BOLD}${TF_VARS_SECRET_NAME}${COLOR_RESET}"
log_info "You can now proceed to the next step."
