# Outputs for Basic Multi-VPC Example

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = module.multivpc.transit_gateway_id
}

output "vpc_ids" {
  description = "Map of VPC keys to VPC IDs"
  value       = module.multivpc.vpc_ids
}

output "subnet_ids" {
  description = "Map of VPC keys to subnet IDs"
  value       = module.multivpc.subnet_ids
}

output "security_group_ids" {
  description = "Map of VPC keys to security group IDs"
  value       = module.multivpc.security_group_ids
}

output "vpc_peering_connection_ids" {
  description = "Map of peering connection keys to VPC peering connection IDs"
  value       = module.multivpc.vpc_peering_connection_ids
}

output "connectivity_summary" {
  description = "Summary of connectivity configuration"
  value       = module.multivpc.connectivity_summary
}

output "network_architecture" {
  description = "Detailed network architecture information"
  value       = module.multivpc.network_architecture
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value       = module.multivpc.estimated_monthly_cost
}

# Example of how to reference specific resources
output "app_vpc_id" {
  description = "ID of the application VPC"
  value       = module.multivpc.vpc_ids["vpc-app"]
}

output "data_vpc_id" {
  description = "ID of the data VPC"
  value       = module.multivpc.vpc_ids["vpc-data"]
}

output "app_public_subnet_ids" {
  description = "IDs of the application VPC public subnets"
  value = {
    us-west-2a = module.multivpc.subnet_ids["vpc-app"]["public-1a"]
    us-west-2b = module.multivpc.subnet_ids["vpc-app"]["public-1b"]
  }
}

output "app_private_subnet_ids" {
  description = "IDs of the application VPC private subnets"
  value = {
    us-west-2a = module.multivpc.subnet_ids["vpc-app"]["private-1a"]
    us-west-2b = module.multivpc.subnet_ids["vpc-app"]["private-1b"]
  }
}

output "data_private_subnet_ids" {
  description = "IDs of the data VPC private subnets"
  value = {
    us-west-2a = module.multivpc.subnet_ids["vpc-data"]["private-1a"]
    us-west-2b = module.multivpc.subnet_ids["vpc-data"]["private-1b"]
  }
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.multivpc.security_group_ids["vpc-app"]["web-sg"]
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.multivpc.security_group_ids["vpc-app"]["app-sg"]
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.multivpc.security_group_ids["vpc-data"]["db-sg"]
} 