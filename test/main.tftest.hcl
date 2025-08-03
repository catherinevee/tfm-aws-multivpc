terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2.0"
    }
  }
}

run "validate_transit_gateway_creation" {
  command = plan

  variables {
    name_prefix = "test-multivpc"
    create_transit_gateway = true
    transit_gateway_description = "Test Transit Gateway"
    transit_gateway_amazon_side_asn = 64512
    
    common_tags = {
      Environment = "test"
      Project     = "multivpc-test"
    }

    vpcs = {
      vpc1 = {
        cidr_block = "10.0.0.0/16"
        create_internet_gateway = true
        attach_to_transit_gateway = true
        
        subnets = {
          public-1a = {
            cidr_block = "10.0.1.0/24"
            type = "public"
            availability_zone = "us-east-1a"
          }
        }
      }
    }
  }

  assert {
    condition     = aws_ec2_transit_gateway.main[0].description == "Test Transit Gateway"
    error_message = "Transit Gateway description does not match input"
  }

  assert {
    condition     = aws_ec2_transit_gateway.main[0].amazon_side_asn == 64512
    error_message = "Transit Gateway ASN does not match input"
  }
}

run "validate_vpc_creation" {
  command = plan

  variables {
    name_prefix = "test-multivpc"
    create_transit_gateway = false
    
    common_tags = {
      Environment = "test"
      Project     = "multivpc-test"
    }

    vpcs = {
      vpc1 = {
        cidr_block = "10.0.0.0/16"
        create_internet_gateway = true
        enable_dns_hostnames = true
        enable_dns_support = true
        
        subnets = {
          public-1a = {
            cidr_block = "10.0.1.0/24"
            type = "public"
            availability_zone = "us-east-1a"
          }
          private-1a = {
            cidr_block = "10.0.2.0/24"
            type = "private"
            availability_zone = "us-east-1a"
          }
        }
      }
    }
  }

  assert {
    condition     = aws_vpc.vpcs["vpc1"].cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block does not match input"
  }

  assert {
    condition     = aws_vpc.vpcs["vpc1"].enable_dns_hostnames == true
    error_message = "VPC DNS hostnames setting does not match input"
  }
}

run "validate_vpc_peering" {
  command = plan

  variables {
    name_prefix = "test-multivpc"
    create_transit_gateway = false
    
    common_tags = {
      Environment = "test"
      Project     = "multivpc-test"
    }

    vpcs = {
      vpc1 = {
        cidr_block = "10.0.0.0/16"
        create_internet_gateway = true
      }
      vpc2 = {
        cidr_block = "10.1.0.0/16"
        create_internet_gateway = true
      }
    }

    vpc_peering_connections = {
      vpc1-to-vpc2 = {
        requester_vpc_key = "vpc1"
        accepter_vpc_key = "vpc2"
        auto_accept = true
        requester_cidr_block = "10.1.0.0/16"
        accepter_cidr_block = "10.0.0.0/16"
      }
    }
  }

  assert {
    condition     = aws_vpc_peering_connection.peering["vpc1-to-vpc2"].auto_accept == true
    error_message = "VPC peering auto_accept setting does not match input"
  }
}
