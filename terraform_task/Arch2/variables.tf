variable "aws_region" {
  description = "AWS region to deploy resources"
  type    = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type    = string
}

variable "availability_zone" {
  description = "Availability Zone for the subnet"
  type    = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type    = string
}

variable "ami" {
  description = "AMI ID for the EC2 instance"
  type    = string
}

variable "key_name" {
  description = "Key pair name for EC2"
  type = string
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type    = string
}
