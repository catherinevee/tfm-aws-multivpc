# Advanced Multi-VPC Connectivity Example
# This example demonstrates enterprise-level multi-account, multi-region connectivity

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "multivpc" {
  source = "../../"

  name_prefix = "enterprise-multivpc"
  
  common_tags = {
    Environment = "production"
    Project     = "enterprise-connectivity"
    Owner       = "enterprise-architects"
    CostCenter  = "infrastructure"
    Compliance  = "sox-pci"
  }

  # Transit Gateway Configuration
  create_transit_gateway = true
  transit_gateway_description = "Enterprise Transit Gateway for multi-account connectivity"
  transit_gateway_auto_accept_shared_attachments = "enable"
  transit_gateway_multicast_support = "enable"

  # Cross-Account Sharing Configuration
  enable_cross_account_sharing = true
  ram_allow_external_principals = false
  cross_account_principals = {
    dev-account     = "111111111111"
    staging-account = "222222222222"
    prod-account    = "333333333333"
    shared-account  = "444444444444"
  }

  # VPC Configurations
  vpcs = {
    # Shared Services VPC - Centralized services for all accounts
    vpc-shared = {
      cidr_block = "10.100.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      create_internet_gateway = true
      attach_to_transit_gateway = true
      
      subnets = {
        public-1a = {
          cidr_block        = "10.100.1.0/24"
          availability_zone = "us-west-2a"
          type             = "public"
          map_public_ip_on_launch = true
          tags = {
            Purpose = "shared-public"
          }
        }
        private-1a = {
          cidr_block        = "10.100.2.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
          tags = {
            Purpose = "shared-private"
          }
        }
        private-1b = {
          cidr_block        = "10.100.3.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
          tags = {
            Purpose = "shared-private"
          }
        }
        database-1a = {
          cidr_block        = "10.100.4.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
          tags = {
            Purpose = "shared-database"
          }
        }
        database-1b = {
          cidr_block        = "10.100.5.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
          tags = {
            Purpose = "shared-database"
          }
        }
      }

      # Transit Gateway Routes
      transit_gateway_routes = [
        {
          destination_cidr_block = "10.200.0.0/16"
          transit_gateway_attachment_id = "tgw-attach-prod"  # Reference to production VPC attachment
        },
        {
          destination_cidr_block = "10.300.0.0/16"
          transit_gateway_attachment_id = "tgw-attach-staging"  # Reference to staging VPC attachment
        }
      ]

      # Security Groups
      security_groups = {
        shared-web-sg = {
          name_prefix = "shared-web-sg"
          description = "Security group for shared web services"
          ingress_rules = [
            {
              description = "HTTP from all VPCs"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              cidr_blocks = ["10.100.0.0/16", "10.200.0.0/16", "10.300.0.0/16"]
            },
            {
              description = "HTTPS from all VPCs"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              cidr_blocks = ["10.100.0.0/16", "10.200.0.0/16", "10.300.0.0/16"]
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
        shared-app-sg = {
          name_prefix = "shared-app-sg"
          description = "Security group for shared application services"
          ingress_rules = [
            {
              description = "Application traffic from all VPCs"
              from_port   = 8080
              to_port     = 8080
              protocol    = "tcp"
              cidr_blocks = ["10.100.0.0/16", "10.200.0.0/16", "10.300.0.0/16"]
            },
            {
              description = "SSH from corporate network"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              cidr_blocks = ["192.168.0.0/16"]
            }
          ]
          egress_rules = [
            {
              description = "Database access to shared database"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              cidr_blocks = ["10.100.4.0/24", "10.100.5.0/24"]
            }
          ]
        }
        shared-db-sg = {
          name_prefix = "shared-db-sg"
          description = "Security group for shared database services"
          ingress_rules = [
            {
              description = "PostgreSQL from shared app servers"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              cidr_blocks = ["10.100.2.0/24", "10.100.3.0/24"]
            }
          ]
          egress_rules = [
            {
              description = "Limited outbound traffic"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["10.100.0.0/16"]
            }
          ]
        }
      }

      # Network ACLs for additional security
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
            },
            {
              protocol   = "tcp"
              rule_no    = 120
              action     = "allow"
              cidr_block = "192.168.0.0/16"
              from_port  = 22
              to_port    = 22
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
        private-nacl = {
          ingress_rules = [
            {
              protocol   = "tcp"
              rule_no    = 100
              action     = "allow"
              cidr_block = "10.100.0.0/16"
              from_port  = 0
              to_port    = 65535
            },
            {
              protocol   = "tcp"
              rule_no    = 110
              action     = "allow"
              cidr_block = "10.200.0.0/16"
              from_port  = 0
              to_port    = 65535
            },
            {
              protocol   = "tcp"
              rule_no    = 120
              action     = "allow"
              cidr_block = "10.300.0.0/16"
              from_port  = 0
              to_port    = 65535
            }
          ]
          egress_rules = [
            {
              protocol   = "-1"
              rule_no    = 100
              action     = "allow"
              cidr_block = "10.100.0.0/16"
            }
          ]
        }
      }

      tags = {
        Purpose = "shared-services"
        Tier    = "shared"
      }
    }

    # Production VPC - High-security production workloads
    vpc-production = {
      cidr_block = "10.200.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      create_internet_gateway = false  # No direct internet access
      attach_to_transit_gateway = true
      
      subnets = {
        private-1a = {
          cidr_block        = "10.200.1.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
          tags = {
            Purpose = "production-private"
          }
        }
        private-1b = {
          cidr_block        = "10.200.2.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
          tags = {
            Purpose = "production-private"
          }
        }
        database-1a = {
          cidr_block        = "10.200.3.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
          tags = {
            Purpose = "production-database"
          }
        }
        database-1b = {
          cidr_block        = "10.200.4.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
          tags = {
            Purpose = "production-database"
          }
        }
      }

      # Transit Gateway Routes
      transit_gateway_routes = [
        {
          destination_cidr_block = "10.100.0.0/16"
          transit_gateway_attachment_id = "tgw-attach-shared"
        },
        {
          destination_cidr_block = "10.300.0.0/16"
          transit_gateway_attachment_id = "tgw-attach-staging"
        }
      ]

      # Security Groups
      security_groups = {
        prod-app-sg = {
          name_prefix = "prod-app-sg"
          description = "Security group for production application servers"
          ingress_rules = [
            {
              description = "Application traffic from shared services"
              from_port   = 8080
              to_port     = 8080
              protocol    = "tcp"
              cidr_blocks = ["10.100.0.0/16"]
            }
          ]
          egress_rules = [
            {
              description = "Database access to production database"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              cidr_blocks = ["10.200.3.0/24", "10.200.4.0/24"]
            },
            {
              description = "Access to shared services"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["10.100.0.0/16"]
            }
          ]
        }
        prod-db-sg = {
          name_prefix = "prod-db-sg"
          description = "Security group for production database servers"
          ingress_rules = [
            {
              description = "PostgreSQL from production app servers"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              cidr_blocks = ["10.200.1.0/24", "10.200.2.0/24"]
            }
          ]
          egress_rules = [
            {
              description = "Limited outbound traffic"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["10.200.0.0/16"]
            }
          ]
        }
      }

      tags = {
        Purpose = "production"
        Tier    = "production"
        Compliance = "pci-dss"
      }
    }

    # Staging VPC - Pre-production testing environment
    vpc-staging = {
      cidr_block = "10.300.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      create_internet_gateway = true  # Limited internet access for testing
      attach_to_transit_gateway = true
      
      subnets = {
        public-1a = {
          cidr_block        = "10.300.1.0/24"
          availability_zone = "us-west-2a"
          type             = "public"
          map_public_ip_on_launch = true
          tags = {
            Purpose = "staging-public"
          }
        }
        private-1a = {
          cidr_block        = "10.300.2.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
          tags = {
            Purpose = "staging-private"
          }
        }
        private-1b = {
          cidr_block        = "10.300.3.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
          tags = {
            Purpose = "staging-private"
          }
        }
      }

      # Transit Gateway Routes
      transit_gateway_routes = [
        {
          destination_cidr_block = "10.100.0.0/16"
          transit_gateway_attachment_id = "tgw-attach-shared"
        },
        {
          destination_cidr_block = "10.200.0.0/16"
          transit_gateway_attachment_id = "tgw-attach-prod"
        }
      ]

      # Security Groups
      security_groups = {
        staging-app-sg = {
          name_prefix = "staging-app-sg"
          description = "Security group for staging application servers"
          ingress_rules = [
            {
              description = "HTTP from internet for testing"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
            },
            {
              description = "HTTPS from internet for testing"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
            },
            {
              description = "SSH from corporate network"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              cidr_blocks = ["192.168.0.0/16"]
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

      tags = {
        Purpose = "staging"
        Tier    = "staging"
      }
    }
  }

  # VPC Peering for high-bandwidth connections
  vpc_peering_connections = {
    shared-to-prod = {
      requester_vpc_key = "vpc-shared"
      accepter_vpc_key  = "vpc-production"
      requester_cidr_block = "10.200.0.0/16"
      accepter_cidr_block  = "10.100.0.0/16"
      auto_accept = true
      tags = {
        Purpose = "shared-prod-peering"
      }
    }
  }

  # Enhanced monitoring and logging
  enable_flow_logs = true
  flow_log_retention_days = 90
  enable_cloudwatch_logs = true
  cloudwatch_log_group_name = "/aws/vpc/enterprise-flowlogs"
  enable_vpc_flow_logs_encryption = true

  # VPC Endpoints for AWS services
  enable_vpc_endpoints = true
  vpc_endpoint_services = ["s3", "dynamodb", "ec2", "ec2messages", "ssm", "ssmmessages", "logs", "monitoring"]

  # Security and compliance
  enable_encryption = true
  enable_cost_optimization = true
} 