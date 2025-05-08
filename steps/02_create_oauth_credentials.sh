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

# This script manages the OAuth client credentials for Sync to Cloud
# It stores API and UI OAuth client credentials securely in Secret Manager

# Exit on error
set -e

# Source common utilities and environment variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/env.sh"

# Display banner
display_banner "OAuth Credentials Manager" "Storing OAuth client credentials for Google Sync to Cloud"

# Check required commands
check_command "gcloud"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")
PROJECT_NUMBER=$(get_project_number "$PROJECT_ID")

log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Project Number: ${COLOR_BOLD}${PROJECT_NUMBER}${COLOR_RESET}"

# --- API OAuth Client (Desktop App) ---
log_step "API OAuth Client (Desktop App)"

# Check if secrets exist
API_CLIENT_ID_EXISTS=$(gcloud secrets describe "$API_CLIENT_ID_SECRET" --project="$PROJECT_ID" 2>/dev/null || echo "")
API_CLIENT_SECRET_EXISTS=$(gcloud secrets describe "$API_CLIENT_SECRET_SECRET" --project="$PROJECT_ID" 2>/dev/null || echo "")

if [[ -n "$API_CLIENT_ID_EXISTS" && -n "$API_CLIENT_SECRET_EXISTS" ]]; then
  log_success "API OAuth client secrets already exist in Secret Manager."
else
  log_info "Please enter the client ID and secret for your Desktop App OAuth client:"
  
  # Get client ID and secret from user
  API_CLIENT_ID=$(ask_required "Enter API Client ID: " "Client ID is required.")
  API_CLIENT_SECRET=$(ask_required "Enter API Client Secret: " "Client Secret is required.")
  
  # Store in Secret Manager
  log_info "Storing API client credentials in Secret Manager..."
  
  # Create secrets if they don't exist
  if [[ -z "$API_CLIENT_ID_EXISTS" ]]; then
    gcloud secrets create "$API_CLIENT_ID_SECRET" \
      --replication-policy="automatic" \
      --project="$PROJECT_ID"
  fi
  
  if [[ -z "$API_CLIENT_SECRET_EXISTS" ]]; then
    gcloud secrets create "$API_CLIENT_SECRET_SECRET" \
      --replication-policy="automatic" \
      --project="$PROJECT_ID"
  fi
  
  # Update secret values
  echo -n "$API_CLIENT_ID" | gcloud secrets versions add "$API_CLIENT_ID_SECRET" \
    --data-file=- \
    --project="$PROJECT_ID"
  
  echo -n "$API_CLIENT_SECRET" | gcloud secrets versions add "$API_CLIENT_SECRET_SECRET" \
    --data-file=- \
    --project="$PROJECT_ID"
  
  log_success "API OAuth client credentials stored in Secret Manager."
fi

# --- UI OAuth Client (Web App) ---
log_step "UI OAuth Client (Web App)"

# Check if secrets exist
UI_CLIENT_ID_EXISTS=$(gcloud secrets describe "$UI_CLIENT_ID_SECRET" --project="$PROJECT_ID" 2>/dev/null || echo "")
UI_CLIENT_SECRET_EXISTS=$(gcloud secrets describe "$UI_CLIENT_SECRET_SECRET" --project="$PROJECT_ID" 2>/dev/null || echo "")

if [[ -n "$UI_CLIENT_ID_EXISTS" && -n "$UI_CLIENT_SECRET_EXISTS" ]]; then
  log_success "UI OAuth client secrets already exist in Secret Manager."
else
  log_info "Please enter the client ID and secret for your Web Application OAuth client:"
  
  # Get client ID and secret from user
  UI_CLIENT_ID=$(ask_required "Enter UI Client ID: " "Client ID is required.")
  UI_CLIENT_SECRET=$(ask_required "Enter UI Client Secret: " "Client Secret is required.")
  
  # Store in Secret Manager
  log_info "Storing UI client credentials in Secret Manager..."
  
  # Create secrets if they don't exist
  if [[ -z "$UI_CLIENT_ID_EXISTS" ]]; then
    gcloud secrets create "$UI_CLIENT_ID_SECRET" \
      --replication-policy="automatic" \
      --project="$PROJECT_ID"
  fi
  
  if [[ -z "$UI_CLIENT_SECRET_EXISTS" ]]; then
    gcloud secrets create "$UI_CLIENT_SECRET_SECRET" \
      --replication-policy="automatic" \
      --project="$PROJECT_ID"
  fi
  
  # Update secret values
  echo -n "$UI_CLIENT_ID" | gcloud secrets versions add "$UI_CLIENT_ID_SECRET" \
    --data-file=- \
    --project="$PROJECT_ID"
  
  echo -n "$UI_CLIENT_SECRET" | gcloud secrets versions add "$UI_CLIENT_SECRET_SECRET" \
    --data-file=- \
    --project="$PROJECT_ID"
  
  log_success "UI OAuth client credentials stored in Secret Manager."
fi

# Final message
log_step "OAuth Credentials setup completed successfully!"
log_info "OAuth client credentials are now stored in Secret Manager"
log_info "You can now proceed to the next step."