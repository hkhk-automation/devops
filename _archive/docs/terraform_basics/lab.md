# Terraform Basics Labor

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Praktiliselt õppida Terraform'i kasutamist ja luua infrastruktuuri koodi abil

---

## 1. Ettevalmistus ja Installatsioon

### 1.1 Terraform'i Installeerimine

Valige oma operatsioonisüsteem ja installige Terraform:

**macOS:**
```bash
brew install terraform
```text

**Linux (Ubuntu/Debian):**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```text

**Windows:**
```powershell
choco install terraform
```text

**Kontrollige installatsiooni:**
```bash
terraform version
```text

### 1.2 Projekti Struktuuri Loomine

```bash
mkdir terraform-lab
cd terraform-lab
mkdir -p {config,scripts,templates}
```bash

**Kontrollpunkt:** `terraform version` näitab versiooni numbrit.

---

## 2. Esimene Terraform Projekt

### 2.1 Põhilise Konfiguratsiooni Loomine

Looge fail `main.tf`:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Loo lihtne tekstifail
resource "local_file" "welcome" {
  content  = "Tere tulemast Terraform'i maailma!"
  filename = "${path.module}/welcome.txt"
}

# Loo konfiguratsioonikaust
resource "local_file" "config_dir" {
  content  = ""
  filename = "${path.module}/config/.gitkeep"
}
```bash

### 2.2 Terraform Workflow

**1. Projekti initsialiseerimine:**
```bash
terraform init
```bash

Terraform laadib alla vajalikud provider'id ja seadistab töökeskkonna.

**2. Muudatuste planeerimine:**
```bash
terraform plan
```bash

Terraform näitab, mida kavatseb teha. Lugege väljund läbi ja veenduge, et see vastab ootustele.

**3. Muudatuste rakendamine:**
```bash
terraform apply
```bash

Terraform küsib kinnitust. Sisestage `yes` jätkamiseks.

### 2.3 Tulemuste Kontrollimine

```bash
# Kontrollige loodud faile
ls -la
cat welcome.txt

# Vaadake Terraform state'i
terraform show
terraform state list
```bash

**Kontrollpunkt:** Kaust sisaldab faile `welcome.txt`, `terraform.tfstate` ja `.terraform` kataloogi.

---

## 3. Muutujad ja Väljundid

### 3.1 Muutujate Defineerimine

Looge fail `variables.tf`:

```hcl
variable "project_name" {
  description = "Projekti nimi"
  type        = string
  default     = "terraform-lab"
}

variable "environment" {
  description = "Keskkond (dev, test, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Keskkond peab olema dev, test või prod."
  }
}

variable "file_count" {
  description = "Loodavate failide arv"
  type        = number
  default     = 3
  
  validation {
    condition     = var.file_count > 0 && var.file_count <= 10
    error_message = "Failide arv peab olema vahemikus 1-10."
  }
}

variable "enable_backup" {
  description = "Kas luua varukoopiafailid"
  type        = bool
  default     = false
}
```text

### 3.2 Väljundite Defineerimine

Looge fail `outputs.tf`:

```hcl
output "project_info" {
  description = "Projekti üldinfo"
  value = {
    name        = var.project_name
    environment = var.environment
    file_count  = var.file_count
    created_at  = timestamp()
  }
}

output "created_files" {
  description = "Loodud failide nimekiri"
  value       = local_file.examples[*].filename
}

output "config_summary" {
  description = "Konfiguratsiooni kokkuvõte"
  value       = "Projekt '${var.project_name}' ${var.environment} keskkonnas, ${var.file_count} faili loodud"
}
```text

### 3.3 Main.tf Uuendamine

Uuendage `main.tf` faili:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Locals plokk arvutatud väärtuste jaoks
locals {
  timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())
  file_prefix = "${var.project_name}-${var.environment}"
}

# Loo mitu faili kasutades count
resource "local_file" "examples" {
  count = var.file_count
  
  content = templatefile("${path.module}/templates/file_template.txt", {
    file_number  = count.index + 1
    project_name = var.project_name
    environment  = var.environment
    timestamp    = local.timestamp
  })
  
  filename = "${path.module}/${local.file_prefix}-${count.index + 1}.txt"
}

# Konfiguratsioonifail JSON formaadis
resource "local_file" "config" {
  content = jsonencode({
    project = {
      name        = var.project_name
      environment = var.environment
      created_at  = local.timestamp
    }
    settings = {
      file_count     = var.file_count
      backup_enabled = var.enable_backup
    }
    metadata = {
      terraform_version = terraform.version
      created_by       = "Terraform Lab"
    }
  })
  
  filename = "${path.module}/config/project.json"
}

# Tinglik ressurss - luuakse ainult kui backup on lubatud
resource "local_file" "backup_config" {
  count = var.enable_backup ? 1 : 0
  
  content  = "Backup configuration for ${var.project_name}"
  filename = "${path.module}/config/backup.conf"
}
```text

### 3.4 Template Faili Loomine

Looge fail `templates/file_template.txt`:

```
==================================================
TERRAFORM LAB FAIL #${file_number}
==================================================

Projekt: ${project_name}
Keskkond: ${environment}
Faili number: ${file_number}
Loodud: ${timestamp}

See fail loodi Terraform'i abil automaatselt.
Terraform on Infrastructure as Code tööriist.

--------------------------------------------------
Terraform Lab - IT-süsteemide automatiseerimine
==================================================
```text

### 3.5 Uue Konfiguratsiooni Rakendamine

```bash
# Planeeri muudatused
terraform plan

# Rakenda muudatused
terraform apply

# Vaata väljundeid
terraform output

# Vaata konkreetset väljundit
terraform output project_info
```text

**Kontrollpunkt:** Näete loodud faile ja väljundeid, mis kasutavad muutujaid.

---

## 4. Täpsemad Funktsioonid

### 4.1 Data Source'ide Kasutamine

Lisage `main.tf` faili:

```hcl
# Loe olemasoleva faili sisu
data "local_file" "existing_config" {
  filename = "${path.module}/config/project.json"
  depends_on = [local_file.config]
}

# Loo kokkuvõttefail data source'i põhjal
resource "local_file" "summary" {
  content = templatefile("${path.module}/templates/summary.txt", {
    config_content = data.local_file.existing_config.content
    total_files    = length(local_file.examples)
    project_name   = var.project_name
  })
  
  filename = "${path.module}/project_summary.txt"
}
```text

Looge fail `templates/summary.txt`:

```
PROJEKTI KOKKUVÕTE
==================

Projekti nimi: ${project_name}
Loodud failide arv: ${total_files}

Konfiguratsiooni sisu:
${config_content}

Kokkuvõte genereeritud: ${timestamp()}
```text

### 4.2 For_each Kasutamine

Lisage `main.tf` faili erinevat tüüpi failide loomiseks:

```hcl
# Teenuste konfiguratsioonid
locals {
  services = {
    web = {
      port = 8080
      replicas = var.environment == "prod" ? 3 : 1
    }
    api = {
      port = 3000
      replicas = 2
    }
    database = {
      port = 5432
      replicas = 1
    }
  }
}

# Loo konfiguratsioonifail iga teenuse jaoks
resource "local_file" "service_configs" {
  for_each = local.services
  
  content = templatefile("${path.module}/templates/service.conf", {
    service_name = each.key
    port         = each.value.port
    replicas     = each.value.replicas
    environment  = var.environment
  })
  
  filename = "${path.module}/config/${each.key}-service.conf"
}
```text

Looge fail `templates/service.conf`:

```
# ${service_name} teenuse konfiguratsioon
# Keskkond: ${environment}

[service]
name = ${service_name}
port = ${port}
replicas = ${replicas}
environment = ${environment}

[health]
check_interval = 30s
timeout = 5s

[logging]
level = ${environment == "prod" ? "info" : "debug"}
```text

### 4.3 Lifecycle Rules

Lisage faili, mis on kaitstud tahtmatu kustutamise eest:

```hcl
resource "local_file" "important_data" {
  content = jsonencode({
    critical_info = "See on oluline konfiguratsioon"
    created_at    = timestamp()
    protected     = true
  })
  
  filename = "${path.module}/config/critical.json"
  
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [content]
  }
}
```text

### 4.4 Muudatuste Rakendamine

```bash
terraform plan
terraform apply

# Kontrollige loodud faile
ls -la config/
cat project_summary.txt
```bash

**Kontrollpunkt:** Näete erinevat tüüpi konfiguratsioone ja template'e.

---

## 5. Keskkonnapõhine Konfiguratsioon

### 5.1 Terraform Variable Failide Loomine

Looge erinevate keskkondade jaoks muutujate failid:

**`dev.tfvars`:**
```hcl
project_name = "my-terraform-project"
environment  = "dev"
file_count   = 2
enable_backup = false
```text

**`prod.tfvars`:**
```hcl
project_name = "my-terraform-project"
environment  = "prod"
file_count   = 5
enable_backup = true
```text

### 5.2 Erinevate Keskkondade Testimine

```bash
# Testi development konfiguratsiooni
terraform plan -var-file="dev.tfvars"

# Rakenda development konfiguratsioon
terraform apply -var-file="dev.tfvars"

# Kustuta ressursid
terraform destroy

# Testi production konfiguratsiooni
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```text

### 5.3 Workspace'ide Kasutamine

```bash
# Loo uued workspace'd
terraform workspace new development
terraform workspace new production

# Lülitu development workspace'i
terraform workspace select development
terraform apply -var-file="dev.tfvars"

# Lülitu production workspace'i
terraform workspace select production
terraform apply -var-file="prod.tfvars"

# Vaata workspace'e
terraform workspace list
```text

**Kontrollpunkt:** Erinevates workspace'ides on erinevad failid ja konfiguratsioonid.

---

## 6. State Management ja Troubleshooting

### 6.1 State'i Haldamine

```bash
# Vaata kõiki ressursse state'is
terraform state list

# Vaata konkreetse ressursi detaile
terraform state show local_file.config

# Liiguta ressurss state'is
terraform state mv local_file.examples[0] local_file.renamed_file

# Eemalda ressurss state'ist (ei kustuta tegelikku faili)
terraform state rm local_file.backup_config[0]

# Impordi olemasolev fail state'i
terraform import local_file.imported_file welcome.txt
```text

### 6.2 Tõrkeotsing

**State'i probleemide lahendamine:**
```bash
# Värskenda state olukordadega
terraform refresh

# Kontrolli state'i terviklikkust
terraform validate

# Formateeri kood
terraform fmt
```text

**Logide vaatamine:**
```bash
# Detailne väljund
TF_LOG=DEBUG terraform apply

# Salvestage logid faili
TF_LOG=INFO TF_LOG_PATH=terraform.log terraform apply
```text

### 6.3 State'i Backup ja Taastamine

```bash
# Tee state'i koopia
cp terraform.tfstate terraform.tfstate.backup

# Kui state on katki, taasta varukoopia
cp terraform.tfstate.backup terraform.tfstate
```text

**Kontrollpunkt:** Oskate hallata state'i ja lahendada tavalisi probleeme.

---

## 7. Cleanup ja Kokkuvõte

### 7.1 Ressursside Kustutamine

```bash
# Kustuta kõik workspace'i ressursid
terraform destroy

# Lülitu teise workspace'i ja kustuta sealsed ressursid
terraform workspace select development
terraform destroy

terraform workspace select production  
terraform destroy

# Kustuta workspace'd
terraform workspace select default
terraform workspace delete development
terraform workspace delete production
```text

### 7.2 Projekti Puhastamine

```bash
# Kustuta kõik loodud failid (valikuline)
rm -f *.txt *.json
rm -rf config/ .terraform/
rm -f terraform.tfstate*
```bash

---

## Labor Kokkuvõte

**Mida õppisite:**

1. **Terraform'i installeerimine ja seadistamine** - töökeskkonna ettevalmistamine
2. **Põhiline Terraform workflow** - init, plan, apply, destroy
3. **HCL süntaksi kasutamine** - muutujad, ressursid, väljundid
4. **Template'id ja funktsioonid** - dünaamiline sisu genereerimine
5. **Keskkonnapõhine konfiguratsioon** - erinevad seadistused erinevateks keskkondadeks
6. **State management** - infrastruktuuri oleku jälgimine
7. **Tõrkeotsimine** - probleemide tuvastamine ja lahendamine

**Järgmised sammud:**
- Uurige cloud provider'eid (AWS, Azure, GCP)
- Õppige Terraform module'eid
- Tutvuge CI/CD integratsiooniga
- Uurige Terraform Cloud'i

**Praktilised oskused:**
- Infrastruktuuri kirjeldamine koodina
- Versioonihaldus infrastruktuuri jaoks
- Automatiseeritud ja korduvkasutatav deploy
- Keskkondade vaheliste erinevuste haldamine

---

## Viited ja Dokumentatsioon

- [Terraform Official Documentation](https://www.terraform.io/docs) - täielik dokumentatsioon
- [Local Provider Documentation](https://registry.terraform.io/providers/hashicorp/local/latest/docs) - local provider'i dokumentatsioon
- [HCL Language Reference](https://www.terraform.io/docs/language) - HCL keele käsiraamat
- [Terraform CLI Commands](https://www.terraform.io/docs/cli) - käsurea liidese juhend
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices) - parimad praktikad
