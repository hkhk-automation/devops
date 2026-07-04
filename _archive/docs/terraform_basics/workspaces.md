---
title: Terraform Workspaces
tags:
  - terraform
  - lecture
  - workspaces
---

# Terraform Workspaces

Terraformi workspaced võimaldavad sama konfiguratsiooni kasutada mitmes eraldatud keskkonnas (nt `dev`, `stage`, `prod`) ilma eraldi kaustadeta.

## Põhimõtted

- Workspace lisab eraldi olekufaili iga keskkonna jaoks.
- `default` workspace on alati olemas; soovitatav on luua eraldi `dev`, `stage`, `prod`.
- Workspace nimi on kättesaadav väljendina: `${terraform.workspace}`.

## Kiirstart

```bash
terraform init
terraform workspace new dev
terraform workspace list
terraform workspace select dev
terraform apply
```

## Tingimuslikud väärtused workspace'i alusel

```hcl
locals {
  instance_type = terraform.workspace == "prod" ? "t3.large" : "t3.micro"
}

resource "aws_instance" "app" {
  ami           = var.ami
  instance_type = local.instance_type
}
```

## Kaustastrateegia vs workspaced

- Kui ressursside koostis erineb oluliselt, kasuta eraldi kaustasid/mooduleid.
- Kui erinevad peamiselt parameetrid, kasuta workspacese + `tfvars` faile.

## Hea tava

- Ära pane kriitilisi salajasi väärtusi ainult workspace'i; hoia need turvalises backendis (nt S3 + DynamoDB lock).
- Standardiseeri nimed: `dev`, `stage`, `prod` (väldi vabateksti).
- Visualiseeri aktiivne workspace CI-s (logides/keskkonnamuutujates).

## Käsud

```bash
terraform workspace new <name>
terraform workspace select <name>
terraform workspace list
terraform workspace delete <name>
```


