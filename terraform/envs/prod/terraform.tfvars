# terraform/environments/prod/terraform.tfvars

project_id  = "manypets-ml-prod"
region      = "europe-west2"
environment = "prod"

# IAM
data_scientist_group_email = "data-science@manypets.com"
data_team_email            = "data-team@manypets.com"
admin_group_email          = "ml-ops-admins@manypets.com"
github_repository          = "manypets/ml-platform"

# Cloud Run
api_container_image = "europe-west2-docker.pkg.dev/manypets-ml-prod/serving-images/prediction-api:v1.2.3"
authorized_api_invokers = [
  "serviceAccount:frontend-service@manypets-prod.iam.gserviceaccount.com"
]
allowed_ip_ranges = [
  "10.0.0.0/8",
  "203.0.113.0/24"
]

# Monitoring
alert_emails = [
  "ml-ops-team@manypets.com",
  "on-call@manypets.com"
]
slack_webhook_url     = "WILL_BE_SET_VIA_SECRET_MANAGER"
pagerduty_service_key = "WILL_BE_SET_VIA_SECRET_MANAGER"