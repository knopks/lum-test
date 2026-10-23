AWS_PROFILE ?= lum
STACK       ?= github

export AWS_PROFILE

.PHONY: bootstrap
bootstrap:
	aws cloudformation deploy \
		--stack-name lum-test-bootstrap \
		--template-file cloudformation/bootstrap.yaml \
		--region eu-north-1 \
		--no-fail-on-empty-changeset

.PHONY: init
init:
	cd terraform/$(STACK) && terraform init

.PHONY: validate
validate:
	cd terraform/$(STACK) && terraform fmt -check -recursive
	cd terraform/$(STACK) && terraform validate

.PHONY: plan
plan:
	cd terraform/$(STACK) && terraform plan

.PHONY: apply
apply:
	cd terraform/$(STACK) && terraform apply $(ARGS)

.PHONY: destroy
destroy:
	cd terraform/$(STACK) && terraform destroy $(ARGS)
