#!/bin/bash

# Exit on error
set -e

# --- Colors and Formatting ---
COLOR_RESET=$(tput sgr0)
COLOR_BOLD=$(tput bold)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_BLUE=$(tput setaf 4)
COLOR_RED=$(tput setaf 1)

# --- Log Functions ---
log_header() { echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== $1 ===${COLOR_RESET}"; }
log_step() { echo -e "\n${COLOR_BOLD}${COLOR_BLUE}==> $1${COLOR_RESET}"; }
log_info() { echo -e "${COLOR_YELLOW}[INFO]${COLOR_RESET} $1"; }
log_success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"; }
log_error() { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"; }
log_fatal() {
  log_error "$1"
  exit 1
}

# --- Helper Functions ---
check_command() {
  log_info "Checking for command: $1"
  if ! command -v "$1" &>/dev/null; then
    log_fatal "Required command '$1' not found. Please install it and ensure it's in your PATH."
  fi
  log_success "Command '$1' found."
}

ask_yes_no() {
  while true; do
    read -p "$1 (y/n): " answer
    case $answer in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes (y) or no (n).";;
    esac
  done
}

check_gcloud_login() {
  log_step "Checking gcloud login status"
  if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    log_info "You are not logged into gcloud. Initiating login..."
    gcloud auth login
    gcloud auth application-default login # For application default credentials
    log_success "gcloud login successful."
  else
    log_success "gcloud user is already logged in."
  fi

  log_info "Checking gcloud project configuration..."
  if ! gcloud config get-value project &>/dev/null; then
    log_info "No default gcloud project configured. Let's set one:"
    gcloud projects list
    read -p "Enter your project ID: " project_id
    gcloud config set project "$project_id"
  fi
  log_success "gcloud project is configured."
}

get_project_id() {
  local project_id
  project_id=$(gcloud config get-value project 2>/dev/null)
  if [[ -z "$project_id" ]]; then
    log_fatal "Could not determine GCP Project ID. Make sure it's set in gcloud config."
  fi
  echo "$project_id"
}

get_user_email() {
  local user_email
  user_email=$(gcloud config get-value account 2>/dev/null)
  if [[ -z "$user_email" ]]; then
    log_fatal "Could not determine gcloud user email."
  fi
  echo "$user_email"
}

enable_apis() {
  local project_id=$1
  local apis=(
    "cloudidentity.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "compute.googleapis.com"
    "dns.googleapis.com"
    "firebase.googleapis.com"
    "iam.googleapis.com"
    "iamcredentials.googleapis.com"
    "logging.googleapis.com"
    "monitoring.googleapis.com"
    "secretmanager.googleapis.com"
    "serviceusage.googleapis.com"
    "storage.googleapis.com"
    "vpcaccess.googleapis.com"
    "container.googleapis.com"
    "run.googleapis.com"
  )
  log_step "Enabling required Google Cloud APIs for project ${COLOR_BOLD}${project_id}${COLOR_RESET}"
  log_info "Attempting to enable ${#apis[@]} APIs. This may take a few minutes..."
  gcloud services enable "${apis[@]}" --project="$project_id"
  log_success "All required APIs enabled successfully."
}

create_oauth_secrets() {
  local project_id=$1
  local secrets_to_create=(
    "sync-to-cloud-ui-client-id"
    "sync-to-cloud-ui-client-secret"
    "sync-to-cloud-api-client-id"
    "sync-to-cloud-api-client-secret"
  )

  log_step "Ensuring required OAuth Secret Manager secrets exist"

  for secret_name in "${secrets_to_create[@]}"; do
    log_info "Checking for secret: ${COLOR_BOLD}${secret_name}${COLOR_RESET}"
    if gcloud secrets describe "$secret_name" --project="$project_id" &>/dev/null; then
      log_success "Secret '$secret_name' already exists."
    else
      log_info "Creating secret '$secret_name'..."
      # Use automatic replication policy
      gcloud secrets create "$secret_name" --replication-policy="automatic" --project="$project_id"
      log_success "Secret '$secret_name' created successfully."
      
      # Now prompt for the secret value
      log_info "Please enter the value for $secret_name:"
      read -s secret_value
      echo "$secret_value" | gcloud secrets versions add "$secret_name" --data-file=- --project="$project_id"
      log_success "Secret value set for '$secret_name'."
    fi
  done
  log_success "OAuth secret check/creation complete."
}

create_tfvars() {
  log_step "Creating terraform.tfvars file"
  
  # Get project ID
  local project_id=$(get_project_id)
  
  # Default region
  local region="us-central1"
  read -p "Enter region (default: us-central1): " region_input
  if [[ -n "$region_input" ]]; then
    region="$region_input"
  fi
  
  # API user email for domain-wide delegation (optional)
  local api_user_email=""
  read -p "Enter API user email for domain-wide delegation (optional): " api_user_email
  
  # Create terraform.tfvars file
  cat > terraform.tfvars <<EOL
project_id = "${project_id}"
terraform_sa = "terraform-admin@${project_id}.iam.gserviceaccount.com"
region = "${region}"

# Registry settings - DO NOT CHANGE
registry_project = "sync-to-cloud-registry"
registry_region = "us-central1"
repository_name = "sync-to-cloud-app"

api_image_name = "sync-to-cloud-api"
ui_image_name = "sync-to-cloud-ui"
worker_image_name = "sync-to-cloud-worker"

# Domain-wide delegation
api_user_email = "${api_user_email}"

# BigQuery Configuration
bigquery_project_id = "${project_id}"
bigquery_dataset = "drive_inventory_report"
bigquery_table = "inventory"
EOL

  log_success "terraform.tfvars file created."
}

run_terraform_docker() {
  log_step "Running Terraform Docker image"
  
  local project_id=$(get_project_id)
  
  # Pull the Docker image (adjust with your actual image location)
  log_info "Pulling Terraform Docker image..."
  docker pull gcr.io/sync-to-cloud-registry/terraform-deployer:latest
  
  # Run initialization
  log_info "Initializing Terraform..."
  docker run -v $(pwd)/terraform.tfvars:/workspace/terraform.tfvars \
    -v $HOME/.config/gcloud:/root/.config/gcloud:ro \
    -e GOOGLE_PROJECT="$project_id" \
    gcr.io/sync-to-cloud-registry/terraform-deployer:latest init
  
  # Run plan
  log_info "Running Terraform plan..."
  docker run -v $(pwd)/terraform.tfvars:/workspace/terraform.tfvars \
    -v $HOME/.config/gcloud:/root/.config/gcloud:ro \
    -e GOOGLE_PROJECT="$project_id" \
    gcr.io/sync-to-cloud-registry/terraform-deployer:latest plan -var-file=terraform.tfvars
  
  # Confirm apply
  if ask_yes_no "Do you want to proceed with the deployment?"; then
    log_info "Running Terraform apply..."
    docker run -v $(pwd)/terraform.tfvars:/workspace/terraform.tfvars \
      -v $HOME/.config/gcloud:/root/.config/gcloud:ro \
      -e GOOGLE_PROJECT="$project_id" \
      gcr.io/sync-to-cloud-registry/terraform-deployer:latest apply -var-file=terraform.tfvars -auto-approve
    
    log_success "Deployment completed successfully!"
  else
    log_info "Deployment canceled."
  fi
}

display_outputs() {
  log_step "Deployment Outputs"
  
  local project_id=$(get_project_id)
  
  log_info "Retrieving outputs..."
  docker run -v $(pwd)/terraform.tfvars:/workspace/terraform.tfvars \
    -v $HOME/.config/gcloud:/root/.config/gcloud:ro \
    -e GOOGLE_PROJECT="$project_id" \
    gcr.io/sync-to-cloud-registry/terraform-deployer:latest output
  
  log_success "You can access your Sync to Cloud instance using the URLs above."
}

# --- Main Function ---
main() {
  log_header "Welcome to Sync to Cloud Deployment"
  
  # Check prerequisites
  check_command "gcloud"
  check_command "docker"
  
  # Check gcloud login
  check_gcloud_login
  
  # Get project info
  local project_id=$(get_project_id)
  local user_email=$(get_user_email)
  log_info "Project ID: ${COLOR_BOLD}${project_id}${COLOR_RESET}"
  log_info "User: ${COLOR_BOLD}${user_email}${COLOR_RESET}"
  
  # Enable required APIs
  enable_apis "$project_id"
  
  # Create OAuth secrets
  create_oauth_secrets "$project_id"
  
  # Create terraform.tfvars file
  create_tfvars
  
  # Run Terraform Docker
  run_terraform_docker
  
  # Display outputs
  display_outputs
  
  log_header "Deployment Complete"
  log_info "Your Sync to Cloud instance has been deployed."
  log_info "For support, contact team@automatearmy.com."
}

# Execute main function
main
