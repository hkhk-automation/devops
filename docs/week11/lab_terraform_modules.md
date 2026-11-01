---
tags:
  - OpenTofu
  - Moodulid
  - Praktikum
---

# Praktikum: OpenTofu moodulid

N10-s kirjeldasid ühe virtuaalmasina. Täna kirjutad HCL-i ise, lisad muutujad ja väljundid ning teed koodist mooduli, mida kutsud kaks korda. Provider `local` loob faile ainult kettale, seega Proxmoxi ega tokenit vaja ei ole. Töötsükkel `init`, `plan`, `apply`, `destroy` on seletatud [N10 loengus](../week10/lecture.md).

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

??? abstract "Õpiväljundid"
    Praktikumi lõpuks oskad:

    1. selgitada failide `main.tf`, `variables.tf` ja `outputs.tf` erinevust;
    2. kirjutada HCL-i, mis loob ressursi;
    3. kasutada muutujaid (`var.nimi`) ja väljundeid (`output`);
    4. teha koodist mooduli ja kutsuda seda mitu korda eri sisenditega;
    5. viia ressursi moodulisse nii, et OpenTofu seda ei kustuta (`moved`).

## Osa 1 · Esimene ressurss

### 1.1 Töökaust

Töötad masinas `proxmox1` VS Code'i kaudu, kuhu paigaldasid OpenTofu N10-s. Kontrolli:

```bash
tofu version
```

Klooni oma Lab 11 repositoorium (link on Classroom 50-s) ja tee tööharu:

```bash
git clone <sinu-repo-URL> ~/lab11-tofu && cd ~/lab11-tofu
git switch -c n11-moodulid
mkdir -p logid
```

Kõik järgmised käsud käivitad kaustas `~/lab11-tofu`. Loo kohe fail `.gitignore`, et olekufail ja provider Giti ei läheks:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
tfplan
```

??? warning "Kui tuleb `tofu: command not found`"
    OpenTofu ei ole selles masinas paigaldatud. Paigalda see [N10 praktikumi osa 1.3](../week10/lab.md) järgi.

### 1.2 Lihtsaim ressurss

Loo fail `main.tf` ja kirjuta see ise, ära kopeeri. Nii jääb süntaks paremini meelde ([OpenTofu keel](https://opentofu.org/docs/language/)):

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
  content  = "Tere, OpenTofu!"
}
```

Plokk `terraform` on sama nimega ka OpenTofus. Ressursi `local_file` parameetrid on [provideri `local` lehel](https://search.opentofu.org/provider/hashicorp/local/latest). Käsk `init` laadib provideri alla:

```bash
tofu init
ls -a
```

??? success "Oodatav tulemus"
    Väljundis on `OpenTofu has been successfully initialized!` ning kaustas on `.terraform/` ja `.terraform.lock.hcl`.

??? warning "Kui tuleb `Failed to install provider`"
    Loe veateade läbi. Kui seal on `could not connect` või `timeout`, kontrolli võrku (`curl -sI https://registry.opentofu.org`). Kui seal on versioon, kontrolli rida `version`.

### 1.3 Plaan ja loomine

```bash
tofu plan
```

Rida `+ create` näitab, mida OpenTofu teeks. `plan` ei muuda veel midagi.

```bash
tofu apply
cat tervitus.txt
```

Fail tekib alles siis, kui kinnitad sõnaga `yes`.

??? question "Küsimus"
    Mille poolest erineb ressurss `local_file` käsust `echo "tekst" > fail.txt`?

### 1.4 Fail kustutatakse käsitsi

**Ennusta:** kustutad faili `tervitus.txt` käsitsi. Mida näitab järgmine plaan?

```bash
rm tervitus.txt
tofu plan
```

??? success "Oodatav tulemus"
    `1 to add`. Kood nõuab endiselt faili, seega tahab OpenTofu selle uuesti luua. Olekufail ütleb, et see fail on OpenTofu hallata.

Loo fail uuesti käsuga `tofu apply`. Fail jääb alles kuni osa 5 lõpuni.

## Osa 2 · Muutujad

Failinimi on praegu koodi sisse kirjutatud. Muutuja eraldab sisendi koodist.

### 2.1 Üks muutuja

Loo fail `variables.tf`:

```hcl
variable "faili_nimi" {
  description = "Loodava faili nimi"
  type        = string
  default     = "tervitus.txt"
}
```

Muuda failis `main.tf` ressurssi:

```hcl
resource "local_file" "tervitus" {
  filename = var.faili_nimi
  content  = "Tere, OpenTofu!"
}
```

**Ennusta:** vaikeväärtus on sama, mis enne. Kas plaan näitab muudatusi?

```bash
tofu plan
```

??? success "Oodatav tulemus"
    `No changes.` Fail on olemas ja selle nimi ei muutunud.

### 2.2 Väärtus käsurealt

```bash
tofu plan -var="faili_nimi=proov.txt"
```

Plaan näitab, et vana fail kustutatakse ja uus luuakse (`-/+`), sest uue nimega fail on uus ressurss. Ära seda plaani rakenda.

??? question "Küsimus"
    Miks on `default` arenduses mugav, aga tootmises nõutakse tihti, et väärtus antakse alati eraldi?

### 2.3 Teine muutuja

Lisa faili `variables.tf`:

```hcl
variable "faili_sisu" {
  description = "Faili sisu"
  type        = string
  default     = "Tere, OpenTofu!"
}
```

Muuda ressursis rida `content = var.faili_sisu` ja rakenda:

```bash
tofu apply
cat tervitus.txt
```

??? warning "Kui tuleb `Unsupported argument`"
    Argumendi nimes on kirjaviga. Kontrolli nime ressursi `local_file` lehelt.

## Osa 3 · Väljundid

Loo fail `outputs.tf`:

```hcl
output "loodud_faili_nimi" {
  value = local_file.tervitus.filename
}

output "sisu_rasi" {
  value = local_file.tervitus.content_md5
}
```

```bash
tofu apply
tofu output
```

??? question "Küsimus"
    Mida tähendavad viite `local_file.tervitus.filename` kolm osa? Kust need nimed tulevad?

??? warning "Kui tuleb `Unsupported attribute`"
    Atribuudi nimi on vale. Veateade näitab, millised atribuudid on olemas.

## Osa 4 · Moodul

Kümne faili jaoks peaksid ressursi kümme korda kopeerima. Moodul pakib koodi üheks osaks, mida saab mitu korda kutsuda, sarnaselt funktsiooniga ([moodulid](https://opentofu.org/docs/language/modules/)).

### 4.1 Mooduli failid

Selles projektis hoiame mooduleid kaustas `modules/`. Kus moodul asub, ütleb mooduli kutses rida `source`.

```bash
mkdir -p modules/tekstifail
```

Loo `modules/tekstifail/main.tf`. Moodul kirjutab ise üles, millist providerit ta vajab:

```hcl
terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

resource "local_file" "see" {
  filename = var.faili_nimi
  content  = var.faili_sisu
}
```

Mooduli sisendid `modules/tekstifail/variables.tf`:

```hcl
variable "faili_nimi" {
  type = string
}

variable "faili_sisu" {
  type    = string
  default = "Tere, OpenTofu!"
}
```

Muutujal `faili_nimi` ei ole vaikeväärtust, seega peab iga kutse failinime andma.

Mooduli väljundid `modules/tekstifail/outputs.tf`:

```hcl
output "faili_nimi" {
  value = local_file.see.filename
}

output "sisu_rasi" {
  value = local_file.see.content_md5
}
```

### 4.2 Mooduli kutse

Muuda juurkausta `main.tf`: plokk `terraform` jääb, ressurss `local_file` asendub mooduli kutsega:

```hcl
module "tervitus" {
  source     = "./modules/tekstifail"
  faili_nimi = var.faili_nimi
  faili_sisu = var.faili_sisu
}
```

Muuda juurkausta `outputs.tf`:

```hcl
output "loodud_faili_nimi" {
  value = module.tervitus.faili_nimi
}

output "sisu_rasi" {
  value = module.tervitus.sisu_rasi
}
```

### 4.3 Ressursi uus aadress

**Ennusta:** fail `tervitus.txt` on olemas. Mida tahab OpenTofu teha, kui ressurss on nüüd mooduli sees?

```bash
tofu init
tofu plan
```

??? success "Oodatav tulemus"
    `1 to add, 0 to change, 1 to destroy`. OpenTofu näeb kahte eri ressurssi: vana aadress `local_file.tervitus` kaob ja uus `module.tervitus.local_file.see` luuakse. Ta kustutaks faili ja looks selle uuesti. Failiga pole see oluline, aga andmebaasiga oleks.

Ära seda plaani rakenda. Ütle OpenTofule, et ressurss liikus. Lisa juurkausta `main.tf` lõppu plokk [`moved`](https://opentofu.org/docs/language/modules/develop/refactoring/):

```hcl
moved {
  from = local_file.tervitus
  to   = module.tervitus.local_file.see
}
```

```bash
tofu plan 2>&1 | tee logid/01-moved.txt
tofu apply
```

??? success "Oodatav tulemus"
    Plaanis on rida `has moved to module.tervitus.local_file.see` ja `0 to add, 0 to change, 0 to destroy`. Fail jääb puutumata.

??? warning "Kui tuleb `Module not installed`"
    Pärast iga uue ploki `module` lisamist käivita `tofu init`.

## Osa 5 · Sama moodul kaks korda

### 5.1 Teine kutse

Lisa juurkausta `main.tf` teine kutse:

```hcl
module "logi" {
  source     = "./modules/tekstifail"
  faili_nimi = "logi.txt"
  faili_sisu = "Loodud teise mooduli kutsega."
}
```

Iga kutse peab andma erineva `faili_nimi`. Kui kahel kutsel on sama nimi, kirjutab üks fail teise üle ja OpenTofu seda ei keela.

### 5.2 Väljundid

Juurkausta `outputs.tf` lõplik sisu on neli väljundit:

```hcl
output "loodud_faili_nimi" {
  value = module.tervitus.faili_nimi
}

output "sisu_rasi" {
  value = module.tervitus.sisu_rasi
}

output "logi_fail" {
  value = module.logi.faili_nimi
}

output "logi_rasi" {
  value = module.logi.sisu_rasi
}
```

### 5.3 Kontroll ja kustutamine

```bash
tofu init
tofu validate
tofu apply
tofu output | tee logid/02-output.txt
tofu plan 2>&1 | tee logid/03-plan-uuesti.txt
ls *.txt
```

??? success "Oodatav tulemus"
    Kaustas on `tervitus.txt` ja `logi.txt`. `tofu output` näitab nelja väljundit. Teine plaan näitab `No changes.`

Lõpuks kustuta kõik, mida see konfiguratsioon haldab. Loe plaan enne `yes` kirjutamist läbi:

```bash
tofu destroy 2>&1 | tee logid/04-destroy.txt
ls *.txt
```

??? success "Oodatav tulemus"
    `Destroy complete! Resources: 2 destroyed.` Failid `tervitus.txt` ja `logi.txt` on kadunud. Kood, lukufail ja logid on alles.

??? question "Küsimus"
    Kui homme tuleks luua kümme faili eri sisenditega, mis muutub juurkausta `main.tf` failis ja mis jääb kaustas `modules/tekstifail/` samaks?

## Töö esitamine

Repositooriumis on juurkausta `main.tf`, `variables.tf`, `outputs.tf`, `.terraform.lock.hcl`, `.gitignore`, kaust `modules/tekstifail/` kolme failiga ja neli logi kaustas `logid/`. Faili `README.md` kirjuta kahe lausega, mis vahe on aadressidel `local_file.tervitus` ja `module.tervitus.local_file.see` ning miks oli vaja plokki `moved`.

```bash
tofu fmt -recursive
git add .
git status --short
git commit -m "N11: moodul tekstifail, kaks kutset ja moved"
git push -u origin n11-moodulid
```

Käsu `git status --short` väljundis ei tohi olla `.terraform/` ega `terraform.tfstate`. Ava pull request harusse `main` ja liida see. Tulemuse näed Classroom 50-s.

## Lisaülesanded

??? example "1 · Mitu faili ühe plokiga"
    Uuri võtmeid [`for_each` ja `count`](https://opentofu.org/docs/language/meta-arguments/for_each/) ja loo viis faili ühe plokiga `module`.

??? example "2 · Fail alamkausta"
    Pane mooduli kutses `faili_nimi = "valjund/logi.txt"`. Kas OpenTofu loob kausta `valjund/` ise? Leia ressursi `local_file` lehelt, millega määratakse faili ja kausta õigused (`file_permission`, `directory_permission`).

??? example "3 · Aheldamine"
    Lisa kolmas kutse, mille `faili_sisu` on teise mooduli väljund (`module.logi.sisu_rasi`). Mis järjekorras OpenTofu faile loob ja kust ta selle teab?
