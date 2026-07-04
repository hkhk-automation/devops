---
tags:
  - Terraform
  - Moodulid
  - Praktikum
---

# Terraform moodulid — Labor (Valik 1)

**Kestus:** 4 tundi
**Tase:** Algaste
**Eeldused:** Nädal 10 — nägid `init/plan/apply/destroy` tsüklit ja jooksutasid valmis konfiga sama ise. Tead mis on muutuja programmeerimises. Kui udu — [tagasi nädal 10 loengusse](../week10/lecture.md).
**Töökeskkond:** oma masin, **VS Code**, Terraform installitud (`terraform -version`). `local` provider — loob faile ainult su kettal, serverit ega kontot vaja pole.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Selgitad mis vahe on `main.tf`, `variables.tf`, `outputs.tf` failidel
    2. Kirjutad nullist HCL-i, mis loob resource'i
    3. Kasutad muutujaid (`var.nimi`) ja väljundeid (`output`)
    4. Ehitad korduvkasutatava mooduli ja kutsud seda mitu korda erinevate sisenditega

---

Labi loogika: **HCL nullist → muutujad → outputs → moodul → korda kaks korda.** Sa kirjutad iga rea ise (mitte ei kopeeri suurt näidet) — nii jääb süntaks meelde. Fragmendid, testid igal sammul.

---

## Osa 1 · Esimene HCL nullist

Nädal 10 nägid valmis `.tf` faili teise kirjutatuna. Täna kirjutad rea-realt ise. Tee uus tühi kaust, ava VS Code'is:

```bash
mkdir ~/terraform-lab11
cd ~/terraform-lab11
code .
```

### 1.1 Minimaalne resource

Loo `main.tf`, **tipi käsitsi** (ära kopeeri):

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

Ainult **üks resource** — muutujad ja outputid tulevad hiljem.

```bash
terraform init
ls -la
```

`Terraform has been successfully initialized!` + uued `.terraform/` ja `.terraform.lock.hcl`.

!!! tip
    `Failed to install provider` — kontrolli internetti, `init` laeb plugina ainult esimesel korral.

??? question "Mõtle"
    Mis on `.terraform/` ja `.terraform.lock.hcl`, ja miks Terraform neid enne `plan`-i vajab?

### 1.2 Plan ja apply

```bash
terraform plan
```

`+ create` näitab mida tehtaks, **ei tee veel midagi**.

```bash
terraform apply
cat tervitus.txt
```

Kinnita `yes` enne kui fail tekib.

!!! tip
    Korduval testimisel `terraform apply -auto-approve` jätab kinnituse vahele. Tavatöös on kinnituse lugemine turvavõrk — ära harju `-auto-approve`-ga.

??? question "Mõtle"
    Mille poolest erineb `local_file` resource tavalisest `echo "tekst" > fail.txt` käsust? Miks selleks Terraform?

### 1.3 State ja lahknevus

```bash
cat terraform.tfstate
```

JSON, kus Terraform peab arvet mida ta on loonud. State ütleb mis **peaks** olemas olema, `plan` võrdleb tegelikkusega. Tekita lahknevus:

```bash
rm tervitus.txt
terraform plan
```

Terraform tahab faili taastada — state ütleb et peaks olema. Taasta `apply`-ga.

### 1.4 Destroy

```bash
terraform destroy
```

Kinnita `yes`, kontrolli et fail kadus.

??? question "Mõtle"
    Mis tundub teisiti sama `init → plan → apply → destroy` tsükli juures, kui ise iga rea kirjutasid, võrreldes õpetaja ekraani vaatamisega nädal 10?

---

## Osa 2 · Muutujad

Kõvasti kirjutatud `"tervitus.txt"` töötab, aga teise nimega faili jaoks pead koodi muutma. Muutuja lahutab sisendi konfist.

### 2.1 Üks muutuja

Loo `variables.tf`:

```hcl
variable "faili_nimi" {
  description = "Loodava faili nimi"
  type        = string
  default     = "tervitus.txt"
}
```

Muuda `main.tf`, asenda string viitega:

```hcl
resource "local_file" "tervitus" {
  filename = var.faili_nimi
  content  = "Tere, Terraform!"
}
```

```bash
terraform init && terraform plan
```

`default` on sama → tulemus sama. Esimene test enne edasi minemist.

!!! tip
    Kirjutad `variable` bloki, aga unustad `main.tf`-is `var.faili_nimi` kasutada — muutuja jääb kasutuks. Kontrolli alati et iga uus muutuja on päriselt kasutuses.

### 2.2 Ülekirjutamine käsurealt

```bash
terraform plan -var="faili_nimi=proov.txt"
```

??? question "Mõtle"
    Miks on `default` mugav arenduses, aga tootmises tahaks meeskond ehk nõuda et väärtus antaks alati eksplitsiitselt?

### 2.3 Teine muutuja — sisu

`variables.tf`-i:

```hcl
variable "faili_sisu" {
  description = "Faili sisu"
  type        = string
  default     = "Tere, Terraform!"
}
```

`main.tf`-i:

```hcl
resource "local_file" "tervitus" {
  filename = var.faili_nimi
  content  = var.faili_sisu
}
```

```bash
terraform apply && cat tervitus.txt
```

!!! tip
    `plan` näitab destroy + create lihtsa muutuse asemel? Normaalne kui `filename` muutub — fail loetakse uueks resource'iks.

---

## Osa 3 · Outputs

Kui konfig loob midagi, tahad tulemust näha ilma faile otsimata — ja Osas 4–5 väärtust edasi anda.

### 3.1 Esimene output

Loo `outputs.tf`:

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
    `local_file.tervitus.filename` — mis need kolm osa tähendavad? Kust said need nimed, kui vaatad `main.tf`-i?

### 3.2 Teine output — räsi

`local_file` loob automaatselt `content_md5`:

```hcl
output "sisu_rasi" {
  value = local_file.tervitus.content_md5
}
```

```bash
terraform apply && terraform output sisu_rasi
```

!!! tip
    Atribuudi nimi valesti (nt `content_hash`) → `plan` annab `Unsupported attribute`. Veateade ütleb mis atribuudid on saadaval.

---

## Osa 4 · Moodul

Sul on üks fail, mis loob ühe teksti-faili. Kümne jaoks kopeeriksid koodi kümme korda. Moodul pakib loogika korduvkasutatavaks üksuseks — nagu funktsioon.

### 4.1 Mooduli kaust

```bash
mkdir -p modules/tekstifail
```

`modules/<nimi>/` on Terraformi kokkulepe — juur kutsub, alamkataloogid on moodulid.

### 4.2 Tõsta kood moodulisse

`modules/tekstifail/main.tf` (**ilma** `terraform { required_providers }` plokita — see jääb ainult juurde):

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

!!! tip
    `faili_nimi`-l pole `default`-i — iga mooduli kutse **peab** failinime andma, muidu tekiks mitme kutse vahel konflikt.

`modules/tekstifail/outputs.tf`:

```hcl
output "faili_nimi" {
  value = local_file.see.filename
}

output "sisu_rasi" {
  value = local_file.see.content_md5
}
```

### 4.3 Kutsu moodulit juurest

Kirjuta juure `main.tf` ümber — **kutsub moodulit** resource'i asemel:

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

Uuenda juure `outputs.tf` viitama moodulile:

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

!!! tip
    `Module not installed` — iga kord kui lisad/muudad `module` plokki, jooksuta `init` uuesti (mitte ainult provider'ite jaoks).

??? question "Mõtle"
    Ava `terraform.tfstate`. Kuidas erineb resource'i nimi state's (`module.tervitus.local_file.see`) võrreldes varasemaga (`local_file.tervitus`)?

---

## Osa 5 · Kutsu moodulit kaks korda

See ongi mooduli mõte — üks kood, mitu kasutuskorda.

### 5.1 Teine kutse

`main.tf`-i kaks `module` plokki, **erineva nimega**:

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

!!! tip
    Sama `faili_nimi` mõlemale → mõlemad kirjutavad sama faili, üks üle teise. Terraform seda plan-i tasemel ei keela. Kontrolli et sisendid ei kattu.

### 5.2 Outputid

```hcl
output "tervituse_fail" {
  value = module.tervitus.faili_nimi
}

output "logi_fail" {
  value = module.logi.faili_nimi
}
```

### 5.3 Testi kogu tsükkel

```bash
terraform init
terraform plan
terraform apply
ls *.txt
cat tervitus.txt logi.txt
terraform destroy
```

Kontrolli et mõlemad failid tekkisid ja siis kadusid.

??? question "Mõtle"
    Kui homme peaksid tegema kümme faili erinevate sisenditega, mis muutub `main.tf`-is ja mis jääb samaks `modules/tekstifail/`-is?

---

## Lõppkontroll — oskad ilma juhendita

- [ ] Juurkataloogis `main.tf`, `variables.tf`, `outputs.tf` + `modules/tekstifail/` kolme failiga
- [ ] `terraform validate` ei anna viga
- [ ] `terraform plan` näitab null muudatust kui midagi pole muudetud
- [ ] `apply` loob kaks faili kahe mooduli kutsega
- [ ] `terraform output` näitab vähemalt nelja väljundit
- [ ] `destroy` kustutab mõlemad, `ls *.txt` tühi
- [ ] Selgitad mille poolest `module "logi" {}` erineb otse resource'i kirjutamisest

---

## Lisaülesanded (kui jõuad ette)

1. **Loop:** uuri `for_each` / `count`, loo viis faili **ühe** `module` plokiga.
2. **Uus resource:** uuri mis muid resource'e `hashicorp/local` pakub, lisa moodulisse kaustaloomine.
3. **Aheldamine:** kolmas kutse, mille `faili_sisu` sõltub teise mooduli outputist (`module.logi.sisu_rasi`).

---

## Veaotsing

| Probleem | Lahendus |
|---|---|
| `terraform: command not found` | Pole PATH-is — `which terraform`, installi |
| `Failed to install provider` | Kontrolli võrku; kustuta `.terraform/`, `init` uuesti |
| `Unsupported argument` | Kirjaviga atribuudis — kontrolli `local_file` dokke |
| `Reference to undeclared resource/module` | Viitad millelegi defineerimata, või kirjaviga |
| `Module not installed` | `terraform init` uuesti — iga uus/muudetud `module` vajab init'i |
| Kaks moodulit kirjutavad sama faili | Iga kutse `faili_nimi` unikaalseks |
| `plan` tahab faili taastada | Fail kustutati/muudeti käsitsi — state vs tegelikkus lahknevad |
| `destroy` ei kustuta | Vale kaust — `terraform.tfstate` peab samas olema |

*Tabel 11.2. Levinumad tõrked ja lahendused.*

---

## Allikad

| Allikas | URL |
|---|---|
| Local Provider | <https://registry.terraform.io/providers/hashicorp/local/latest/docs> |
| Terraform Modules (õpetus) | <https://developer.hashicorp.com/terraform/tutorials/modules/module> |
| Terraform Language | <https://developer.hashicorp.com/terraform/language> |
| CLI Commands | <https://developer.hashicorp.com/terraform/cli/commands> |
