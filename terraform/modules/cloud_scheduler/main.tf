terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.6.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------------
# Service Account for Cloud Scheduler
# -----------------------------------
resource "google_service_account" "scheduler_sa" {
  account_id   = "${var.job_name}-sa"
  display_name = "Service Account for ${var.job_name} Cloud Scheduler"
}

# Grant the service account permission to invoke Cloud Run or HTTP targets
resource "google_project_iam_member" "scheduler_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# ------------------------
# Cloud Scheduler Job
# ------------------------
resource "google_cloud_scheduler_job" "job" {
  name        = var.job_name
  description = "Scheduler job to trigger ${var.target_name}"
  schedule    = var.schedule
  time_zone   = var.time_zone

  http_target {
    uri         = var.target_uri
    http_method = "POST"

    headers = {
      "Content-Type" = "application/json"
    }

    body = jsonencode({
      message = "Triggered by Cloud Scheduler"
      env     = var.environment
    })

    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
      audience              = var.target_audience
    }
  }
}
