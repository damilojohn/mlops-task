output "vertex_ai_training_sa_email" {
  description = "Email of Vertex AI training service account"
  value       = google_service_account.vertex_ai_training.email
}

output "cloudrun_serving_sa_email" {
  description = "Email of Cloud Run serving service account"
  value       = google_service_account.cloudrun_serving.email
}

output "cicd_sa_email" {
  description = "Email of CI/CD service account"
  value       = google_service_account.cicd.email
}

output "batch_prediction_sa_email" {
  description = "Email of batch prediction service account"
  value       = google_service_account.batch_prediction.email
}

output "data_scientist_sa_email" {
  description = "Email of data scientist service account"
  value       = google_service_account.data_scientist.email
}

output "workload_identity_pool_name" {
  description = "Name of GitHub Actions Workload Identity Pool"
  value       = var.enable_github_oidc ? google_iam_workload_identity_pool.github_actions[0].name : null
}

output "workload_identity_provider_name" {
  description = "Name of GitHub Actions Workload Identity Provider"
  value       = var.enable_github_oidc ? google_iam_workload_identity_pool_provider.github_actions[0].name : null
}