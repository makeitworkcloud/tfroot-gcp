resource "google_billing_budget" "project" {
  count = var.monthly_budget_usd == null ? 0 : 1

  billing_account = var.billing_account_id
  display_name    = "${var.project_name} monthly budget"

  budget_filter {
    projects = ["projects/${google_project.this.number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_usd)
    }
  }

  dynamic "threshold_rules" {
    for_each = toset([0.5, 0.9, 1.0])

    content {
      threshold_percent = threshold_rules.value
    }
  }

  all_updates_rule {
    monitoring_notification_channels = []
    disable_default_iam_recipients   = true
    schema_version                   = "1.0"
  }
}
