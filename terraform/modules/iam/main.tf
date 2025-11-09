# terraform/modules/iam/main.tf

# Service Account: Vertex AI Training
resource "google_service_account" "vertex_ai_training" {
  account_id   = "vertex-ai-training-${var.environment}"
  display_name = "Vertex AI Training Service Account (${var.environment})"
  description  = "Service account for Vertex AI training jobs"
}

# Permissions for training SA
resource "google_project_iam_member" "vertex_ai_training_roles" {
  for_each = toset([
    "roles/bigquery.dataViewer",          # Read training data
    "roles/storage.objectAdmin",          # Read/write model artifacts
    "roles/aiplatform.user",              # Use Vertex AI services
    "roles/logging.logWriter",            # Write logs
    "roles/monitoring.metricWriter",      # Write custom metrics
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.vertex_ai_training.email}"
}

# Service Account: Cloud Run Serving
resource "google_service_account" "cloudrun_serving" {
  account_id   = "cloudrun-serving-${var.environment}"
  display_name = "Cloud Run Serving Service Account (${var.environment})"
  description  = "Service account for Cloud Run prediction API"
}

# Permissions for serving SA
resource "google_project_iam_member" "cloudrun_serving_roles" {
  for_each = toset([
    "roles/storage.objectViewer",         # Read model artifacts
    "roles/bigquery.dataEditor",          # Write predictions
    "roles/aiplatform.user",              # Access Model Registry
    "roles/logging.logWriter",            # Write logs
    "roles/monitoring.metricWriter",      # Write metrics
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloudrun_serving.email}"
}

# Service Account: CI/CD Pipeline
resource "google_service_account" "cicd" {
  account_id   = "cicd-pipeline-${var.environment}"
  display_name = "CI/CD Pipeline Service Account (${var.environment})"
  description  = "Service account for GitHub Actions / Cloud Build"
}

# Permissions for CI/CD SA
resource "google_project_iam_member" "cicd_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",      # Push Docker images
    "roles/storage.admin",                # Manage GCS objects
    "roles/run.admin",                    # Deploy Cloud Run services
    "roles/iam.serviceAccountUser",       # Act as other service accounts
    "roles/aiplatform.admin",             # Manage Vertex AI resources
    "roles/secretmanager.secretVersionManager", # Update secrets
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cicd.email}"
}

# Service Account: Batch Prediction
resource "google_service_account" "batch_prediction" {
  account_id   = "batch-prediction-${var.environment}"
  display_name = "Batch Prediction Service Account (${var.environment})"
  description  = "Service account for batch prediction jobs"
}

# Permissions for batch prediction SA
resource "google_project_iam_member" "batch_prediction_roles" {
  for_each = toset([
    "roles/bigquery.dataEditor",          # Read input, write output
    "roles/storage.objectViewer",         # Read models
    "roles/aiplatform.user",              # Run batch jobs
    "roles/logging.logWriter",
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.batch_prediction.email}"
}

# Service Account: Data Scientists (Workbench)
resource "google_service_account" "data_scientist" {
  account_id   = "data-scientist-${var.environment}"
  display_name = "Data Scientist Service Account (${var.environment})"
  description  = "Service account for Vertex AI Workbench instances"
}

# Permissions for data scientist SA
resource "google_project_iam_member" "data_scientist_roles" {
  for_each = toset([
    "roles/bigquery.dataViewer",          # Read-only BigQuery access
    "roles/storage.objectViewer",         # Read model artifacts
    "roles/aiplatform.user",              # Use Vertex AI
    "roles/notebooks.admin",              # Manage notebooks
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.data_scientist.email}"
}

# Custom Role: Model Registry Manager
resource "google_project_iam_custom_role" "model_registry_manager" {
  role_id     = "modelRegistryManager_${var.environment}"
  title       = "Model Registry Manager"
  description = "Manage models in Vertex AI Model Registry"
  
  permissions = [
    "aiplatform.models.create",
    "aiplatform.models.delete",
    "aiplatform.models.get",
    "aiplatform.models.list",
    "aiplatform.models.update",
    "aiplatform.models.upload",
    "aiplatform.modelDeploymentMonitoringJobs.create",
    "aiplatform.modelDeploymentMonitoringJobs.get",
  ]
}

# Grant training SA permission to manage models
resource "google_project_iam_member" "training_model_manager" {
  project = var.project_id
  role    = google_project_iam_custom_role.model_registry_manager.id
  member  = "serviceAccount:${google_service_account.vertex_ai_training.email}"
}

# IAM: Allow Cloud Run to impersonate training SA (for triggering jobs)
resource "google_service_account_iam_member" "cloudrun_impersonate_training" {
  count = var.allow_api_trigger_training ? 1 : 0
  
  service_account_id = google_service_account.vertex_ai_training.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloudrun_serving.email}"
}

# IAM: Allow data scientists to impersonate training SA
resource "google_service_account_iam_member" "datascientist_impersonate_training" {
  service_account_id = google_service_account.vertex_ai_training.name
  role               = "roles/iam.serviceAccountUser"
  member             = "group:${var.data_scientist_group_email}"
}

# IAM: Bind GitHub OIDC to CI/CD service account (for Workload Identity Federation)
resource "google_iam_workload_identity_pool" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0
  
  workload_identity_pool_id = "github-actions-${var.environment}"
  display_name              = "GitHub Actions (${var.environment})"
  description               = "Workload Identity Pool for GitHub Actions"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0
  
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_actions_workload_identity" {
  count = var.enable_github_oidc ? 1 : 0
  
  service_account_id = google_service_account.cicd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions[0].name}/attribute.repository/${var.github_repository}"
}