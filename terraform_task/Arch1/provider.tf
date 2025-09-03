provider "aws" {
  region = var.aws_region
}
terraform {
  backend "s3" {
    bucket = "konecta-terraform-task-ali"
    key    = "task1/state.tfstate"
    region = "us-east-1"
  }
}