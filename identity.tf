resource "google_service_account" "terraformer" {
  project      = google_project.this.project_id
  account_id   = var.terraformer_service_account_id
  display_name = "OpenTofu automation"

  depends_on = [google_project_service.this]
}

resource "google_project_iam_member" "terraformer" {
  for_each = var.terraformer_project_roles

  project = google_project.this.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraformer.email}"
}

# This service account is reserved for OpenCode's direct connection to the
# Google-managed Cloud CLI MCP server. It has no key and can only be
# impersonated by the named Kubernetes ServiceAccount through WIF.
resource "google_service_account" "opencode_mcp" {
  project      = google_project.this.project_id
  account_id   = "opencode-mcp"
  display_name = "OpenCode managed MCP"

  depends_on = [google_project_service.this]
}

resource "google_project_iam_member" "opencode_mcp" {
  for_each = toset([
    "roles/browser",
    "roles/cloudkms.viewer",
    "roles/iam.securityReviewer",
    "roles/mcp.toolUser",
    "roles/serviceusage.serviceUsageViewer",
  ])

  project = google_project.this.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.opencode_mcp.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = google_project.this.project_id
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
  description               = "GitHub Actions identities for ${local.github_repository}."

  depends_on = [google_project_service.this]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = google_project.this.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == \"${local.github_repository}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_workload_identity_user" {
  service_account_id = google_service_account.terraformer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.github_repository}"
}

# Kubernetes publishes the public ServiceAccount signing keys at this issuer.
# The provider accepts only the OpenCode workload identity, preventing other
# cluster workloads from impersonating the Google MCP service account.
resource "google_iam_workload_identity_pool" "kubernetes" {
  project                   = google_project.this.project_id
  workload_identity_pool_id = "kubernetes"
  display_name              = "k3s workloads"
  description               = "k3s ServiceAccount identities for Make IT Work Cloud workloads."

  depends_on = [google_project_service.this]
}

resource "google_iam_workload_identity_pool_provider" "opencode_kubernetes" {
  project                            = google_project.this.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.kubernetes.workload_identity_pool_id
  workload_identity_pool_provider_id = "opencode"
  display_name                       = "OpenCode k3s workload"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  attribute_condition = "assertion.sub == \"system:serviceaccount:opencode:opencode-mcp\""

  oidc {
    issuer_uri = "https://api.makeitwork.cloud"
  }
}

resource "google_service_account_iam_member" "opencode_mcp_workload_identity_user" {
  service_account_id = google_service_account.opencode_mcp.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.kubernetes.name}/subject/system:serviceaccount:opencode:opencode-mcp"
}
