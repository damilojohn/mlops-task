# terraform/modules/cloud-run/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "container_image" {
  description = "Full container image URI"
  type        = string
}

# Scaling configuration
variable "min_instances" {
  description = "Minimum number of instances (0 for scale-to-zero)"
  type        = number
  default     = 0
  
  validation {
    condition     = var.min_instances >= 0
    error_message = "min_instances must be non-negative"
  }
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 100
  
  validation {
    condition     = var.max_instances > 0
    error_message = "max_instances must be positive"
  }
}

# Resource configuration
variable "cpu" {
  description = "Number of CPUs (e.g., '1', '2', '4')"
  type        = string
  default     = "1"
  
  validation {
    condition     = contains(["1", "2", "4", "6", "8"], var.cpu)
    error_message = "CPU must be 1, 2, 4, 6, or 8"
  }
}

variable "memory" {
  description = "Memory allocation (e.g., '512Mi', '1Gi', '2Gi')"
  type        = string
  default     = "1Gi"
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 60
  
  validation {
    condition     = var.timeout_seconds > 0 && var.timeout_seconds <= 3600
    error_message = "Timeout must be between 1 and 3600 seconds"
  }
}

# Service account
variable "service_account_email" {
  description = "Service account email for Cloud Run"
  type        = string
}

# Environment-specific config
variable "model_bucket_name" {
  description = "GCS bucket containing model artifacts"
  type        = string
}

variable "bigquery_predictions_dataset" {
  description = "BigQuery dataset for storing predictions"
  type        = string
}

variable "api_auth_secret_id" {
  description = "Secret Manager secret ID for API authentication token"
  type        = string
}

# Networking
variable "vpc_connector_id" {
  description = "VPC connector ID for private access"
  type        = string
  default     = null
}

variable "ingress_settings" {
  description = "Ingress settings (INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER)"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

# IAM
variable "allow_public_access" {
  description = "Allow unauthenticated access"
  type        = bool
  default     = false
}

variable "authorized_invokers" {
  description = "List of service accounts allowed to invoke (e.g., ['serviceAccount:sa@project.iam.gserviceaccount.com'])"
  type        = list(string)
  default     = []
}

# Custom domain
variable "custom_domain" {
  description = "Custom domain for Cloud Run service"
  type        = string
  default     = null
}

# Security
variable "enable_cloud_armor" {
  description = "Enable Cloud Armor security policy"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for Cloud Armor"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}