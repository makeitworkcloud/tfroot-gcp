resource "google_storage_bucket" "state" {
  project                     = google_project.this.project_id
  name                        = var.state_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.this]
}

resource "google_kms_key_ring" "sops" {
  project  = google_project.this.project_id
  name     = "sops"
  location = var.region

  depends_on = [google_project_service.this]
}

resource "google_kms_crypto_key" "sops" {
  name            = "sops"
  key_ring        = google_kms_key_ring.sops.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}
