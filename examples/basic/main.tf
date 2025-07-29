# Basic Multi-VPC Connectivity Example
# This example demonstrates a simple hub-and-spoke architecture with two VPCs

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

  name_prefix = "basic-multivpc"
  
  common_tags = {
    Environment = "development"
    Project     = "multi-vpc-demo"
    Owner       = "devops-team"
    CostCenter  = "engineering"
  }

  # Transit Gateway Configuration
  create_transit_gateway = true
  transit_gateway_description = "Basic Transit Gateway for demo environment"

  # VPC Configurations
  vpcs = {
    # Application VPC - Public-facing resources
    vpc-app = {
      cidr_block = "10.0.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      create_internet_gateway = true
      attach_to_transit_gateway = true
      
      subnets = {
        public-1a = {
          cidr_block        = "10.0.1.0/24"
          availability_zone = "us-west-2a"
          type             = "public"
          map_public_ip_on_launch = true
          tags = {
            Purpose = "public-subnet"
          }
        }
        private-1a = {
          cidr_block        = "10.0.2.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
          tags = {
            Purpose = "private-subnet"
          }
        }
        public-1b = {
          cidr_block        = "10.0.3.0/24"
          availability_zone = "us-west-2b"
          type             = "public"
          map_public_ip_on_launch = true
          tags = {
            Purpose = "public-subnet"
          }
        }
        private-1b = {
          cidr_block        = "10.0.4.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
          tags = {
            Purpose = "private-subnet"
          }
        }
      }

      # Route configuration for Transit Gateway
      routes = [
        {
          cidr_block = "10.1.0.0/16"
          transit_gateway_id = module.multivpc.transit_gateway_id
        }
      ]

      # Security Groups
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
          tags = {
            Purpose = "web-security"
          }
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
              cidr_blocks = ["10.0.1.0/24", "10.0.3.0/24"]
            },
            {
              description = "SSH from web servers"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              cidr_blocks = ["10.0.1.0/24", "10.0.3.0/24"]
            }
          ]
          egress_rules = [
            {
              description = "Database access to data VPC"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              cidr_blocks = ["10.1.0.0/16"]
            },
            {
              description = "All outbound traffic"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["0.0.0.0/0"]
            }
          ]
          tags = {
            Purpose = "app-security"
          }
        }
      }

      tags = {
        Purpose = "application-vpc"
      }
    }

    # Data VPC - Private resources, no internet access
    vpc-data = {
      cidr_block = "10.1.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      create_internet_gateway = false
      attach_to_transit_gateway = true
      
      subnets = {
        private-1a = {
          cidr_block        = "10.1.1.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
          tags = {
            Purpose = "database-subnet"
          }
        }
        private-1b = {
          cidr_block        = "10.1.2.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
          tags = {
            Purpose = "database-subnet"
          }
        }
      }

      # Route configuration for Transit Gateway
      routes = [
        {
          cidr_block = "10.0.0.0/16"
          transit_gateway_id = module.multivpc.transit_gateway_id
        }
      ]

      # Security Groups
      security_groups = {
        db-sg = {
          name_prefix = "db-sg"
          description = "Security group for database servers"
          ingress_rules = [
            {
              description = "PostgreSQL from application VPC"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              cidr_blocks = ["10.0.0.0/16"]
            },
            {
              description = "SSH from application VPC"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              cidr_blocks = ["10.0.0.0/16"]
            }
          ]
          egress_rules = [
            {
              description = "Limited outbound traffic"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["10.0.0.0/16"]
            }
          ]
          tags = {
            Purpose = "database-security"
          }
        }
      }

      tags = {
        Purpose = "data-vpc"
      }
    }
  }

  # VPC Peering Configuration (alternative to Transit Gateway)
  vpc_peering_connections = {
    app-to-data = {
      requester_vpc_key = "vpc-app"
      accepter_vpc_key  = "vpc-data"
      requester_cidr_block = "10.1.0.0/16"
      accepter_cidr_block  = "10.0.0.0/16"
      auto_accept = true
      tags = {
        Purpose = "app-data-peering"
      }
    }
  }

  # Enable basic monitoring
  enable_flow_logs = true
  flow_log_retention_days = 7
  enable_encryption = true
} 