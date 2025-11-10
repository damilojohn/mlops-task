variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "topic_name" {
  description = "Name of the Pub/Sub topic"
  type        = string
}

variable "subscription_name" {
  description = "Name of the Pub/Sub subscription"
  type        = string
}

variable "ack_deadline_seconds" {
  description = "Ack deadline in seconds for the subscription"
  type        = number
  default     = 60
}

variable "push_endpoint" {
  description = "Optional push endpoint URL for the subscription"
  type        = string
  default     = null
}

variable "push_sa_email" {
  description = "Optional service account email for OIDC token authentication"
  type        = string
  default     = null
}
