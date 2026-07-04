---
tags:
  - Terraform
  - IaC
  - Praktikum
---

# Terraform — esimene kontakt — Labor

**Kestus:** 4 tundi
**Tase:** Algaste
**Eeldused:** Nädal 9 (async) võrdlustabel + ennustus. Nädal 10 loeng (init/plan/apply, provider/resource/variable). Kui udu — [tagasi loengusse](lecture.md).
**Töökeskkond:** oma masin, **VS Code**, Terraform installitud (`terraform -version`). `main.tf` annab õpetaja — alustad **lugedes ja jooksutades** (Osad 1–7), siis **laiendad seda ise** (Osad 8–10). `local` provider loob faile ainult su kettal, serverit vaja pole.

---

!!! abstract "Õpiväljundid"

    1. Kirjeldad mida teevad `init`, `plan`, `apply`, `show`, `state list`, `destroy`
    2. Loed `plan` väljundit ja **ennustad tulemuse enne** `apply`-t
    3. Selgitad mis on state ja miks see erineb tavalisest failisüsteemist
    4. Täidad nädal 9 tabeli Terraformi rea päris kogemuse põhjal

---

## Eeltöö

Kopeeri õpetaja antud kaust oma masinale, ava VS Code'is (`code .`) ja loe `main.tf` läbi — **ära muuda veel midagi**.

```bash
cd terraform-nadal10
ls
```

---

## Osa 1 · `terraform init`

Terraform peab laadima provider'i plugina, mida `main.tf` vajab.

```bash
terraform init
ls -la
```

Loe väljundist `Terraform has been successfully initialized!`. Kaustas on nüüd `.terraform/` ja `.terraform.lock.hcl`, mida sina ei loonud.

!!! tip
    `Failed to install provider` — kontrolli internetti. Võrku vajab ainult esimene `init`, provider salvestub `.terraform/`-i.

??? question "Mõtle"
    `.terraform/` sisaldab provider'i binaari (kümneid MB). Miks ei kuulu see kaust Gitti?

---

## Osa 2 · `terraform plan` — loe enne kui usud

```bash
terraform plan
```

**Ära käivita veel `apply`-t.** Loe väljund: `+` loomine, ressursi nimi (nt `local_file.tervitus`) tuleb `main.tf`-ist, kokkuvõte ("Plan: X to add...") näitab kogumõju.

!!! tip
    Ressursside arv ei klapi ootusega? Loe `main.tf` uuesti — mõni resource-plokk jääb esmapilgul märkamatuks.

??? question "Mõtle"
    Miks ei tohi tootmises kunagi jooksutada `apply`-t ilma `plan`-i lugemata?

---

## Osa 3 · `terraform apply`

```bash
terraform apply
```

Kinnituseks kirjuta täpselt `yes`. Kontrolli:

```bash
ls
cat <sinu_failinimi>
```

Fail ja sisu peavad vastama `main.tf`-ile.

!!! tip
    Midagi ei tekkinud, viga polnud? Kontrolli et kirjutasid täpselt `yes` — mitte `y` ega Enter.

??? question "Mõtle"
    Nägid sama tegevust kaks korda — `plan`-is ja `apply` kinnitusekraanil. Miks Terraform ei käivitu kohe pärast `plan`-i?

---

## Osa 4 · Ketas ja state läksid lahku

```bash
terraform state list
terraform show
cat terraform.tfstate
```

`state list` näitab mida Terraform "oma vastutusel" peab; `show` iga ressursi atribuute; `terraform.tfstate` on JSON, kust Terraform iga `plan` käigus loeb mis peaks juba olemas olema.

Nüüd **tekita lahknevus meelega** — kustuta loodud fail **käsitsi** (`rm`, mitte `destroy`):

```bash
rm <failinimi>
terraform plan
```

??? question "Diagnoosi"
    Terraform tahab faili **taastada**. Kettal pole faili, aga state ütleb et peaks olema — kaks reaalsust läksid lahku, ja Terraform usub state'i. Mis juhtuks, kui kustutaksid hoopis `terraform.tfstate` faili — kas Terraform teaks siis, et fail kunagi eksisteeris?

Taasta `apply`-ga (või jätka Osa 5).

---

## Osa 5 · Muuda muutuja väärtust

Ava `main.tf`, leia `variable` plokk `default` väärtusega ja muuda **ainult** seda. Salvesta, `terraform plan` — **ära veel apply**.

Loe väljund: `~` = ressurss **muudetakse kohapeal**; `-` + `+` koos = vana kustutatakse, uus luuakse (juhtub nt failinime muutmisel).

Kui mõistlik, `terraform apply` ja kontrolli `cat`-iga.

!!! tip
    `plan` näitab destroy+create seal kus ootasid lihtsat muudatust? Mõni atribuut (nt failinimi) pole providerile "kohapeal muudetav" — vana tuleb kustutada, uus luua.

??? question "Mõtle"
    Mille poolest erineb `~ update in-place` väljund `- destroy` + `+ create` paarist? Kummal on suurem andmekao risk, kui tegu oleks päris serveriga?

---

## Osa 6 · `terraform destroy`

```bash
terraform destroy
```

Loe väljund (kõik `-`), kinnita `yes`, siis:

```bash
ls
terraform state list
```

Loodud fail peab olema kadunud, `state list` tühi.

!!! tip
    `destroy` küsib kinnitust ressursside kohta, mida ei oodanud? Peatu ja loe uuesti — sama põhimõte mis `plan`-il.

??? question "Mõtle"
    `.terraform/` ja `.terraform.lock.hcl` jäävad alles ka pärast `destroy`-t. Miks — mille vahel Terraform siin vahet teeb?

---

## Osa 7 · Täida nädal 9 tabel

Ava nädal 9 võrdlustabel, täida Terraformi rida **päris kogemuse** põhjal:

| Tööriist | Lähenemine | Mida haldab | Idempotentne? |
|---|---|---|---|
| Terraform | ? | ? | ? |

- **Lähenemine:** kas `main.tf` kirjeldas samme (kuidas) või lõppseisundit (mis peab olema)?
- **Mida haldab:** mida haldas tänane `local_file`?
- **Idempotentne?:** mis juhtus, kui jooksutasid `plan` teist korda ilma muutmata?

Võrdle oma nädal 9 ennustusega — mis läks kokku, mis mitte?

---

## Osa 8 · Muutuja faili — `terraform.tfvars`

Seni oli muutuja `default` väärtus otse `main.tf`-is. Päris elus antakse väärtused eraldi failist, et sama kood töötaks eri keskkondades (meenuta Ansible group_vars). Terraformis on see `terraform.tfvars`.

Loo `terraform.tfvars` (täpselt see nimi — Terraform loeb selle automaatselt):

```hcl
faili_nimi = "tfvars-test.txt"
```

```bash
terraform plan
```

Väärtus tuli `.tfvars`-ist, mitte `default`-ist. Kontrolli:

```bash
terraform apply
ls *.txt
```

??? question "Mõtle"
    Nii `default` (`variables.tf`-is) kui `terraform.tfvars` annavad muutujale väärtuse. Kumb võidab, kui mõlemad on olemas? Milleks siis üldse `default`, kui `.tfvars` selle üle kirjutab?

!!! tip
    `.tfvars` sisaldab sageli keskkonna-spetsiifilisi väärtusi (paroolid, domeenid) — sama loogika mis Ansible `.env` / Vault. Tootmise `.tfvars` ei käi Gitti.

---

## Osa 9 · Lisa ise teine ressurss

Seni muutsid õpetaja faili. Nüüd **kirjuta ise** juurde. Lisa `main.tf`-i teine `local_file` ressurss (uue nimega, et esimesega ei põrka):

```hcl
resource "local_file" "logi" {
  filename = "minu-logi.txt"
  content  = "Selle rea kirjutasin mina, mitte õpetaja."
}
```

```bash
terraform plan
```

Loe väljund: `Plan: 1 to add`. Esimene ressurss on juba olemas (state teab), ainult uus lisatakse.

```bash
terraform apply
cat minu-logi.txt
terraform state list
```

`state list` näitab nüüd **kahte** ressurssi — üks õpetaja oma, üks sinu.

??? question "Diagnoosi enne kui parandad"
    Anna **meelega** teisele ressursile sama `filename` mis esimesel. `terraform apply`. Terraform ei kaeba plan-i tasemel, aga mis juhtub sisuga? Kaks ressurssi, üks fail — kumb võidab? Miks on see ohtlik päris infras (nt kaks VM-i sama nimega)?

Paranda nimi tagasi unikaalseks.

---

## Osa 10 · Output sinu ressursile + terve tsükkel

Lisa `outputs.tf`-i (kui pole, loo) väljund **oma** ressursile:

```hcl
output "minu_faili_rasi" {
  value = local_file.logi.content_md5
}
```

Jooksuta terve tsükkel algusest lõpuni, nüüd **kahe** ressursiga:

```bash
terraform apply
terraform output
terraform destroy
ls *.txt
```

`output` näitab väärtuse ilma faili avamata; `destroy` kustutab **mõlemad** ressursid; `ls` on tühi.

??? question "Mõtle"
    Sa alustasid õpetaja valmis failiga (Osa 1), lõpetasid oma ressursi + outputiga (Osa 10). Mis on ainus asi, mida sa pead teadma, et lisada kolmas, neljas, kümnes ressurss? Nädal 11 (moodulid) vastab: kuidas seda kordust vältida.

---

## Lõppkontroll

- [ ] `.terraform/` + `.terraform.lock.hcl` tekkisid `init` järel
- [ ] Oskad `plan` väljundist öelda mitu ressurssi luuakse/muudetakse/kustutatakse
- [ ] `apply` järel fail eksisteerib, sisu vastab `main.tf`-ile
- [ ] Näinud `state list` ja `show` väljundit, oskad selgitada
- [ ] Muutsid muutujat, lugesid uut `plan`-i enne `apply`-t
- [ ] `destroy` järel fail kustunud, `state list` tühi
- [ ] Nädal 9 tabeli Terraformi rida täidetud
- [ ] `terraform.tfvars` üle kirjutab `default`-i (Osa 8)
- [ ] Lisasid **ise** teise ressursi, `state list` näitab kahte (Osa 9)
- [ ] Oma output näitab väärtust, `destroy` kustutab mõlemad (Osa 10)

---

## Veaotsing

| Probleem | Lahendus |
|---|---|
| `terraform: command not found` | Pole installitud/PATH-is — teavita õpetajat |
| `Failed to install provider` | Kontrolli internetti, `init` uuesti |
| `apply` ei küsi kinnitust | Vale kaust (`pwd`, `ls`) |
| Fail ei tekkinud, viga polnud | Kontrolli failiteed `main.tf`-is |
| `plan` tahab taastada käsitsi kustutatud faili | Oodatud (Osa 4) — kasuta `destroy`, mitte `rm` |
| `.terraform/` jäi alles pärast `destroy` | Normaalne — Terraformi tööriist, mitte `main.tf` ressurss |

*Tabel 10.1. Levinumad tõrked ja lahendused.*

---

## Allikad

| Allikas | URL |
|---|---|
| CLI Workflow | <https://developer.hashicorp.com/terraform/cli/run> |
| Terraform State | <https://developer.hashicorp.com/terraform/language/state> |
| `terraform show` | <https://developer.hashicorp.com/terraform/cli/commands/show> |
| `state list` | <https://developer.hashicorp.com/terraform/cli/commands/state/list> |
| Local Provider | <https://registry.terraform.io/providers/hashicorp/local/latest/docs> |
