variable "project_id" {
  description = "The GCP project ID where the Cloud Scheduler job will be created."
  type        = string
}

variable "region" {
  description = "The region in which to deploy the Cloud Scheduler job."
  type        = string
  default     = "europe-west1"
}

variable "job_name" {
  description = "Name of the Cloud Scheduler job."
  type        = string
}

variable "schedule" {
  description = "Cron schedule expression for the job. Example: every 5 minutes = '*/5 * * * *'"
  type        = string
}

variable "time_zone" {
  description = "Time zone for the job schedule."
  type        = string
  default     = "Etc/UTC"
}

variable "target_uri" {
  description = "The HTTP endpoint or Cloud Run URL to trigger."
  type        = string
}

variable "target_audience" {
  description = "The OIDC audience claim (usually same as target_uri)."
  type        = string
}

variable "target_name" {
  description = "Human-readable name of the target system or service."
  type        = string
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod."
  type        = string
}
