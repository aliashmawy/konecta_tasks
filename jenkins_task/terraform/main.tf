module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "konecta-vpc"
  cidr = var.vpc_cidr

  azs             = [var.availability_zone]
  public_subnets  = [var.public_subnet_cidr]
}

module "ephemeral_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "ephemeral-sg"
  description = "Security group for ephemeral instance"
  vpc_id      = module.vpc.vpc_id


  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow HTTP from within VPC"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow SSH only from inside VPC"
    }
  ]


  egress_rules = ["all-all"]
}


resource "aws_instance" "ephemeral" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.ephemeral_sg.security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = "ci-ephemeral"
    lifespan = "ephemeral"
    owner = "jenkins"
  }
}
