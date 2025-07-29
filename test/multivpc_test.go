package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestMultiVPCBasic(t *testing.T) {
	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code
		TerraformDir: "../examples/basic",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"name_prefix": "test-multivpc",
		},

		// Environment variables to set
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},

		// Retry up to 3 times with 10 seconds between retries
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,

		// Disable colors in Terraform output
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	transitGatewayID := terraform.Output(t, terraformOptions, "transit_gateway_id")
	vpcIDs := terraform.OutputMap(t, terraformOptions, "vpc_ids")
	subnetIDs := terraform.OutputMap(t, terraformOptions, "subnet_ids")

	// Assertions
	assert.NotEmpty(t, transitGatewayID, "Transit Gateway ID should not be empty")
	assert.NotEmpty(t, vpcIDs, "VPC IDs should not be empty")
	assert.NotEmpty(t, subnetIDs, "Subnet IDs should not be empty")

	// Verify Transit Gateway exists
	aws.ValidateTransitGatewayExists(t, "us-west-2", transitGatewayID)

	// Verify VPCs exist
	for vpcKey, vpcID := range vpcIDs {
		t.Logf("Verifying VPC %s with ID %s", vpcKey, vpcID)
		aws.ValidateVpcExists(t, "us-west-2", vpcID)
	}

	// Verify subnets exist
	for vpcKey, subnetMap := range subnetIDs {
		for subnetKey, subnetID := range subnetMap {
			t.Logf("Verifying subnet %s in VPC %s with ID %s", subnetKey, vpcKey, subnetID)
			aws.ValidateSubnetExists(t, "us-west-2", subnetID)
		}
	}
}

func TestMultiVPCAdvanced(t *testing.T) {
	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code
		TerraformDir: "../examples/advanced",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"name_prefix": "test-enterprise-multivpc",
		},

		// Environment variables to set
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},

		// Retry up to 3 times with 10 seconds between retries
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,

		// Disable colors in Terraform output
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	transitGatewayID := terraform.Output(t, terraformOptions, "transit_gateway_id")
	vpcIDs := terraform.OutputMap(t, terraformOptions, "vpc_ids")
	connectivitySummary := terraform.OutputMap(t, terraformOptions, "connectivity_summary")

	// Assertions
	assert.NotEmpty(t, transitGatewayID, "Transit Gateway ID should not be empty")
	assert.NotEmpty(t, vpcIDs, "VPC IDs should not be empty")
	assert.NotEmpty(t, connectivitySummary, "Connectivity summary should not be empty")

	// Verify Transit Gateway exists
	aws.ValidateTransitGatewayExists(t, "us-west-2", transitGatewayID)

	// Verify VPCs exist
	for vpcKey, vpcID := range vpcIDs {
		t.Logf("Verifying VPC %s with ID %s", vpcKey, vpcID)
		aws.ValidateVpcExists(t, "us-west-2", vpcID)
	}

	// Verify cross-account sharing is enabled
	ramShareARN := terraform.Output(t, terraformOptions, "ram_resource_share_arn")
	assert.NotEmpty(t, ramShareARN, "RAM resource share ARN should not be empty")
}

func TestMultiVPCSecurityGroups(t *testing.T) {
	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code
		TerraformDir: "../examples/basic",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"name_prefix": "test-security-multivpc",
		},

		// Environment variables to set
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},

		// Retry up to 3 times with 10 seconds between retries
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,

		// Disable colors in Terraform output
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get security group outputs
	securityGroupIDs := terraform.OutputMap(t, terraformOptions, "security_group_ids")

	// Assertions
	assert.NotEmpty(t, securityGroupIDs, "Security group IDs should not be empty")

	// Verify security groups exist
	for vpcKey, sgMap := range securityGroupIDs {
		for sgKey, sgID := range sgMap {
			t.Logf("Verifying security group %s in VPC %s with ID %s", sgKey, vpcKey, sgID)
			aws.ValidateSecurityGroupExists(t, "us-west-2", sgID)
		}
	}
}

func TestMultiVPCCostEstimation(t *testing.T) {
	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code
		TerraformDir: "../examples/basic",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"name_prefix": "test-cost-multivpc",
		},

		// Environment variables to set
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},

		// Retry up to 3 times with 10 seconds between retries
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,

		// Disable colors in Terraform output
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get cost estimation outputs
	estimatedCost := terraform.OutputMap(t, terraformOptions, "estimated_monthly_cost")

	// Assertions
	assert.NotEmpty(t, estimatedCost, "Estimated cost should not be empty")

	// Verify cost estimation contains expected fields
	assert.Contains(t, estimatedCost, "transit_gateway", "Should contain Transit Gateway cost")
	assert.Contains(t, estimatedCost, "vpc_attachments", "Should contain VPC attachment cost")
	assert.Contains(t, estimatedCost, "total_estimated_monthly_cost", "Should contain total cost")
}

func TestMultiVPCNetworkArchitecture(t *testing.T) {
	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code
		TerraformDir: "../examples/basic",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"name_prefix": "test-arch-multivpc",
		},

		// Environment variables to set
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},

		// Retry up to 3 times with 10 seconds between retries
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,

		// Disable colors in Terraform output
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get network architecture outputs
	networkArch := terraform.OutputMap(t, terraformOptions, "network_architecture")

	// Assertions
	assert.NotEmpty(t, networkArch, "Network architecture should not be empty")

	// Verify network architecture contains expected components
	assert.Contains(t, networkArch, "transit_gateway", "Should contain Transit Gateway information")
	assert.Contains(t, networkArch, "vpcs", "Should contain VPC information")
	assert.Contains(t, networkArch, "peering_connections", "Should contain peering connection information")
}

// Test for VPC peering connections
func TestMultiVPCPeering(t *testing.T) {
	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code
		TerraformDir: "../examples/basic",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"name_prefix": "test-peering-multivpc",
		},

		// Environment variables to set
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},

		// Retry up to 3 times with 10 seconds between retries
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,

		// Disable colors in Terraform output
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get VPC peering connection outputs
	peeringConnectionIDs := terraform.OutputMap(t, terraformOptions, "vpc_peering_connection_ids")
	peeringStatus := terraform.OutputMap(t, terraformOptions, "vpc_peering_connection_status")

	// Assertions
	assert.NotEmpty(t, peeringConnectionIDs, "VPC peering connection IDs should not be empty")
	assert.NotEmpty(t, peeringStatus, "VPC peering connection status should not be empty")

	// Verify peering connections exist and are active
	for peeringKey, peeringID := range peeringConnectionIDs {
		t.Logf("Verifying VPC peering connection %s with ID %s", peeringKey, peeringID)
		aws.ValidateVpcPeeringConnectionExists(t, "us-west-2", peeringID)

		// Check if status is active
		if status, exists := peeringStatus[peeringKey]; exists {
			assert.Equal(t, "active", status, "VPC peering connection should be active")
		}
	}
}
