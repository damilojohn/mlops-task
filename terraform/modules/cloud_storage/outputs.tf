
output "model_artifacts_bucket_name" {
  description = "Name of bucket storing model artifacts"
  value       = google_storage_bucket.model_artifacts.name
}

output "model_artifacts_bucket_url" {
  description = "GCS URL for model artifacts"
  value       = google_storage_bucket.model_artifacts.url
}

output "training_data_bucket_name" {
  description = "Name of bucket storing training data snapshots"
  value       = google_storage_bucket.training_data.name
}

output "pipeline_artifacts_bucket_name" {
  description = "Name of bucket for Vertex AI pipeline artifacts"
  value       = google_storage_bucket.pipeline_artifacts.name
}

output "logs_bucket_name" {
  description = "Name of bucket for logs (if enabled)"
  value       = var.enable_log_bucket ? google_storage_bucket.logs[0].name : null
}