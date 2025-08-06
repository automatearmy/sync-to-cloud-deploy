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

# This script helps grant BigQuery permissions to Sync to Cloud service accounts
# It provides the exact gcloud commands needed to grant access in the BigQuery project

# Exit on error
set -e

# Source common utilities and environment variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/env.sh"

# Display banner
display_banner "BigQuery Access Configuration" "Grant BigQuery permissions to Sync to Cloud service accounts"

# Check required commands
check_command "gcloud"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")

log_info "Sync to Cloud Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"

# Define service accounts
WORKER_SA="sa-sync-to-cloud-worker@${PROJECT_ID}.iam.gserviceaccount.com"
API_SA="sa-sync-to-cloud-api@${PROJECT_ID}.iam.gserviceaccount.com"

log_info "Worker Service Account: ${COLOR_BOLD}${WORKER_SA}${COLOR_RESET}"
log_info "API Service Account: ${COLOR_BOLD}${API_SA}${COLOR_RESET}"

# Get BigQuery project information from terraform.tfvars if available
BQ_PROJECT_ID=""
BQ_DATASET=""
BQ_TABLE=""

if [[ -f "terraform.tfvars" ]]; then
  log_info "Reading BigQuery configuration from terraform.tfvars..."
  
  # Extract BigQuery configuration
  BQ_PROJECT_ID=$(grep "^bigquery_project_id" terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
  BQ_DATASET=$(grep "^bigquery_dataset" terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
  BQ_TABLE=$(grep "^bigquery_table" terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
  
  if [[ -n "$BQ_PROJECT_ID" ]]; then
    log_success "Found BigQuery configuration:"
    log_info "  BigQuery Project ID: ${COLOR_BOLD}${BQ_PROJECT_ID}${COLOR_RESET}"
    log_info "  BigQuery Dataset: ${COLOR_BOLD}${BQ_DATASET}${COLOR_RESET}"
    log_info "  BigQuery Table: ${COLOR_BOLD}${BQ_TABLE}${COLOR_RESET}"
  fi
else
  log_warning "terraform.tfvars not found. You'll need to provide BigQuery project information manually."
fi

# Ask for BigQuery project if not found
if [[ -z "$BQ_PROJECT_ID" ]]; then
  echo ""
  BQ_PROJECT_ID=$(ask_required "Enter your BigQuery project ID: " "BigQuery project ID is required.")
  log_success "BigQuery project ID set to: ${COLOR_BOLD}${BQ_PROJECT_ID}${COLOR_RESET}"
fi

echo ""
log_step "BigQuery Permission Commands"
log_info "You need to run the following commands to grant BigQuery permissions."
log_info "These commands should be run in the context of your BigQuery project: ${COLOR_BOLD}${BQ_PROJECT_ID}${COLOR_RESET}"

echo ""
log_info "${COLOR_BOLD}Option 1: Grant permissions at PROJECT level${COLOR_RESET}"
echo ""
echo "# Set the BigQuery project as active"
echo "gcloud config set project ${BQ_PROJECT_ID}"
echo ""
echo "# Grant BigQuery Job User role to Worker Service Account"
echo "gcloud projects add-iam-policy-binding ${BQ_PROJECT_ID} \\"
echo "  --member=\"serviceAccount:${WORKER_SA}\" \\"
echo "  --role=\"roles/bigquery.jobUser\""
echo ""
echo "# Grant BigQuery Data Viewer role to Worker Service Account"
echo "gcloud projects add-iam-policy-binding ${BQ_PROJECT_ID} \\"
echo "  --member=\"serviceAccount:${WORKER_SA}\" \\"
echo "  --role=\"roles/bigquery.dataViewer\""
echo ""
echo "# Grant BigQuery Job User role to API Service Account"
echo "gcloud projects add-iam-policy-binding ${BQ_PROJECT_ID} \\"
echo "  --member=\"serviceAccount:${API_SA}\" \\"
echo "  --role=\"roles/bigquery.jobUser\""
echo ""
echo "# Grant BigQuery Data Viewer role to API Service Account"
echo "gcloud projects add-iam-policy-binding ${BQ_PROJECT_ID} \\"
echo "  --member=\"serviceAccount:${API_SA}\" \\"
echo "  --role=\"roles/bigquery.dataViewer\""

if [[ -n "$BQ_DATASET" ]]; then
  echo ""
  log_info "${COLOR_BOLD}Option 2: Grant permissions at DATASET level (more restrictive)${COLOR_RESET}"
  echo ""
  echo "# Set the BigQuery project as active"
  echo "gcloud config set project ${BQ_PROJECT_ID}"
  echo ""
  echo "# Grant BigQuery Job User role to Worker Service Account (must be at project level)"
  echo "gcloud projects add-iam-policy-binding ${BQ_PROJECT_ID} \\"
  echo "  --member=\"serviceAccount:${WORKER_SA}\" \\"
  echo "  --role=\"roles/bigquery.jobUser\""
  echo ""
  echo "# Grant BigQuery Job User role to API Service Account (must be at project level)"
  echo "gcloud projects add-iam-policy-binding ${BQ_PROJECT_ID} \\"
  echo "  --member=\"serviceAccount:${API_SA}\" \\"
  echo "  --role=\"roles/bigquery.jobUser\""
  echo ""
  echo "# Grant BigQuery Data Viewer role to Worker Service Account at dataset level"
  echo "bq add-iam-policy-binding \\"
  echo "  --member=\"serviceAccount:${WORKER_SA}\" \\"
  echo "  --role=\"roles/bigquery.dataViewer\" \\"
  echo "  ${BQ_PROJECT_ID}:${BQ_DATASET}"
  echo ""
  echo "# Grant BigQuery Data Viewer role to API Service Account at dataset level"
  echo "bq add-iam-policy-binding \\"
  echo "  --member=\"serviceAccount:${API_SA}\" \\"
  echo "  --role=\"roles/bigquery.dataViewer\" \\"
  echo "  ${BQ_PROJECT_ID}:${BQ_DATASET}"
fi

echo ""
log_step "Next Steps"
log_info "1. Copy and run the commands above in your terminal"
log_info "2. Make sure you're authenticated with sufficient permissions in the BigQuery project"
log_info "3. Choose either project-level or dataset-level permissions based on your security requirements"
log_info "4. Verify the permissions were granted successfully"

echo ""
log_success "BigQuery access configuration commands generated successfully!"
log_info "After running these commands, your Sync to Cloud service accounts will have access to query your Drive inventory data."
