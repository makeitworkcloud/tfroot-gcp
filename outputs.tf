output "project_id" {
  description = "Created GCP project ID."
  value       = google_project.this.project_id
}

output "state_bucket_name" {
  description = "GCS bucket to configure as the OpenTofu backend after bootstrap."
  value       = google_storage_bucket.state.name
}

output "sops_kms_resource" {
  description = "Cloud KMS resource for SOPS gcp_kms recipients."
  value       = google_kms_crypto_key.sops.id
}

output "terraformer_service_account_email" {
  description = "GitHub Actions Workload Identity Federation service account email."
  value       = google_service_account.terraformer.email
}

output "github_workload_identity_provider" {
  description = "GitHub Actions Workload Identity Provider resource name."
  value       = google_iam_workload_identity_pool_provider.github.name
}
