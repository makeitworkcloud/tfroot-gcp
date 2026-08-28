# Agent Instructions

OpenTofu root for Make IT Work Cloud Google Cloud infrastructure.

Use Application Default Credentials for bootstrap and GitHub Actions Workload Identity Federation for automation; never create, store, or use service-account keys. Bootstrap state migration to GCS is a reviewed live operation, not a server-side task.

Use GitHub MCP and PR CI plans as validation authority. `main` is an apply path after configured environment approval: use scoped branches and PRs, never direct pushes. Shared workflow and runner ownership belongs to `shared-workflows` and `images/tfroot-runner`. Keep SOPS data encrypted; never expose state, API keys, credentials, or sensitive plan output.
