# terraform/modules/cloud-run/outputs.tf

output "service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.prediction_api.name
}

output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.prediction_api.uri
}

output "service_id" {
  description = "Cloud Run service ID"
  value       = google_cloud_run_v2_service.prediction_api.id
}

output "latest_revision_name" {
  description = "Latest revision name"
  value       = google_cloud_run_v2_service.prediction_api.latest_ready_revision
}