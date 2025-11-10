terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.6.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "topic" {
  name = var.topic_name
}


resource "google_pubsub_subscription" "subscription" {
  name  = var.subscription_name
  topic = google_pubsub_topic.topic.name

  ack_deadline_seconds = var.ack_deadline_seconds


  push_config {
    push_endpoint = var.push_endpoint
 
    oidc_token {
      service_account_email = var.push_sa_email
    }
  }
}
