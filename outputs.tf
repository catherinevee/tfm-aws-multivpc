# Multi-Account, Multi-Region, Multi-VPC Connectivity Module Outputs

# Transit Gateway Outputs
output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.main[0].id : null
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.main[0].arn : null
}

output "transit_gateway_route_table_id" {
  description = "ID of the Transit Gateway route table"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway_route_table.main[0].id : null
}

output "transit_gateway_owner_id" {
  description = "AWS Account ID of the Transit Gateway owner"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.main[0].owner_id : null
}

output "transit_gateway_amazon_side_asn" {
  description = "Amazon side ASN of the Transit Gateway"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.main[0].amazon_side_asn : null
}

output "transit_gateway_description" {
  description = "Description of the Transit Gateway"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.main[0].description : null
}

# VPC Outputs
output "vpc_ids" {
  description = "Map of VPC keys to VPC IDs"
  value       = { for k, v in aws_vpc.vpcs : k => v.id }
}

output "vpc_arns" {
  description = "Map of VPC keys to VPC ARNs"
  value       = { for k, v in aws_vpc.vpcs : k => v.arn }
}

output "vpc_cidr_blocks" {
  description = "Map of VPC keys to VPC CIDR blocks"
  value       = { for k, v in aws_vpc.vpcs : k => v.cidr_block }
}

# Subnet Outputs
output "subnet_ids" {
  description = "Map of VPC keys to subnet IDs"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      for subnet_key, subnet in aws_subnet.vpcs[vpc_key] : subnet_key => subnet.id
    }
    if vpc.subnets != null
  }
}

output "subnet_arns" {
  description = "Map of VPC keys to subnet ARNs"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      for subnet_key, subnet in aws_subnet.vpcs[vpc_key] : subnet_key => subnet.arn
    }
    if vpc.subnets != null
  }
}

output "subnet_cidr_blocks" {
  description = "Map of VPC keys to subnet CIDR blocks"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      for subnet_key, subnet in aws_subnet.vpcs[vpc_key] : subnet_key => subnet.cidr_block
    }
    if vpc.subnets != null
  }
}

# Route Table Outputs
output "route_table_ids" {
  description = "Map of VPC keys to route table IDs"
  value       = { for k, v in aws_route_table.vpcs : k => v.id }
}

output "route_table_arns" {
  description = "Map of VPC keys to route table ARNs"
  value       = { for k, v in aws_route_table.vpcs : k => v.arn }
}

# Internet Gateway Outputs
output "internet_gateway_ids" {
  description = "Map of VPC keys to Internet Gateway IDs"
  value       = { for k, v in aws_internet_gateway.vpcs : k => v.id }
}

output "internet_gateway_arns" {
  description = "Map of VPC keys to Internet Gateway ARNs"
  value       = { for k, v in aws_internet_gateway.vpcs : k => v.arn }
}

# Transit Gateway VPC Attachment Outputs
output "transit_gateway_vpc_attachment_ids" {
  description = "Map of VPC keys to Transit Gateway VPC attachment IDs"
  value = {
    for k, v in aws_ec2_transit_gateway_vpc_attachment.vpcs : k => v.id
  }
}

output "transit_gateway_vpc_attachment_arns" {
  description = "Map of VPC keys to Transit Gateway VPC attachment ARNs"
  value = {
    for k, v in aws_ec2_transit_gateway_vpc_attachment.vpcs : k => v.arn
  }
}

# VPC Peering Connection Outputs
output "vpc_peering_connection_ids" {
  description = "Map of peering connection keys to VPC peering connection IDs"
  value       = { for k, v in aws_vpc_peering_connection.peering : k => v.id }
}

output "vpc_peering_connection_arns" {
  description = "Map of peering connection keys to VPC peering connection ARNs"
  value       = { for k, v in aws_vpc_peering_connection.peering : k => v.arn }
}

output "vpc_peering_connection_status" {
  description = "Map of peering connection keys to VPC peering connection status"
  value       = { for k, v in aws_vpc_peering_connection.peering : k => v.accept_status }
}

# Security Group Outputs
output "security_group_ids" {
  description = "Map of VPC keys to security group IDs"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      for sg_key, sg in aws_security_group.vpcs[vpc_key] : sg_key => sg.id
    }
    if vpc.security_groups != null
  }
}

output "security_group_arns" {
  description = "Map of VPC keys to security group ARNs"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      for sg_key, sg in aws_security_group.vpcs[vpc_key] : sg_key => sg.arn
    }
    if vpc.security_groups != null
  }
}

# Network ACL Outputs
output "network_acl_ids" {
  description = "Map of VPC keys to network ACL IDs"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      for nacl_key, nacl in aws_network_acl.vpcs[vpc_key] : nacl_key => nacl.id
    }
    if vpc.network_acls != null
  }
}

output "network_acl_arns" {
  description = "Map of VPC keys to network ACL ARNs"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      for nacl_key, nacl in aws_network_acl.vpcs[vpc_key] : nacl_key => nacl.arn
    }
    if vpc.network_acls != null
  }
}

# Cross-Account Sharing Outputs
output "ram_resource_share_arn" {
  description = "ARN of the RAM resource share for Transit Gateway"
  value       = var.enable_cross_account_sharing && var.create_transit_gateway ? aws_ram_resource_share.transit_gateway[0].arn : null
}

output "ram_resource_share_id" {
  description = "ID of the RAM resource share for Transit Gateway"
  value       = var.enable_cross_account_sharing && var.create_transit_gateway ? aws_ram_resource_share.transit_gateway[0].id : null
}

# Connectivity Summary Outputs
output "connectivity_summary" {
  description = "Summary of connectivity configuration"
  value = {
    transit_gateway_created = var.create_transit_gateway
    vpc_count              = length(var.vpcs)
    vpcs_with_internet_gateway = length({
      for k, v in var.vpcs : k => v
      if v.create_internet_gateway
    })
    vpcs_with_transit_gateway = length({
      for k, v in var.vpcs : k => v
      if v.attach_to_transit_gateway
    })
    peering_connections_count = length(var.vpc_peering_connections)
    cross_account_sharing_enabled = var.enable_cross_account_sharing
    cross_account_principals_count = length(var.cross_account_principals)
  }
}

output "vpc_connectivity_matrix" {
  description = "Matrix showing connectivity between VPCs"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      has_internet_gateway = vpc.create_internet_gateway
      has_transit_gateway  = vpc.attach_to_transit_gateway
      peering_connections = {
        as_requester = [
          for peering_key, peering in var.vpc_peering_connections : peering.accepter_vpc_key
          if peering.requester_vpc_key == vpc_key
        ]
        as_accepter = [
          for peering_key, peering in var.vpc_peering_connections : peering.requester_vpc_key
          if peering.accepter_vpc_key == vpc_key
        ]
      }
      subnet_count = vpc.subnets != null ? length(vpc.subnets) : 0
      security_group_count = vpc.security_groups != null ? length(vpc.security_groups) : 0
    }
  }
}

# Network Architecture Outputs
output "network_architecture" {
  description = "Detailed network architecture information"
  value = {
    transit_gateway = var.create_transit_gateway ? {
      id          = aws_ec2_transit_gateway.main[0].id
      arn         = aws_ec2_transit_gateway.main[0].arn
      owner_id    = aws_ec2_transit_gateway.main[0].owner_id
      description = aws_ec2_transit_gateway.main[0].description
      route_table_id = aws_ec2_transit_gateway_route_table.main[0].id
    } : null
    vpcs = {
      for vpc_key, vpc in aws_vpc.vpcs : vpc_key => {
        id          = vpc.id
        arn         = vpc.arn
        cidr_block  = vpc.cidr_block
        subnets = vpc.subnets != null ? {
          for subnet_key, subnet in aws_subnet.vpcs[vpc_key] : subnet_key => {
            id          = subnet.id
            arn         = subnet.arn
            cidr_block  = subnet.cidr_block
            az          = subnet.availability_zone
            type        = subnet.tags["Type"]
          }
        } : {}
        route_table = {
          id   = aws_route_table.vpcs[vpc_key].id
          arn  = aws_route_table.vpcs[vpc_key].arn
        }
        internet_gateway = vpc.create_internet_gateway ? {
          id  = aws_internet_gateway.vpcs[vpc_key].id
          arn = aws_internet_gateway.vpcs[vpc_key].arn
        } : null
        transit_gateway_attachment = vpc.attach_to_transit_gateway && var.create_transit_gateway ? {
          id  = aws_ec2_transit_gateway_vpc_attachment.vpcs[vpc_key].id
          arn = aws_ec2_transit_gateway_vpc_attachment.vpcs[vpc_key].arn
        } : null
      }
    }
    peering_connections = {
      for peering_key, peering in aws_vpc_peering_connection.peering : peering_key => {
        id           = peering.id
        arn          = peering.arn
        status       = peering.accept_status
        requester_vpc = peering.vpc_id
        accepter_vpc  = peering.peer_vpc_id
      }
    }
  }
}

# Cost Estimation Outputs
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown for the infrastructure"
  value = {
    transit_gateway = var.create_transit_gateway ? {
      hourly_rate = 0.50  # USD per hour
      monthly_cost = 0.50 * 730  # 730 hours per month
    } : null
    vpc_attachments = var.create_transit_gateway ? {
      hourly_rate_per_attachment = 0.05  # USD per hour per attachment
      attachment_count = length({
        for k, v in var.vpcs : k => v
        if v.attach_to_transit_gateway
      })
      monthly_cost = 0.05 * 730 * length({
        for k, v in var.vpcs : k => v
        if v.attach_to_transit_gateway
      })
    } : null
    data_processing = var.create_transit_gateway ? {
      per_gb_rate = 0.02  # USD per GB
      estimated_monthly_gb = 1000  # Estimated data transfer
      monthly_cost = 0.02 * 1000
    } : null
    total_estimated_monthly_cost = var.create_transit_gateway ? (
      0.50 * 730 +  # Transit Gateway
      0.05 * 730 * length({
        for k, v in var.vpcs : k => v
        if v.attach_to_transit_gateway
      }) +  # VPC Attachments
      0.02 * 1000   # Data Processing
    ) : 0
  }
}

# Security and Compliance Outputs
output "security_compliance" {
  description = "Security and compliance information"
  value = {
    encryption_enabled = var.enable_encryption
    flow_logs_enabled = var.enable_flow_logs
    vpc_endpoints_enabled = var.enable_vpc_endpoints
    cross_account_sharing_enabled = var.enable_cross_account_sharing
    security_groups_created = length({
      for vpc_key, vpc in var.vpcs : vpc_key => vpc
      if vpc.security_groups != null
    })
    network_acls_created = length({
      for vpc_key, vpc in var.vpcs : vpc_key => vpc
      if vpc.network_acls != null
    })
  }
}

# Enhanced VPC Outputs
output "vpc_ipv6_cidr_blocks" {
  description = "Map of VPC keys to IPv6 CIDR blocks"
  value       = { for k, v in aws_vpc.vpcs : k => v.ipv6_cidr_block }
}

output "vpc_instance_tenancy" {
  description = "Map of VPC keys to instance tenancy"
  value       = { for k, v in aws_vpc.vpcs : k => v.instance_tenancy }
}

output "vpc_enable_network_address_usage_metrics" {
  description = "Map of VPC keys to network address usage metrics status"
  value       = { for k, v in aws_vpc.vpcs : k => v.enable_network_address_usage_metrics }
}

# Enhanced Subnet Outputs
output "subnet_ipv6_cidr_blocks" {
  description = "Map of VPC keys to subnet IPv6 CIDR blocks"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      for subnet_key, subnet in aws_subnet.vpcs[vpc_key] : subnet_key => subnet.ipv6_cidr_block
    }
    if vpc.subnets != null
  }
}

output "subnet_availability_zones" {
  description = "Map of VPC keys to subnet availability zones"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      for subnet_key, subnet in aws_subnet.vpcs[vpc_key] : subnet_key => subnet.availability_zone
    }
    if vpc.subnets != null
  }
}

# Enhanced Transit Gateway Outputs
output "transit_gateway_route_tables" {
  description = "Map of Transit Gateway route table IDs"
  value = var.create_transit_gateway_route_tables ? {
    for k, v in aws_ec2_transit_gateway_route_table.additional : k => v.id
  } : {}
}

# Enhanced VPC Peering Outputs
output "vpc_peering_connection_peer_owner_id" {
  description = "Map of peering connection keys to peer owner IDs"
  value       = { for k, v in aws_vpc_peering_connection.peering : k => v.peer_owner_id }
}

output "vpc_peering_connection_peer_region" {
  description = "Map of peering connection keys to peer regions"
  value       = { for k, v in aws_vpc_peering_connection.peering : k => v.peer_region }
}

# Enhanced RAM Sharing Outputs
output "ram_principal_associations" {
  description = "Map of RAM principal associations"
  value = var.enable_cross_account_sharing && var.create_transit_gateway ? {
    for k, v in aws_ram_principal_association.transit_gateway : k => v.principal
  } : {}
}

# Configuration Summary Output
output "configuration_summary" {
  description = "Detailed configuration summary for the MultiVPC module"
  value = {
    transit_gateway = var.create_transit_gateway ? {
      amazon_side_asn = var.transit_gateway_amazon_side_asn
      description = var.transit_gateway_description
      default_route_table_association = var.transit_gateway_default_route_table_association
      default_route_table_propagation = var.transit_gateway_default_route_table_propagation
      auto_accept_shared_attachments = var.transit_gateway_auto_accept_shared_attachments
      dns_support = var.transit_gateway_dns_support
      vpn_ecmp_support = var.transit_gateway_vpn_ecmp_support
      multicast_support = var.transit_gateway_multicast_support
    } : null
    vpcs = {
      for vpc_key, vpc in var.vpcs : vpc_key => {
        cidr_block = vpc.cidr_block
        enable_dns_hostnames = vpc.enable_dns_hostnames
        enable_dns_support = vpc.enable_dns_support
        instance_tenancy = lookup(vpc, "instance_tenancy", "default")
        enable_network_address_usage_metrics = lookup(vpc, "enable_network_address_usage_metrics", false)
        ipv6_cidr_block = lookup(vpc, "ipv6_cidr_block", null)
        secondary_cidr_blocks = lookup(vpc, "secondary_cidr_blocks", [])
        create_internet_gateway = vpc.create_internet_gateway
        attach_to_transit_gateway = vpc.attach_to_transit_gateway
        subnet_count = vpc.subnets != null ? length(vpc.subnets) : 0
        security_group_count = vpc.security_groups != null ? length(vpc.security_groups) : 0
        network_acl_count = vpc.network_acls != null ? length(vpc.network_acls) : 0
        vpc_endpoint_count = vpc.vpc_endpoints != null ? length(vpc.vpc_endpoints) : 0
        nat_gateway_count = vpc.nat_gateways != null ? length(vpc.nat_gateways) : 0
        route_table_count = vpc.route_tables != null ? length(vpc.route_tables) : 0
      }
    }
    cross_account_sharing = var.enable_cross_account_sharing ? {
      allow_external_principals = var.ram_allow_external_principals
      principal_count = length(var.cross_account_principals)
    } : null
    monitoring = {
      flow_logs_enabled = var.enable_flow_logs
      cloudwatch_logs_enabled = var.enable_cloudwatch_logs
      cloudwatch_alarms_enabled = var.enable_cloudwatch_alarms
      cloudtrail_enabled = var.enable_cloudtrail
      xray_tracing_enabled = var.enable_xray_tracing
    }
    security = {
      encryption_enabled = var.enable_encryption
      vpc_endpoints_enabled = var.enable_vpc_endpoints
      compliance_tagging_enabled = var.enable_compliance_tagging
      resource_policies_enabled = var.enable_resource_policies
    }
    cost_optimization = {
      cost_optimization_enabled = var.enable_cost_optimization
      auto_scaling_enabled = var.enable_auto_scaling
      scheduled_actions_enabled = var.enable_scheduled_actions
    }
  }
} 