TF_DIR := infrastructure/environments/dev

.DEFAULT_GOAL := help

.PHONY: help init fmt validate plan apply destroy kubeconfig doctor onboard-demo onboard-check test-onboarding

help:
	@echo "Targets: init fmt validate plan apply destroy kubeconfig doctor onboard-demo onboard-check test-onboarding"

init:
	terraform -chdir=$(TF_DIR) init

fmt:
	terraform fmt -recursive infrastructure

validate: init
	terraform -chdir=$(TF_DIR) validate

plan: init
	terraform -chdir=$(TF_DIR) plan -var-file=dev.tfvars

apply: init
	terraform -chdir=$(TF_DIR) apply -var-file=dev.tfvars

destroy: init
	terraform -chdir=$(TF_DIR) destroy -var-file=dev.tfvars

kubeconfig:
	az aks get-credentials --resource-group $$(terraform -chdir=$(TF_DIR) output -raw resource_group_name) --name $$(terraform -chdir=$(TF_DIR) output -raw aks_name) --overwrite-existing

doctor:
	@for command in terraform az kubectl docker python; do command -v $$command >/dev/null || { echo "Missing required command: $$command"; exit 1; }; done
	@az account show --output none || { echo "Azure CLI is not authenticated. Run az login."; exit 1; }

onboard-demo:
	python scripts/onboard_application.py generate --config applications/registrations/demo-api.json --output applications/onboarded/demo-api

onboard-check:
	python scripts/onboard_application.py check --config applications/registrations/demo-api.json --output applications/onboarded/demo-api

test-onboarding:
	python -m unittest discover -s scripts -p "test_*.py"
