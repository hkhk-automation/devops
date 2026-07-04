---
title: Terraform Tööriistad
tags:
  - terraform
  - tools
---

# Terraform Tööriistad

Käepärased abivahendid kvaliteetse Terraformi kirjutamiseks.

## terraform-docs — mooduli dokumentatsioon

Paigaldus (macOS):

```bash
brew install terraform-docs
```

Kasutus mooduli juurkaustas (loob/uuendab `README.md`):

```bash
terraform-docs markdown table . > README.md
```

CI/CD näide (GitHub Actions):

```yaml
- name: Generate docs
  run: terraform-docs markdown table . > README.md
```

## tflint — lintija

Paigaldus:

```bash
brew install tflint
```

Kasutus:

```bash
tflint --init
tflint
```

Soovitus: lisa `tflint.hcl` ja providerispetsiifilised pluginad.

## tfsec — turvakontroll

Paigaldus:

```bash
brew install tfsec
```

Kasutus:

```bash
tfsec .
```

CI-s kombineeri `tflint` + `tfsec` enne `terraform plan`i.


