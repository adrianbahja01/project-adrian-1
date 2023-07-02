module "lbsg" {
  source = "terraform-aws-modules/security-group/aws"

  create = true
  name   = "${var.project_name}-public-lb"
  vpc_id = data.terraform_remote_state.tf_remote_state_call.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "HTTP access"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "HTTPS access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "https to ELB"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "${var.project_name}-public-lb"
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  depends_on         = [module.lbsg, module.acm]
  create_lb          = true
  name               = "${var.project_name}-lb-main"
  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.tf_remote_state_call.outputs.public_subnet_ids
  vpc_id             = data.terraform_remote_state.tf_remote_state_call.outputs.vpc_id
  security_groups    = [module.lbsg.security_group_id]
  internal           = false

  target_groups = [
    {
      name             = "${var.project_name}-wp-main"
      backend_port     = 80
      backend_protocol = "HTTP"
      health_check = {
        enabled             = true
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 2
        timeout             = 3
        interval            = 15
        matcher             = 200
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]


  tags = {
    Name = "${var.project_name}-lb-main"
  }
}
