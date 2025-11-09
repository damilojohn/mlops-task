# terraform/modules/iam/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "data_scientist_group_email" {
  description = "Google Group email for data scientists"
  type        = string
}

variable "allow_api_trigger_training" {
  description = "Allow API service to trigger training jobs"
  type        = bool
  default     = false
}

variable "enable_github_oidc" {
  description = "Enable GitHub OIDC for Workload Identity Federation"
  type        = bool
  default     = true
}

variable "github_repository" {
  description = "GitHub repository (format: owner/repo)"
  type        = string
  default     = "manypets/ml-platform"
}