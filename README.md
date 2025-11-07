# ManyPets MLOps Engineer Task

## Business Case

ManyPets processes thousands of pet insurance claims every day.  
The Data Science team has developed a model that predicts the probability of **claim leakage** — situations where a claim might be overpaid or misclassified.

The team now wants to deploy this model so it can be used in both:
- **Offline batch pipelines** (daily leakage scoring reports)
- **Online APIs** (real-time insights for claims handlers)

You are the **MLOps Engineer** responsible for designing the infrastructure, CI/CD workflows, and monitoring to operationalize this model on **Google Cloud Platform (GCP)** using **Vertex AI**.

---

## Objective

Design and document a **cloud-native MLOps platform** for deploying and managing ML models on GCP Vertex AI.  
Demonstrate how Data Scientists can train, containerize, deploy, and monitor models efficiently and safely.

You are expected to propose an architecture, outline Terraform modules, define CI/CD workflows, and document monitoring and release strategies.

---

## Deliverables Overview

| Section | Deliverable | Format |
|----------|--------------|--------|
| 1 | Architecture diagram and design document | PDF / Markdown |
| 2 | Terraform module structure | Code or pseudocode |
| 3 | CI/CD workflow | YAML or diagram |
| 4 | Model container contract | FastAPI spec and Dockerfile |
| 5 | Monitoring specification | Table or Markdown document |
| 6 | Release and rollback strategy | Documentation |

---

## Part 1 — Solution Design

### Task
Draw and document a **high-level architecture** for deploying ML models to GCP Vertex AI.

The design should describe how:
- Data Scientists train models using data from the **ManyPets Lakehouse** (BigQuery).
- Models are packaged and stored in **Artifact Registry** or **Cloud Storage**.
- Deployments are managed with **Terraform** and **CI/CD pipelines**.
- Model endpoints are served via **Vertex AI** or **Cloud Run**.
- Monitoring and alerting are handled via **Cloud Monitoring** and **Logging**.

### Deliverables
- Architecture diagram (can be drawn in draw.io, Miro, or similar).
- Short design document explaining:
  - GCP components and their roles.
  - Repository strategy (mono-repo vs. multi-repo) and reasoning.
  - How multiple models and environments (dev/prod) are supported.
  - Secrets management and security considerations.

---

## Part 2 — Infrastructure as Code (Terraform)

### Task
Outline **Terraform modules** to provision the core MLOps infrastructure.

### Required Modules

| Resource | Description |
|-----------|--------------|
| Artifact Registry | To store model Docker images. |
| Cloud Storage | For storing model binaries (`model.pkl`) and training artifacts. |
| Vertex AI Endpoint or Cloud Run Service | To serve the deployed models. |
| Secret Manager | To manage sensitive configuration and API keys. |
| Cloud Monitoring & Logging | To collect metrics and logs. |
| IAM Roles & Service Accounts | For secure role-based access control. |

### Requirements
- Parameterize resources for multiple environments (dev, prod).
- Keep modules reusable across multiple model projects.
- Include teardown considerations (safe cleanup of resources).

---

## Part 3 — CI/CD Pipelines

### Task
Define a **CI/CD pipeline** to handle both pull requests and deployments using GitHub Actions, GitLab CI, or Cloud Build.

### Requirements

#### Pull Request Workflow
- Lint and validate Terraform (`terraform fmt`, `terraform validate`).
- Run infrastructure unit tests and security scans (e.g., Trivy, tfsec).

#### Merge to Main Workflow
- Build and push the Docker image to Artifact Registry.
- Generate and archive a Terraform plan artifact.
- Apply changes automatically to **dev**.
- Require **manual approval** to deploy to **prod**.

#### Example Workflow (YAML Sketch)
```yaml
name: model-deploy

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: terraform fmt -check
      - run: terraform validate

  build-deploy:
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v3
      - run: docker build -t $IMAGE_TAG .
      - run: docker push $IMAGE_TAG
      - run: terraform plan -out=tfplan
      - run: terraform apply -auto-approve
```

---

## Part 4 — Model Training and Inference

### Task

You are provided with a notebook (train_leakage_model.ipynb) that demonstrates how the ManyPets Data Science team trains a simple leakage model using claims data.

Your task is to take this research-grade artifact and make it production-ready. Specifically:

1. Reproduce and refine the notebook to export a model file (model.pkl) that can be used for inference.
2. Create an inference service container (e.g., FastAPI or Flask) that loads this model and exposes:
   - /healthz – service health endpoint 
   - /predict – returns predictions given JSON claim data
3. Ensure the container adheres to the API contract provided in api_contract.yaml.
4. Prepare the container so it can be deployed on Vertex AI or Cloud Run. 
5. Document how the model artifact would be versioned and stored for deployment (e.g., in Artifact Registry or GCS).

The goal is not to improve the model’s accuracy but to demonstrate the workflow of operationalizing a trained model from notebook to deployable asset.

---

## Part 5 — Monitoring and Alerts

### Task
Define infrastructure and data-level monitoring specifications.

| Category | Metric | Description | Alert Threshold |
|-----------|---------|--------------|-----------------|
| Infrastructure | Uptime | Endpoint availability | Alert if <99% uptime in 15 minutes |
| Infrastructure | Latency | Average response time | Alert if >500 ms |
| Infrastructure | Error rate | 5xx error percentage | Alert if >2% |
| Data | Schema validation | Missing or unexpected fields | Alert if schema fails >5 times in 10 min |
| Data | Prediction drift | Mean probability drift vs baseline | Alert if deviation >20% |

You may describe how to expose metrics via Cloud Monitoring or Prometheus.

---

## Part 6 — Release and Rollback Strategy

### Scenario
The Data Science team produces a new version (`v2`) of the leakage model trained on fresher data.

### Task
Describe how to deploy v2 without disrupting v1.

- Choose one release strategy (blue/green, canary, or shadow).
- Explain traffic routing and cutover approach.
- Describe how rollback would occur if metrics degrade (e.g., revert Terraform plan, redeploy previous image tag).

---

## Starter Pack Files

| File                                     | Description                                    |
|------------------------------------------|------------------------------------------------|
| `starter_pack/train_leakage_model.ipynb` | Example notebook training a leakage model      |
| `starter_pack/sample_payload.json`       | 10 claims example prediction requests          |
| `starter_pack/api_contract.yaml`         | OpenAPI 3.0 spec for `/predict` and `/healthz` |
---

## Submission Guidelines

- Deliver your solution as a GitHub repository or ZIP file.
- Include your architecture diagram, IaC outlines, CI/CD YAMLs, and documentation.
- The task is designed for approximately 4–6 hours of focused work.
- You may include optional implementation details or diagrams for clarity.
