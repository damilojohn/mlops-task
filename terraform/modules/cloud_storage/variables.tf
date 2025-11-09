# terraform/modules/storage/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for storage buckets"
  type        = string
  default     = "europe-west2"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_log_bucket" {
  description = "Create a separate bucket for log exports"
  type        = bool
  default     = false
}

variable "vertex_ai_service_account_email" {
  description = "Service account for Vertex AI"
  type        = string
}

variable "cloudrun_service_account_email" {
  description = "Service account for Cloud Run"
  type        = string
}

variable "cicd_service_account_email" {
  description = "Service account for CI/CD"
  type        = string
}