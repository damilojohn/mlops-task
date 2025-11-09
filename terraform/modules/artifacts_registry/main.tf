# terraform/modules/artifact-registry/main.tf

# Docker repository for training images
resource "google_artifact_registry_repository" "training_images" {
  location      = var.region
  repository_id = "${var.environment}-training-images"
  description   = "Docker images for Vertex AI training jobs"
  format        = "DOCKER"
  
  labels = {
    environment = var.environment
    purpose     = "training"
    managed_by  = "terraform"
  }
  
  # Cleanup policy: Delete images older than 90 days
  cleanup_policy_dry_run = false
  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    
    condition {
      older_than = "7776000s"  # 90 days
      tag_state  = "UNTAGGED"
    }
  }
}

# Docker repository for serving/prediction images
resource "google_artifact_registry_repository" "serving_images" {
  location      = var.region
  repository_id = "${var.environment}-serving-images"
  description   = "Docker images for model serving (FastAPI, Cloud Run)"
  format        = "DOCKER"
  
  labels = {
    environment = var.environment
    purpose     = "serving"
    managed_by  = "terraform"
  }
  
  cleanup_policies {
    id     = "keep-recent-images"
    action = "KEEP"
    
    # Keep last 10 versions
    most_recent_versions {
      keep_count = 10
    }
  }
}

# Python package repository (for shared libraries)
resource "google_artifact_registry_repository" "python_packages" {
  location      = var.region
  repository_id = "${var.environment}-python-packages"
  description   = "Private Python packages (e.g., shared data preprocessing)"
  format        = "PYTHON"
  
  labels = {
    environment = var.environment
    purpose     = "libraries"
    managed_by  = "terraform"
  }
}

# IAM: Allow CI/CD to push images
resource "google_artifact_registry_repository_iam_member" "cicd_writer" {
  location   = google_artifact_registry_repository.training_images.location
  repository = google_artifact_registry_repository.training_images.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.cicd_service_account_email}"
}

# IAM: Allow Vertex AI to pull training images
resource "google_artifact_registry_repository_iam_member" "vertex_ai_reader" {
  location   = google_artifact_registry_repository.training_images.location
  repository = google_artifact_registry_repository.training_images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.vertex_ai_service_account_email}"
}

# IAM: Allow Cloud Run to pull serving images
resource "google_artifact_registry_repository_iam_member" "cloudrun_reader" {
  location   = google_artifact_registry_repository.serving_images.location
  repository = google_artifact_registry_repository.serving_images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.cloudrun_service_account_email}"
}