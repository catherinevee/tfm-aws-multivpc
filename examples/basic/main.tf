# Basic Multi-VPC Connectivity Example
# This example demonstrates a simple hub-and-spoke architecture with two VPCs

terraform {
  required_version = ">= 1.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2.0"
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



  # Enhanced VPC configurations with IPv6 support
  vpcs = {
    # Application VPC - Public-facing resources
    vpc-app = {
      cidr_block = "10.0.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      instance_tenancy = "default"
      enable_network_address_usage_metrics = true
      ipv6_cidr_block = "2001:db8::/56"
      secondary_cidr_blocks = ["10.1.0.0/16"]
      create_internet_gateway = true
      attach_to_transit_gateway = true
      
      subnets = {
        public-1a = {
          cidr_block        = "10.0.1.0/24"
          availability_zone = "us-west-2a"
          type             = "public"
          map_public_ip_on_launch = true
          assign_ipv6_address_on_creation = true
          ipv6_cidr_block = "2001:db8:0:1::/64"
          tags = {
            Purpose = "public-subnet"
          }
        }
        private-1a = {
          cidr_block        = "10.0.2.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
          assign_ipv6_address_on_creation = true
          ipv6_cidr_block = "2001:db8:0:2::/64"
          tags = {
            Purpose = "private-subnet"
          }
        }
        public-1b = {
          cidr_block        = "10.0.3.0/24"
          availability_zone = "us-west-2b"
          type             = "public"
          map_public_ip_on_launch = true
          assign_ipv6_address_on_creation = true
          ipv6_cidr_block = "2001:db8:0:3::/64"
          tags = {
            Purpose = "public-subnet"
          }
        }
        private-1b = {
          cidr_block        = "10.0.4.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
          assign_ipv6_address_on_creation = true
          ipv6_cidr_block = "2001:db8:0:4::/64"
          tags = {
            Purpose = "private-subnet"
          }
        }
      }

      # Enhanced route configuration
      routes = [
        {
          cidr_block = "10.1.0.0/16"
          transit_gateway_id = module.multivpc.transit_gateway_id
        },
        {
          cidr_block = "0.0.0.0/0"
          gateway_id = module.multivpc.internet_gateway_ids["vpc-app"]
        }
      ]

      # Enhanced security groups with additional attributes
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
              self = false
              prefix_list_ids = []
            },
            {
              description = "HTTPS from internet"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
              self = false
              prefix_list_ids = []
            },
            {
              description = "SSH from corporate network"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              cidr_blocks = ["192.168.0.0/16"]
              self = false
              prefix_list_ids = []
            }
          ]
          egress_rules = [
            {
              description = "All outbound traffic"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["0.0.0.0/0"]
              self = false
              prefix_list_ids = []
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
              self = false
              prefix_list_ids = []
            },
            {
              description = "SSH from web servers"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              cidr_blocks = ["10.0.1.0/24", "10.0.3.0/24"]
              self = false
              prefix_list_ids = []
            }
          ]
          egress_rules = [
            {
              description = "Database access to data VPC"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              cidr_blocks = ["10.1.0.0/16"]
              self = false
              prefix_list_ids = []
            },
            {
              description = "All outbound traffic"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["0.0.0.0/0"]
              self = false
              prefix_list_ids = []
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
      instance_tenancy = "default"
      enable_network_address_usage_metrics = false
      ipv6_cidr_block = "2001:db8:1::/56"
      create_internet_gateway = false
      attach_to_transit_gateway = true
      
      subnets = {
        private-1a = {
          cidr_block        = "10.1.1.0/24"
          availability_zone = "us-west-2a"
          type             = "private"
          assign_ipv6_address_on_creation = true
          ipv6_cidr_block = "2001:db8:1:1::/64"
          tags = {
            Purpose = "database-subnet"
          }
        }
        private-1b = {
          cidr_block        = "10.1.2.0/24"
          availability_zone = "us-west-2b"
          type             = "private"
          assign_ipv6_address_on_creation = true
          ipv6_cidr_block = "2001:db8:1:2::/64"
          tags = {
            Purpose = "database-subnet"
          }
        }
      }

      # Enhanced route configuration
      routes = [
        {
          cidr_block = "10.0.0.0/16"
          transit_gateway_id = module.multivpc.transit_gateway_id
        }
      ]

      # Enhanced security groups
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
              self = false
              prefix_list_ids = []
            },
            {
              description = "SSH from application VPC"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              cidr_blocks = ["10.0.0.0/16"]
              self = false
              prefix_list_ids = []
            }
          ]
          egress_rules = [
            {
              description = "Limited outbound traffic"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["10.0.0.0/16"]
              self = false
              prefix_list_ids = []
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

  # Enhanced VPC Peering Configuration
  vpc_peering_connections = {
    app-to-data = {
      requester_vpc_key = "vpc-app"
      accepter_vpc_key  = "vpc-data"
      requester_cidr_block = "10.1.0.0/16"
      accepter_cidr_block  = "10.0.0.0/16"
      auto_accept = true
      peer_owner_id = null
      peer_region = null
      tags = {
        Purpose = "app-data-peering"
      }
    }
  }

  # Enhanced monitoring and security
  enable_flow_logs = true
  flow_log_retention_days = 30
  flow_log_traffic_type = "ALL"
  flow_log_destination_type = "cloud-watch-logs"
  flow_log_max_aggregation_interval = 600
  flow_log_kms_key_id = null
  flow_log_tags = {
    Purpose = "flow-logs"
  }
  
  enable_cloudwatch_logs = true
  cloudwatch_log_group_name = "/aws/vpc/flowlogs"
  cloudwatch_log_group_kms_key_id = null
  cloudwatch_log_group_tags = {
    Purpose = "cloudwatch-logs"
  }
  
  enable_cloudwatch_alarms = true
  cloudwatch_alarms = {
    vpc_flow_logs = {
      alarm_name = "vpc-flow-logs-alarm"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods = 2
      metric_name = "FlowLogRecords"
      namespace = "AWS/Logs"
      period = 300
      statistic = "Sum"
      threshold = 1000
      alarm_description = "Alarm for VPC flow log records"
      treat_missing_data = "notBreaching"
      tags = {
        Purpose = "flow-logs-monitoring"
      }
    }
  }
  
  enable_encryption = true
  enable_vpc_flow_logs_encryption = true
  kms_key_arn = ""
  
  enable_vpc_endpoints = true
  vpc_endpoint_services = ["s3", "dynamodb", "ec2", "logs"]
  vpc_endpoint_tags = {
    Purpose = "vpc-endpoints"
  }
  
  enable_compliance_tagging = true
  compliance_tags = {
    Environment = "development"
    DataClassification = "internal"
    ComplianceFramework = "SOC2"
  }
} 