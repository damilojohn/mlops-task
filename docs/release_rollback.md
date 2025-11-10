Release and Rollback Strategy
Chosen Strategy: Blue/Green Deployment

We adopt a Blue/Green deployment strategy to release the new leakage model (v2) without disrupting the current production model (v1). This approach minimizes downtime and risk by running two identical environments in parallel.

1. Architecture Overview

Blue environment (current): Hosts model v1 (active version serving live traffic).

Green environment (new): Hosts model v2 (new version deployed for validation and smoke testing).

Both environments share:

The same FastAPI backend architecture.

Isolated storage (e.g., separate GCS buckets or MongoDB collections for inference logs).

Identical infrastructure provisioned via Terraform.

2. Deployment Process

Build and Tag New Image

The CI/CD pipeline builds a new Docker image for v2 and pushes it to the container registry:

gcr.io/pocketcoach/leakage-model:v2


Provision Green Environment

Terraform creates a parallel set of compute instances or Cloud Run services for leakage-service-green.

Environment variables and IAM permissions are synced with the Blue environment.

Endpoint:

https://manypets.com/api/v2/predict


Smoke Test and Validation

Automated tests verify that:

API routes respond correctly.

Latency and response schema are consistent.

Metrics and logs are flowing correctly into monitoring.

Traffic Routing (Cutover)

Once v2 passes validation, traffic gradually shifts via a load balancer (e.g., Cloud Load Balancing or Envoy):

Start with 10% traffic to Green.

Monitor metrics (latency, error rate, prediction drift).

Gradually increase to 100% once stable.

Example routing policy:

traffic_split:
  - service: leakage-blue
    percent: 90
  - service: leakage-green
    percent: 10

3. Monitoring and Validation

Metrics collected via Prometheus / Cloud Monitoring:

Latency (p95): Should remain within ±10% of v1 baseline.

Error rate (5xx): Must stay <2%.

Prediction drift: Should not exceed 20% from baseline.

If thresholds are exceeded, automatic alerts trigger rollback procedures.

4. Rollback Procedure (Modified)
If degradation or anomalies are detected:

Traffic Reversion Instantly reroute all traffic to the Blue (v1) environment. Since the previous stable version is still running in the service, this is instantaneous:

gcloud run services update-traffic leakage-service-prod --to-latest --no-traffic-tags
# This command points traffic back to the original stable revision.
Container Rollback (If necessary) If the service itself failed to deploy or needs full reversion, we use the rollback- tag created by the CD pipeline to redeploy the exact previous image:

# 1. Retrieve the latest rollback tag
ROLLBACK_TAG=$(gcloud container images list-tags \
  ${{ env.GCP_REGION }}-docker.pkg.dev/manypets-ml-prod/serving-images/prediction-api \
  --filter="tags:rollback*" \
  --format="value(tags)" \
  --limit=1)

# 2. Deploy the previous image, ensuring a complete service revert
gcloud run deploy leakage-service-prod \
  --image=${{ env.GCP_REGION }}-docker.pkg.dev/manypets-ml-prod/serving-images/prediction-api:$ROLLBACK_TAG \
  --region=${{ env.GCP_REGION }} \
  --platform=managed
Terraform Synchronization The rollback is primarily handled by the traffic shift and the gcloud run deploy command. After rollback, the CD pipeline should be re-run manually with the previous successful version to ensure the Terraform state (.tfstate) is correctly synchronized to the reverted model version.

5. Advantages

Zero-downtime deployment.

Instant rollback capability.

Safe validation of v2 under real-world load without impacting users.

Clear isolation between versions simplifies debugging and monitoring.