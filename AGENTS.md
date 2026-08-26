# Agent Instructions

## Repository Purpose

OpenTofu root module for Make IT Work Cloud Google Cloud infrastructure.

## Git Workflow

Use a feature branch and open a pull request rather than pushing directly to
`main`. A push to `main` can invoke apply after tests pass and configured
environment gates approve it. Do not push any branch unless explicitly
requested.

## Authentication and State

Use Application Default Credentials for local bootstrap and GitHub Actions
Workload Identity Federation for automation. Do not create, store, or use
service-account key files.

The first apply uses local state to create the project, state bucket, SOPS KMS
key, and automation identity. Migrate to the GCS backend only after that apply.
Never commit OpenTofu state, plans, provider logs, decrypted SOPS data, or API
key strings.

## Pre-commit Configuration

Pre-commit configuration is centralized at
`https://raw.githubusercontent.com/makeitworkcloud/images/main/tfroot-runner/pre-commit-config.yaml`.
The root `.pre-commit-config.yaml` is generated and ignored; do not edit it.

For local development, run:
```bash
make test
```

## CI/CD

This repo uses the shared `opentofu.yml` workflow from `shared-workflows`.
The runner uses the `tfroot-runner` image, which already includes the canonical
pre-commit hooks and tooling.
