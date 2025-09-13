variable "aws_region" {
  description = "aws region for resources"
  default = "us-east-1"
}

variable "ami" {
  description = "ami for ec2"
  default = "ami-0360c520857e3138f"
}

variable "key_name" {
  description = "key pair name"
  default = "vockey3"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type    = string
  default = "10.0.0.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for the subnet"
  type    = string
  default = "us-east-1a"
}