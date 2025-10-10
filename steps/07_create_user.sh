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

# This script creates an initial user in the database for Google Sync to Cloud
# It creates a user document in the users collection and grants necessary IAM permissions

# Exit on error
set -e

# Source common utilities and environment variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/env.sh"

# Display banner
display_banner "User Setup" "Creating initial user for Google Sync to Cloud"

# Check required commands
check_command "gcloud"
check_command "curl"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")
PROJECT_NUMBER=$(get_project_number "$PROJECT_ID")

log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Project Number: ${COLOR_BOLD}${PROJECT_NUMBER}${COLOR_RESET}"

# Get user input
log_step "User Information"
log_info "Please provide the details for the initial user."

USER_EMAIL=$(ask_required "Enter user email: " "User email is required.")
USER_NAME=$(ask_required "Enter user name: " "User name is required.")

# Get current timestamp in RFC3339 format
CURRENT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log_info "User email: ${COLOR_BOLD}${USER_EMAIL}${COLOR_RESET}"
log_info "User name: ${COLOR_BOLD}${USER_NAME}${COLOR_RESET}"

# Create the user document
log_step "Creating user in database"

# Get access token for API authentication
ACCESS_TOKEN=$(gcloud auth print-access-token)

# Construct the document
FIRESTORE_DOC='{
  "fields": {
    "created_at": {
      "timestampValue": "'${CURRENT_TIMESTAMP}'"
    },
    "display_name": {
      "stringValue": "'${USER_NAME}'"
    },
    "email": {
      "stringValue": "'${USER_EMAIL}'"
    },
    "id": {
      "stringValue": "'${USER_EMAIL}'"
    },
    "last_login_at": {
      "nullValue": null
    },
    "picture": {
      "nullValue": null
    },
    "role_id": {
      "nullValue": null
    },
    "status": {
      "stringValue": "pending"
    },
    "updated_at": {
      "timestampValue": "'${CURRENT_TIMESTAMP}'"
    }
  }
}'

# Create the document using Firestore REST API
FIRESTORE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users?documentId=${USER_EMAIL}"

log_info "Creating user document in database..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${FIRESTORE_URL}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${FIRESTORE_DOC}")

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
# Extract response body (everything except last line)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" ]]; then
  log_success "User created successfully in database!"
  log_info "User ID: ${COLOR_BOLD}${USER_EMAIL}${COLOR_RESET}"
  log_info "Status: ${COLOR_BOLD}pending${COLOR_RESET}"
elif [[ "$HTTP_CODE" == "409" ]]; then
  log_warning "User already exists in database."
  log_info "User ID: ${COLOR_BOLD}${USER_EMAIL}${COLOR_RESET}"
else
  log_error "Failed to create user in database. HTTP Status: $HTTP_CODE"
  log_error "Response: $RESPONSE_BODY"
  exit 1
fi

# Grant IAM permissions
log_step "Granting IAM Permissions"

log_info "Granting Cloud Run Invoker role..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="user:${USER_EMAIL}" \
  --role="roles/run.invoker" \
  --quiet > /dev/null 2>&1

log_success "Cloud Run Invoker role granted."

log_info "Granting IAP-secured Web App User role..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="user:${USER_EMAIL}" \
  --role="roles/iap.httpsResourceAccessor" \
  --quiet > /dev/null 2>&1

log_success "IAP-secured Web App User role granted."

# Final message
log_step "User setup completed successfully!"
log_info "The user has been created and granted necessary permissions."
log_info "Email: ${COLOR_BOLD}${USER_EMAIL}${COLOR_RESET}"
log_info "Name: ${COLOR_BOLD}${USER_NAME}${COLOR_RESET}"
log_info "Permissions:"
log_info "  - Cloud Run Invoker"
log_info "  - IAP-secured Web App User"
log_info "You can now proceed to the next step."
