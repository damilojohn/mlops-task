# terraform/modules/secrets/outputs.tf

output "api_auth_token_secret_id" {
  description = "Secret ID for API authentication token"
  value       = google_secret_manager_secret.api_auth_token.secret_id
}

output "api_auth_token_secret_name" {
  description = "Full secret name"
  value       = google_secret_manager_secret.api_auth_token.name
}

output "model_signing_key_secret_id" {
  description = "Secret ID for model signing key"
  value       = google_secret_manager_secret.model_signing_key.secret_id
}

output "bigquery_sa_key_secret_id" {
  description = "Secret ID for BigQuery service account key (if created)"
  value       = var.create_bigquery_secret ? google_secret_manager_secret.bigquery_sa_key[0].secret_id : null
}

output "third_party_secret_ids" {
  description = "Map of third-party secret names to secret IDs"
  value = {
    for name in var.third_party_secret_names :
    name => google_secret_manager_secret.third_party_keys[name].secret_id
  }
}