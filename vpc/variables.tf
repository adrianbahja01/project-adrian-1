variable "vpc_cidr" {
  description = "This is the CIDR which will be used for the VPC"
}

variable "profile_name" {
  description = "The AWS profile name which is configured locally"
}

variable "project_name" {
  description = "The project name which can be used broadly when creating AWS resources"
}

variable "region_name" {
  description = "The region name where to deploy AWS resources"
}

variable "private_subnet_cidr" {
  description = "The list of CIDRs which will be used for private subnets"
}

variable "public_subnet_cidr" {
  description = "The list of CIDRs which will be used for public subnets"
}
