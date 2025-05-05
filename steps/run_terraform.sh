#!/bin/bash

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

# Get terraform service account email
TF_SERVICE_ACCOUNT=""
if [[ -f "tf_sa_env.sh" ]]; then
  source tf_sa_env.sh
  TF_SERVICE_ACCOUNT="$TF_SERVICE_ACCOUNT_EMAIL"
else
  # If not available, construct it based on standard naming
  TF_SERVICE_ACCOUNT="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com"
  log_info "Service account environment file not found, using default: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"
fi

# Use terraform image from env.sh
log_info "Using Terraform image: ${COLOR_BOLD}${TERRAFORM_IMAGE}${COLOR_RESET}"

# Get state bucket name
TF_STATE_BUCKET=""
if [[ -f "tf_sa_env.sh" ]]; then
  source tf_sa_env.sh
fi

# If bucket name wasn't loaded from file, try to construct it based on project ID
if [[ -z "$TF_STATE_BUCKET" ]]; then
  TF_STATE_BUCKET="terraform-state-${PROJECT_ID}"
  log_info "State bucket environment file not found, using default: ${COLOR_BOLD}${TF_STATE_BUCKET}${COLOR_RESET}"
fi

# Generate OAuth token for service account impersonation
log_step "Generating OAuth token for service account impersonation"
log_info "Impersonating service account: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"

# Export the OAuth token
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token --impersonate-service-account="${TF_SERVICE_ACCOUNT}")
if [[ -z "$GOOGLE_OAUTH_ACCESS_TOKEN" ]]; then
  log_error "Failed to generate OAuth access token. Please check your permissions."
  exit 1
fi
log_success "OAuth token generated successfully."

# Check if terraform.tfvars exists
if [[ ! -f "terraform.tfvars" ]]; then
  log_error "terraform.tfvars file not found."
  log_info "Please run the create_terraform_tfvars.sh script first."
  exit 1
fi

log_step "Running Terraform Deployment"
log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Service Account: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"
log_info "State Bucket: ${COLOR_BOLD}${TF_STATE_BUCKET}${COLOR_RESET}"

# Set up for Terraform deployment

# Run Terraform operations in sequence with consistent state
log_step "Running Terraform commands (init, plan, apply) in sequence"
log_info "This approach ensures Terraform state is preserved between commands..."

# Ask for confirmation before proceeding
if ask_confirmation "Do you want to proceed with deployment?"; then
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

# Show outputs
echo "Showing terraform outputs..."
terraform output
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

  log_success "Terraform deployment completed successfully!"
else
  log_info "Deployment cancelled."
  exit 0
fi

# Final message
log_step "Deployment Complete!"
display_success "Google Sync to Cloud has been successfully deployed to your project"
log_info "You can access the application using the UI URL displayed above."
log_info "For support, please contact team@automatearmy.com."
