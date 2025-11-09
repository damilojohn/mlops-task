# terraform/modules/cloud-run/main.tf

# Enable Cloud Run API
resource "google_project_service" "cloud_run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Cloud Run service for model predictions
resource "google_cloud_run_v2_service" "prediction_api" {
  name     = "claim-prediction-api-${var.environment}"
  location = var.region
  ingress  = var.ingress_settings
  
  template {
    # Scaling configuration
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    
    # Service account
    service_account = var.service_account_email
    
    # Timeout
    timeout = "${var.timeout_seconds}s"
    
    # Container configuration
    containers {
      image = var.container_image
      
      # Resource limits
      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle          = false  # Always allocate CPU (better latency)
        startup_cpu_boost = true   # Boost CPU during startup
      }
      
      # Environment variables
      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
      
      env {
        name  = "GCP_PROJECT_ID"
        value = var.project_id
      }
      
      env {
        name  = "MODEL_BUCKET"
        value = var.model_bucket_name
      }
      
      env {
        name  = "BIGQUERY_DATASET"
        value = var.bigquery_predictions_dataset
      }
      
      # Secrets from Secret Manager
      env {
        name = "API_AUTH_TOKEN"
        value_source {
          secret_key_ref {
            secret  = var.api_auth_secret_id
            version = "latest"
          }
        }
      }
      
      # Health check endpoint
      startup_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 3
      }
      
      liveness_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 30
        timeout_seconds       = 3
        period_seconds        = 30
        failure_threshold     = 3
      }
      
      # Port
      ports {
        name           = "http1"
        container_port = 8080
      }
    }
    
    # VPC connector for private access to other GCP services
    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }
    
    # Labels and annotations
    labels = {
      environment = var.environment
      service     = "prediction-api"
      managed_by  = "terraform"
    }
    
    annotations = {
      "run.googleapis.com/launch-stage" = "BETA"
      "autoscaling.knative.dev/maxScale" = tostring(var.max_instances)
      "autoscaling.knative.dev/minScale" = tostring(var.min_instances)
    }
  }
  
  # Traffic routing (supports blue-green deployments)
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  
  lifecycle {
    ignore_changes = [
      # Allow manual traffic splitting during deployments
      traffic,
    ]
  }
}

# IAM: Allow public access (authentication handled by API)
# Or restrict to specific service accounts
resource "google_cloud_run_service_iam_member" "public_access" {
  count = var.allow_public_access ? 1 : 0
  
  location = google_cloud_run_v2_service.prediction_api.location
  service  = google_cloud_run_v2_service.prediction_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# IAM: Allow specific service accounts (e.g., frontend service)
resource "google_cloud_run_service_iam_member" "authorized_invokers" {
  for_each = toset(var.authorized_invokers)
  
  location = google_cloud_run_v2_service.prediction_api.location
  service  = google_cloud_run_v2_service.prediction_api.name
  role     = "roles/run.invoker"
  member   = each.value
}

# Cloud Run domain mapping (custom domain)
resource "google_cloud_run_domain_mapping" "custom_domain" {
  count = var.custom_domain != null ? 1 : 0
  
  location = google_cloud_run_v2_service.prediction_api.location
  name     = var.custom_domain
  
  metadata {
    namespace = var.project_id
  }
  
  spec {
    route_name = google_cloud_run_v2_service.prediction_api.name
  }
}

# Cloud Armor security policy (if needed)
resource "google_compute_security_policy" "cloud_run_policy" {
  count = var.enable_cloud_armor ? 1 : 0
  
  name        = "cloud-run-api-policy-${var.environment}"
  description = "Security policy for Cloud Run API"
  
  # Default rule: deny all
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    
    description = "Default deny rule"
  }
  
  # Allow specific IP ranges
  rule {
    action   = "allow"
    priority = "1000"
    
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.allowed_ip_ranges
      }
    }
    
    description = "Allow specific IP ranges"
  }
  
  # Rate limiting
  rule {
    action   = "rate_based_ban"
    priority = "2000"
    
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      
      enforce_on_key = "IP"
      
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      
      ban_duration_sec = 600  # 10 minutes
    }
    
    description = "Rate limit: 100 requests per minute per IP"
  }
}