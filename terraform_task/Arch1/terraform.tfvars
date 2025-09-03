aws_region       = "us-east-1"

vpc_cidr         = "10.0.0.0/16"
vpc_name         = "Konecta-vpc"

public_subnet_cidr      = "10.0.2.0/24"
public_subnet_name      = "public-subnet"
public_subnet_az        = "us-east-1a"

private_subnet_cidr      = "10.0.4.0/24"
private_subnet_name      = "private-subnet"
private_subnet_az        = "us-east-1a"

igw_name         = "main-igw"
rt_name          = "public-rt"

sg_name          = "nginx-sg"
allowed_ssh_cidr = "0.0.0.0/0"
allowed_http_cidr= "0.0.0.0/0"

instance_ami     = "ami-0360c520857e3138f"
instance_type    = "t2.micro"
instance_name    = "nginx-server"
key_name         = "vockey3"
