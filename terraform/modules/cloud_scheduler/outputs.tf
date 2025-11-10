ECHO is on.
# -------------------------
# Service Account Outputs
# -------------------------
output "scheduler_service_account_email" {
  description = "Email of the Cloud Scheduler service account"
  value       = google_service_account.scheduler_sa.email
}

output "scheduler_service_account_id" {
  description = "Resource ID of the Cloud Scheduler service account"
  value       = google_service_account.scheduler_sa.id
}

# -------------------------
# IAM Binding Output
# -------------------------
output "scheduler_invoker_binding" {
  description = "The IAM member binding granting invoker role"
  value       = google_project_iam_member.scheduler_invoker.member
}

# -------------------------
# Cloud Scheduler Job Outputs
# -------------------------
output "scheduler_job_name" {
  description = "The name of the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.job.name
}

output "scheduler_job_id" {
  description = "Fully qualified ID of the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.job.id
}

output "scheduler_job_uri" {
  description = "The target URI that the Cloud Scheduler job invokes"
  value       = google_cloud_scheduler_job.job.http_target[0].uri
}

output "scheduler_job_schedule" {
  description = "The cron schedule used by this Cloud Scheduler job"
  value       = google_cloud_scheduler_job.job.schedule
}

output "scheduler_job_time_zone" {
  description = "The time zone used by the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.job.time_zone
}
