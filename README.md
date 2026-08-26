# Make IT Work Cloud GCP OpenTofu root

This root creates and manages the Make IT Work Cloud GCP project, its GCS
OpenTofu backend, the Cloud KMS key used by SOPS, GitHub Actions Workload
Identity Federation, project API enablement, restricted API keys, and an
optional billing budget.

## Bootstrap

Use user Application Default Credentials for the one-time bootstrap. Do not
create a service-account key file.

1. Confirm the project ID is available and that the active identity can create
   a project, attach the configured billing account, enable services, and grant
   IAM roles.
2. Run `make bootstrap-plan`. This creates an ignored, backend-free local copy
   solely for the initial stateful bootstrap.
3. Review and explicitly approve the local-state plan, then run
   `make bootstrap-apply`.
4. After the state bucket exists, run `make bootstrap-migrate` to move state
   to GCS and remove the local bootstrap workspace.
5. Configure GitHub Actions with the `github_workload_identity_provider` and
   `terraformer_service_account_email` outputs. Protect `main`, because any
   workflow in this repository can impersonate the automation account.

`terraformer_project_roles` defaults to `roles/owner` so the root can manage
all project resources. This is intentionally explicit and should be narrowed
once the required resource set is established.

## API keys

`api_keys` defaults to an empty map. Any key created by this root must define
at least one allowed API service and exactly one application restriction type:
HTTP referrers for browser clients or source IP addresses for server clients.
Use `generativelanguage.googleapis.com` as the API target for Gemini Developer
API keys. API key strings are never declared in source or outputs, but provider
state can still contain sensitive key material; protect the GCS backend
accordingly.

## SOPS

After the initial apply creates the KMS key, create encrypted application
configuration under `secrets/` with the recipient defined in `.sops.yaml`.
Never commit plaintext secrets or decrypt them to terminal output.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | ~> 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_apikeys_key.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/apikeys_key) | resource |
| [google_billing_budget.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) | resource |
| [google_iam_workload_identity_pool.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_kms_crypto_key.sops](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_key_ring.sops](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project) | resource |
| [google_project_iam_member.terraformer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account.terraformer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.github_workload_identity_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket.state](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_keys"></a> [api\_keys](#input\_api\_keys) | Named API keys with mandatory API and application restrictions. API key strings are deliberately not output. | <pre>map(object({<br/>    display_name      = string<br/>    api_targets       = set(string)<br/>    allowed_referrers = optional(set(string), [])<br/>    allowed_ips       = optional(set(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_billing_account_id"></a> [billing\_account\_id](#input\_billing\_account\_id) | Billing account ID without the billingAccounts/ prefix. | `string` | `"01927F-E3CF2E-1488D3"` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | Optional folder ID for the project. Leave null to create at the organization root. | `string` | `null` | no |
| <a name="input_monthly_budget_usd"></a> [monthly\_budget\_usd](#input\_monthly\_budget\_usd) | Optional whole-dollar monthly billing budget. Set null to defer budget creation. | `number` | `null` | no |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | Optional organization ID for the project. Leave null for a standalone project. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Globally unique GCP project ID to create and manage. | `string` | `"makeitworkcloud"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Human-readable GCP project name. | `string` | `"Make IT Work Cloud"` | no |
| <a name="input_region"></a> [region](#input\_region) | Primary region for regional services, the state bucket, and the SOPS KMS key ring. | `string` | `"us-west3"` | no |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Globally unique GCS bucket name for the migrated OpenTofu state backend. | `string` | `"makeitworkcloud-tf-gcp-infra"` | no |
| <a name="input_terraformer_project_roles"></a> [terraformer\_project\_roles](#input\_terraformer\_project\_roles) | Project roles granted to the automation service account. Keep this explicit because broad roles affect all project resources. | `set(string)` | <pre>[<br/>  "roles/owner"<br/>]</pre> | no |
| <a name="input_terraformer_service_account_id"></a> [terraformer\_service\_account\_id](#input\_terraformer\_service\_account\_id) | Account ID of the GitHub Actions Workload Identity Federation service account. | `string` | `"terraformer"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_github_workload_identity_provider"></a> [github\_workload\_identity\_provider](#output\_github\_workload\_identity\_provider) | GitHub Actions Workload Identity Provider resource name. |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | Created GCP project ID. |
| <a name="output_sops_kms_resource"></a> [sops\_kms\_resource](#output\_sops\_kms\_resource) | Cloud KMS resource for SOPS gcp\_kms recipients. |
| <a name="output_state_bucket_name"></a> [state\_bucket\_name](#output\_state\_bucket\_name) | GCS bucket to configure as the OpenTofu backend after bootstrap. |
| <a name="output_terraformer_service_account_email"></a> [terraformer\_service\_account\_email](#output\_terraformer\_service\_account\_email) | GitHub Actions Workload Identity Federation service account email. |
<!-- END_TF_DOCS -->
