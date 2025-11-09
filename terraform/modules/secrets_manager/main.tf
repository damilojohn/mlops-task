# terraform/modules/secrets/main.tf

# Enable Secret Manager API
resource "google_project_service" "secret_manager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Secret for API authentication token
resource "google_secret_manager_secret" "api_auth_token" {
  secret_id = "api-auth-token-${var.environment}"
  
  replication {
    auto {}  # Automatic replication across regions
  }
  
  labels = {
    environment = var.environment
    purpose     = "api-authentication"
    managed_by  = "terraform"
  }
}

# Note: Actual secret value NOT stored in Terraform
# Populate via: gcloud secrets versions add SECRET_ID --data-file=-
# Or via CI/CD pipeline
resource "google_secret_manager_secret_version" "api_auth_token_version" {
  secret = google_secret_manager_secret.api_auth_token.id
  
  # Placeholder - will be overwritten by external process
  secret_data = "PLACEHOLDER_CHANGE_ME"
  
  lifecycle {
    ignore_changes = [secret_data]  # Prevent Terraform from overwriting
  }
}

# Secret for BigQuery service account key (if needed)
resource "google_secret_manager_secret" "bigquery_sa_key" {
  count = var.create_bigquery_secret ? 1 : 0
  
  secret_id = "bigquery-service-account-key-${var.environment}"
  
  replication {
    auto {}
  }
  
  labels = {
    environment = var.environment
    purpose     = "bigquery-access"
    managed_by  = "terraform"
  }
}

# Secret for model signing key (to verify model integrity)
resource "google_secret_manager_secret" "model_signing_key" {
  secret_id = "model-signing-key-${var.environment}"
  
  replication {
    user_managed {
      replicas {
        location = var.region
      }
      # Add more replicas for prod
      dynamic "replicas" {
        for_each = var.environment == "prod" ? ["europe-west1", "us-central1"] : []
        content {
          location = replicas.value
        }
      }
    }
  }
  
  labels = {
    environment = var.environment
    purpose     = "model-integrity"
    managed_by  = "terraform"
  }
}

# Secret for third-party API keys (e.g., monitoring, alerting)
resource "google_secret_manager_secret" "third_party_keys" {
  for_each = toset(var.third_party_secret_names)
  
  secret_id = "${each.key}-${var.environment}"
  
  replication {
    auto {}
  }
  
  labels = {
    environment = var.environment
    purpose     = "third-party-integration"
    managed_by  = "terraform"
  }
}

# IAM: Grant Cloud Run access to API auth token
resource "google_secret_manager_secret_iam_member" "cloudrun_api_token_access" {
  secret_id = google_secret_manager_secret.api_auth_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.cloudrun_service_account_email}"
}

# IAM: Grant Vertex AI access to BigQuery credentials
resource "google_secret_manager_secret_iam_member" "vertex_ai_bq_access" {
  count = var.create_bigquery_secret ? 1 : 0
  
  secret_id = google_secret_manager_secret.bigquery_sa_key[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.vertex_ai_service_account_email}"
}

# IAM: Grant CI/CD access to manage secret versions
resource "google_secret_manager_secret_iam_member" "cicd_secret_admin" {
  secret_id = google_secret_manager_secret.api_auth_token.secret_id
  role      = "roles/secretmanager.secretVersionManager"
  member    = "serviceAccount:${var.cicd_service_account_email}"
}

# IAM: Grant admins ability to view secret metadata (not values)
resource "google_secret_manager_secret_iam_member" "admin_viewer" {
  for_each = toset([
    google_secret_manager_secret.api_auth_token.secret_id,
    google_secret_manager_secret.model_signing_key.secret_id,
  ])
  
  secret_id = each.value
  role      = "roles/secretmanager.viewer"
  member    = "group:${var.admin_group_email}"
}