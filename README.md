# AWS Multi-Account, Multi-Region, Multi-VPC Connectivity Module

A comprehensive Terraform module for designing and implementing routing strategies and connectivity architecture across multiple AWS accounts, regions, and VPCs to support different connectivity patterns.

## 🗺️ Resource Map

This module provisions and manages the following AWS resources:

| Resource Type | Purpose | Dependencies |
|--------------|---------|--------------|
| `aws_ec2_transit_gateway` | Central hub for VPC and VPN connectivity | None |
| `aws_ec2_transit_gateway_route_table` | Route tables for TGW traffic control | Transit Gateway |
| `aws_vpc` | Virtual Private Clouds for resource isolation | None |
| `aws_vpc_ipv4_cidr_block_association` | Secondary CIDR blocks for VPC expansion | VPC |
| `aws_internet_gateway` | Internet access for public subnets | VPC |
| `aws_ec2_transit_gateway_vpc_attachment` | Connect VPCs to Transit Gateway | VPC, Transit Gateway |
| `aws_subnet` | Network segments within VPCs | VPC |
| `aws_route_table` | Traffic routing control within VPCs | VPC |
| `aws_route_table_association` | Link subnets to route tables | Subnet, Route Table |
| `aws_vpc_peering_connection` | Direct VPC-to-VPC connectivity | VPCs |
| `aws_ram_resource_share` | Cross-account resource sharing | None |
| `aws_security_group` | Network security at instance level | VPC |
| `aws_network_acl` | Network security at subnet level | VPC |

## 🌟 Features

- **Transit Gateway Integration**: Centralized connectivity hub for multiple VPCs
- **Multi-Account Support**: Cross-account Transit Gateway sharing using AWS RAM
- **VPC Peering**: Direct VPC-to-VPC connectivity
- **Flexible Routing**: Customizable route tables and routing strategies
- **Security Groups & NACLs**: Comprehensive network security controls
- **Cost Optimization**: Built-in cost estimation and optimization features
- **Monitoring & Logging**: VPC Flow Logs and CloudWatch integration
- **IPv6 Support**: Native IPv6 support for modern applications

## 📋 Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| aws | ~> 6.2.0 |
| terragrunt | >= 0.84.0 |

## 🏗️ Architecture Overview

This module supports multiple connectivity patterns:

1. **Hub-and-Spoke**: Central Transit Gateway with VPC attachments
2. **Mesh Network**: VPC peering connections between all VPCs
3. **Hybrid Approach**: Combination of Transit Gateway and VPC peering
4. **Cross-Account**: Shared Transit Gateway across multiple AWS accounts
5. **Multi-Region**: Support for resources across different AWS regions

## 🔒 Security Features

1. **Network Isolation**
   - Dedicated route tables per VPC
   - Custom NACLs for subnet-level security
   - Security groups for instance-level control

2. **Access Control**
   - RAM-based resource sharing
   - Cross-account access controls
   - Principle of least privilege

3. **Monitoring & Auditing**
   - VPC Flow Logs integration
   - CloudWatch metrics
   - AWS CloudTrail integration

## 💰 Cost Optimization

1. **Resource Efficiency**
   - Shared Transit Gateway for multiple VPCs
   - Optional components (create only what's needed)
   - Resource tagging for cost allocation

2. **Network Cost Control**
   - Strategic placement of NAT Gateways
   - VPC Peering for direct connectivity
   - Region-aware routing for data transfer optimization

## Usage

### Basic Example

```hcl
module "multivpc" {
  source = "./tfm-aws-multivpc"

  name_prefix = "my-multivpc"
  
  common_tags = {
    Environment = "production"
    Project     = "multi-vpc-connectivity"
    Owner       = "devops-team"
  }

  vpcs = {
    vpc-app = {
      cidr_block = "10.0.0.0/16"
      create_internet_gateway = true
      attach_to_transit_gateway = true
      
      subnets = {
        public-1a = {
          cidr_block        = "10.0.1.0/24"
          availability_zone = "us-west-2a"
          type             = "public"
          map_public_ip_on_launch = true
        }
        private-1a = {
          cidr_block        = "10.0.2.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
        }
        public-1b = {
          cidr_block        = "10.0.3.0/24"
          availability_zone = "us-west-2b"
          type             = "public"
          map_public_ip_on_launch = true
        }
        private-1b = {
          cidr_block        = "10.0.4.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
        }
      }

      security_groups = {
        app-sg = {
          name_prefix = "app-sg"
          description = "Security group for application servers"
          ingress_rules = [
            {
              description = "HTTP from anywhere"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
            },
            {
              description = "HTTPS from anywhere"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
            }
          ]
          egress_rules = [
            {
              description = "All outbound traffic"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["0.0.0.0/0"]
            }
          ]
        }
      }
    }

    vpc-data = {
      cidr_block = "10.1.0.0/16"
      attach_to_transit_gateway = true
      
      subnets = {
        private-1a = {
          cidr_block        = "10.1.1.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
        }
        private-1b = {
          cidr_block        = "10.1.2.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
        }
      }

      security_groups = {
        data-sg = {
          name_prefix = "data-sg"
          description = "Security group for data layer"
          ingress_rules = [
            {
              description = "Database access from app VPC"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              cidr_blocks = ["10.0.0.0/16"]
            }
          ]
        }
      }
    }
  }

  vpc_peering_connections = {
    app-to-data = {
      requester_vpc_key = "vpc-app"
      accepter_vpc_key  = "vpc-data"
      requester_cidr_block = "10.1.0.0/16"
      accepter_cidr_block  = "10.0.0.0/16"
    }
  }
}
```

### Advanced Example with Cross-Account Sharing

```hcl
module "multivpc" {
  source = "./tfm-aws-multivpc"

  name_prefix = "enterprise-multivpc"
  
  # Enable cross-account sharing
  enable_cross_account_sharing = true
  cross_account_principals = {
    account-1 = "123456789012"
    account-2 = "987654321098"
  }

  # Transit Gateway configuration
  create_transit_gateway = true
  transit_gateway_description = "Enterprise Transit Gateway for multi-account connectivity"
  transit_gateway_auto_accept_shared_attachments = "enable"

  vpcs = {
    shared-services = {
      cidr_block = "10.100.0.0/16"
      attach_to_transit_gateway = true
      
      subnets = {
        private-1a = {
          cidr_block        = "10.100.1.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
        }
      }

      security_groups = {
        shared-sg = {
          name_prefix = "shared-sg"
          description = "Security group for shared services"
          ingress_rules = [
            {
              description = "SSH from corporate network"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              cidr_blocks = ["192.168.0.0/16"]
            }
          ]
        }
      }
    }
  }

  # Enable monitoring and logging
  enable_flow_logs = true
  enable_cloudwatch_logs = true
  enable_vpc_endpoints = true
  vpc_endpoint_services = ["s3", "dynamodb", "ec2", "ssm"]
}
```

### Multi-Region Example

```hcl
# Primary region configuration
module "multivpc-primary" {
  source = "./tfm-aws-multivpc"

  providers = {
    aws = aws.us-west-2
  }

  name_prefix = "primary-multivpc"
  
  vpcs = {
    production = {
      cidr_block = "10.0.0.0/16"
      attach_to_transit_gateway = true
      # ... subnet and security group configuration
    }
  }
}

# Secondary region configuration
module "multivpc-secondary" {
  source = "./tfm-aws-multivpc"

  providers = {
    aws = aws.us-east-1
  }

  name_prefix = "secondary-multivpc"
  
  vpcs = {
    disaster-recovery = {
      cidr_block = "10.1.0.0/16"
      attach_to_transit_gateway = true
      # ... subnet and security group configuration
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix to be used for all resource names | `string` | `"multivpc"` | no |
| common_tags | Common tags to be applied to all resources | `map(string)` | `{}` | no |
| create_transit_gateway | Whether to create a Transit Gateway for centralized connectivity | `bool` | `true` | no |
| transit_gateway_description | Description for the Transit Gateway | `string` | `"Centralized Transit Gateway for multi-VPC connectivity"` | no |
| enable_cross_account_sharing | Whether to enable cross-account Transit Gateway sharing using RAM | `bool` | `false` | no |
| cross_account_principals | Map of cross-account principals (account IDs) to share the Transit Gateway with | `map(string)` | `{}` | no |
| vpcs | Map of VPC configurations | `map(object)` | `{}` | no |
| vpc_peering_connections | Map of VPC peering connection configurations | `map(object)` | `{}` | no |
| enable_flow_logs | Whether to enable VPC Flow Logs for all VPCs | `bool` | `false` | no |
| enable_vpc_endpoints | Whether to create VPC endpoints for AWS services | `bool` | `false` | no |
| enable_encryption | Whether to enable encryption for all resources | `bool` | `true` | no |

### VPC Configuration Object

```hcl
object({
  cidr_block           = string
  enable_dns_hostnames = optional(bool, true)
  enable_dns_support   = optional(bool, true)
  create_internet_gateway = optional(bool, false)
  attach_to_transit_gateway = optional(bool, true)
  subnets = optional(map(object({
    cidr_block                      = string
    availability_zone               = string
    map_public_ip_on_launch         = optional(bool, false)
    assign_ipv6_address_on_creation = optional(bool, false)
    type                            = optional(string, "private")
    tags                            = optional(map(string), {})
  })), {})
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
  tags = optional(map(string), {})
})
```

## Outputs

| Name | Description |
|------|-------------|
| transit_gateway_id | ID of the Transit Gateway |
| transit_gateway_arn | ARN of the Transit Gateway |
| vpc_ids | Map of VPC keys to VPC IDs |
| subnet_ids | Map of VPC keys to subnet IDs |
| route_table_ids | Map of VPC keys to route table IDs |
| vpc_peering_connection_ids | Map of peering connection keys to VPC peering connection IDs |
| connectivity_summary | Summary of connectivity configuration |
| network_architecture | Detailed network architecture information |
| estimated_monthly_cost | Estimated monthly cost breakdown for the infrastructure |

## Connectivity Patterns

### 1. Hub-and-Spoke Pattern

Use Transit Gateway as a central hub connecting multiple VPCs:

```hcl
vpcs = {
  hub-vpc = {
    cidr_block = "10.0.0.0/16"
    attach_to_transit_gateway = true
    # Hub VPC configuration
  }
  spoke-1 = {
    cidr_block = "10.1.0.0/16"
    attach_to_transit_gateway = true
    # Spoke VPC configuration
  }
  spoke-2 = {
    cidr_block = "10.2.0.0/16"
    attach_to_transit_gateway = true
    # Spoke VPC configuration
  }
}
```

### 2. Mesh Network Pattern

Connect VPCs directly using peering connections:

```hcl
vpc_peering_connections = {
  vpc1-to-vpc2 = {
    requester_vpc_key = "vpc1"
    accepter_vpc_key  = "vpc2"
    requester_cidr_block = "10.2.0.0/16"
    accepter_cidr_block  = "10.1.0.0/16"
  }
  vpc1-to-vpc3 = {
    requester_vpc_key = "vpc1"
    accepter_vpc_key  = "vpc3"
    requester_cidr_block = "10.3.0.0/16"
    accepter_cidr_block  = "10.1.0.0/16"
  }
  vpc2-to-vpc3 = {
    requester_vpc_key = "vpc2"
    accepter_vpc_key  = "vpc3"
    requester_cidr_block = "10.3.0.0/16"
    accepter_cidr_block  = "10.2.0.0/16"
  }
}
```

### 3. Hybrid Pattern

Combine Transit Gateway and VPC peering for optimal connectivity:

```hcl
# Use Transit Gateway for main connectivity
vpcs = {
  main-vpc = {
    cidr_block = "10.0.0.0/16"
    attach_to_transit_gateway = true
  }
  secondary-vpc = {
    cidr_block = "10.1.0.0/16"
    attach_to_transit_gateway = true
  }
}

# Use peering for specific high-bandwidth connections
vpc_peering_connections = {
  main-to-secondary = {
    requester_vpc_key = "main-vpc"
    accepter_vpc_key  = "secondary-vpc"
    requester_cidr_block = "10.1.0.0/16"
    accepter_cidr_block  = "10.0.0.0/16"
  }
}
```

## Security Best Practices

### 1. Network Segmentation

```hcl
vpcs = {
  dmz-vpc = {
    cidr_block = "10.0.0.0/16"
    create_internet_gateway = true
    # DMZ VPC with public-facing resources
  }
  app-vpc = {
    cidr_block = "10.1.0.0/16"
    attach_to_transit_gateway = true
    # Application VPC with private resources
  }
  data-vpc = {
    cidr_block = "10.2.0.0/16"
    attach_to_transit_gateway = true
    # Data VPC with sensitive resources
  }
}
```

### 2. Security Groups

```hcl
security_groups = {
  web-sg = {
    name_prefix = "web-sg"
    description = "Security group for web servers"
    ingress_rules = [
      {
        description = "HTTP from internet"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        description = "HTTPS from internet"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
  app-sg = {
    name_prefix = "app-sg"
    description = "Security group for application servers"
    ingress_rules = [
      {
        description = "Application traffic from web servers"
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        security_groups = ["sg-web"]
      }
    ]
  }
}
```

### 3. Network ACLs

```hcl
network_acls = {
  public-nacl = {
    ingress_rules = [
      {
        protocol   = "tcp"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
      },
      {
        protocol   = "tcp"
        rule_no    = 110
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 443
        to_port    = 443
      }
    ]
    egress_rules = [
      {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
      }
    ]
  }
}
```

## Cost Optimization

### 1. Enable Cost Estimation

```hcl
module "multivpc" {
  # ... other configuration

  enable_cost_optimization = true
  
  # Use the cost estimation outputs to monitor expenses
  # outputs.estimated_monthly_cost will provide cost breakdown
}
```

### 2. Optimize Transit Gateway Usage

```hcl
# Only attach VPCs that need cross-VPC communication
vpcs = {
  vpc-app = {
    cidr_block = "10.0.0.0/16"
    attach_to_transit_gateway = true  # Needs to communicate with other VPCs
  }
  vpc-isolated = {
    cidr_block = "10.1.0.0/16"
    attach_to_transit_gateway = false  # Isolated VPC, no Transit Gateway needed
  }
}
```

## Monitoring and Logging

### 1. VPC Flow Logs

```hcl
module "multivpc" {
  # ... other configuration

  enable_flow_logs = true
  flow_log_retention_days = 30
  enable_vpc_flow_logs_encryption = true
}
```

### 2. CloudWatch Integration

```hcl
module "multivpc" {
  # ... other configuration

  enable_cloudwatch_logs = true
  cloudwatch_log_group_name = "/aws/vpc/flowlogs"
}
```

## Cross-Account Sharing

### 1. Enable RAM Sharing

```hcl
module "multivpc" {
  # ... other configuration

  enable_cross_account_sharing = true
  ram_allow_external_principals = false  # Restrict to specific accounts
  
  cross_account_principals = {
    dev-account   = "111111111111"
    staging-account = "222222222222"
    prod-account  = "333333333333"
  }
}
```

### 2. Accept Shared Transit Gateway (in other accounts)

```hcl
# In the accepting account
data "aws_ec2_transit_gateway" "shared" {
  id = "tgw-xxxxxxxxx"  # ID of the shared Transit Gateway
}

resource "aws_ec2_transit_gateway_vpc_attachment" "local_vpc" {
  subnet_ids         = aws_subnet.local[*].id
  transit_gateway_id = data.aws_ec2_transit_gateway.shared.id
  vpc_id             = aws_vpc.local.id
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This module is licensed under the MIT License. See the LICENSE file for details.

## Support

For support and questions:

1. Check the [documentation](https://registry.terraform.io/modules/your-org/multivpc)
2. Search existing [issues](https://github.com/your-org/tfm-aws-multivpc/issues)
3. Create a new issue with detailed information about your problem

## Roadmap

- [ ] Support for Transit Gateway peering across regions
- [ ] Integration with AWS Network Firewall
- [ ] Support for AWS PrivateLink endpoints
- [ ] Enhanced cost optimization features
- [ ] Integration with AWS Config for compliance monitoring