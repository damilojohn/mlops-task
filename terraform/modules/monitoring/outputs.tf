# terraform/modules/monitoring/outputs.tf

output "dashboard_url" {
  description = "URL to monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.model_performance.id}?project=${var.project_id}"
}

output "log_sink_writer_identity" {
  description = "Writer identity for log sink (for IAM binding)"
  value       = google_logging_project_sink.cloudrun_logs_to_bigquery.writer_identity
}

output "email_notification_channel_ids" {
  description = "Map of email addresses to notification channel IDs"
  value = {
    for email, channel in google_monitoring_notification_channel.email :
    email => channel.id
  }
}

output "slack_notification_channel_id" {
  description = "Slack notification channel ID"
  value       = var.slack_webhook_url != null ? google_monitoring_notification_channel.slack[0].id : null
}

output "pagerduty_notification_channel_id" {
  description = "PagerDuty notification channel ID"
  value       = var.pagerduty_service_key != null ? google_monitoring_notification_channel.pagerduty[0].id : null
}

output "api_availability_slo_name" {
  description = "Name of API availability SLO"
  value       = google_monitoring_slo.api_availability.name
}

output "api_latency_slo_name" {
  description = "Name of API latency SLO"
  value       = google_monitoring_slo.api_latency.name
}