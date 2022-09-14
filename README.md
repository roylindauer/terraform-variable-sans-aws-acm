# Terraform module to create AWS ACM with a variable number of SANs

This module will create the appropriate Route53 validation records for all of the defined domains and subject alternative names. The module outputs the ARN of the ACM it creates.

The important bit is in `locals`. From the variables `domain_name` and `subject_alternative_names` we create a map of domains, distinct zones, certificate sans, and all certificate validation records that need to be created. 

## Usage:

With a module named `ssl_cert_default` you can get the ACM ARN with  `module.ssl_cert_default.acm_arn`

Scenario: You have an application load balancer configured to serve a frontend applications and want an SSL with a wildcard. 

```
module "ssl_cert_default" {
  source = "../modules/multi-domain-acm/"

  domain_name = {
    zone   = "roylindauer.com"
    domain = "roylindauer.com"
  }

  subject_alternative_names = [{ "zone" : "roylindauer.com", "domain" : "*.roylindauer.com" }]

  tags = { 
    "Environment" = "prod",
    "Description" = "Managed by Terraform",
    "Creator" = "Terraform",
    "Name" = "Prod Cluster - Roycom ACM"
  }
}
```


Scenario: You have an application load balancer configured to serve 2 different frontend applications with appropriate target groups for the two apps. The apps are `app.develop.roylindauer.com` and `app.develop.roylindauer.art`. You want to create a single SSL certificate for the load balancer.


```
module "ssl_cert_develop_alb" {
  source = "./modules/multi-domain-acm/"

  domain_name = {
    zone   = "roylindauer.com"
    domain = "*.develop.roylindauer.com"
  }

  subject_alternative_names = [
    {
      "zone" : "roylindauer.art",
      "domain" : "*.develop.roylindauer.art"
    }
  ]

  tags = { 
    "Environment" = "develop",
    "Description" = "Managed by Terraform",
    "Creator" = "Terraform",
    "Name" = "Develop Cluster - Default ACM"
  }
}
```

Scenario: You just want an ACM with no SANs 

```
module "ssl_cert_default" {
  source = "../modules/multi-domain-acm/"

  domain_name = {
    zone   = "roylindauer.com"
    domain = "roylindauer.com"
  }

  subject_alternative_names = []

  tags = { 
    "Environment" = "prod",
    "Description" = "Managed by Terraform",
    "Creator" = "Terraform",
    "Name" = "Prod Cluster - Roycom ACM"
  }
}
```