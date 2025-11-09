# terraform/modules/vertex-ai/outputs.tf

output "workbench_instance_name" {
  description = "Name of Vertex AI Workbench instance"
  value       = var.create_workbench ? google_notebooks_instance.workbench[0].name : null
}

output "workbench_proxy_uri" {
  description = "Proxy URI to access Workbench"
  value       = var.create_workbench ? google_notebooks_instance.workbench[0].proxy_uri : null
}

output "tensorboard_name" {
  description = "Tensorboard resource name"
  value       = var.create_tensorboard ? google_vertex_ai_tensorboard.main[0].name : null
}

output "endpoint_id" {
  description = "Vertex AI Endpoint ID (if created)"
  value       = var.create_vertex_endpoint ? google_vertex_ai_endpoint.model_endpoint[0].id : null
}

output "metadata_store_name" {
  description = "Metadata store resource name"
  value       = var.create_metadata_store ? google_vertex_ai_metadata_store.main[0].name : null
}