# terraform/modules/monitoring/main.tf

# Enable Cloud Monitoring and Logging APIs
resource "google_project_service" "monitoring" {
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging" {
  service            = "logging.googleapis.com"
  disable_on_destroy = false
}

# Log sink: Export Cloud Run logs to BigQuery
resource "google_logging_project_sink" "cloudrun_logs_to_bigquery" {
  name        = "cloudrun-logs-${var.environment}"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.logs_dataset_id}"
  
  filter = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${var.cloudrun_service_name}"
    severity >= ${var.log_level}
  EOT
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Grant log sink permission to write to BigQuery
resource "google_bigquery_dataset_iam_member" "log_sink_writer" {
  dataset_id = var.logs_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.cloudrun_logs_to_bigquery.writer_identity
}

# Log sink: Export training job logs
resource "google_logging_project_sink" "training_logs_to_bigquery" {
  name        = "training-logs-${var.environment}"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.logs_dataset_id}"
  
  filter = <<-EOT
    resource.type="aiplatform.googleapis.com/CustomJob"
    severity >= INFO
  EOT
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Log-based metric: Prediction latency
resource "google_logging_metric" "prediction_latency" {
  name   = "prediction_latency_${var.environment}"
  filter = <<-EOT
    resource.type="cloud_run_revision"
    httpRequest.requestUrl=~"/predict/*"
    httpRequest.latency!=""
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "ms"
    
    labels {
      key         = "model_name"
      value_type  = "STRING"
      description = "Name of the model being served"
    }
    
    labels {
      key         = "response_code"
      value_type  = "INT64"
      description = "HTTP response code"
    }
  }
  
  value_extractor = "EXTRACT(httpRequest.latency)"
  
  label_extractors = {
    "model_name"    = "EXTRACT(jsonPayload.model_name)"
    "response_code" = "EXTRACT(httpRequest.status)"
  }
}

# Log-based metric: Prediction error rate
resource "google_logging_metric" "prediction_errors" {
  name   = "prediction_errors_${var.environment}"
  filter = <<-EOT
    resource.type="cloud_run_revision"
    httpRequest.requestUrl=~"/predict/*"
    httpRequest.status >= 500
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    
    labels {
      key         = "error_type"
      value_type  = "STRING"
      description = "Type of error"
    }
  }
  
  label_extractors = {
    "error_type" = "EXTRACT(jsonPayload.error_type)"
  }
}

# Monitoring Dashboard: Model Performance
resource "google_monitoring_dashboard" "model_performance" {
  dashboard_json = jsonencode({
    displayName = "Model Performance - ${upper(var.environment)}"
    
    mosaicLayout = {
      columns = 12
      
      tiles = [
        # Prediction latency
        {
          width  = 6
          height = 4
          widget = {
            title = "Prediction Latency (p50, p95, p99)"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" metric.type=\"logging.googleapis.com/user/prediction_latency_${var.environment}\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_50"
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "p50"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" metric.type=\"logging.googleapis.com/user/prediction_latency_${var.environment}\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_95"
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "p95"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" metric.type=\"logging.googleapis.com/user/prediction_latency_${var.environment}\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_99"
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "p99"
                }
              ]
            }
          }
        },
        
        # Error rate
        {
          width  = 6
          height = 4
          yPos   = 0
          xPos   = 6
          widget = {
            title = "Prediction Error Rate"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" metric.type=\"logging.googleapis.com/user/prediction_errors_${var.environment}\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                        groupByFields      = ["metric.error_type"]
                      }
                    }
                  }
                  plotType = "STACKED_AREA"
                }
              ]
            }
          }
        },
        
        # Request throughput
        {
          width  = 6
          height = 4
          yPos   = 4
          widget = {
            title = "Request Throughput (req/s)"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" metric.type=\"run.googleapis.com/request_count\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        
        # Instance count
        {
          width  = 6
          height = 4
          yPos   = 4
          xPos   = 6
          widget = {
            title = "Active Instances"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" metric.type=\"run.googleapis.com/container/instance_count\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MAX"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        }
      ]
    }
  })
}

# Alert Policy: High prediction latency
resource "google_monitoring_alert_policy" "high_latency" {
  display_name = "[${upper(var.environment)}] High Prediction Latency"
  combiner     = "OR"
  
  conditions {
    display_name = "Prediction latency p99 > ${var.latency_threshold_ms}ms"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" metric.type=\"logging.googleapis.com/user/prediction_latency_${var.environment}\""
      duration        = "300s"  # 5 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = var.latency_threshold_ms
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
      }
    }
  }
  
  notification_channels = var.notification_channel_ids
  
  alert_strategy {
    auto_close = "1800s"  # Auto-close after 30 minutes
  }
  
  documentation {
    content = <<-EOT
      ## High Prediction Latency Alert
      
      The p99 latency for predictions has exceeded ${var.latency_threshold_ms}ms.
      
      **Runbook**: https://docs.manypets.com/runbooks/high-latency
      
      **Common Causes**:
      - Model loading issues
      - Cold start delays
      - Downstream service (BigQuery) slowness
      - Resource constraints (CPU/memory)
      
      **Immediate Actions**:
      1. Check Cloud Run metrics for resource utilization
      2. Review recent deployments
      3. Check for errors in logs
      4. Consider scaling up instances
    EOT
    mime_type = "text/markdown"
  }
}

# Alert Policy: High error rate
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "[${upper(var.environment)}] High Prediction Error Rate"
  combiner     = "OR"
  
  conditions {
    display_name = "Error rate > ${var.error_rate_threshold}%"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class=\"5xx\""
      duration        = "180s"  # 3 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = var.error_rate_threshold / 100
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.notification_channel_ids
  
  alert_strategy {
    auto_close = "900s"  # Auto-close after 15 minutes
  }
  
  documentation {
    content = <<-EOT
      ## High Error Rate Alert
      
      The 5xx error rate has exceeded ${var.error_rate_threshold}%.
      
      **Runbook**: https://docs.manypets.com/runbooks/high-errors
      
      **Immediate Actions**:
      1. Check Cloud Logging for error details
      2. Verify model is loaded correctly
      3. Check BigQuery connectivity
      4. Consider rolling back recent deployment
    EOT
    mime_type = "text/markdown"
  }
}

# Alert Policy: Model drift detected (custom metric from drift detection pipeline

resource "google_monitoring_alert_policy" "model_drift" {
  count = var.enable_drift_alerts ? 1 : 0
  
  display_name = "[${upper(var.environment)}] Model Drift Detected"
  combiner     = "OR"
  
  conditions {
    display_name = "Feature distribution drift exceeds threshold"
    
    condition_threshold {
      filter          = "resource.type=\"global\" metric.type=\"custom.googleapis.com/ml/feature_drift_score\""
      duration        = "0s"  # Alert immediately
      comparison      = "COMPARISON_GT"
      threshold_value = var.drift_threshold
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }
  
  notification_channels = var.notification_channel_ids
  
  alert_strategy {
    auto_close = "3600s"  # Auto-close after 1 hour
  }
  
  documentation {
    content = <<-EOT
      ## Model Drift Alert
      
      Feature distribution has drifted significantly from training distribution.
      This may indicate model performance degradation.
      
      **Runbook**: https://docs.manypets.com/runbooks/model-drift
      
      **Next Steps**:
      1. Review drift detection dashboard
      2. Compare current vs training feature distributions
      3. Check model performance metrics
      4. Consider triggering model retraining
      5. Notify data science team
    EOT
    mime_type = "text/markdown"
  }
}

# Notification Channel: Email
resource "google_monitoring_notification_channel" "email" {
  for_each = toset(var.alert_emails)
  
  display_name = "Email: ${each.value}"
  type         = "email"
  
  labels = {
    email_address = each.value
  }
  
  enabled = true
}

# Notification Channel: Slack (requires webhook setup)
resource "google_monitoring_notification_channel" "slack" {
  count = var.slack_webhook_url != null ? 1 : 0
  
  display_name = "Slack: ${var.slack_channel_name}"
  type         = "slack"
  
  labels = {
    channel_name = var.slack_channel_name
  }
  
  sensitive_labels {
    auth_token = var.slack_webhook_url
  }
  
  enabled = true
}

# Notification Channel: PagerDuty (for production critical alerts)
resource "google_monitoring_notification_channel" "pagerduty" {
  count = var.pagerduty_service_key != null ? 1 : 0
  
  display_name = "PagerDuty: ML Ops"
  type         = "pagerduty"
  
  sensitive_labels {
    service_key = var.pagerduty_service_key
  }
  
  enabled = var.environment == "prod"
}

# SLO: Prediction API Availability
resource "google_monitoring_slo" "api_availability" {
  service = google_monitoring_service.prediction_api.service_id
  
  slo_id       = "api-availability-${var.environment}"
  display_name = "Prediction API Availability"
  
  goal                = var.availability_target  # e.g., 0.999 (99.9%)
  rolling_period_days = 30
  
  request_based_sli {
    good_total_ratio {
      good_service_filter = <<-EOT
        resource.type="cloud_run_revision"
        metric.type="run.googleapis.com/request_count"
        metric.label.response_code_class!="5xx"
      EOT
      
      total_service_filter = <<-EOT
        resource.type="cloud_run_revision"
        metric.type="run.googleapis.com/request_count"
      EOT
    }
  }
}

# SLO: Prediction Latency
resource "google_monitoring_slo" "api_latency" {
  service = google_monitoring_service.prediction_api.service_id
  
  slo_id       = "api-latency-${var.environment}"
  display_name = "Prediction API Latency"
  
  goal                = var.latency_slo_target  # e.g., 0.95 (95%)
  rolling_period_days = 30
  
  request_based_sli {
    distribution_cut {
      distribution_filter = <<-EOT
        resource.type="cloud_run_revision"
        metric.type="run.googleapis.com/request_latencies"
      EOT
      
      range {
        max = var.latency_threshold_ms / 1000  # Convert to seconds
      }
    }
  }
}

# Monitoring Service definition
resource "google_monitoring_service" "prediction_api" {
  service_id   = "prediction-api-${var.environment}"
  display_name = "Prediction API (${upper(var.environment)})"
  
  user_labels = {
    environment = var.environment
    service     = "prediction-api"
  }
}

# Custom metric: Model prediction confidence distribution
resource "google_monitoring_metric_descriptor" "prediction_confidence" {
  description  = "Distribution of model prediction confidence scores"
  display_name = "Prediction Confidence"
  type         = "custom.googleapis.com/ml/prediction_confidence"
  metric_kind  = "GAUGE"
  value_type   = "DISTRIBUTION"
  unit         = "1"
  
  labels {
    key         = "model_name"
    value_type  = "STRING"
    description = "Name of the model"
  }
  
  labels {
    key         = "model_version"
    value_type  = "STRING"
    description = "Version of the model"
  }
}

# Custom metric: Feature drift score
resource "google_monitoring_metric_descriptor" "feature_drift" {
  count = var.enable_drift_alerts ? 1 : 0
  
  description  = "KL divergence score measuring feature distribution drift"
  display_name = "Feature Drift Score"
  type         = "custom.googleapis.com/ml/feature_drift_score"
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  unit         = "1"
  
  labels {
    key         = "feature_name"
    value_type  = "STRING"
    description = "Name of the feature"
  }
  
  labels {
    key         = "model_name"
    value_type  = "STRING"
    description = "Name of the model"
  }
}

# Uptime check: Health endpoint
resource "google_monitoring_uptime_check_config" "health_check" {
  display_name = "Prediction API Health Check (${var.environment})"
  timeout      = "10s"
  period       = "60s"  # Check every minute
  
  http_check {
    path         = "/health"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.cloudrun_service_url
    }
  }
  
  selected_regions = ["USA", "EUROPE"]
}