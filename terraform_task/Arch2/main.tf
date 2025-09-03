module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "konecta2-vpc"
  cidr = var.vpc_cidr

  azs             = [var.availability_zone]
  public_subnets  = [var.public_subnet_cidr]
}

module "nginx_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "nginx-private-sg"
  description = "Security group for private Nginx instance"
  vpc_id      = module.vpc.vpc_id


  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = var.vpc_cidr
      description = "Allow HTTP from within VPC"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.vpc_cidr
      description = "Allow SSH only from inside VPC"
    }
  ]


  egress_rules = ["all-all"]
}


resource "aws_instance" "nginx" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.nginx_sg.security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data = <<-EOF
            #!/bin/bash
            apt-get update -y
            apt-get install -y nginx
            systemctl start nginx
            systemctl enable nginx

              EOF

  tags = {
    Name = var.instance_name
  }
}
output "public_instance_id" {
  value = aws_instance.nginx.public_ip
}
