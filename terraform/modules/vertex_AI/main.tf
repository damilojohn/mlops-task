# terraform/modules/vertex-ai/main.tf

# Enable Vertex AI API
resource "google_project_service" "vertex_ai" {
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "notebooks" {
  service            = "notebooks.googleapis.com"
  disable_on_destroy = false
}

# Vertex AI Workbench Instance for Data Scientists
resource "google_notebooks_instance" "workbench" {
  count = var.create_workbench ? 1 : 0
  
  name     = "ml-workbench-${var.environment}"
  location = "${var.region}-a"  # Zonal resource
  
  machine_type = var.workbench_machine_type
  
  vm_image {
    project      = "deeplearning-platform-release"
    image_family = "common-cpu-notebooks"  # Or common-gpu-notebooks
  }
  
  install_gpu_driver = var.workbench_gpu_enabled
  
  boot_disk_type    = "PD_SSD"
  boot_disk_size_gb = 100
  data_disk_type    = "PD_STANDARD"
  data_disk_size_gb = 200
  
  # Network configuration
  network = var.vpc_network_name
  subnet  = var.vpc_subnet_name
  
  no_public_ip    = var.environment == "prod" ? true : false
  no_proxy_access = false
  
  service_account = var.workbench_service_account_email
  
  metadata = {
    terraform-managed = "true"
    environment       = var.environment
  }
  
  labels = {
    environment = var.environment
    purpose     = "data-science"
    managed_by  = "terraform"
  }
}

# Tensorboard instance for experiment tracking
resource "google_vertex_ai_tensorboard" "main" {
  count = var.create_tensorboard ? 1 : 0
  
  display_name = "ml-experiments-${var.environment}"
  description  = "Tensorboard for tracking training experiments"
  region       = var.region
  
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Model Registry is created automatically, but we can set up metadata
# Note: Individual models are registered via Python SDK during training

# Optional: Vertex AI Endpoint for model serving
# (We'll use Cloud Run instead, but include for reference)
resource "google_vertex_ai_endpoint" "model_endpoint" {
  count = var.create_vertex_endpoint ? 1 : 0
  
  name         = "claim-leakage-endpoint-${var.environment}"
  display_name = "Claim Leakage Prediction Endpoint"
  description  = "Serves claim leakage classification models"
  region       = var.region
  
  labels = {
    environment = var.environment
    model       = "claim-leakage"
    managed_by  = "terraform"
  }
  
  # Encryption
  encryption_spec {
    kms_key_name = var.kms_key_id
  }
}

# Metadata: Define where training artifacts are stored
resource "google_vertex_ai_metadata_store" "main" {
  count = var.create_metadata_store ? 1 : 0
  
  name        = "ml-metadata-${var.environment}"
  description = "Metadata store for ML lineage tracking"
  region      = var.region
  
  encryption_spec {
    kms_key_name = var.kms_key_id
  }
}