# terraform/modules/artifact-registry/outputs.tf

output "training_repository_id" {
  description = "Full repository ID for training images"
  value       = google_artifact_registry_repository.training_images.id
}

output "training_repository_url" {
  description = "Docker URL for training images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.training_images.repository_id}"
}

output "serving_repository_url" {
  description = "Docker URL for serving images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.serving_images.repository_id}"
}

output "python_repository_url" {
  description = "URL for Python packages"
  value       = "https://${var.region}-python.pkg.dev/${var.project_id}/${google_artifact_registry_repository.python_packages.repository_id}"
}