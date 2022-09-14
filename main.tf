terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

locals {
  all_domains = concat([var.domain_name.domain], [
    for v in var.subject_alternative_names : v.domain
  ])
  
  all_zones = concat([var.domain_name.zone], [
    for v in var.subject_alternative_names : v.zone
  ])

  distinct_zones      = distinct(local.all_zones)
  zone_name_to_id_map = zipmap(local.distinct_zones, data.aws_route53_zone.domain[*].zone_id)
  domain_to_zone_map  = zipmap(local.all_domains, local.all_zones)

  cert_san = reverse(sort([
    for v in var.subject_alternative_names : v.domain
  ]))

  cert_validation_domains = [
    for v in aws_acm_certificate.certificate.domain_validation_options : tomap(v)
  ]
}

data "aws_route53_zone" "domain" {
  count = length(local.distinct_zones)

  name         = local.distinct_zones[count.index]
  private_zone = false
}

resource "aws_acm_certificate" "certificate"{
  domain_name               = var.domain_name.domain
  subject_alternative_names = local.cert_san
  validation_method         = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation_records" {
  count = length(distinct(local.all_domains))

  zone_id = lookup(local.zone_name_to_id_map, lookup(local.domain_to_zone_map, local.cert_validation_domains[count.index]["domain_name"]))
  name    = local.cert_validation_domains[count.index]["resource_record_name"]
  type    = local.cert_validation_domains[count.index]["resource_record_type"]
  ttl     = 60

  allow_overwrite = true

  records = [
    local.cert_validation_domains[count.index]["resource_record_value"]
  ]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count = 1

  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = local.cert_validation_domains[*]["resource_record_name"]
}
