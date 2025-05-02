#!/bin/bash

# Exit on error
set -e

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/utils.sh"

# Display banner
display_banner "Terraform Deployment Runner" "Running Terraform to deploy Google Sync to Cloud"

# Check required commands
check_command "gcloud"
check_command "docker"
check_command "jq"

# Get project details from argument or from gcloud config
PROJECT_ID=$(get_project_id "$1")

# Get terraform service account email from file or use default
TF_SERVICE_ACCOUNT=""
if [[ -f "tf_sa_env.sh" ]]; then
  source tf_sa_env.sh
  TF_SERVICE_ACCOUNT="$TF_SERVICE_ACCOUNT_EMAIL"
else
  # If not available, construct it based on standard naming
  TF_SERVICE_ACCOUNT="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com"
  log_info "Service account environment file not found, using default: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"
fi

log_step "Running Terraform Deployment"
log_info "Project ID: ${COLOR_BOLD}${PROJECT_ID}${COLOR_RESET}"
log_info "Service Account: ${COLOR_BOLD}${TF_SERVICE_ACCOUNT}${COLOR_RESET}"

# Check if terraform.tfvars exists
if [[ ! -f "terraform.tfvars" ]]; then
  log_error "terraform.tfvars file not found."
  log_info "Please run the create_terraform_tfvars.sh script first."
  exit 1
fi

# Verify access to artifact registry
log_step "Checking access to artifact registry"
log_info "Verifying you have access to the Sync to Cloud artifact registry..."

# Get short-lived access token for the Terraform service account
log_info "Generating access token for service account impersonation..."
TOKEN=$(gcloud auth print-access-token --impersonate-service-account="${TF_SERVICE_ACCOUNT}")

if [[ -z "$TOKEN" ]]; then
  log_error "Failed to generate access token for service account impersonation."
  log_info "Please ensure you have the Service Account Token Creator role and try again."
  exit 1
fi

# Configure Docker to use the service account credentials
log_info "Configuring Docker authentication..."
echo "$TOKEN" | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev

# Pull the Terraform Docker image
TERRAFORM_IMAGE="us-central1-docker.pkg.dev/sync-to-cloud-registry/sync-to-cloud-app/sync-to-cloud-terraform:latest"
log_step "Pulling Terraform Docker image"
log_info "Image: ${COLOR_BOLD}${TERRAFORM_IMAGE}${COLOR_RESET}"

if ! docker pull "${TERRAFORM_IMAGE}"; then
  log_error "Failed to pull the Terraform Docker image."
  log_info "Please confirm with the Sync to Cloud team that your project (${PROJECT_ID}, ${PROJECT_NUMBER}) has access to the artifact registry."
  exit 1
fi

log_success "Terraform Docker image pulled successfully."

# Run Terraform init
log_step "Initializing Terraform"
log_info "This step sets up Terraform to use your state bucket and providers..."

docker run --rm \
  -v "$(pwd)/terraform.tfvars:/app/terraform.tfvars:ro" \
  -v "$HOME/.config/gcloud:/root/.config/gcloud:ro" \
  -e GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="${TF_SERVICE_ACCOUNT}" \
  "${TERRAFORM_IMAGE}" \
  init

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
read -p "Do you want to proceed with deployment? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  log_info "Deployment cancelled."
  exit 0
fi

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

# Final message
log_step "Deployment Complete!"
log_success "Google Sync to Cloud has been successfully deployed to your project."
log_info "You can access the application using the UI URL displayed above."
log_info "For support, please contact team@automatearmy.com."
