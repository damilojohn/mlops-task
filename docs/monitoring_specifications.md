# Monitoring & Alerting Specification

This document describes infrastructure and data-level monitoring for the ManyPets claim leakage prediction platform on GCP. It maps metrics, sources, thresholds, and actions to Terraform-managed resources (Cloud Monitoring, Cloud Logging, Vertex AI monitoring, BigQuery).

---

## Objectives
- Ensure service availability and acceptable latency for online predictions.
- Detect and surface data quality and model drift issues.
- Provide actionable alerts and dashboards for MLOps and Data Science teams.

---

## Monitoring Summary Table

| Category       | Metric (name / source)                                | Description                                                | Alert Threshold / Rule                                 |
|----------------|--------------------------------------------------------|------------------------------------------------------------|--------------------------------------------------------|
| Infrastructure | Uptime (`uptime_check`)                                | Endpoint availability (health check `/health`)             | Alert if **< 99% uptime** within **15 minutes**        |
| Infrastructure | Latency (`logging.googleapis.com/user/prediction_latency_${env}`) | Average / p99 response time for `/predict` requests        | Alert if **p99 > 500 ms** over **5 minutes**           |
| Infrastructure | Error rate (`run.googleapis.com/request_count`, 5xx)   | Percentage of 5xx responses                                | Alert if **> 2% 5xx** over **3 minutes**               |
| Infrastructure | Resource utilization (`run.googleapis.com/container/memory/utilization`) | CPU / memory high utilization                              | Alert if **> 80%** sustained for **10 minutes**        |
| Data           | Schema validation (custom metric `data_validation_failures`) | Missing/unexpected fields in incoming payloads             | Alert if **> 5 failures** in **10 minutes**            |
| Data           | Prediction drift (`custom.googleapis.com/ml/feature_drift_score`) | Per-feature drift score (KL-divergence or PSI proxy)      | Alert if **drift > 0.20** (20%) — immediate alert      |
| Data           | Prediction confidence (`custom.googleapis.com/ml/prediction_confidence`) | Distribution of model output probabilities                 | Alert if mean prob drifts **> 20%** from baseline      |
| Model          | Inference latency (`vertex.googleapis.com/onlinePrediction/latency`) | Vertex AI endpoint latency                                  | Alert if **> 300 ms** (p95)                            |
| Batch          | Batch job success rate / lag (custom)                  | Batch job completion & lag for daily batch scoring         | Alert if job fails or lag > **5 minutes**              |

---

## Metric Sources & Implementation Notes

- **Cloud Run / FastAPI**:
  - Cloud Run automatically emits HTTP metrics (request_count, request_latencies).
  - Use structured JSON logs (`jsonPayload`) with fields like `model_name`, `model_version`, `error_type`, `request_id`. These are used by log-based metrics and dashboards.
  - Expose Prometheus-style metrics using the `prometheus_fastapi_instrumentator` if you want detailed app metrics. Use Google Managed Prometheus or export custom app metrics to Cloud Monitoring from the app.

- **Vertex AI**:
  - Use Vertex AI Model Monitoring for automatic feature skew and prediction skew detection for deployed Vertex models.
  - For custom detection (e.g., non-Vertex deployed models), ingest telemetry (predictions + labels) to BigQuery and run drift evaluation jobs that publish `custom.googleapis.com/ml/feature_drift_score`.

- **BigQuery / Batch**:
  - Cloud Scheduler → Cloud Run / Vertex Batch Prediction triggers daily scoring. Write results and runner logs to BigQuery.
  - Use scheduled evaluation (daily) to compute AUC, precision, recall and update monitoring tables. Publish alerts when metrics degrade.

- **Logging & Log-based metrics**:
  - Create log sinks (Terraform: `google_logging_project_sink`) exporting to BigQuery for long-term analysis.
  - Create log-based metrics (Terraform: `google_logging_metric`) for latency and error counts (you already have `prediction_latency` and `prediction_errors`).

---

## Alerting & Routing

- **Notification channels**:
  - Slack: `#ml-infra-alerts`, using webhook-based notification channel in Terraform.
  - Email: `mlops-alerts@manypets.com`
  - PagerDuty: for critical production alerts (uptime and severe drift)

- **Escalation**:
  - Auto-notify MLOps Slack & email. PagerDuty only for production-critical failures (SLO breaches or repeated 5xx).

- **Runbooks**:
  - Each alert policy includes a runbook link. Example actions:
    - For latency: check Cloud Run CPU/memory, check model cold-start, check BigQuery query times.
    - For drift: run retrain job, create dataset snapshot, notify DS team.

---

## Dashboards

- Provision via Terraform a Cloud Monitoring dashboard that includes:
  - p50/p95/p99 latency graph (user/prediction_latency_<env>)
  - Error rate graph (5xx percent)
  - Request rate (req/s)
  - Active instances
  - Drift metrics and per-feature distribution comparison
  - Batch job success & latency

---

## Prometheus & App Metrics

- If exposing Prometheus metrics in the FastAPI app:
  - Add `/metrics` endpoint with `prometheus_fastapi_instrumentator`.
  - Prefer using **Managed Service for Prometheus** or pushing custom metrics to Cloud Monitoring using the Cloud Monitoring client library.
  - Alternatively, push aggregates directly to Cloud Monitoring via the API from within the app.

---

## SLOs

- Example SLOs to monitor:
  - **Availability**: 99.9% rolling 30-day for prediction API
  - **Latency**: 95% of requests < 300 ms

---

## Runbook Links & Contacts
- Add direct runbook links for each alert in Terraform `documentation` block.
- Primary on-call: `mlops@manypets.com`
