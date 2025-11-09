# terraform/modules/storage/main.tf

# Bucket for model artifacts (model.pkl files)
resource "google_storage_bucket" "model_artifacts" {
  name          = "${var.project_id}-${var.environment}-model-artifacts"
  location      = var.region
  storage_class = "STANDARD"
  
  uniform_bucket_level_access {
    enabled = true
  }
  
  versioning {
    enabled = true  # Critical: Never lose a model version
  }
  
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
    condition {
      age = 90  # Move to cheaper storage after 3 months
      matches_storage_class = ["STANDARD"]
    }
  }
  
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = 365  # Archive after 1 year
      matches_storage_class = ["NEARLINE"]
    }
  }
  
  labels = {
    environment = var.environment
    purpose     = "model-artifacts"
    managed_by  = "terraform"
  }
}

# Bucket for training data snapshots
resource "google_storage_bucket" "training_data" {
  name          = "${var.project_id}-${var.environment}-training-data"
  location      = var.region
  storage_class = "STANDARD"
  
  uniform_bucket_level_access {
    enabled = true
  }
  
  # No versioning needed (large files, immutable snapshots)
  versioning {
    enabled = false
  }
  
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 180  # Delete after 6 months (data in BigQuery is source of truth)
    }
  }
  
  labels = {
    environment = var.environment
    purpose     = "training-data-snapshots"
    managed_by  = "terraform"
  }
}

# Bucket for Vertex AI pipeline artifacts
resource "google_storage_bucket" "pipeline_artifacts" {
  name          = "${var.project_id}-${var.environment}-pipeline-artifacts"
  location      = var.region
  storage_class = "STANDARD"
  
  uniform_bucket_level_access {
    enabled = true
  }
  
  versioning {
    enabled = true
  }
  
  # Vertex AI pipelines create many intermediate files
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30  # Clean up after 30 days
      matches_prefix = ["tmp/", "staging/"]
    }
  }
  
  labels = {
    environment = var.environment
    purpose     = "vertex-ai-pipelines"
    managed_by  = "terraform"
  }
}

# Bucket for logs and monitoring data (optional)
resource "google_storage_bucket" "logs" {
  count = var.enable_log_bucket ? 1 : 0
  
  name          = "${var.project_id}-${var.environment}-logs"
  location      = var.region
  storage_class = "STANDARD"
  
  uniform_bucket_level_access {
    enabled = true
  }
  
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90  # Delete logs after 90 days
    }
  }
  
  labels = {
    environment = var.environment
    purpose     = "logs-export"
    managed_by  = "terraform"
  }
}

# IAM: Vertex AI training jobs can write model artifacts
resource "google_storage_bucket_iam_member" "vertex_ai_writer" {
  bucket = google_storage_bucket.model_artifacts.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.vertex_ai_service_account_email}"
}

# IAM: Cloud Run can read model artifacts
resource "google_storage_bucket_iam_member" "cloudrun_reader" {
  bucket = google_storage_bucket.model_artifacts.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.cloudrun_service_account_email}"
}

# IAM: CI/CD can read/write for testing
resource "google_storage_bucket_iam_member" "cicd_admin" {
  bucket = google_storage_bucket.model_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.cicd_service_account_email}"
}