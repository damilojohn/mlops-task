# terraform/modules/bigquery/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "data_team_email" {
  description = "Email of data team (dataset owner)"
  type        = string
}

variable "data_scientist_group_email" {
  description = "Google Group email for data scientists"
  type        = string
}

variable "vertex_ai_service_account_email" {
  description = "Service account for Vertex AI"
  type        = string
}

variable "cloudrun_service_account_email" {
  description = "Service account for Cloud Run"
  type        = string
}