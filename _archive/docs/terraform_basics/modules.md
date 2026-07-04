---
title: Terraform Modules
tags:
  - terraform
  - lecture
  - modules
---

# Terraform Modules

Moodulid võimaldavad ressursse taaskasutada ja standardiseerida.

## Struktuur

```text
modules/
  vpc/
    main.tf
    variables.tf
    outputs.tf
envs/
  dev/
    main.tf
```

## Lihtne moodul

```hcl
# modules/vpc/variables.tf
variable "cidr_block" { type = string }

# modules/vpc/main.tf
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = { Name = "example" }
}

# modules/vpc/outputs.tf
output "vpc_id" { value = aws_vpc.this.id }
```

## Mooduli kasutus

```hcl
module "network" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
}

output "vpc_id" { value = module.network.vpc_id }
```

## Versioonihaldus ja registrid

- Git URL: `source = "git::https://github.com/org/repo.git//modules/vpc?ref=v1.2.0"`
- Terraform Registry: `source = "terraform-aws-modules/vpc/aws"` koos `version = "~> 5.0"`.

## Hea tava

- Dokumenteeri sisendid/väljundid (`terraform-docs`).
- Väldi sisemiste ressursside nimesid väljundites; ekspordi ID-d ja olulised väljad.
- Tee moodulid väikeseks ja komposeeritavaks.
- Lisa `required_version` ja providerite versioonipiirangud.


