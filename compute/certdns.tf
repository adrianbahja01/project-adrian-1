module "acm" {
  source = "terraform-aws-modules/acm/aws"

  create_certificate = true
  domain_name        = var.domain_name
  zone_id            = data.aws_route53_zone.dns-main.zone_id


  wait_for_validation = true
  validation_method   = "DNS"

  tags = {
    Name = "${var.project_name}-lb-cert"
  }
}

module "dnsrecord" {
  source = "terraform-aws-modules/route53/aws//modules/records"

  zone_id = data.aws_route53_zone.dns-main.zone_id
  records = [
    {
      type    = "CNAME"
      name    = "wpab"
      ttl     = 300
      records = [module.alb.lb_dns_name]
    }
  ]
}
