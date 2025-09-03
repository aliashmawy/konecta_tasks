aws_region         = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
availability_zone  = "us-east-1a"

instance_type = "t2.micro"
ami           = "ami-0360c520857e3138f"
key_name      = "vockey3"
instance_name = "public-nginx"
