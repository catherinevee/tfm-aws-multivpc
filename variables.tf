# Multi-Account, Multi-Region, Multi-VPC Connectivity Module Variables

variable "name_prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
  default     = "multivpc"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.common_tags : can(regex("^[a-zA-Z0-9_.:/=+-@]+$", k)) && can(regex("^[a-zA-Z0-9_.:/=+-@]*$", v))
    ])
    error_message = "Tags must contain only alphanumeric characters, hyphens, underscores, periods, colons, slashes, equals, plus signs, minus signs, and at signs."
  }
}

# Transit Gateway Configuration
variable "create_transit_gateway" {
  description = "Whether to create a Transit Gateway for centralized connectivity"
  type        = bool
  default     = true
}

variable "transit_gateway_description" {
  description = "Description for the Transit Gateway"
  type        = string
  default     = "Centralized Transit Gateway for multi-VPC connectivity"
}

variable "transit_gateway_default_route_table_association" {
  description = "Whether resource attachments are automatically associated with the default association route table"
  type        = string
  default     = "enable"
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_default_route_table_association)
    error_message = "Transit Gateway default route table association must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_default_route_table_propagation" {
  description = "Whether resource attachments automatically propagate routes to the default propagation route table"
  type        = string
  default     = "enable"
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_default_route_table_propagation)
    error_message = "Transit Gateway default route table propagation must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_auto_accept_shared_attachments" {
  description = "Whether resource attachments are automatically accepted"
  type        = string
  default     = "disable"
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_auto_accept_shared_attachments)
    error_message = "Transit Gateway auto accept shared attachments must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_dns_support" {
  description = "Whether DNS support is enabled for the Transit Gateway"
  type        = string
  default     = "enable"
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_dns_support)
    error_message = "Transit Gateway DNS support must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_vpn_ecmp_support" {
  description = "Whether VPN ECMP support is enabled for the Transit Gateway"
  type        = string
  default     = "enable"
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_vpn_ecmp_support)
    error_message = "Transit Gateway VPN ECMP support must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_multicast_support" {
  description = "Whether multicast support is enabled for the Transit Gateway"
  type        = string
  default     = "disable"
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_multicast_support)
    error_message = "Transit Gateway multicast support must be either 'enable' or 'disable'."
  }
}

# Cross-Account Sharing Configuration
variable "enable_cross_account_sharing" {
  description = "Whether to enable cross-account Transit Gateway sharing using RAM"
  type        = bool
  default     = false
}

variable "ram_allow_external_principals" {
  description = "Whether to allow external principals to access the RAM resource share"
  type        = bool
  default     = false
}

variable "cross_account_principals" {
  description = "Map of cross-account principals (account IDs) to share the Transit Gateway with"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for principal in values(var.cross_account_principals) : can(regex("^[0-9]{12}$", principal))
    ])
    error_message = "Cross account principals must be valid 12-digit AWS account IDs."
  }
}

# VPC Configuration
variable "vpcs" {
  description = "Map of VPC configurations"
  type = map(object({
    cidr_block           = string
    enable_dns_hostnames = optional(bool, true)
    enable_dns_support   = optional(bool, true)
    create_internet_gateway = optional(bool, false)
    attach_to_transit_gateway = optional(bool, true)
    transit_gateway_appliance_mode_support = optional(string, "disable")
    transit_gateway_dns_support = optional(string, "enable")
    transit_gateway_ipv6_support = optional(string, "disable")
    subnets = optional(map(object({
      cidr_block                      = string
      availability_zone               = string
      map_public_ip_on_launch         = optional(bool, false)
      assign_ipv6_address_on_creation = optional(bool, false)
      type                            = optional(string, "private")
      tags                            = optional(map(string), {})
    })), {})
    routes = optional(list(object({
      cidr_block                = string
      gateway_id                = optional(string)
      nat_gateway_id            = optional(string)
      network_interface_id      = optional(string)
      transit_gateway_id        = optional(string)
      vpc_peering_connection_id = optional(string)
      vpc_endpoint_id           = optional(string)
    })), [])
    transit_gateway_routes = optional(list(object({
      destination_cidr_block        = string
      transit_gateway_attachment_id = string
    })), [])
    security_groups = optional(map(object({
      name_prefix = string
      description = string
      ingress_rules = optional(list(object({
        description      = string
        from_port       = number
        to_port         = number
        protocol        = string
        cidr_blocks     = optional(list(string))
        security_groups = optional(list(string))
      })), [])
      egress_rules = optional(list(object({
        description      = string
        from_port       = number
        to_port         = number
        protocol        = string
        cidr_blocks     = optional(list(string))
        security_groups = optional(list(string))
      })), [])
      tags = optional(map(string), {})
    })), {})
    network_acls = optional(map(object({
      ingress_rules = optional(list(object({
        protocol   = string
        rule_no    = number
        action     = string
        cidr_block = string
        from_port  = optional(number)
        to_port    = optional(number)
      })), [])
      egress_rules = optional(list(object({
        protocol   = string
        rule_no    = number
        action     = string
        cidr_block = string
        from_port  = optional(number)
        to_port    = optional(number)
      })), [])
      tags = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for vpc_key, vpc in var.vpcs : can(cidrhost(vpc.cidr_block, 0))
    ])
    error_message = "All VPC CIDR blocks must be valid IPv4 CIDR notation."
  }

  validation {
    condition = alltrue([
      for vpc_key, vpc in var.vpcs : alltrue([
        for subnet_key, subnet in vpc.subnets : can(cidrhost(subnet.cidr_block, 0))
      ])
    ])
    error_message = "All subnet CIDR blocks must be valid IPv4 CIDR notation."
  }

  validation {
    condition = alltrue([
      for vpc_key, vpc in var.vpcs : alltrue([
        for subnet_key, subnet in vpc.subnets : contains(["private", "public"], subnet.type)
      ])
    ])
    error_message = "Subnet types must be either 'private' or 'public'."
  }
}

# VPC Peering Configuration
variable "vpc_peering_connections" {
  description = "Map of VPC peering connection configurations"
  type = map(object({
    requester_vpc_key = string
    accepter_vpc_key  = string
    auto_accept       = optional(bool, true)
    requester_cidr_block = string
    accepter_cidr_block  = string
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for peering_key, peering in var.vpc_peering_connections : 
        contains(keys(var.vpcs), peering.requester_vpc_key) && 
        contains(keys(var.vpcs), peering.accepter_vpc_key)
    ])
    error_message = "All VPC peering connections must reference valid VPC keys."
  }

  validation {
    condition = alltrue([
      for peering_key, peering in var.vpc_peering_connections : 
        can(cidrhost(peering.requester_cidr_block, 0)) && 
        can(cidrhost(peering.accepter_cidr_block, 0))
    ])
    error_message = "All VPC peering CIDR blocks must be valid IPv4 CIDR notation."
  }
}

# Additional Configuration Variables
variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs for all VPCs"
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 7

  validation {
    condition     = var.flow_log_retention_days >= 1 && var.flow_log_retention_days <= 365
    error_message = "Flow log retention days must be between 1 and 365."
  }
}

variable "enable_vpc_endpoints" {
  description = "Whether to create VPC endpoints for AWS services"
  type        = bool
  default     = false
}

variable "vpc_endpoint_services" {
  description = "List of VPC endpoint services to create"
  type        = list(string)
  default     = ["s3", "dynamodb"]

  validation {
    condition = alltrue([
      for service in var.vpc_endpoint_services : 
        contains(["s3", "dynamodb", "ec2", "ec2messages", "ssm", "ssmmessages", "logs", "monitoring"], service)
    ])
    error_message = "VPC endpoint services must be valid AWS service names."
  }
}

variable "enable_nat_gateways" {
  description = "Whether to create NAT Gateways for private subnets"
  type        = bool
  default     = false
}

variable "nat_gateway_allocation_ids" {
  description = "Map of VPC keys to Elastic IP allocation IDs for NAT Gateways"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for vpc_key, allocation_id in var.nat_gateway_allocation_ids : 
        can(regex("^eipalloc-[a-z0-9]+$", allocation_id))
    ])
    error_message = "NAT Gateway allocation IDs must be valid Elastic IP allocation IDs."
  }
}

# Monitoring and Logging Variables
variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch Logs for monitoring"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  type        = string
  default     = "/aws/vpc/flowlogs"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_/-]+$", var.cloudwatch_log_group_name))
    error_message = "CloudWatch Log Group name must contain only alphanumeric characters, hyphens, underscores, and forward slashes."
  }
}

# Cost Optimization Variables
variable "enable_cost_optimization" {
  description = "Whether to enable cost optimization features"
  type        = bool
  default     = false
}

variable "enable_auto_scaling" {
  description = "Whether to enable auto scaling for NAT Gateways"
  type        = bool
  default     = false
}

# Security Variables
variable "enable_encryption" {
  description = "Whether to enable encryption for all resources"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs_encryption" {
  description = "Whether to enable encryption for VPC Flow Logs"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encryption"
  type        = string
  default     = ""

  validation {
    condition     = var.kms_key_arn == "" || can(regex("^arn:aws:kms:", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid AWS KMS ARN or empty string."
  }
} 