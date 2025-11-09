# terraform/modules/secrets/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_bigquery_secret" {
  description = "Create secret for BigQuery service account key"
  type        = bool
  default     = false
}

variable "third_party_secret_names" {
  description = "List of third-party secret names to create (e.g., ['slack-webhook', 'datadog-api-key'])"
  type        = list(string)
  default     = []
}

# Service accounts that need access
variable "cloudrun_service_account_email" {
  description = "Cloud Run service account email"
  type        = string
}

variable "vertex_ai_service_account_email" {
  description = "Vertex AI service account email"
  type        = string
}

variable "cicd_service_account_email" {
  description = "CI/CD service account email"
  type        = string
}

variable "admin_group_email" {
  description = "Admin group email for secret metadata access"
  type        = string
}