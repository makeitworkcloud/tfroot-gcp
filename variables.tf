variable "project_id" {
  description = "Globally unique GCP project ID to create and manage."
  type        = string
  default     = "makeitworkcloud"
}

variable "project_name" {
  description = "Human-readable GCP project name."
  type        = string
  default     = "Make IT Work Cloud"
}

variable "billing_account_id" {
  description = "Billing account ID without the billingAccounts/ prefix."
  type        = string
  default     = "01927F-E3CF2E-1488D3"
}

variable "folder_id" {
  description = "Optional folder ID for the project. Leave null to create at the organization root."
  type        = string
  default     = null
  nullable    = true
}

variable "org_id" {
  description = "Optional organization ID for the project. Leave null for a standalone project."
  type        = string
  default     = null
  nullable    = true
}

variable "region" {
  description = "Primary region for regional services, the state bucket, and the SOPS KMS key ring."
  type        = string
  default     = "us-west3"
}

variable "state_bucket_name" {
  description = "Globally unique GCS bucket name for the migrated OpenTofu state backend."
  type        = string
  default     = "makeitworkcloud-tf-gcp-infra"
}

variable "terraformer_service_account_id" {
  description = "Account ID of the GitHub Actions Workload Identity Federation service account."
  type        = string
  default     = "terraformer"
}

variable "terraformer_project_roles" {
  description = "Project roles granted to the automation service account. Keep this explicit because broad roles affect all project resources."
  type        = set(string)
  default     = ["roles/owner"]
}

variable "api_keys" {
  description = "Named API keys with mandatory API and application restrictions. API key strings are deliberately not output."
  type = map(object({
    display_name      = string
    api_targets       = set(string)
    allowed_referrers = optional(set(string), [])
    allowed_ips       = optional(set(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for key in values(var.api_keys) :
      length(key.api_targets) > 0 &&
      ((length(key.allowed_referrers) > 0 && length(key.allowed_ips) == 0) ||
      (length(key.allowed_referrers) == 0 && length(key.allowed_ips) > 0))
    ])
    error_message = "Every API key must have at least one API target and exactly one application restriction type: allowed_referrers or allowed_ips."
  }
}

variable "monthly_budget_usd" {
  description = "Optional whole-dollar monthly billing budget. Set null to defer budget creation."
  type        = number
  default     = null
  nullable    = true

  validation {
    condition     = var.monthly_budget_usd == null || var.monthly_budget_usd > 0
    error_message = "monthly_budget_usd must be positive when set."
  }
}
