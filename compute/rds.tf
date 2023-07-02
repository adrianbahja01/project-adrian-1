data "aws_secretsmanager_secret" "db_secret" {
  name = "db_secret"
}

data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)["db_pass"]
}

module "rdssg" {
  source = "terraform-aws-modules/security-group/aws"

  depends_on = [module.wpsg]
  create     = true
  name       = "${var.project_name}-rds-sg"
  vpc_id     = data.terraform_remote_state.tf_remote_state_call.outputs.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.wpsg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier             = "${var.project_name}-rds"
  allocated_storage      = 15
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  major_engine_version   = "5.7"
  family                 = "mysql5.7"
  db_name                = "wpdb"
  username               = "admin"
  port                   = "3306"
  password               = local.db_password
  create_db_subnet_group = true

  skip_final_snapshot         = true
  manage_master_user_password = false
  vpc_security_group_ids      = [module.rdssg.security_group_id]
  subnet_ids                  = data.terraform_remote_state.tf_remote_state_call.outputs.private_subnet_ids

  tags = {
    Name = "${var.project_name}-rds"
  }
}
