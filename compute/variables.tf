variable "profile_name" {
  description = "The AWS profile name which is configured locally"
}

variable "project_name" {
  description = "The project name which can be used broadly when creating AWS resources"
}

variable "region_name" {
  description = "The region name where to deploy AWS resources"
}

variable "ec2_type" {
  description = "The EC2 instance type"
}

variable "domain_name" {
  description = "The DNS record name which will be used by LB"
}
