module "wpsg" {
  source = "terraform-aws-modules/security-group/aws"

  create = true
  name   = "${var.project_name}-private-asg"
  vpc_id = data.terraform_remote_state.tf_remote_state_call.outputs.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.lbsg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  computed_egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  number_of_computed_egress_with_cidr_blocks = 1

  tags = {
    Name = "${var.project_name}-private-asg"
  }
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  create                          = true
  name                            = "${var.project_name}-asg-main"
  use_name_prefix                 = true
  create_launch_template          = true
  launch_template_use_name_prefix = true
  min_size                        = 2
  max_size                        = 3
  desired_capacity                = 2
  health_check_type               = "EC2"
  image_id                        = data.aws_ami.ami_ubuntu.image_id
  instance_type                   = var.ec2_type
  user_data = base64encode(templatefile("./wp-install.sh",
    { db_pass = local.db_password,
      db_name = module.rds.db_instance_name,
      db_user = module.rds.db_instance_username,
  db_host = module.rds.db_instance_endpoint }))

  target_group_arns   = module.alb.target_group_arns
  vpc_zone_identifier = data.terraform_remote_state.tf_remote_state_call.outputs.private_subnet_ids
  security_groups     = [module.wpsg.security_group_id]

  create_iam_instance_profile = true
  iam_role_name               = "${var.project_name}-asg-main"
  iam_role_path               = "/ec2/"
  iam_role_tags = {
    Name = "${var.project_name}-asg-main"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "aws_iam_policy" "rds-access" {
  name        = "${var.project_name}-rds-access"
  description = "This is the policy for RDS access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds-db:connect"
        ]
        Effect   = "Allow"
        Resource = module.rds.db_instance_arn
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "rds-attach" {
  name       = "${var.project_name}-rds-attach"
  roles      = [module.asg.iam_role_name]
  policy_arn = aws_iam_policy.rds-access.arn
}
