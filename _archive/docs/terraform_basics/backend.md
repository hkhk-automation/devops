---
title: Terraform Backend Configuration
tags:
  - terraform
  - lecture
  - backend
---

# Terraform Backend Configuration

Backend määrab, kuhu Terraform salvestab oleku (state). Tiimitöös peab state olema keskne ja lukustatav.

## Miks backend oluline on?

- Jagatud olek väldib konflikte ja "state drift" olukordi.
- Lukustamine hoiab ära samaaegsed `apply` käigud.
- Varundus ja ajalugu.

## S3 + DynamoDB (AWS) näide

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state-bucket"
    key            = "project/network/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "my-tf-locks"
    encrypt        = true
  }
}
```

Algne seadistus:

```bash
aws s3 mb s3://my-tf-state-bucket
aws dynamodb create-table \
  --table-name my-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

terraform init -reconfigure
```

## Azure Storage (Azure) näide

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tf-state"
    storage_account_name = "tfstate123456"
    container_name       = "state"
    key                  = "project/infra.tfstate"
  }
}
```

## GCS (Google Cloud) näide

```hcl
terraform {
  backend "gcs" {
    bucket = "my-tf-state-bucket"
    prefix = "project"
  }
}
``;

## Hea tava

- Hoia `backend` konfis ainult mitte-salajasi väärtusi; kasuta keskkonnamuutujaid/CI saladusi.
- Lülita lukustamine sisse (nt DynamoDB).
- Kasuta eraldi võtmeradu (`key/prefix`) iga keskkonna/workspace'i jaoks.
- Versiooniuuendustel kasuta `terraform init -reconfigure`.


