# Terraform Põhitõed Kodutöö

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Õppida Terraform'i põhialused praktilist tööd tehes

## Õpieesmärgid

Selle kodutöö lõpuks oskate:
- Seadistada lihtsat Terraform projekti
- Kasutada muutujaid ja väljundeid
- Rakendada `count` funktsionaalsust
- Mõista Infrastructure as Code põhimõtteid

## Ülesanne 1: Esimene Projekt (3 punkti)

### 1.1 Projekti Loomine

Looge uus kaust ja failid:

```bash
mkdir minu-terraform-projekt
cd minu-terraform-projekt
touch main.tf variables.tf outputs.tf terraform.tfvars
```text

### 1.2 Põhikonfiguratsioon

Kirjutage `main.tf` faili:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "tervitus" {
  content  = "Tere! See on minu esimene Terraform fail."
  filename = "tervitus.txt"
}
```bash

**Ülesanded:**
1. Jooksutage `terraform init`
2. Jooksutage `terraform plan` ja selgitage väljundit
3. Jooksutage `terraform apply`
4. Kontrollige, et fail loodi

## Ülesanne 2: Muutujad (3 punkti)

### 2.1 Muutujate Defineerimine

Kirjutage `variables.tf` faili:

```hcl
variable "nimi" {
  description = "Teie nimi"
  type        = string
}

variable "arv" {
  description = "Failide arv"
  type        = number
  default     = 2
  
  validation {
    condition     = var.arv >= 1 && var.arv <= 5
    error_message = "Arv peab olema 1-5 vahel."
  }
}
```bash

### 2.2 Väärtuste Määramine

Kirjutage `terraform.tfvars` faili:

```hcl
nimi = "Teie-Nimi"
arv  = 3
```text

### 2.3 Muutujate Kasutamine

Muutke `main.tf` faili:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "info" {
  content = <<-EOF
    Nimi: ${var.nimi}
    Failide arv: ${var.arv}
    Loodud: ${timestamp()}
  EOF
  filename = "${var.nimi}_info.txt"
}
```bash

**Ülesanded:**
1. Rakendage muudatused
2. Muutke `arv` väärtust `terraform.tfvars` failis
3. Jooksutage uuesti ja vaadake muudatusi

## Ülesanne 3: Count ja Loops (4 punkti)

### 3.1 Mitme Faili Loomine

Lisage `main.tf` faili:

```hcl
resource "local_file" "failid" {
  count = var.arv
  
  content = <<-EOF
    Fail number: ${count.index + 1}
    Nimi: ${var.nimi}
    Index: ${count.index}
    
    See on fail ${count.index + 1} kokku ${var.arv}-st.
  EOF
  
  filename = "${var.nimi}_fail_${count.index + 1}.txt"
}
```text

### 3.2 Kokkuvõte

Lisage veel üks ressurss:

```hcl
resource "local_file" "kokkuvote" {
  content = jsonencode({
    kasutaja = var.nimi
    loodud_failide_arv = var.arv
    failide_nimed = [for i in range(var.arv) : "${var.nimi}_fail_${i + 1}.txt"]
    loomise_aeg = timestamp()
  })
  
  filename = "${var.nimi}_kokkuvote.json"
}
```text

**Ülesanded:**
1. Selgitage, mis on `count.index`
2. Proovige muuta `arv` väärtust 1-le, siis 4-le
3. Vaadake, kuidas failid muutuvad

## Ülesanne 4: Outputs (2 punkti)

### 4.1 Väljundite Defineerimine

Kirjutage `outputs.tf` faili:

```hcl
output "projekt_info" {
  description = "Projekti põhiinfo"
  value = {
    nimi = var.nimi
    failide_arv = var.arv
    loodud_failid = local_file.failid[*].filename
  }
}

output "tervitus_sisu" {
  description = "Tervituse faili sisu"
  value = local_file.info.content
}
```bash

**Ülesanded:**
1. Jooksutage `terraform output`
2. Selgitage, mida näitavad väljundid
3. Proovige `terraform output projekt_info`

## Ülesanne 5: Muudatuste Testimine (3 punkti)

### 5.1 Eksperimenteerimine

**Ülesanded:**
1. Muutke `nimi` väärtust uueks nimeks
2. Muutke `arv` väärtust 5-ks
3. Jooksutage `terraform plan` ja vaadake, millised muudatused toimuvad
4. Rakendage muudatused `terraform apply`-ga

### 5.2 Cleanup

**Ülesanded:**
1. Jooksutage `terraform destroy`
2. Selgitage, mis juhtub
3. Kontrollige, et failid kustutati

## Esitamise Nõuded

### Kohustuslikud Failid
1. `main.tf` - põhikonfiguratsioon
2. `variables.tf` - muutujate definitsioonid
3. `outputs.tf` - väljundite definitsioonid
4. `terraform.tfvars` - muutujate väärtused

### Dokumentatsioon
Kirjutage lühike selgitus (0.5 lk):
1. Mida õppisite Terraform'i kohta?
2. Millised olid keerulisemad osad?
3. Kuidas saaksite seda praktikas kasutada?

## Hindamise Kriteeriumid (15 punkti)

- **Tehniline korrektsus** (8p): Kas konfiguratsioon töötab?
- **Muutujate kasutamine** (3p): Kas muutujad on õigesti defineeritud?
- **Count funktsionaalsus** (2p): Kas count töötab korrektselt?
- **Dokumentatsioon** (2p): Kas selgitused on arusaadavad?

## Abi ja Nõuanded

- Alustage lihtsalt, lisage keerukust järk-järgult
- Testige pärast iga muudatust
- Kasutage `terraform plan` enne `apply`-d
- Kui midagi ei tööta, vaadake error messag'id hoolikalt
