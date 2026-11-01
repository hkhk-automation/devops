---
tags:
  - Terraform
  - Moodulid
  - Praktikum
---

# Praktikum: Terraformi moodulid

Nädalal 10 nägid tsüklit `init`, `plan`, `apply`, `destroy` valmis konfiguratsiooniga. Selles praktikumis kirjutad HCL-i ise rida realt, lisad muutujad ja väljundid ning teed koodist mooduli, mida kutsud kaks korda. Kui tsükkel on veel segane, loe uuesti [nädala 10 loengut](../week10/lecture.md).

Töötad oma arvutis VS Code'is ja Terraform peab olema paigaldatud (`terraform -version`). Provider `local` loob faile ainult sinu kettale, serverit ega kontot ei ole vaja.

??? abstract "Õpiväljundid"

    Selle praktikumi lõpuks oskad:

    1. selgitada failide `main.tf`, `variables.tf` ja `outputs.tf` erinevust;
    2. kirjutada nullist HCL-i, mis loob ressursi;
    3. kasutada muutujaid (`var.nimi`) ja väljundeid (`output`);
    4. koostada korduvkasutatava mooduli ja kutsuda seda mitu korda erinevate sisenditega.

## Osa 1 · Esimene HCL nullist

Nädalal 10 nägid valmis `.tf` faili, mille kirjutas keegi teine. Täna kirjutad faili rida realt ise, nii jääb süntaks paremini meelde. HCL-i süntaks on kirjas dokumentatsioonis [Terraform Language](https://developer.hashicorp.com/terraform/language). Loo uus tühi kaust ja ava see VS Code'is:

```bash
mkdir ~/terraform-lab11
cd ~/terraform-lab11
code .
```

??? warning "Kui tuleb `terraform: command not found`"
    Terraform ei ole PATH-is. Kontrolli käsuga `which terraform` ja paigalda Terraform, kui seda ei ole.

### 1.1 Lihtsaim ressurss

Loo fail `main.tf` ja kirjuta see käsitsi (ära kopeeri):

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "tervitus" {
  filename = "tervitus.txt"
  content  = "Tere, Terraform!"
}
```

Failis on ainult üks ressurss, muutujad ja väljundid tulevad hiljem. Ressursi `local_file` parameetrid on kirjas [provideri `local` dokumentatsioonis](https://registry.terraform.io/providers/hashicorp/local/latest/docs).

```bash
terraform init
ls -la
```

Väljundis on `Terraform has been successfully initialized!` ning kaustas on uued `.terraform/` ja `.terraform.lock.hcl`.

??? warning "Kui tuleb `Failed to install provider`"
    Kontrolli internetiühendust. `init` laadib plugina alla ainult esimesel korral. Kui viga jääb, kustuta `.terraform/` ja käivita `terraform init` uuesti.

??? question "Mõtle"
    Mis on `.terraform/` ja `.terraform.lock.hcl` ning miks Terraform vajab neid enne `plan` käsku?

### 1.2 Plan ja apply

Kõigi käskude kirjeldus on lehel [CLI Commands](https://developer.hashicorp.com/terraform/cli/commands).

```bash
terraform plan
```

Rida `+ create` näitab, mida Terraform teeks. Käsk `plan` ei muuda veel midagi.

```bash
terraform apply
cat tervitus.txt
```

Fail tekib alles siis, kui kinnitad käsu sõnaga `yes`.

!!! tip
    Korduval testimisel jätab `terraform apply -auto-approve` kinnituse vahele. Tavatöös on kinnituse lugemine turvavõrk, seega ära harju `-auto-approve` kasutama.

??? question "Mõtle"
    Mille poolest erineb ressurss `local_file` käsust `echo "tekst" > fail.txt`? Miks kasutada selleks Terraformi?

### 1.3 Olekufail ja lahknevus

```bash
cat terraform.tfstate
```

Olekufail on JSON, kus Terraform peab arvet selle üle, mida ta on loonud. Olek ütleb, mis peaks olemas olema, ja `plan` võrdleb seda tegelikkusega. Tekita lahknevus:

```bash
rm tervitus.txt
terraform plan
```

Terraform tahab faili taastada, sest olekufaili järgi peaks fail olemas olema. Taasta fail käsuga `apply`.

### 1.4 Destroy

```bash
terraform destroy
```

Kinnita sõnaga `yes` ja kontrolli, et fail kadus.

??? warning "Kui `destroy` ei kustuta midagi"
    Oled tõenäoliselt vales kaustas. `terraform.tfstate` peab olema samas kaustas, kus käsku käivitad.

??? question "Mõtle"
    Mis tundub tsükli `init → plan → apply → destroy` juures teisiti, kui kirjutasid iga rea ise, võrreldes nädalaga 10, kui vaatasid õpetaja ekraani?

## Osa 2 · Muutujad

Failinimi `"tervitus.txt"` on praegu koodi sisse kirjutatud. Teise nimega faili jaoks peaks koodi muutma. Muutuja eraldab sisendi konfiguratsioonist.

### 2.1 Üks muutuja

Loo fail `variables.tf`:

```hcl
variable "faili_nimi" {
  description = "Loodava faili nimi"
  type        = string
  default     = "tervitus.txt"
}
```

Muuda faili `main.tf` ja asenda tekst viitega muutujale:

```hcl
resource "local_file" "tervitus" {
  filename = var.faili_nimi
  content  = "Tere, Terraform!"
}
```

```bash
terraform init && terraform plan
```

Vaikeväärtus `default` on sama mis enne, seega tulemus ei muutu. See on esimene kontroll enne edasi liikumist.

!!! tip
    Kui kirjutad ploki `variable`, aga ei kasuta failis `main.tf` viidet `var.faili_nimi`, jääb muutuja kasutuks. Kontrolli, et iga uus muutuja on kasutusel.

### 2.2 Ülekirjutamine käsurealt

```bash
terraform plan -var="faili_nimi=proov.txt"
```

??? question "Mõtle"
    Miks on `default` arenduses mugav, aga tootmises võib meeskond nõuda, et väärtus antakse alati eraldi?

### 2.3 Teine muutuja: sisu

Lisa faili `variables.tf`:

```hcl
variable "faili_sisu" {
  description = "Faili sisu"
  type        = string
  default     = "Tere, Terraform!"
}
```

Muuda faili `main.tf`:

```hcl
resource "local_file" "tervitus" {
  filename = var.faili_nimi
  content  = var.faili_sisu
}
```

```bash
terraform apply && cat tervitus.txt
```

??? warning "Kui `plan` näitab lihtsa muudatuse asemel destroy ja create"
    See on normaalne, kui `filename` muutub. Uue nimega fail on Terraformi jaoks uus ressurss.

??? warning "Kui tuleb `Unsupported argument`"
    Atribuudi nimes on kirjaviga. Kontrolli nime ressursi `local_file` dokumentatsioonist.

## Osa 3 · Väljundid

Kui konfiguratsioon loob midagi, tahad tulemust näha ilma faile otsimata. Osades 4–5 annad väljundi väärtuse ka edasi.

### 3.1 Esimene väljund

Loo fail `outputs.tf`:

```hcl
output "loodud_faili_nimi" {
  description = "Loodud faili nimi"
  value       = local_file.tervitus.filename
}
```

```bash
terraform apply
terraform output loodud_faili_nimi
```

??? question "Mõtle"
    Mida tähendavad viite `local_file.tervitus.filename` kolm osa? Kust need nimed tulevad, kui vaatad faili `main.tf`?

### 3.2 Teine väljund: räsi

Ressurss `local_file` arvutab ise atribuudi `content_md5`:

```hcl
output "sisu_rasi" {
  value = local_file.tervitus.content_md5
}
```

```bash
terraform apply && terraform output sisu_rasi
```

??? warning "Kui tuleb `Unsupported attribute`"
    Atribuudi nimi on vale (näiteks `content_hash`). Veateade näitab, millised atribuudid on olemas.

??? warning "Kui tuleb `Reference to undeclared resource`"
    Viitad millelegi, mida ei ole defineeritud, või on nimes kirjaviga.

## Osa 4 · Moodul

Praegu loob konfiguratsioon ühe tekstifaili. Kümne faili jaoks peaksid koodi kümme korda kopeerima. Moodul pakib loogika korduvkasutatavaks üksuseks, sarnaselt funktsiooniga. Moodulite koostamist näitab HashiCorpi õpetus [Build and use a local module](https://developer.hashicorp.com/terraform/tutorials/modules/module).

### 4.1 Mooduli kaust

```bash
mkdir -p modules/tekstifail
```

Kaust `modules/<nimi>/` on Terraformi kokkulepe: juurkaust kutsub mooduleid ja alamkaustad on moodulid.

### 4.2 Kood moodulisse

Loo `modules/tekstifail/main.tf` (ilma plokita `terraform { required_providers }`, see jääb ainult juurkausta):

```hcl
resource "local_file" "see" {
  filename = var.faili_nimi
  content  = var.faili_sisu
}
```

`modules/tekstifail/variables.tf`:

```hcl
variable "faili_nimi" {
  type = string
}

variable "faili_sisu" {
  type    = string
  default = "Tere, Terraform!"
}
```

Muutujal `faili_nimi` ei ole vaikeväärtust, seega peab iga mooduli kutse failinime andma. Muidu kirjutaksid mitu kutset sama faili.

`modules/tekstifail/outputs.tf`:

```hcl
output "faili_nimi" {
  value = local_file.see.filename
}

output "sisu_rasi" {
  value = local_file.see.content_md5
}
```

### 4.3 Mooduli kutsumine juurkaustast

Kirjuta juurkausta `main.tf` ümber nii, et see kutsub moodulit ressursi asemel:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

module "tervitus" {
  source     = "./modules/tekstifail"
  faili_nimi = var.faili_nimi
  faili_sisu = var.faili_sisu
}
```

Muuda juurkausta `outputs.tf` nii, et see viitab moodulile:

```hcl
output "loodud_faili_nimi" {
  value = module.tervitus.faili_nimi
}

output "sisu_rasi" {
  value = module.tervitus.sisu_rasi
}
```

### 4.4 Testi

```bash
terraform init
terraform plan
terraform apply
```

??? warning "Kui tuleb `Module not installed`"
    Iga kord, kui lisad või muudad plokki `module`, käivita `terraform init` uuesti. `init` ei ole vajalik ainult provider'ite jaoks.

??? question "Mõtle"
    Ava `terraform.tfstate`. Kuidas erineb ressursi nimi olekufailis (`module.tervitus.local_file.see`) varasemast (`local_file.tervitus`)?

## Osa 5 · Moodul kaks korda

Mooduli mõte on see, et üht koodi saab kasutada mitu korda.

### 5.1 Teine kutse

Kirjuta faili `main.tf` kaks plokki `module` erinevate nimedega:

```hcl
module "tervitus" {
  source     = "./modules/tekstifail"
  faili_nimi = var.faili_nimi
  faili_sisu = var.faili_sisu
}

module "logi" {
  source     = "./modules/tekstifail"
  faili_nimi = "logi.txt"
  faili_sisu = "Loodud teise mooduli kutsega."
}
```

??? warning "Kui kaks moodulit kirjutavad sama faili"
    Kui mõlemal kutsel on sama `faili_nimi`, kirjutab üks fail teise üle. Terraform ei keela seda plaani tasemel. Kontrolli, et iga kutse `faili_nimi` on erinev.

### 5.2 Väljundid

```hcl
output "tervituse_fail" {
  value = module.tervitus.faili_nimi
}

output "logi_fail" {
  value = module.logi.faili_nimi
}
```

### 5.3 Kogu tsükkel

```bash
terraform init
terraform plan
terraform apply
ls *.txt
cat tervitus.txt logi.txt
terraform destroy
```

Kontrolli, et mõlemad failid tekkisid ja seejärel kadusid.

??? question "Mõtle"
    Kui homme tuleks luua kümme faili erinevate sisenditega, mis muutub failis `main.tf` ja mis jääb kaustas `modules/tekstifail/` samaks?

??? note "Kontrollnimekiri"

    - Juurkaustas on `main.tf`, `variables.tf`, `outputs.tf` ja kaust `modules/tekstifail/` kolme failiga.
    - `terraform validate` ei anna viga.
    - `terraform plan` ei näita muudatusi, kui midagi ei ole muudetud.
    - `apply` loob kahe mooduli kutsega kaks faili.
    - `terraform output` näitab vähemalt nelja väljundit.
    - `destroy` kustutab mõlemad failid ja `ls *.txt` ei leia midagi.
    - Oskad selgitada, mille poolest `module "logi" {}` erineb otse ressursi kirjutamisest.

## Lisaülesanded

??? example "1 · Tsükkel"
    uuri `for_each` ja `count` võimalusi ning loo viis faili ühe plokiga `module`.

??? example "2 · Uus ressurss"
    uuri, milliseid ressursse provider `hashicorp/local` veel pakub, ja lisa moodulisse kausta loomine.

??? example "3 · Aheldamine"
    lisa kolmas kutse, mille `faili_sisu` sõltub teise mooduli väljundist (`module.logi.sisu_rasi`).
