data "terraform_remote_state" "tf_remote_state_call" {
  backend = "s3"

  config = {
    bucket  = "tf-remote-state-ab"
    key     = "project1vpc.tfstate"
    region  = "us-east-1"
    profile = "adrianpersonal"
  }
}

data "aws_ami" "ami_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_route53_zone" "dns-main" {
  name = "cloud-adrian.click"
}
