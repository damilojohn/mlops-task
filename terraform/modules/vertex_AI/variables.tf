# terraform/modules/vertex-ai/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Workbench configuration
variable "create_workbench" {
  description = "Whether to create Vertex AI Workbench instance"
  type        = bool
  default     = true
}

variable "workbench_machine_type" {
  description = "Machine type for Workbench"
  type        = string
  default     = "n1-standard-4"
}

variable "workbench_gpu_enabled" {
  description = "Enable GPU for Workbench"
  type        = bool
  default     = false
}

variable "workbench_service_account_email" {
  description = "Service account for Workbench"
  type        = string
}

# Network configuration
variable "vpc_network_name" {
  description = "VPC network name"
  type        = string
  default     = "default"
}

variable "vpc_subnet_name" {
  description = "VPC subnet name"
  type        = string
  default     = "default"
}

# Optional components
variable "create_tensorboard" {
  description = "Create Tensorboard instance"
  type        = bool
  default     = true
}

variable "create_vertex_endpoint" {
  description = "Create Vertex AI Endpoint (alternative to Cloud Run)"
  type        = bool
  default     = false  # We'll use Cloud Run
}

variable "create_metadata_store" {
  description = "Create metadata store for lineage tracking"
  type        = bool
  default     = true
}

# Security
variable "kms_key_id" {
  description = "KMS key for encryption (optional)"
  type        = string
  default     = null
}