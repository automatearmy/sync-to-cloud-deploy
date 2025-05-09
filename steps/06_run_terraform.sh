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

# This script executes Terraform commands to deploy Sync to Cloud in the Google Cloud project
# It handles authentication, Terraform initialization, planning, and applying the configuration

# Exit on error
set -e

# Source common utilities and environment variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/env.sh"

# Display banner
display_banner "Terraform Deployment Runner" "Running Terraform to deploy Google Sync to Cloud"

# Check required commands
check_command "gcloud"
check_command "docker"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")
PROJECT_NUMBER=$(get_project_number "$PROJECT_ID")
TF_SERVICE_ACCOUNT="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com"
TF_STATE_BUCKET="${PROJECT_ID}-${STATE_BUCKET_SUFIX}"

log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Project Number: ${COLOR_BOLD}${PROJECT_NUMBER}${COLOR_RESET}"
log_info "Terraform Service Account: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"
log_info "Terraform Image: ${COLOR_BOLD}${TERRAFORM_IMAGE}${COLOR_RESET}"
log_info "Terraform State Bucket: ${COLOR_BOLD}${TF_STATE_BUCKET}${COLOR_RESET}"

# Generate OAuth token for service account impersonation
log_step "Generating OAuth token for service account impersonation"
log_info "Impersonating service account: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"

# Export the OAuth token
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token --impersonate-service-account="${TF_SERVICE_ACCOUNT}" 2>/dev/null)
if [[ -n "$GOOGLE_OAUTH_ACCESS_TOKEN" ]]; then
  log_success "Successfully generated OAuth access token for service account impersonation."
else
  log_error "Failed to generate OAuth access token for service account impersonation."
  log_info "Please ensure you have the Service Account Token Creator role and try again."
  exit 1
fi

# Check terraform.tfvars configuration
log_step "Checking terraform.tfvars configuration"
log_info "Verifying terraform.tfvars file exists and is properly configured"

if [[ -f "terraform.tfvars" ]]; then
  log_success "Found terraform.tfvars configuration file"
  log_info "Using configuration from terraform.tfvars"
else
  log_error "terraform.tfvars file not found"
  log_info "Please run 04_create_terraform_tfvars.sh before continuing"
  exit 1
fi

# Run Terraform operations in sequence with consistent state
log_step "Running Terraform commands (init, plan, apply) in sequence"
log_info "This approach ensures Terraform state is preserved between commands..."

run_terraform_deployment() {
  # Create a custom entrypoint script for our container
  ENTRYPOINT_SCRIPT="$(mktemp)"
  cat > "${ENTRYPOINT_SCRIPT}" << 'EOF'
#!/bin/sh
set -e

# Run terraform init
echo "Running terraform init..."
terraform init -backend-config="bucket=$1" -input=false

# Run terraform plan
echo "Running terraform plan..."
terraform plan -var-file=/workspace/terraform.tfvars -input=false

# Run terraform apply
echo "Running terraform apply..."
terraform apply -var-file=/workspace/terraform.tfvars -auto-approve -input=false
EOF
  chmod +x "${ENTRYPOINT_SCRIPT}"
  
  # Run all terraform commands in a single container
  log_info "Running all Terraform commands in a single execution..."
  docker run --rm \
    -v "$(pwd)/terraform.tfvars:/workspace/terraform.tfvars:ro" \
    -v "${ENTRYPOINT_SCRIPT}:/entrypoint.sh:ro" \
    -e GOOGLE_OAUTH_ACCESS_TOKEN="${GOOGLE_OAUTH_ACCESS_TOKEN}" \
    -e CLOUDSDK_AUTH_ACCESS_TOKEN="${GOOGLE_OAUTH_ACCESS_TOKEN}" \
    --entrypoint "/entrypoint.sh" \
    "${TERRAFORM_IMAGE}" \
    "${TF_STATE_BUCKET}"
    
  # Clean up the temporary script
  rm -f "${ENTRYPOINT_SCRIPT}"
}

if ask_confirmation "Do you want to proceed with deployment?"; then
  log_info "Starting Terraform deployment..."
  run_terraform_deployment
else
  log_error "Deployment cancelled by user."
  log_info "You can run this script again when ready to deploy."
  exit 0
fi

# Final message
log_step "Terraform deployment completed successfully!"
log_info "You can now proceed to the next step."