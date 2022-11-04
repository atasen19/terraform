terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Each resource type is implemented by a provider, which is a plugin for Terraform that offers a collection of resource types.
provider "aws" {
  region = var.aws_region
}

# A resource block declares a resource of a given type ("aws_instance") with a given local name ("web"). 
# The name is used to refer to this resource from elsewhere in the same Terraform module, but has no significance outside that module's scope.
# The resource type and name together serve as an identifier for a given resource and so must be unique within a module.
resource "aws_instance" "app_server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"

  tags = {
    Name = var.instance_name
  }
}

# Data sources allow Terraform to use information defined outside of Terraform, 
# defined by another separate Terraform configuration, or modified by functions.
data "aws_availability_zones" "available" {
  state = "available"
}

# Modules are containers for multiple resources that are used together. 
# A module consists of a collection of .tf and/or .tf.json files kept together in a directory.
# Modules are the main way to package and reuse resource configurations with Terraform.
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  cidr = var.vpc_cidr_block
  azs = data.aws_availability_zones.available.names
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    project = "my-test-project",
    environment = "dev"
  }
}

# For detailed information please visit [here](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest/submodules/web)
module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws/modules/web"
  version = "4.16.0"

  name = "web-sg-my-test-project"
  description = "Security group for web servers with HTTP ports open within VPC"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.public_subnets_cidr_blocks

  tags = {
    project = "my-test-project",
    environment = "dev"
  }
}

# For detailed information please visit [here](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest/submodules/web)
module "lb_security_group" {
  source  = "terraform-aws-modules/security-group/aws/modules/web"
  version = "4.16.0"

  name = "lb-sg-my-test-project"
  description = "Security group for load balancer with HTTP ports open within VPC"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = var.ingress_cidr_blocks

  tags = {
    project = "my-test-project",
    environment = "dev"
  }
}

resource "random_string" "lb_id" {
  length  = 3
  special = false
}

# For detailed inputs and outputs please visit [here](https://registry.terraform.io/modules/terraform-aws-modules/elb/aws/latest)
module "elb_http" {
  source = "terraform-aws-modules/elb/aws"
  version = "3.0.1"

  # Ensure lb name is unique
  name = "lb-${random_string.lb_id.result}-my-test-project-dev"

  internal = false

  # Detailed output parameters [here](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest/submodules/web#outputs)
  security_groups = [module.lb_security_group.this.security_group_id]
  subnets = module.vpc.public_subnets

  number_of_instances = length(module.ec2_instances.instance_ids)
  instances = module.ec2_instances.instance_ids

  listener = [{
    instance_port = "80"
    instance_protocol = "HTTP"
    lb_port = "80"
    lb_protocol = "HTTP"
  }]

  health_check = {
    # The instance being checked. The protocol is either TCP, HTTP, HTTPS, or SSL. 
    # The range of valid ports is one (1) through 65535.
    target = "HTTP:80/index.html"
    
    # The approximate interval, in seconds, between health checks of an individual instance. 
    # Type: Integer. Valid Range: Minimum value of 5. Maximum value of 300.
    interval = 10

    # The number of consecutive health checks successes required before moving the instance to the Healthy state.
    # Valid Range: Minimum value of 2. Maximum value of 10.
    healthy_threshold = 3

    # The number of consecutive health check failures required before moving the instance to the Unhealthy state.
    # Valid Range: Minimum value of 2. Maximum value of 10.
    unhealthy_threshold = 10

    # The amount of time, in seconds, during which no response means a failed health check.
    # Valid Range: Minimum value of 2. Maximum value of 60.
    timeout = 5
  }

  tags = {
    project = "my-test-project",
    environment = "dev"
  }
}

module "ec2_instances" {
  source = "./modules/aws-instance"

  instance_count     = 2
  instance_type      = "t2.micro"
  subnet_ids         = module.vpc.private_subnets[*]
  security_group_ids = [module.app_security_group.this_security_group_id]

  tags = {
    project = "my-test-project",
    environment = "dev"
  }
}