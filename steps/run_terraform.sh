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

log_step "Running Terraform Deployment"
log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Service Account: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"
log_info "State Bucket: ${COLOR_BOLD}${TF_STATE_BUCKET}${COLOR_RESET}"

# Check if terraform.tfvars exists
if [[ ! -f "terraform.tfvars" ]]; then
  log_error "terraform.tfvars file not found."
  log_info "Please run the create_terraform_tfvars.sh script first."
  exit 1
fi

# Run Terraform init
log_step "Initializing Terraform"
log_info "This step sets up Terraform to use your state bucket and providers..."

docker run --rm \
  -v "$(pwd)/terraform.tfvars:/app/terraform.tfvars:ro" \
  -v "$HOME/.config/gcloud:/root/.config/gcloud:ro" \
  -e GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="${TF_SERVICE_ACCOUNT}" \
  "${TERRAFORM_IMAGE}" \
  init -backend-config="bucket=${TF_STATE_BUCKET}"

log_success "Terraform initialization completed."

# Run Terraform plan
log_step "Running Terraform plan"
log_info "This step will show what resources will be created..."

docker run --rm \
  -v "$(pwd)/terraform.tfvars:/app/terraform.tfvars:ro" \
  -v "$HOME/.config/gcloud:/root/.config/gcloud:ro" \
  -e GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="${TF_SERVICE_ACCOUNT}" \
  "${TERRAFORM_IMAGE}" \
  plan -var-file=/app/terraform.tfvars

# Ask for confirmation before applying
if ask_confirmation "Do you want to proceed with deployment?"; then
  # Run Terraform apply
  log_step "Running Terraform apply"
  log_info "This step will create all the resources for Google Sync to Cloud..."
  log_info "This may take 15-20 minutes to complete. Please be patient."

  docker run --rm \
    -v "$(pwd)/terraform.tfvars:/app/terraform.tfvars:ro" \
    -v "$HOME/.config/gcloud:/root/.config/gcloud:ro" \
    -e GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="${TF_SERVICE_ACCOUNT}" \
    "${TERRAFORM_IMAGE}" \
    apply -var-file=/app/terraform.tfvars -auto-approve

  log_success "Terraform deployment completed successfully!"

  # Get outputs
  log_step "Deployment Outputs"
  log_info "Here are the details of your Google Sync to Cloud deployment:"

  docker run --rm \
    -v "$(pwd)/terraform.tfvars:/app/terraform.tfvars:ro" \
    -v "$HOME/.config/gcloud:/root/.config/gcloud:ro" \
    -e GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="${TF_SERVICE_ACCOUNT}" \
    "${TERRAFORM_IMAGE}" \
    output
else
  log_info "Deployment cancelled."
  exit 0
fi

# Final message
log_step "Deployment Complete!"
display_success "Google Sync to Cloud has been successfully deployed to your project"
log_info "You can access the application using the UI URL displayed above."
log_info "For support, please contact team@automatearmy.com."
