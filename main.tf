# Multi-Account, Multi-Region, Multi-VPC Connectivity Module
# This module provides comprehensive connectivity between multiple AWS accounts, regions, and VPCs

terraform {
  required_version = ">= 1.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2.0"
    }
  }
}

# Data sources for current account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Transit Gateway for centralized connectivity
resource "aws_ec2_transit_gateway" "main" {
  count = var.create_transit_gateway ? 1 : 0

  description                     = var.transit_gateway_description
  amazon_side_asn                 = var.transit_gateway_amazon_side_asn
  default_route_table_association = var.transit_gateway_default_route_table_association
  default_route_table_propagation = var.transit_gateway_default_route_table_propagation
  auto_accept_shared_attachments  = var.transit_gateway_auto_accept_shared_attachments
  dns_support                     = var.transit_gateway_dns_support
  vpn_ecmp_support                = var.transit_gateway_vpn_ecmp_support
  multicast_support               = var.transit_gateway_multicast_support

  tags = merge(var.common_tags, var.transit_gateway_tags, {
    Name = "${var.name_prefix}-transit-gateway"
  })
}

# Transit Gateway Route Tables
resource "aws_ec2_transit_gateway_route_table" "main" {
  count = var.create_transit_gateway ? 1 : 0

  transit_gateway_id = aws_ec2_transit_gateway.main[0].id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-transit-gateway-rt"
  })
}

# VPCs with Transit Gateway attachments
resource "aws_vpc" "vpcs" {
  for_each = var.vpcs

  cidr_block           = each.value.cidr_block
  enable_dns_hostnames = each.value.enable_dns_hostnames
  enable_dns_support   = each.value.enable_dns_support
  instance_tenancy     = lookup(each.value, "instance_tenancy", "default")
  enable_network_address_usage_metrics = lookup(each.value, "enable_network_address_usage_metrics", false)

  # IPv6 Configuration
  ipv6_cidr_block                                   = lookup(each.value, "ipv6_cidr_block", null)
  ipv6_cidr_block_network_border_group             = lookup(each.value, "ipv6_cidr_block_network_border_group", null)
  assign_generated_ipv6_cidr_block                 = lookup(each.value, "assign_generated_ipv6_cidr_block", false)

  tags = merge(var.common_tags, each.value.tags, {
    Name = "${var.name_prefix}-vpc-${each.key}"
  })
}

# Secondary CIDR blocks for VPCs
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidrs" {
  for_each = {
    for pair in setproduct(keys(var.vpcs), lookup(var.vpcs[pair[0]], "secondary_cidr_blocks", [])) : "${pair[0]}-${pair[1]}" => {
      vpc_key = pair[0]
      cidr    = pair[1]
    }
  }

  vpc_id     = aws_vpc.vpcs[each.value.vpc_key].id
  cidr_block = each.value.cidr
}

# Internet Gateways for VPCs that need internet access
resource "aws_internet_gateway" "vpcs" {
  for_each = {
    for k, v in var.vpcs : k => v
    if v.create_internet_gateway
  }

  vpc_id = aws_vpc.vpcs[each.key].id

  tags = merge(var.common_tags, each.value.tags, {
    Name = "${var.name_prefix}-igw-${each.key}"
  })
}

# Transit Gateway VPC Attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "vpcs" {
  for_each = {
    for k, v in var.vpcs : k => v
    if v.attach_to_transit_gateway && var.create_transit_gateway
  }

  subnet_ids         = aws_subnet.vpcs[each.key].ids
  transit_gateway_id = aws_ec2_transit_gateway.main[0].id
  vpc_id             = aws_vpc.vpcs[each.key].id

  appliance_mode_support = each.value.transit_gateway_appliance_mode_support
  dns_support            = each.value.transit_gateway_dns_support
  ipv6_support           = each.value.transit_gateway_ipv6_support

  tags = merge(var.common_tags, each.value.tags, {
    Name = "${var.name_prefix}-tgw-attachment-${each.key}"
  })
}

# Subnets for each VPC
resource "aws_subnet" "vpcs" {
  for_each = {
    for k, v in var.vpcs : k => v
    if v.subnets != null
  }

  dynamic "subnet" {
    for_each = each.value.subnets
    content {
      vpc_id                  = aws_vpc.vpcs[each.key].id
      cidr_block              = subnet.value.cidr_block
      availability_zone       = subnet.value.availability_zone
      map_public_ip_on_launch = subnet.value.map_public_ip_on_launch
      assign_ipv6_address_on_creation = subnet.value.assign_ipv6_address_on_creation

      tags = merge(var.common_tags, subnet.value.tags, {
        Name = "${var.name_prefix}-subnet-${each.key}-${subnet.key}"
        Type = subnet.value.type
      })
    }
  }
}

# Route Tables for each VPC
resource "aws_route_table" "vpcs" {
  for_each = var.vpcs

  vpc_id = aws_vpc.vpcs[each.key].id

  dynamic "route" {
    for_each = each.value.routes != null ? each.value.routes : []
    content {
      cidr_block                = route.value.cidr_block
      gateway_id                = route.value.gateway_id
      nat_gateway_id            = route.value.nat_gateway_id
      network_interface_id      = route.value.network_interface_id
      transit_gateway_id        = route.value.transit_gateway_id
      vpc_peering_connection_id = route.value.vpc_peering_connection_id
      vpc_endpoint_id           = route.value.vpc_endpoint_id
    }
  }

  tags = merge(var.common_tags, each.value.tags, {
    Name = "${var.name_prefix}-rt-${each.key}"
  })
}

# Route Table Associations
resource "aws_route_table_association" "vpcs" {
  for_each = {
    for k, v in var.vpcs : k => v
    if v.subnets != null
  }

  dynamic "association" {
    for_each = each.value.subnets
    content {
      subnet_id      = aws_subnet.vpcs[each.key][association.key].id
      route_table_id = aws_route_table.vpcs[each.key].id
    }
  }
}

# Transit Gateway Route Table Associations
resource "aws_ec2_transit_gateway_route_table_association" "vpcs" {
  for_each = {
    for k, v in var.vpcs : k => v
    if v.attach_to_transit_gateway && var.create_transit_gateway
  }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main[0].id
}

# Transit Gateway Routes
resource "aws_ec2_transit_gateway_route" "vpc_routes" {
  for_each = {
    for k, v in var.vpcs : k => v
    if v.attach_to_transit_gateway && var.create_transit_gateway && v.transit_gateway_routes != null
  }

  dynamic "route" {
    for_each = each.value.transit_gateway_routes
    content {
      destination_cidr_block         = route.value.destination_cidr_block
      transit_gateway_attachment_id  = route.value.transit_gateway_attachment_id
      transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main[0].id
    }
  }
}

# VPC Peering Connections
resource "aws_vpc_peering_connection" "peering" {
  for_each = var.vpc_peering_connections

  vpc_id      = aws_vpc.vpcs[each.value.requester_vpc_key].id
  peer_vpc_id = aws_vpc.vpcs[each.value.accepter_vpc_key].id
  auto_accept = each.value.auto_accept

  tags = merge(var.common_tags, each.value.tags, {
    Name = "${var.name_prefix}-peering-${each.key}"
  })
}

# VPC Peering Route Table Entries
resource "aws_route" "peering_routes" {
  for_each = var.vpc_peering_connections

  route_table_id            = aws_route_table.vpcs[each.value.requester_vpc_key].id
  destination_cidr_block    = each.value.requester_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[each.key].id
}

resource "aws_route" "peering_routes_accepter" {
  for_each = var.vpc_peering_connections

  route_table_id            = aws_route_table.vpcs[each.value.accepter_vpc_key].id
  destination_cidr_block    = each.value.accepter_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[each.key].id
}

# Cross-Account Transit Gateway Sharing (if enabled)
resource "aws_ram_resource_share" "transit_gateway" {
  count = var.enable_cross_account_sharing && var.create_transit_gateway ? 1 : 0

  name                      = "${var.name_prefix}-transit-gateway-share"
  allow_external_principals = var.ram_allow_external_principals

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-transit-gateway-share"
  })
}

resource "aws_ram_resource_association" "transit_gateway" {
  count = var.enable_cross_account_sharing && var.create_transit_gateway ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.main[0].arn
  resource_share_arn = aws_ram_resource_share.transit_gateway[0].arn
}

resource "aws_ram_principal_association" "transit_gateway" {
  for_each = var.enable_cross_account_sharing && var.create_transit_gateway ? var.cross_account_principals : {}

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.transit_gateway[0].arn
}

# Security Groups for VPCs
resource "aws_security_group" "vpcs" {
  for_each = {
    for k, v in var.vpcs : k => v
    if v.security_groups != null
  }

  dynamic "security_group" {
    for_each = each.value.security_groups
    content {
      name_prefix = security_group.value.name_prefix
      description = security_group.value.description
      vpc_id      = aws_vpc.vpcs[each.key].id

      dynamic "ingress" {
        for_each = security_group.value.ingress_rules != null ? security_group.value.ingress_rules : []
        content {
          description      = ingress.value.description
          from_port       = ingress.value.from_port
          to_port         = ingress.value.to_port
          protocol        = ingress.value.protocol
          cidr_blocks     = ingress.value.cidr_blocks
          security_groups = ingress.value.security_groups
        }
      }

      dynamic "egress" {
        for_each = security_group.value.egress_rules != null ? security_group.value.egress_rules : []
        content {
          description      = egress.value.description
          from_port       = egress.value.from_port
          to_port         = egress.value.to_port
          protocol        = egress.value.protocol
          cidr_blocks     = egress.value.cidr_blocks
          security_groups = egress.value.security_groups
        }
      }

      tags = merge(var.common_tags, security_group.value.tags, {
        Name = "${var.name_prefix}-sg-${each.key}-${security_group.key}"
      })
    }
  }
}

# Network ACLs for VPCs
resource "aws_network_acl" "vpcs" {
  for_each = {
    for k, v in var.vpcs : k => v
    if v.network_acls != null
  }

  dynamic "network_acl" {
    for_each = each.value.network_acls
    content {
      vpc_id = aws_vpc.vpcs[each.key].id

      dynamic "ingress" {
        for_each = network_acl.value.ingress_rules != null ? network_acl.value.ingress_rules : []
        content {
          protocol   = ingress.value.protocol
          rule_no    = ingress.value.rule_no
          action     = ingress.value.action
          cidr_block = ingress.value.cidr_block
          from_port  = ingress.value.from_port
          to_port    = ingress.value.to_port
        }
      }

      dynamic "egress" {
        for_each = network_acl.value.egress_rules != null ? network_acl.value.egress_rules : []
        content {
          protocol   = egress.value.protocol
          rule_no    = egress.value.rule_no
          action     = egress.value.action
          cidr_block = egress.value.cidr_block
          from_port  = egress.value.from_port
          to_port    = egress.value.to_port
        }
      }

      tags = merge(var.common_tags, network_acl.value.tags, {
        Name = "${var.name_prefix}-nacl-${each.key}-${network_acl.key}"
      })
    }
  }
}

# Network ACL Associations
resource "aws_network_acl_association" "vpcs" {
  for_each = {
    for k, v in var.vpcs : k => v
    if v.network_acls != null
  }

  dynamic "association" {
    for_each = each.value.subnets
    content {
      network_acl_id = aws_network_acl.vpcs[each.key][association.key].id
      subnet_id      = aws_subnet.vpcs[each.key][association.key].id
    }
  }
} 