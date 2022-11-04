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
  region = "us-west-2"
}

# A resource block declares a resource of a given type ("aws_instance") with a given local name ("web"). 
# The name is used to refer to this resource from elsewhere in the same Terraform module, but has no significance outside that module's scope.
# The resource type and name together serve as an identifier for a given resource and so must be unique within a module.
resource "aws_instance" "app_server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
