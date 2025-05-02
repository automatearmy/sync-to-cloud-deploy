#!/bin/bash

# Exit on error
set -e

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"

# Display banner
display_banner "OAuth Credentials Creator" "Creating OAuth clients for Google Sync to Cloud"

# Check required commands
check_command "gcloud"
check_command "jq"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")
PROJECT_NUMBER=$(get_project_number "$PROJECT_ID")

# Redirect URI domain for UI client
UI_DOMAIN="sync-to-cloud-ui-${PROJECT_NUMBER}.us-central1.run.app"

log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Project Number: ${COLOR_BOLD}${PROJECT_NUMBER}${COLOR_RESET}"
log_info "UI Domain: ${COLOR_BOLD}${UI_DOMAIN}${COLOR_RESET}"

# Check if OAuth consent screen exists
log_step "Checking OAuth consent screen"
OAUTH_APP_EXISTS=$(gcloud alpha iap oauth-brands list --format="value(name)" 2>/dev/null || echo "")

if [[ -z "$OAUTH_APP_EXISTS" ]]; then
  log_error "OAuth consent screen is not configured."
  log_info "Please complete the OAuth consent screen setup in the Google Cloud Console first."
  log_info "Follow the instructions in the tutorial to set up the OAuth consent screen."
  exit 1
else
  log_success "OAuth consent screen is configured. Proceeding with client creation."
fi

# Create API OAuth Client (Desktop App)
log_step "Creating API OAuth Client"

# Check if secrets exist
API_CLIENT_ID_EXISTS=$(gcloud secrets describe sync-to-cloud-api-client-id --project="$PROJECT_ID" 2>/dev/null || echo "")
API_CLIENT_SECRET_EXISTS=$(gcloud secrets describe sync-to-cloud-api-client-secret --project="$PROJECT_ID" 2>/dev/null || echo "")

if [[ -n "$API_CLIENT_ID_EXISTS" && -n "$API_CLIENT_SECRET_EXISTS" ]]; then
  log_info "API OAuth client already configured in Secret Manager."
else
  log_info "Creating API OAuth client..."
  
  # Get brand name
  BRAND_NAME=$(gcloud alpha iap oauth-brands list --format="value(name)" 2>/dev/null)
  
  # Create client
  API_CLIENT=$(gcloud alpha iap oauth-clients create "$BRAND_NAME" \
    --display_name="Sync to Cloud API - Admin Transfers" \
    --type=desktop \
    --format="json")
  
  # Extract client ID and secret
  API_CLIENT_ID=$(echo "$API_CLIENT" | jq -r '.name' | sed 's|.*/||')
  API_CLIENT_SECRET=$(echo "$API_CLIENT" | jq -r '.secret')
  
  # Store in Secret Manager
  log_info "Storing API client credentials in Secret Manager..."
  
  # Create secrets if they don't exist
  if [[ -z "$API_CLIENT_ID_EXISTS" ]]; then
    gcloud secrets create sync-to-cloud-api-client-id \
      --replication-policy="automatic" \
      --project="$PROJECT_ID"
  fi
  
  if [[ -z "$API_CLIENT_SECRET_EXISTS" ]]; then
    gcloud secrets create sync-to-cloud-api-client-secret \
      --replication-policy="automatic" \
      --project="$PROJECT_ID"
  fi
  
  # Update secret values
  echo -n "$API_CLIENT_ID" | gcloud secrets versions add sync-to-cloud-api-client-id \
    --data-file=- \
    --project="$PROJECT_ID"
  
  echo -n "$API_CLIENT_SECRET" | gcloud secrets versions add sync-to-cloud-api-client-secret \
    --data-file=- \
    --project="$PROJECT_ID"
  
  log_success "API OAuth client created and stored in Secret Manager."
  log_info "Client ID: ${COLOR_BOLD}${API_CLIENT_ID}${COLOR_RESET}"
  # Don't display secret in logs for security
fi

# Create UI OAuth Client (Web App)
log_step "Creating UI OAuth Client"

# Check if secrets exist
UI_CLIENT_ID_EXISTS=$(gcloud secrets describe sync-to-cloud-ui-client-id --project="$PROJECT_ID" 2>/dev/null || echo "")
UI_CLIENT_SECRET_EXISTS=$(gcloud secrets describe sync-to-cloud-ui-client-secret --project="$PROJECT_ID" 2>/dev/null || echo "")

if [[ -n "$UI_CLIENT_ID_EXISTS" && -n "$UI_CLIENT_SECRET_EXISTS" ]]; then
  log_info "UI OAuth client already configured in Secret Manager."
else
  log_info "Creating UI OAuth client..."
  
  # Get brand name
  BRAND_NAME=$(gcloud alpha iap oauth-brands list --format="value(name)" 2>/dev/null)
  
  # Create client
  UI_CLIENT=$(gcloud alpha iap oauth-clients create "$BRAND_NAME" \
    --display_name="Sync to Cloud UI - IAP/Auth" \
    --type=web \
    --javascript_origins="http://localhost,http://localhost:5001,https://${UI_DOMAIN}" \
    --redirect_uris="https://${UI_DOMAIN}" \
    --format="json")
  
  # Extract client ID and secret
  UI_CLIENT_ID=$(echo "$UI_CLIENT" | jq -r '.name' | sed 's|.*/||')
  UI_CLIENT_SECRET=$(echo "$UI_CLIENT" | jq -r '.secret')
  
  # Add IAP redirect URI
  gcloud alpha iap oauth-clients update "$BRAND_NAME/identityAwareProxyClients/$UI_CLIENT_ID" \
    --redirect_uris="https://${UI_DOMAIN},https://iap.googleapis.com/v1/oauth/clientIds/${UI_CLIENT_ID}:handleRedirect"
  
  # Store in Secret Manager
  log_info "Storing UI client credentials in Secret Manager..."
  
  # Create secrets if they don't exist
  if [[ -z "$UI_CLIENT_ID_EXISTS" ]]; then
    gcloud secrets create sync-to-cloud-ui-client-id \
      --replication-policy="automatic" \
      --project="$PROJECT_ID"
  fi
  
  if [[ -z "$UI_CLIENT_SECRET_EXISTS" ]]; then
    gcloud secrets create sync-to-cloud-ui-client-secret \
      --replication-policy="automatic" \
      --project="$PROJECT_ID"
  fi
  
  # Update secret values
  echo -n "$UI_CLIENT_ID" | gcloud secrets versions add sync-to-cloud-ui-client-id \
    --data-file=- \
    --project="$PROJECT_ID"
  
  echo -n "$UI_CLIENT_SECRET" | gcloud secrets versions add sync-to-cloud-ui-client-secret \
    --data-file=- \
    --project="$PROJECT_ID"
  
  log_success "UI OAuth client created and stored in Secret Manager."
  log_info "Client ID: ${COLOR_BOLD}${UI_CLIENT_ID}${COLOR_RESET}"
  # Don't display secret in logs for security
fi

# Final message
log_step "OAuth Credentials Setup Completed"
log_success "OAuth clients created and stored in Secret Manager."
log_info "Client credentials are securely stored in Secret Manager and will be used during deployment."
