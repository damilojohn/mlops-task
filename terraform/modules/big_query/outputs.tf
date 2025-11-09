output "raw_data_dataset_id" {
  description = "BigQuery dataset ID for raw data"
  value       = google_bigquery_dataset.raw_data.dataset_id
}

output "features_dataset_id" {
  description = "BigQuery dataset ID for features"
  value       = google_bigquery_dataset.features.dataset_id
}

output "predictions_dataset_id" {
  description = "BigQuery dataset ID for predictions"
  value       = google_bigquery_dataset.predictions.dataset_id
}

output "monitoring_dataset_id" {
  description = "BigQuery dataset ID for monitoring"
  value       = google_bigquery_dataset.monitoring.dataset_id
}

output "claims_table_id" {
  description = "Full table ID for claims"
  value       = "${google_bigquery_table.claims.project}.${google_bigquery_table.claims.dataset_id}.${google_bigquery_table.claims.table_id}"
}

output "predictions_table_id" {
  description = "Full table ID for predictions"
  value       = "${google_bigquery_table.claim_predictions.project}.${google_bigquery_table.claim_predictions.dataset_id}.${google_bigquery_table.claim_predictions.table_id}"
}