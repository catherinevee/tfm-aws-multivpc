# Multi-Account, Multi-Region, Multi-VPC Connectivity Module Variables

variable "name_prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
  default     = "multivpc" # Default: multivpc

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {} # Default: empty map

  validation {
    condition = alltrue([
      for k, v in var.common_tags : can(regex("^[a-zA-Z0-9_.:/=+-@]+$", k)) && can(regex("^[a-zA-Z0-9_.:/=+-@]*$", v))
    ])
    error_message = "Tags must contain only alphanumeric characters, hyphens, underscores, periods, colons, slashes, equals, plus signs, minus signs, and at signs."
  }
}

# =============================================================================
# Transit Gateway Configuration
# =============================================================================

variable "create_transit_gateway" {
  description = "Whether to create a Transit Gateway for centralized connectivity"
  type        = bool
  default     = true # Default: true
}

variable "transit_gateway_description" {
  description = "Description for the Transit Gateway"
  type        = string
  default     = "Centralized Transit Gateway for multi-VPC connectivity" # Default: Centralized Transit Gateway for multi-VPC connectivity
}

variable "transit_gateway_amazon_side_asn" {
  description = "Amazon side ASN for the Transit Gateway"
  type        = number
  default     = 64512 # Default: 64512

  validation {
    condition     = var.transit_gateway_amazon_side_asn >= 64512 && var.transit_gateway_amazon_side_asn <= 65534
    error_message = "Transit Gateway Amazon side ASN must be between 64512 and 65534."
  }
}

variable "transit_gateway_default_route_table_association" {
  description = "Whether resource attachments are automatically associated with the default association route table"
  type        = string
  default     = "enable" # Default: enable
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_default_route_table_association)
    error_message = "Transit Gateway default route table association must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_default_route_table_propagation" {
  description = "Whether resource attachments automatically propagate routes to the default propagation route table"
  type        = string
  default     = "enable" # Default: enable
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_default_route_table_propagation)
    error_message = "Transit Gateway default route table propagation must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_auto_accept_shared_attachments" {
  description = "Whether resource attachments are automatically accepted"
  type        = string
  default     = "disable" # Default: disable
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_auto_accept_shared_attachments)
    error_message = "Transit Gateway auto accept shared attachments must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_dns_support" {
  description = "Whether DNS support is enabled for the Transit Gateway"
  type        = string
  default     = "enable" # Default: enable
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_dns_support)
    error_message = "Transit Gateway DNS support must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_vpn_ecmp_support" {
  description = "Whether VPN ECMP support is enabled for the Transit Gateway"
  type        = string
  default     = "enable" # Default: enable
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_vpn_ecmp_support)
    error_message = "Transit Gateway VPN ECMP support must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_multicast_support" {
  description = "Whether multicast support is enabled for the Transit Gateway"
  type        = string
  default     = "disable" # Default: disable
  
  validation {
    condition     = contains(["enable", "disable"], var.transit_gateway_multicast_support)
    error_message = "Transit Gateway multicast support must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_tags" {
  description = "Additional tags for Transit Gateway"
  type        = map(string)
  default     = {} # Default: empty map
}

# =============================================================================
# Transit Gateway Route Tables Configuration
# =============================================================================

variable "create_transit_gateway_route_tables" {
  description = "Whether to create additional Transit Gateway route tables"
  type        = bool
  default     = false # Default: false
}

variable "transit_gateway_route_tables" {
  description = "Map of additional Transit Gateway route table configurations"
  type = map(object({
    description = optional(string) # Default: null
    tags        = optional(map(string), {}) # Default: empty map
  }))
  default = {} # Default: empty map
}

variable "transit_gateway_route_table_tags" {
  description = "Additional tags for Transit Gateway route tables"
  type        = map(string)
  default     = {} # Default: empty map
}

# =============================================================================
# Cross-Account Sharing Configuration
# =============================================================================

variable "enable_cross_account_sharing" {
  description = "Whether to enable cross-account Transit Gateway sharing using RAM"
  type        = bool
  default     = false # Default: false
}

variable "ram_allow_external_principals" {
  description = "Whether to allow external principals to access the RAM resource share"
  type        = bool
  default     = false # Default: false
}

variable "cross_account_principals" {
  description = "Map of cross-account principals (account IDs) to share the Transit Gateway with"
  type        = map(string)
  default     = {} # Default: empty map

  validation {
    condition = alltrue([
      for principal in values(var.cross_account_principals) : can(regex("^[0-9]{12}$", principal))
    ])
    error_message = "Cross account principals must be valid 12-digit AWS account IDs."
  }
}

variable "ram_resource_share_tags" {
  description = "Additional tags for RAM resource share"
  type        = map(string)
  default     = {} # Default: empty map
}

# =============================================================================
# VPC Configuration
# =============================================================================

variable "vpcs" {
  description = "Map of VPC configurations"
  type = map(object({
    cidr_block           = string
    enable_dns_hostnames = optional(bool, true) # Default: true
    enable_dns_support   = optional(bool, true) # Default: true
    instance_tenancy     = optional(string, "default") # Default: default
    enable_network_address_usage_metrics = optional(bool, false) # Default: false
    
    # IPv6 Configuration
    ipv6_cidr_block                                   = optional(string, null) # Default: null
    ipv6_cidr_block_network_border_group             = optional(string, null) # Default: null
    assign_generated_ipv6_cidr_block                 = optional(bool, false) # Default: false
    
    # Secondary CIDR Blocks
    secondary_cidr_blocks = optional(list(string), []) # Default: empty list
    
    create_internet_gateway = optional(bool, false) # Default: false
    attach_to_transit_gateway = optional(bool, true) # Default: true
    
    # Transit Gateway Attachment Configuration
    transit_gateway_appliance_mode_support = optional(string, "disable") # Default: disable
    transit_gateway_dns_support = optional(string, "enable") # Default: enable
    transit_gateway_ipv6_support = optional(string, "disable") # Default: disable
    
    # Subnet Configuration
    subnets = optional(map(object({
      cidr_block                      = string
      availability_zone               = string
      map_public_ip_on_launch         = optional(bool, false) # Default: false
      assign_ipv6_address_on_creation = optional(bool, false) # Default: false
      outpost_arn                     = optional(string, null) # Default: null
      type                            = optional(string, "private") # Default: private
      tags                            = optional(map(string), {}) # Default: empty map
      
      # IPv6 Configuration
      ipv6_cidr_block = optional(string, null) # Default: null
    })), {}) # Default: empty map
    
    # Route Configuration
    routes = optional(list(object({
      cidr_block                = string
      gateway_id                = optional(string) # Default: null
      nat_gateway_id            = optional(string) # Default: null
      network_interface_id      = optional(string) # Default: null
      transit_gateway_id        = optional(string) # Default: null
      vpc_peering_connection_id = optional(string) # Default: null
      vpc_endpoint_id           = optional(string) # Default: null
      egress_only_gateway_id    = optional(string) # Default: null
      local_gateway_id          = optional(string) # Default: null
      carrier_gateway_id        = optional(string) # Default: null
      core_network_arn          = optional(string) # Default: null
    })), []) # Default: empty list
    
    # Transit Gateway Routes
    transit_gateway_routes = optional(list(object({
      destination_cidr_block        = string
      transit_gateway_attachment_id = string
      transit_gateway_route_table_id = optional(string) # Default: null
    })), []) # Default: empty list
    
    # Security Groups Configuration
    security_groups = optional(map(object({
      name_prefix = string
      description = string
      vpc_id      = optional(string) # Default: null
      
      ingress_rules = optional(list(object({
        description      = string
        from_port       = number
        to_port         = number
        protocol        = string
        cidr_blocks     = optional(list(string), []) # Default: empty list
        security_groups = optional(list(string), []) # Default: empty list
        self            = optional(bool, false) # Default: false
        prefix_list_ids = optional(list(string), []) # Default: empty list
      })), []) # Default: empty list
      
      egress_rules = optional(list(object({
        description      = string
        from_port       = number
        to_port         = number
        protocol        = string
        cidr_blocks     = optional(list(string), []) # Default: empty list
        security_groups = optional(list(string), []) # Default: empty list
        self            = optional(bool, false) # Default: false
        prefix_list_ids = optional(list(string), []) # Default: empty list
      })), []) # Default: empty list
      
      tags = optional(map(string), {}) # Default: empty map
    })), {}) # Default: empty map
    
    # Network ACLs Configuration
    network_acls = optional(map(object({
      vpc_id = optional(string) # Default: null
      
      ingress_rules = optional(list(object({
        protocol   = string
        rule_no    = number
        action     = string
        cidr_block = string
        from_port  = optional(number) # Default: null
        to_port    = optional(number) # Default: null
        icmp_type  = optional(number) # Default: null
        icmp_code  = optional(number) # Default: null
      })), []) # Default: empty list
      
      egress_rules = optional(list(object({
        protocol   = string
        rule_no    = number
        action     = string
        cidr_block = string
        from_port  = optional(number) # Default: null
        to_port    = optional(number) # Default: null
        icmp_type  = optional(number) # Default: null
        icmp_code  = optional(number) # Default: null
      })), []) # Default: empty list
      
      tags = optional(map(string), {}) # Default: empty map
    })), {}) # Default: empty map
    
    # VPC Endpoints Configuration
    vpc_endpoints = optional(map(object({
      service_name             = string
      vpc_endpoint_type        = optional(string, "Gateway") # Default: Gateway
      private_dns_enabled      = optional(bool, true) # Default: true
      subnet_ids               = optional(list(string), []) # Default: empty list
      security_group_ids       = optional(list(string), []) # Default: empty list
      policy                   = optional(string, null) # Default: null
      route_table_ids          = optional(list(string), []) # Default: empty list
      tags                     = optional(map(string), {}) # Default: empty map
    })), {}) # Default: empty map
    
    # NAT Gateways Configuration
    nat_gateways = optional(map(object({
      allocation_id = string
      subnet_id     = string
      connectivity_type = optional(string, "public") # Default: public
      private_ip    = optional(string, null) # Default: null
      tags          = optional(map(string), {}) # Default: empty map
    })), {}) # Default: empty map
    
    # Route Tables Configuration
    route_tables = optional(map(object({
      vpc_id = optional(string) # Default: null
      
      routes = optional(list(object({
        cidr_block                = string
        gateway_id                = optional(string) # Default: null
        nat_gateway_id            = optional(string) # Default: null
        network_interface_id      = optional(string) # Default: null
        transit_gateway_id        = optional(string) # Default: null
        vpc_peering_connection_id = optional(string) # Default: null
        vpc_endpoint_id           = optional(string) # Default: null
        egress_only_gateway_id    = optional(string) # Default: null
        local_gateway_id          = optional(string) # Default: null
        carrier_gateway_id        = optional(string) # Default: null
        core_network_arn          = optional(string) # Default: null
      })), []) # Default: empty list
      
      tags = optional(map(string), {}) # Default: empty map
    })), {}) # Default: empty map
    
    tags = optional(map(string), {}) # Default: empty map
  }))
  default = {} # Default: empty map

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

# =============================================================================
# VPC Peering Configuration
# =============================================================================

variable "vpc_peering_connections" {
  description = "Map of VPC peering connection configurations"
  type = map(object({
    requester_vpc_key = string
    accepter_vpc_key  = string
    auto_accept       = optional(bool, true) # Default: true
    requester_cidr_block = string
    accepter_cidr_block  = string
    peer_owner_id     = optional(string, null) # Default: null
    peer_region       = optional(string, null) # Default: null
    tags = optional(map(string), {}) # Default: empty map
  }))
  default = {} # Default: empty map

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

# =============================================================================
# VPC Flow Logs Configuration
# =============================================================================

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs for all VPCs"
  type        = bool
  default     = false # Default: false
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 7 # Default: 7

  validation {
    condition     = var.flow_log_retention_days >= 1 && var.flow_log_retention_days <= 365
    error_message = "Flow log retention days must be between 1 and 365."
  }
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to log"
  type        = string
  default     = "ALL" # Default: ALL

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "Flow log traffic type must be either 'ACCEPT', 'REJECT', or 'ALL'."
  }
}

variable "flow_log_destination_type" {
  description = "Type of destination for flow logs"
  type        = string
  default     = "cloud-watch-logs" # Default: cloud-watch-logs

  validation {
    condition     = contains(["cloud-watch-logs", "s3", "kinesis-data-firehose"], var.flow_log_destination_type)
    error_message = "Flow log destination type must be either 'cloud-watch-logs', 's3', or 'kinesis-data-firehose'."
  }
}

variable "flow_log_log_format" {
  description = "Format for flow log entries"
  type        = string
  default     = null # Default: null
}

variable "flow_log_max_aggregation_interval" {
  description = "Maximum interval of time during which a flow of packets is captured and aggregated into a flow log record"
  type        = number
  default     = 600 # Default: 600

  validation {
    condition     = contains([60, 600], var.flow_log_max_aggregation_interval)
    error_message = "Flow log max aggregation interval must be either 60 or 600 seconds."
  }
}

variable "flow_log_kms_key_id" {
  description = "KMS key ID for flow log encryption"
  type        = string
  default     = null # Default: null
}

variable "flow_log_tags" {
  description = "Additional tags for flow logs"
  type        = map(string)
  default     = {} # Default: empty map
}

# =============================================================================
# VPC Endpoints Configuration
# =============================================================================

variable "enable_vpc_endpoints" {
  description = "Whether to create VPC endpoints for AWS services"
  type        = bool
  default     = false # Default: false
}

variable "vpc_endpoint_services" {
  description = "List of VPC endpoint services to create"
  type        = list(string)
  default     = ["s3", "dynamodb"] # Default: ["s3", "dynamodb"]

  validation {
    condition = alltrue([
      for service in var.vpc_endpoint_services : 
        contains(["s3", "dynamodb", "ec2", "ec2messages", "ssm", "ssmmessages", "logs", "monitoring"], service)
    ])
    error_message = "VPC endpoint services must be valid AWS service names."
  }
}

variable "vpc_endpoint_tags" {
  description = "Additional tags for VPC endpoints"
  type        = map(string)
  default     = {} # Default: empty map
}

# =============================================================================
# NAT Gateways Configuration
# =============================================================================

variable "enable_nat_gateways" {
  description = "Whether to create NAT Gateways for private subnets"
  type        = bool
  default     = false # Default: false
}

variable "nat_gateway_allocation_ids" {
  description = "Map of VPC keys to Elastic IP allocation IDs for NAT Gateways"
  type        = map(string)
  default     = {} # Default: empty map

  validation {
    condition = alltrue([
      for vpc_key, allocation_id in var.nat_gateway_allocation_ids : 
        can(regex("^eipalloc-[a-z0-9]+$", allocation_id))
    ])
    error_message = "NAT Gateway allocation IDs must be valid Elastic IP allocation IDs."
  }
}

variable "nat_gateway_tags" {
  description = "Additional tags for NAT Gateways"
  type        = map(string)
  default     = {} # Default: empty map
}

# =============================================================================
# CloudWatch Configuration
# =============================================================================

variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch Logs for monitoring"
  type        = bool
  default     = false # Default: false
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  type        = string
  default     = "/aws/vpc/flowlogs" # Default: /aws/vpc/flowlogs

  validation {
    condition     = can(regex("^[a-zA-Z0-9_/-]+$", var.cloudwatch_log_group_name))
    error_message = "CloudWatch Log Group name must contain only alphanumeric characters, hyphens, underscores, and forward slashes."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID for CloudWatch Log Group encryption"
  type        = string
  default     = null # Default: null
}

variable "cloudwatch_log_group_tags" {
  description = "Additional tags for CloudWatch Log Group"
  type        = map(string)
  default     = {} # Default: empty map
}

# =============================================================================
# CloudWatch Alarms Configuration
# =============================================================================

variable "enable_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for monitoring"
  type        = bool
  default     = false # Default: false
}

variable "cloudwatch_alarms" {
  description = "Map of CloudWatch alarm configurations"
  type = map(object({
    alarm_name          = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_description   = optional(string) # Default: null
    alarm_actions       = optional(list(string), []) # Default: empty list
    ok_actions          = optional(list(string), []) # Default: empty list
    insufficient_data_actions = optional(list(string), []) # Default: empty list
    treat_missing_data  = optional(string, "missing") # Default: missing
    unit                = optional(string) # Default: null
    extended_statistic  = optional(string) # Default: null
    datapoints_to_alarm = optional(number) # Default: null
    threshold_metric_id = optional(string) # Default: null
    dimensions = optional(list(object({
      name  = string
      value = string
    })), []) # Default: empty list
    metric_query = optional(list(object({
      id          = string
      expression  = optional(string) # Default: null
      label       = optional(string) # Default: null
      return_data = optional(bool, true) # Default: true
      metric = optional(object({
        metric_name = string
        namespace   = string
        period      = number
        stat        = string
        unit        = optional(string) # Default: null
        dimensions = optional(list(object({
          name  = string
          value = string
        })), []) # Default: empty list
      })) # Default: null
    })), []) # Default: empty list
    tags = optional(map(string), {}) # Default: empty map
  }))
  default = {} # Default: empty map
}

# =============================================================================
# Cost Optimization Variables
# =============================================================================

variable "enable_cost_optimization" {
  description = "Whether to enable cost optimization features"
  type        = bool
  default     = false # Default: false
}

variable "enable_auto_scaling" {
  description = "Whether to enable auto scaling for NAT Gateways"
  type        = bool
  default     = false # Default: false
}

variable "enable_scheduled_actions" {
  description = "Whether to enable scheduled actions for cost optimization"
  type        = bool
  default     = false # Default: false
}

variable "scheduled_actions" {
  description = "Map of scheduled actions for cost optimization"
  type = map(object({
    name                   = string
    schedule               = string
    start_time             = optional(string) # Default: null
    end_time               = optional(string) # Default: null
    timezone               = optional(string, "UTC") # Default: UTC
    desired_capacity       = optional(number) # Default: null
    max_size               = optional(number) # Default: null
    min_size               = optional(number) # Default: null
    recurrence             = optional(string) # Default: null
    tags                   = optional(map(string), {}) # Default: empty map
  }))
  default = {} # Default: empty map
}

# =============================================================================
# Security Variables
# =============================================================================

variable "enable_encryption" {
  description = "Whether to enable encryption for all resources"
  type        = bool
  default     = true # Default: true
}

variable "enable_vpc_flow_logs_encryption" {
  description = "Whether to enable encryption for VPC Flow Logs"
  type        = bool
  default     = true # Default: true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encryption"
  type        = string
  default     = "" # Default: empty string

  validation {
    condition     = var.kms_key_arn == "" || can(regex("^arn:aws:kms:", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid AWS KMS ARN or empty string."
  }
}

variable "enable_vpc_endpoint_policies" {
  description = "Whether to enable VPC endpoint policies"
  type        = bool
  default     = false # Default: false
}

variable "vpc_endpoint_policies" {
  description = "Map of VPC endpoint policies"
  type        = map(string)
  default     = {} # Default: empty map
}

# =============================================================================
# Monitoring and Observability Variables
# =============================================================================

variable "enable_xray_tracing" {
  description = "Whether to enable X-Ray tracing"
  type        = bool
  default     = false # Default: false
}

variable "enable_cloudtrail" {
  description = "Whether to enable CloudTrail logging"
  type        = bool
  default     = false # Default: false
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail"
  type        = string
  default     = "multivpc-trail" # Default: multivpc-trail
}

variable "cloudtrail_s3_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
  default     = "" # Default: empty string
}

variable "cloudtrail_tags" {
  description = "Additional tags for CloudTrail"
  type        = map(string)
  default     = {} # Default: empty map
}

# =============================================================================
# Compliance and Governance Variables
# =============================================================================

variable "enable_compliance_tagging" {
  description = "Whether to enable compliance tagging"
  type        = bool
  default     = false # Default: false
}

variable "compliance_tags" {
  description = "Compliance tags to apply to all resources"
  type        = map(string)
  default     = {} # Default: empty map
}

variable "enable_resource_policies" {
  description = "Whether to enable resource policies"
  type        = bool
  default     = false # Default: false
}

variable "resource_policies" {
  description = "Map of resource policies"
  type        = map(string)
  default     = {} # Default: empty map
} 