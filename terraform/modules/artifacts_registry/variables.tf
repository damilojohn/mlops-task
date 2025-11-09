# terraform/modules/artifact-registry/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Artifact Registry"
  type        = string
  default     = "europe-west2"  # London for ManyPets
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "cicd_service_account_email" {
  description = "Service account for CI/CD pipeline (needs write access)"
  type        = string
}

variable "vertex_ai_service_account_email" {
  description = "Service account for Vertex AI training jobs"
  type        = string
}

variable "cloudrun_service_account_email" {
  description = "Service account for Cloud Run serving"
  type        = string
}