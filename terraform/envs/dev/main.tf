# terraform/environments/prod/main.tf

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    bucket = "manypets-ml-terraform-state-dev"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# IAM Module (create service accounts first)
module "iam" {
  source = "../../modules/iam"
  
  project_id                  = var.project_id
  environment                 = var.environment
  data_scientist_group_email  = var.data_scientist_group_email
  allow_api_trigger_training  = true  # no API-triggered training
  enable_github_oidc          = true
  github_repository           = var.github_repository
}

# Artifact Registry Module
module "artifact_registry" {
  source = "../../modules/artifact-registry"
  
  project_id                         = var.project_id
  region                             = var.region
  environment                        = var.environment
  cicd_service_account_email         = module.iam.cicd_sa_email
  vertex_ai_service_account_email    = module.iam.vertex_ai_training_sa_email
  cloudrun_service_account_email     = module.iam.cloudrun_serving_sa_email
}

# Storage Module
module "storage" {
  source = "../../modules/storage"
  
  project_id                         = var.project_id
  region                             = var.region
  environment                        = var.environment
  enable_log_bucket                  = true
  vertex_ai_service_account_email    = module.iam.vertex_ai_training_sa_email
  cloudrun_service_account_email     = module.iam.cloudrun_serving_sa_email
  cicd_service_account_email         = module.iam.cicd_sa_email
}

# BigQuery Module
module "bigquery" {
  source = "../../modules/bigquery"
  
  project_id                         = var.project_id
  environment                        = var.environment
  data_team_email                    = var.data_team_email
  data_scientist_group_email         = var.data_scientist_group_email
  vertex_ai_service_account_email    = module.iam.vertex_ai_training_sa_email
  cloudrun_service_account_email     = module.iam.cloudrun_serving_sa_email
}

# Secret Manager Module
module "secrets" {
  source = "../../modules/secrets"
  
  project_id                         = var.project_id
  region                             = var.region
  environment                        = var.environment
  create_bigquery_secret             = false
  third_party_secret_names           = ["slack-webhook", "pagerduty-key"]
  cloudrun_service_account_email     = module.iam.cloudrun_serving_sa_email
  vertex_ai_service_account_email    = module.iam.vertex_ai_training_sa_email
  cicd_service_account_email         = module.iam.cicd_sa_email
  admin_group_email                  = var.admin_group_email
}

# Vertex AI Module
module "vertex_ai" {
  source = "../../modules/vertex-ai"
  
  project_id                       = var.project_id
  region                           = var.region
  environment                      = var.environment
  create_workbench                 = true
  workbench_machine_type           = "n1-standard-8"
  workbench_gpu_enabled            = true
  workbench_service_account_email  = module.iam.data_scientist_sa_email
  create_tensorboard               = true
  create_vertex_endpoint           = false  # Using Cloud Run instead
  create_metadata_store            = true
}

# Cloud Run Module
module "cloud_run" {
  source = "../../modules/cloud-run"
  
  project_id                      = var.project_id
  region                          = var.region
  environment                     = var.environment
  container_image                 = var.api_container_image
  min_instances                   = 2  # Always-on for dev
  max_instances                   = 100
  cpu                             = "2"
  memory                          = "4Gi"
  timeout_seconds                 = 60
  service_account_email           = module.iam.cloudrun_serving_sa_email
  model_bucket_name               = module.storage.model_artifacts_bucket_name
  bigquery_predictions_dataset    = module.bigquery.predictions_dataset_id
  api_auth_secret_id              = module.secrets.api_auth_token_secret_id
  allow_public_access             = false  # Require authentication
  authorized_invokers             = var.authorized_api_invokers
  enable_cloud_armor              = true
  allowed_ip_ranges               = var.allowed_ip_ranges
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"
  
  project_id                = var.project_id
  environment               = var.environment
  logs_dataset_id           = module.bigquery.monitoring_dataset_id
  cloudrun_service_name     = module.cloud_run.service_name
  cloudrun_service_url      = module.cloud_run.service_url
  log_level                 = "INFO"
  latency_threshold_ms      = 500
  error_rate_threshold      = 5
  drift_threshold           = 0.3
  enable_drift_alerts       = true
  availability_target       = 0.999  # 99.9%
  latency_slo_target        = 0.95   # 95% under threshold
  alert_emails              = var.alert_emails
  slack_webhook_url         = var.slack_webhook_url
  slack_channel_name        = "#ml-ops-dev"
  pagerduty_service_key     = var.pagerduty_service_key
}