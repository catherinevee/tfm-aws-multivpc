# Makefile for AWS Multi-VPC Connectivity Module
# Provides common operations for Terraform module management

.PHONY: help init plan apply destroy validate fmt lint test clean docs

# Default target
help:
	@echo "AWS Multi-VPC Connectivity Module - Available Commands:"
	@echo ""
	@echo "  init      - Initialize Terraform working directory"
	@echo "  plan      - Generate and show execution plan"
	@echo "  apply     - Build or change infrastructure"
	@echo "  destroy   - Destroy Terraform-managed infrastructure"
	@echo "  validate  - Validate Terraform configuration files"
	@echo "  fmt       - Format Terraform configuration files"
	@echo "  lint      - Run Terraform linting (requires tflint)"
	@echo "  test      - Run Terraform tests (requires terratest)"
	@echo "  clean     - Clean up temporary files and directories"
	@echo "  docs      - Generate documentation"
	@echo "  security  - Run security scanning (requires terrascan)"
	@echo "  cost      - Estimate infrastructure costs"
	@echo ""

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	terraform init -upgrade
	@echo "Terraform initialized successfully!"

# Generate execution plan
plan:
	@echo "Generating Terraform execution plan..."
	terraform plan -out=tfplan
	@echo "Plan generated successfully!"

# Apply infrastructure changes
apply:
	@echo "Applying Terraform configuration..."
	terraform apply tfplan
	@echo "Infrastructure deployed successfully!"

# Destroy infrastructure
destroy:
	@echo "Destroying infrastructure..."
	terraform destroy -auto-approve
	@echo "Infrastructure destroyed successfully!"

# Validate Terraform configuration
validate:
	@echo "Validating Terraform configuration..."
	terraform validate
	@echo "Configuration validation passed!"

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive
	@echo "Files formatted successfully!"

# Run Terraform linting (requires tflint)
lint:
	@echo "Running Terraform linting..."
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init; \
		tflint; \
		echo "Linting completed successfully!"; \
	else \
		echo "tflint not found. Install with: go install github.com/terraform-linters/tflint/cmd/tflint@latest"; \
		exit 1; \
	fi

# Run Terraform tests (requires terratest)
test:
	@echo "Running Terraform tests..."
	@if command -v go >/dev/null 2>&1; then \
		cd test && go test -v -timeout 30m; \
		echo "Tests completed successfully!"; \
	else \
		echo "Go not found. Please install Go to run tests."; \
		exit 1; \
	fi

# Run security scanning (requires terrascan)
security:
	@echo "Running security scanning..."
	@if command -v terrascan >/dev/null 2>&1; then \
		terrascan scan -i terraform; \
		echo "Security scanning completed!"; \
	else \
		echo "terrascan not found. Install with: curl -L \"\$$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E 'https://github.com/tenable/terrascan/releases/download/v[0-9]+\.[0-9]+\.[0-9]+/terrascan_[0-9]+\.[0-9]+\.[0-9]+_Linux_x86_64.tar.gz')\" | tar -xz terrascan && sudo mv terrascan /usr/local/bin/"; \
		exit 1; \
	fi

# Estimate infrastructure costs
cost:
	@echo "Estimating infrastructure costs..."
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path .; \
		echo "Cost estimation completed!"; \
	else \
		echo "infracost not found. Install with: curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh"; \
		exit 1; \
	fi

# Clean up temporary files
clean:
	@echo "Cleaning up temporary files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f tfplan
	rm -f *.tfstate
	rm -f *.tfstate.backup
	rm -rf .terraform.tfstate.lock.info
	@echo "Cleanup completed!"

# Generate documentation
docs:
	@echo "Generating documentation..."
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file README.md --output-mode inject .; \
		echo "Documentation generated successfully!"; \
	else \
		echo "terraform-docs not found. Install with: go install github.com/terraform-docs/terraform-docs@latest"; \
		exit 1; \
	fi

# Check for required tools
check-tools:
	@echo "Checking for required tools..."
	@command -v terraform >/dev/null 2>&1 || { echo "terraform is required but not installed. Aborting." >&2; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "aws CLI is required but not installed. Aborting." >&2; exit 1; }
	@echo "All required tools are available!"

# Setup development environment
setup-dev:
	@echo "Setting up development environment..."
	@if command -v go >/dev/null 2>&1; then \
		go install github.com/terraform-linters/tflint/cmd/tflint@latest; \
		go install github.com/terraform-docs/terraform-docs@latest; \
		go install github.com/tenable/terrascan/cmd/terrascan@latest; \
		echo "Development tools installed successfully!"; \
	else \
		echo "Go not found. Please install Go to set up development tools."; \
		exit 1; \
	fi

# Run all checks
check-all: check-tools validate fmt lint security
	@echo "All checks completed successfully!"

# Quick start for new deployments
quick-start: check-tools init validate plan
	@echo "Quick start completed! Review the plan and run 'make apply' to deploy."

# Example deployments
example-basic:
	@echo "Deploying basic example..."
	cd examples/basic && terraform init && terraform plan

example-advanced:
	@echo "Deploying advanced example..."
	cd examples/advanced && terraform init && terraform plan

# Backup state
backup:
	@echo "Creating state backup..."
	@if [ -f terraform.tfstate ]; then \
		cp terraform.tfstate terraform.tfstate.backup.$$(date +%Y%m%d_%H%M%S); \
		echo "State backup created successfully!"; \
	else \
		echo "No terraform.tfstate file found to backup."; \
	fi

# Restore state from backup
restore:
	@echo "Available backups:"
	@ls -la terraform.tfstate.backup.* 2>/dev/null || echo "No backups found"
	@echo ""
	@echo "To restore, run: cp terraform.tfstate.backup.YYYYMMDD_HHMMSS terraform.tfstate"

# Show module outputs
outputs:
	@echo "Module outputs:"
	@terraform output

# Show module resources
resources:
	@echo "Module resources:"
	@terraform state list

# Show module variables
variables:
	@echo "Module variables:"
	@terraform console -var-file=terraform.tfvars 2>/dev/null || echo "No variables file found"

# Environment-specific targets
dev: init
	@echo "Deploying to development environment..."
	terraform workspace select dev || terraform workspace new dev
	terraform apply -auto-approve

staging: init
	@echo "Deploying to staging environment..."
	terraform workspace select staging || terraform workspace new staging
	terraform apply -auto-approve

prod: init
	@echo "Deploying to production environment..."
	terraform workspace select prod || terraform workspace new prod
	terraform plan -out=tfplan
	@echo "Review the plan above and run 'make apply' to deploy to production"

# Help for specific targets
help-init:
	@echo "init: Initialize Terraform working directory"
	@echo "  This command downloads required providers and modules."

help-plan:
	@echo "plan: Generate and show execution plan"
	@echo "  This command shows what Terraform will do without making changes."

help-apply:
	@echo "apply: Build or change infrastructure"
	@echo "  This command applies the Terraform configuration."

help-destroy:
	@echo "destroy: Destroy Terraform-managed infrastructure"
	@echo "  WARNING: This will delete all resources managed by Terraform."

help-validate:
	@echo "validate: Validate Terraform configuration files"
	@echo "  This command checks for syntax errors and internal consistency."

help-fmt:
	@echo "fmt: Format Terraform configuration files"
	@echo "  This command rewrites configuration files to a canonical format."

help-lint:
	@echo "lint: Run Terraform linting"
	@echo "  This command checks for best practices and potential issues."

help-test:
	@echo "test: Run Terraform tests"
	@echo "  This command runs automated tests for the module."

help-security:
	@echo "security: Run security scanning"
	@echo "  This command scans for security vulnerabilities and compliance issues."

help-cost:
	@echo "cost: Estimate infrastructure costs"
	@echo "  This command provides cost estimates for the infrastructure." 