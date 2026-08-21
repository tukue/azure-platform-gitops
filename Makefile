TF_DIR := infrastructure/environments/dev

.DEFAULT_GOAL := help

.PHONY: help init fmt validate plan apply destroy kubeconfig

help:
	@echo "Targets: init fmt validate plan apply destroy kubeconfig"

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
