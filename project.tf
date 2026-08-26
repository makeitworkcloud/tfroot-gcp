resource "google_project" "this" {
  project_id          = var.project_id
  name                = var.project_name
  billing_account     = var.billing_account_id
  folder_id           = var.folder_id
  org_id              = var.org_id
  auto_create_network = false
}

resource "google_project_service" "this" {
  for_each = local.project_services

  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}
