SHELL      := /bin/bash
TOFU       := $(shell command -v tofu)
GCS_BUCKET ?= makeitworkcloud-tf-gcp-infra
GCS_PREFIX ?= state

.PHONY: help bootstrap-prepare bootstrap-plan bootstrap-apply bootstrap-migrate init plan apply test pre-commit-config pre-commit-check-deps pre-commit-install-hooks

help:
	@echo "General targets"
	@echo "----------------"
	@echo
	@echo "\thelp: show this help text"
	@echo "\ttest: fetch canonical pre-commit config and run checks"
	@echo
	@echo "OpenTofu targets"
	@echo "----------------"
	@echo
	@echo "\tbootstrap-plan: create a local bootstrap workspace and plan initial GCP resources"
	@echo "\tbootstrap-apply: apply the reviewed local bootstrap plan"
	@echo "\tbootstrap-migrate: migrate local bootstrap state to the created GCS backend"
	@echo "\tinit: initialize the migrated GCS backend"
	@echo "\tplan: run an OpenTofu plan using the GCS backend"
	@echo "\tapply: run an OpenTofu apply using the GCS backend"
	@echo
	@echo "Bootstrap order: bootstrap-plan, bootstrap-apply, bootstrap-migrate, then init."

bootstrap-prepare:
	@rm -rf .bootstrap
	@mkdir .bootstrap
	@rsync -a --exclude .git --exclude .terraform --exclude .bootstrap ./ .bootstrap/
	@perl -0pi -e 's/\n  backend "gcs" \{\}\n//' .bootstrap/providers.tf
	@$(TOFU) -chdir=.bootstrap init -input=false

bootstrap-plan: bootstrap-prepare
	@$(TOFU) -chdir=.bootstrap plan -compact-warnings -out=bootstrap.plan

bootstrap-apply:
	@test -f .bootstrap/bootstrap.plan || (echo "Run 'make bootstrap-plan' and review the plan before applying." && exit 1)
	@$(TOFU) -chdir=.bootstrap apply -compact-warnings bootstrap.plan

bootstrap-migrate:
	@test -f .bootstrap/terraform.tfstate || (echo "Bootstrap state is missing; run 'make bootstrap-apply' first." && exit 1)
	@cp .bootstrap/terraform.tfstate terraform.tfstate
	@rm -rf .terraform
	@$(TOFU) init -migrate-state -force-copy -input=false -backend-config="bucket=$(GCS_BUCKET)" -backend-config="prefix=$(GCS_PREFIX)"
	@rm -f terraform.tfstate
	@rm -rf .bootstrap

init:
	@$(TOFU) init -reconfigure -input=false -backend-config="bucket=$(GCS_BUCKET)" -backend-config="prefix=$(GCS_PREFIX)"

plan: init
	@$(TOFU) plan -compact-warnings

apply: init
	@$(TOFU) apply -compact-warnings

test: pre-commit-config pre-commit-install-hooks
	@pre-commit run --all-files

pre-commit-config:
	@curl --fail --silent --show-error --location \
		--output .pre-commit-config.yaml.tmp \
		https://raw.githubusercontent.com/makeitworkcloud/images/main/tfroot-runner/pre-commit-config.yaml
	@cmp -s .pre-commit-config.yaml.tmp .pre-commit-config.yaml || mv .pre-commit-config.yaml.tmp .pre-commit-config.yaml
	@rm -f .pre-commit-config.yaml.tmp

pre-commit-check-deps:
	@command -v pre-commit >/dev/null || (echo "pre-commit is required" && exit 1)

pre-commit-install-hooks: pre-commit-check-deps
	@pre-commit install --install-hooks
	@pre-commit install --hook-type commit-msg
