# terraform/modules/monitoring/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "logs_dataset_id" {
  description = "BigQuery dataset ID for logs"
  type        = string
}

variable "cloudrun_service_name" {
  description = "Cloud Run service name to monitor"
  type        = string
}

variable "cloudrun_service_url" {
  description = "Cloud Run service URL (for uptime checks)"
  type        = string
}

variable "log_level" {
  description = "Minimum log severity to export (DEFAULT, DEBUG, INFO, WARNING, ERROR, CRITICAL)"
  type        = string
  default     = "INFO"
}

# Alerting thresholds
variable "latency_threshold_ms" {
  description = "Alert when p99 latency exceeds this (milliseconds)"
  type        = number
  default     = 500
}

variable "error_rate_threshold" {
  description = "Alert when error rate exceeds this (percentage)"
  type        = number
  default     = 5
}

variable "drift_threshold" {
  description = "Alert when drift score exceeds this value"
  type        = number
  default     = 0.3
}

variable "enable_drift_alerts" {
  description = "Enable model drift alerting"
  type        = bool
  default     = true
}

# SLO targets
variable "availability_target" {
  description = "Availability SLO target (e.g., 0.999 for 99.9%)"
  type        = number
  default     = 0.999
  
  validation {
    condition     = var.availability_target > 0 && var.availability_target <= 1
    error_message = "Availability target must be between 0 and 1"
  }
}

variable "latency_slo_target" {
  description = "Latency SLO target (e.g., 0.95 for 95% of requests)"
  type        = number
  default     = 0.95
}

# Notification channels
variable "alert_emails" {
  description = "List of email addresses for alerts"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = null
  sensitive   = true
}

variable "slack_channel_name" {
  description = "Slack channel name"
  type        = string
  default     = "#ml-ops-alerts"
}

variable "pagerduty_service_key" {
  description = "PagerDuty service key for critical alerts"
  type        = string
  default     = null
  sensitive   = true
}

variable "notification_channel_ids" {
  description = "List of notification channel IDs (pre-created channels)"
  type        = list(string)
  default     = []
}