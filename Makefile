# Ikerian AWS Data Pipeline Makefile
# Simple commands for local testing and deployment
WORKSPACE = $$(terraform workspace show)
WORKSPACE_VARS = "-var-file=envs/$(WORKSPACE).tfvars"


.PHONY: init validate plan apply deploy destroy status

fmt:
	terraform fmt -recursive

init: fmt
	terraform init

validate:
	terraform validate

lint: init
	terraform fmt -diff -check -recursive
	terraform validate

plan:
	terraform plan $(WORKSPACE_VARS) -out=tfplan

apply:
	terraform apply -auto-approve tfplan 

# Full deployment with prerequisites check
deploy: init plan apply
	@echo "🎉 Full deployment completed successfully!"

destroy:
	terraform destroy -auto-approve;
	echo "✅ Resources destroyed successfully!";


# Check if infrastructure is deployed
status:
	@echo "📊 Deployment Status:"
	@echo ""
	@if terraform output -raw raw_data_bucket_name >/dev/null 2>&1; then \
		echo "✅ Raw Data Bucket: $$(terraform output -raw raw_data_bucket_name)"; \
	else \
		echo "❌ Raw Data Bucket: Not deployed"; \
	fi; \
	@if terraform output -raw processed_data_bucket_name >/dev/null 2>&1; then \
		echo "✅ Processed Data Bucket: $$(terraform output -raw processed_data_bucket_name)"; \
	else \
		echo "❌ Processed Data Bucket: Not deployed"; \
	fi; \
	@if terraform output -raw lambda_function_name >/dev/null 2>&1; then \
		echo "✅ Lambda Function: $$(terraform output -raw lambda_function_name)"; \
	else \
		echo "❌ Lambda Function: Not deployed"; \
	fi; \
	@if terraform output -raw cloudwatch_log_group_name >/dev/null 2>&1; then \
		echo "✅ CloudWatch Log Group: $$(terraform output -raw cloudwatch_log_group_name)"; \
	else \
		echo "❌ CloudWatch Log Group: Not deployed"; \
	fi