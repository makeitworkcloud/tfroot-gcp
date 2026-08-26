resource "google_apikeys_key" "this" {
  for_each = var.api_keys

  name         = each.key
  project      = google_project.this.project_id
  display_name = each.value.display_name

  restrictions {
    dynamic "api_targets" {
      for_each = each.value.api_targets

      content {
        service = api_targets.value
      }
    }

    dynamic "browser_key_restrictions" {
      for_each = length(each.value.allowed_referrers) > 0 ? [each.value.allowed_referrers] : []

      content {
        allowed_referrers = browser_key_restrictions.value
      }
    }

    dynamic "server_key_restrictions" {
      for_each = length(each.value.allowed_ips) > 0 ? [each.value.allowed_ips] : []

      content {
        allowed_ips = server_key_restrictions.value
      }
    }
  }

  depends_on = [google_project_service.this]
}
