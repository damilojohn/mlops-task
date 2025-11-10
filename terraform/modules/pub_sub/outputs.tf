# Pub/Sub Topic Outputs
output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic"
  value       = google_pubsub_topic.topic.name
}

output "pubsub_topic_id" {
  description = "Fully qualified Pub/Sub topic ID"
  value       = google_pubsub_topic.topic.id
}

# Pub/Sub Subscription Outputs
output "pubsub_subscription_name" {
  description = "Name of the Pub/Sub subscription"
  value       = google_pubsub_subscription.subscription.name
}

output "pubsub_subscription_id" {
  description = "Fully qualified Pub/Sub subscription ID"
  value       = google_pubsub_subscription.subscription.id
}

output "pubsub_subscription_push_endpoint" {
  description = "Push endpoint URL if configured"
  value       = google_pubsub_subscription.subscription.push_config[0].push_endpoint
  condition   = length(google_pubsub_subscription.subscription.push_config) > 0
}
