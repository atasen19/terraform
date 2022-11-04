# For more variable types please visit [here](https://developer.hashicorp.com/terraform/language/expressions/types)
variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "ExampleAppServerInstance"
}

variable "aws_region" {
  description = "AWS Region"  
  type = string
  default = "eu-central-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type = string
  default = "10.0.0.0/16"
}

variable "ingress_cidr_blocks" {
  description = "Ingress CIDR block for Load Balancer Security Group"
  type = list 
  default = ["0.0.0.0/0"]
}