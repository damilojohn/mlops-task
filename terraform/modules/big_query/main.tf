# terraform/modules/bigquery/main.tf

# Dataset for raw data (source of truth from operational systems)
resource "google_bigquery_dataset" "raw_data" {
  dataset_id    = "lakehouse_${var.environment}_raw"
  friendly_name = "Raw operational data"
  description   = "Immutable raw data from source systems"
  location      = "EU"
  
  default_table_expiration_ms = null  # Never expire raw data
  
  labels = {
    environment = var.environment
    purpose     = "raw-data"
    managed_by  = "terraform"
  }
  
  access {
    role          = "OWNER"
    user_by_email = var.data_team_email
  }
  
  access {
    role          = "READER"
    group_by_email = var.data_scientist_group_email
  }
}

# Dataset for feature-engineered data
resource "google_bigquery_dataset" "features" {
  dataset_id    = "lakehouse_${var.environment}_features"
  friendly_name = "Feature store"
  description   = "Engineered features for ML models"
  location      = "EU"
  
  default_table_expiration_ms = 7776000000  # 90 days (features can be regenerated)
  
  labels = {
    environment = var.environment
    purpose     = "features"
    managed_by  = "terraform"
  }
  
  access {
    role          = "READER"
    group_by_email = var.data_scientist_group_email
  }
  
  access {
    role          = "WRITER"
    user_by_email = var.vertex_ai_service_account_email
  }
}

# Dataset for model predictions
resource "google_bigquery_dataset" "predictions" {
  dataset_id    = "lakehouse_${var.environment}_predictions"
  friendly_name = "Model predictions"
  description   = "Real-time and batch prediction outputs"
  location      = "EU"
  
  default_table_expiration_ms = null  # Keep predictions indefinitely
  
  labels = {
    environment = var.environment
    purpose     = "predictions"
    managed_by  = "terraform"
  }
}

# Dataset for model monitoring metrics
resource "google_bigquery_dataset" "monitoring" {
  dataset_id    = "lakehouse_${var.environment}_monitoring"
  friendly_name = "Model monitoring"
  description   = "Model performance metrics, drift detection, feature distributions"
  location      = "EU"
  
  default_table_expiration_ms = 15552000000  # 180 days
  
  labels = {
    environment = var.environment
    purpose     = "monitoring"
    managed_by  = "terraform"
  }
}

# Example table: Claims data (partitioned and clustered)
resource "google_bigquery_table" "claims" {
  dataset_id = google_bigquery_dataset.raw_data.dataset_id
  table_id   = "claims"
  
  description = "Insurance claims data"
  
  time_partitioning {
    type  = "DAY"
    field = "claim_date"  # Partition by claim date
  }
  
  clustering = ["policy_id", "claim_status"]  # Cluster for common queries
  
  schema = jsonencode([
    {
      name = "claim_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "policy_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "claim_date"
      type = "DATE"
      mode = "REQUIRED"
    },
    {
      name = "claim_amount"
      type = "FLOAT64"
      mode = "REQUIRED"
    },
    {
      name = "claim_status"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "is_leakage"
      type = "BOOLEAN"
      mode = "NULLABLE"
      description = "Ground truth label for model training"
    },
    {
      name = "ingested_at"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    }
  ])
  
  labels = {
    environment = var.environment
    sensitive   = "true"  # Contains PII
  }
}

# Predictions table (where batch/realtime predictions are written)
resource "google_bigquery_table" "claim_predictions" {
  dataset_id = google_bigquery_dataset.predictions.dataset_id
  table_id   = "claim_leakage_predictions"
  
  description = "Claim leakage model predictions"
  
  time_partitioning {
    type  = "DAY"
    field = "predicted_at"
  }
  
  clustering = ["model_version", "prediction_confidence"]
  
  schema = jsonencode([
    {
      name = "prediction_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "claim_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "model_version"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "prediction"
      type = "BOOLEAN"
      mode = "REQUIRED"
      description = "Predicted leakage (true/false)"
    },
    {
      name = "prediction_confidence"
      type = "FLOAT64"
      mode = "REQUIRED"
      description = "Model confidence score (0-1)"
    },
    {
      name = "predicted_at"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "prediction_type"
      type = "STRING"
      mode = "REQUIRED"
      description = "realtime or batch"
    }
  ])
}

# IAM: Allow Vertex AI to read training data
resource "google_bigquery_dataset_iam_member" "vertex_ai_reader" {
  dataset_id = google_bigquery_dataset.raw_data.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.vertex_ai_service_account_email}"
}

# IAM: Allow Cloud Run to write predictions
resource "google_bigquery_dataset_iam_member" "cloudrun_writer" {
  dataset_id = google_bigquery_dataset.predictions.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.cloudrun_service_account_email}"
}