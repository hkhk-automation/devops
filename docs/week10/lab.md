---
tags:
  - OpenTofu
  - IaC
  - Proxmox
  - Praktikum
---

# Praktikum: virtuaalmasin OpenTofuga

Täna kirjeldad failis ühe virtuaalmasina, lood selle OpenTofuga kooli Proxmoxis ja kontrollid kahte [loengu](lecture.md) alguses kirjutatud ennustust: mida teeb OpenTofu, kui masin kustutatakse käsitsi või kui masina kirjeldus kaob failist. Töötad AlmaLinuxi masinas `proxmox1` VS Code'i kaudu ja OpenTofu ühendub sealt Proxmoxi API-ga.

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

??? abstract "Õpiväljundid"

    1. Oskad luua Proxmoxi virtuaalmasina OpenTofuga ja selle uuesti kustutada.
    2. Oskad lugeda `tofu plan` väljundist, mida OpenTofu loob, muudab või kustutab.
    3. Oskad näidata, mida teeb OpenTofu, kui tegelik olek või kood muutub.
    4. Oskad hoida tokenit, olekufaili ja allalaaditud providerit Gitist väljas ning lukufaili Gitis.

Rida **Ennusta** tähendab, et enne käsku mõtled läbi, mis juhtub. Vastus on kokkuvolditud plokis.

## Osa 1 · Ettevalmistus

### 1.1 Mida vajad

- VPN-ühendus ja VS Code'i ühendus masinaga `proxmox1`.
- Proxmoxi veebiliides <https://192.168.124.200:8006>. Logi sisse oma Proxmoxi kasutajaga.
- **VMID**: number vahemikus 4100–4199, mille annab õpetaja tunni alguses. Proxmoxis kannab sinu uus masin seda numbrit.

Sinu kasutajal on õigus luua masinaid pool'i `tofu-<kasutaja>` (näiteks `tofu-mtamm`). Kui sa Proxmoxi vasakus menüüs seda pool'i ei näe, küsi enne jätkamist õpetajalt abi.

### 1.2 Repositoorium

Kui sa loengu alguses ülesannet **Lab 10 - OpenTofu** vastu ei võtnud, tee seda nüüd ([Classroom 50](https://classroom50.org/hkhk-automation/it24-automatiseerimine/assignments)). Klooni repositoorium masinasse `proxmox1`:

```bash
cd ~
git clone <sinu-repo-url> lab10 && cd lab10
ls -a
```

Kõik järgmised käsud käivitad masinas `proxmox1` kaustas `~/lab10`. Logid lähevad kausta `logid/`.

??? success "Oodatav tulemus"
    Kaustas on failid `versions.tf`, `variables.tf`, `terraform.tfvars.example`, `.gitignore` ja `README.md`. Failis `versions.tf` on plokid `terraform` ja `provider`, failis `variables.tf` plokid `variable`.

### 1.3 OpenTofu paigaldamine

OpenTofu [ametlik paigaldusskript](https://opentofu.org/docs/intro/install/) lisab AlmaLinuxi dnf-i OpenTofu repositooriumi ja paigaldab paketi `tofu`. Skript küsib `sudo` parooli. Teiste süsteemide (Windows, macOS, Debian) paigaldusviisid on samal lehel, AlmaLinuxi käsitsi paigaldus lehel [RPM-paketid](https://opentofu.org/docs/intro/install/rpm/).

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
./install-opentofu.sh --install-method rpm
rm -f install-opentofu.sh
```

Kontrolli, et käsk `tofu` töötab:

```bash
tofu version
```

??? success "Oodatav tulemus"
    ```text
    OpenTofu v1.13.2
    on linux_amd64
    ```
    Versiooninumber võib olla suurem.

??? warning "Kui paigaldus ei õnnestu"
    - `curl: (6) Could not resolve host`: masin ei leia serveri nime. Kontrolli eraldi võrku (`ping -c 2 1.1.1.1`) ja DNS-i (`getent hosts get.opentofu.org`).
    - Skript teatab GPG-võtme veast: proovi üks kord uuesti. Kui viga kordub, näita veateadet õpetajale.

### 1.4 API-token

OpenTofu ühendub Proxmoxiga API-tokeniga. Token kuulub sinu kasutajale ja sellel on samad õigused nagu sinul.

1. Vali Proxmoxi veebiliideses **Datacenter → Permissions → API Tokens** ja vajuta **Add**.
2. **User**: sinu kasutaja. **Token ID**: `tofu`. Eemalda linnuke **Privilege Separation**, siis saab token sinu õigused. Vajuta **Add**.
3. Aken näitab väärtusi **Token ID** (näiteks `mtamm@hkhk.edu.ee!tofu`) ja **Secret**. Saladust näidatakse ainult üks kord. Ära sulge akent enne järgmist sammu.

Tee näidisfailist oma muutujate fail ja ava see VS Code'is:

```bash
cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars
```

Kirjuta failis `proxmox_api_token` väärtuseks Token ID, märk `=` ja Secret. Kirjuta `kasutaja` väärtuseks oma kasutajanimi ilma osata `@hkhk.edu.ee` ja `vm_id` väärtuseks õpetajalt saadud number. Salvesta fail.

Kontrolli, et token ei lähe Giti:

```bash
git status --short
```

??? success "Oodatav tulemus"
    Väljundis ei ole faili `terraform.tfvars`, sest `.gitignore` jätab selle välja.

??? warning "Kui sulgesid akna enne tokeni saladuse kopeerimist"
    Vali sama token (**API Tokens** nimekirjas), vajuta **Remove** ja loo uus sama nimega token.

### 1.5 Nimi ja ennustused README-s

Ava VS Code'is fail `README.md`. Kirjuta rea `**Sinu nimi:**` järele oma nimi ja kontrolli, et README 0. osas on loengu alguses kirjutatud kaks ennustust. Kui need puuduvad, kirjuta need nüüd, enne kui lood esimese masina, sest osades 4 ja 5 võrdled nendega.

## Osa 2 · Esimene masin

### 2.1 Masina kirjeldus

Loo fail `vm.tf` (VS Code'is **New File**) ja kirjuta sinna:

```hcl
resource "proxmox_virtual_environment_vm" "veeb" {
  name            = "tofu-${var.kasutaja}"
  node_name       = var.node_name
  vm_id           = var.vm_id
  pool_id         = "tofu-${var.kasutaja}"
  tags            = ["it24", "tofu"]
  stop_on_destroy = true

  clone {
    vm_id = var.template_id
    full  = false
  }

  cpu {
    type  = "x86-64-v2-AES"
    cores = 1
  }

  memory {
    dedicated = 1024
  }

  agent {
    enabled = true
  }
}

output "ip" {
  value = proxmox_virtual_environment_vm.veeb.ipv4_addresses[1][0]
}
```

Iga atribuudi täpse tähenduse leiad provideri dokumentatsioonist: [proxmox_virtual_environment_vm](https://search.opentofu.org/provider/bpg/proxmox/latest/docs/resources/virtual_environment_vm).

??? note "Tabel 10.6. Atribuudid failis `vm.tf`"
    | Atribuut | Mida teeb |
    |---|---|
    | `node_name`, `vm_id`, `pool_id` | Proxmoxi sõlm, masina number ja pool, kuhu masin luuakse |
    | `clone` | masin kloonitakse mallist `template_id` (AlmaLinux). `full = false` teeb lingitud koopia: uus masin kasutab malli ketast ja salvestab ainult erinevused, seega valmib see mõne sekundiga |
    | `cpu.type` | AlmaLinux 9 vajab protsessori tüüpi vähemalt `x86-64-v2`. Vaikimisi tüübiga masin ei käivitu |
    | `memory.dedicated` | mälu megabaitides |
    | `agent` | Proxmox küsib masinas töötavalt guest agent'ilt IP-aadressi. Ilma selleta ei tea OpenTofu masina IP-d |
    | `stop_on_destroy` | kustutamisel lülitatakse masin kohe välja, OpenTofu ei oota korrektset seiskamist |
    | `output "ip"` | `ipv4_addresses` on iga võrguliidese aadresside nimekiri. Meie mallis on esimene liides `lo` (127.0.0.1), seega on masina IP teise liidese (`[1]`) esimene aadress (`[0]`). Kui IP on vale, vaata kõiki aadresse käsuga `tofu state show` |

### 2.2 Provideri allalaadimine

`tofu init` laeb alla provideri, mida nõuab `versions.tf` plokk `required_providers`.

```bash
tofu init
```

Vaata, mis kausta tekkis ja mida Git näeb:

```bash
ls -a
git status --short
```

**Küsimus:** kaustas on nüüd `.terraform/` ja `.terraform.lock.hcl`. Kumb neist on `git status` väljundis ja miks? (README 2.2)

??? success "Oodatav tulemus"
    `tofu init` lõpetab reaga `OpenTofu has been successfully initialized!`. `git status` näitab faile `.terraform.lock.hcl` ja `vm.tf`. Kausta `.terraform/` ei näita, sest see on `.gitignore`-is.

### 2.3 Plaan

**Ennusta:** Mitu ressurssi plaan loob, muudab ja kustutab?

Võti `-out=tfplan` salvestab plaani faili. Käsk `tee` näitab väljundit ekraanil ja kirjutab sama väljundi logifaili:

```bash
tofu plan -out=tfplan 2>&1 | tee logid/01-plan.txt
```

Loe plaan läbi. Leia rida, mis algab märgiga `#`, ja plaani kokkuvõtterida.

??? success "Oodatav tulemus"
    ```text
      # proxmox_virtual_environment_vm.veeb will be created
      + resource "proxmox_virtual_environment_vm" "veeb" {
          + name      = "tofu-mtamm"
          + vm_id     = 4100
    ...
    Plan: 1 to add, 0 to change, 0 to destroy.

    Changes to Outputs:
      + ip = (known after apply)
    ```
    Paljud atribuudid on `(known after apply)`: nende väärtuse teab Proxmox alles siis, kui masin on olemas.

??? warning "Kui plaan annab vea"
    - `No value for required variable`: failis `terraform.tfvars` on muutuja puudu või kirjaviga muutuja nimes.
    - `Reference to undeclared input variable`: failis `vm.tf` on muutuja nimes kirjaviga.
    - `Unsupported argument` või `Unsupported block type`: kontrolli `vm.tf` sulge ja taandeid. `tofu validate` näitab vea rida.

### 2.4 Masina loomine

Plaanifailiga teeb `apply` täpselt need muudatused, mida plaanis lugesid:

```bash
tofu apply tfplan 2>&1 | tee logid/02-apply.txt
```

Masina kloonimine võtab mõne sekundi. Seejärel ootab OpenTofu, kuni masin käivitub ja guest agent teatab IP-aadressi. Seni näed ridu `Still creating...`.

Kontrolli, et masinal on IP-aadress ja see vastab:

```bash
tofu output ip
ping -c 2 $(tofu output -raw ip)
```

Ava Proxmoxi veebiliideses pool `tofu-<kasutaja>`. Selles on masin `tofu-<kasutaja>`, mis töötab.

**Küsimus:** mis on `tofu output ip` väärtus ja kas sama IP on Proxmoxis masina **Summary** lehel? (README 2.1)

??? success "Oodatav tulemus"
    ```text
    proxmox_virtual_environment_vm.veeb: Creating...
    proxmox_virtual_environment_vm.veeb: Still creating... [10s elapsed]
    proxmox_virtual_environment_vm.veeb: Creation complete after 48s [id=4100]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

    Outputs:

    ip = "192.168.125.143"
    ```

??? warning "Kui apply annab vea"
    - `403 Forbidden` või `Permission check failed`: kontrolli kõigepealt failis `terraform.tfvars` tokeni nime. Kui see on õige, on tokenil **Privilege Separation** sees (loo token uuesti, samm 1.4) või sul pole veel pool'i õigusi (küsi õpetajalt).
    - `pool 'tofu-...' does not exist`: `kasutaja` väärtus failis `terraform.tfvars` ei vasta sinu Proxmoxi kasutajanimele.
    - `VM ... already exists`: sinu `vm_id` on kellegi teise masina number. Kontrolli õpetajalt saadud numbrit.
    - `Still creating...` kestab üle 5 minuti: ava Proxmoxis masina **Console** ja vaata, kas masin käivitus. Kui käivitus, aga guest agent ei vasta, küsi õpetajalt abi.

### 2.5 Kood GitHubi

Enne commit'i vorminda failid. `tofu fmt` joondab võrdusmärgid ja taanded nii, nagu OpenTofu stiil ette näeb, ja trükib muudetud failide nimed.

```bash
tofu fmt
git add .
git status --short
git commit -m "N10: masin tofu-<kasutaja> OpenTofuga"
git push
```

??? success "Oodatav tulemus"
    `git status --short` väljundis on teiste hulgas `vm.tf`, `.terraform.lock.hcl` ja kaks logifaili. Faile `terraform.tfvars`, `terraform.tfstate` ja `tfplan` ei ole.

## Osa 3 · Teine plaan ja muudatus

### 3.1 Plaan ilma muudatuseta

**Ennusta:** Sa ei muutnud faile. Mida näitab `tofu plan` nüüd?

```bash
tofu plan 2>&1 | tee logid/03-plan-uuesti.txt
```

**Küsimus:** mida näitas plaan ja millist Ansible'i väljundi rida see sulle meenutab? (README 3.1)

??? success "Oodatav tulemus"
    ```text
    proxmox_virtual_environment_vm.veeb: Refreshing state... [id=4100]

    No changes. Your infrastructure matches the configuration.
    ```
    Rida `Refreshing state` tähendab, et OpenTofu küsis Proxmoxilt masina tegeliku oleku. Kood, olekufail ja Proxmox on kooskõlas. Sama tähendab Ansible'is `changed=0`.

### 3.2 Mälu muutmine

**Ennusta:** Muudad failis `vm.tf` mälu 1024 MB asemel 2048 MB. Kas OpenTofu loob uue masina või muudab olemasolevat?

Muuda failis `vm.tf` rida `dedicated = 1024` reaks `dedicated = 2048` ja salvesta fail. Koosta plaan:

```bash
tofu plan -out=tfplan 2>&1 | tee logid/04-malu.txt
```

Loe plaan läbi. Seal peab olema ainult mälu muutus. Kui plaan tahab masinat kustutada, ära jätka. Kui plaan on õige, rakenda see:

```bash
tofu apply tfplan 2>&1 | tee -a logid/04-malu.txt
```

Proxmoxis on masina **Hardware** lehel **Memory** väärtus nüüd 2.00 GiB.

**Küsimus:** millise märgiga oli muudatus plaanis ja mida ütles kokkuvõtterida? (README 3.2)

??? success "Oodatav tulemus"
    ```text
      # proxmox_virtual_environment_vm.veeb will be updated in-place
      ~ resource "proxmox_virtual_environment_vm" "veeb" {
          ~ memory {
              ~ dedicated      = 1024 -> 2048
    ...
    Plan: 0 to add, 1 to change, 0 to destroy.
    ...
    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
    ```
    Märk `~` tähendab muutmist kohapeal. Masin jääb samaks, muutub ainult seade. Meie mallis ei saa mälu töötavas masinas muuta, seega taaskäivitab provider masina. Vaata seda Proxmoxis.

## Osa 4 · Ennustus 1: masin kustutatakse käsitsi

Loe README 0. osast oma esimene ennustus.

**Ennusta:** Kustutad masina Proxmoxi veebiliideses. Mida näitab OpenTofu järgmine plaan?

1. Vali Proxmoxis masin `tofu-<kasutaja>` ja vajuta **Stop**.
2. Kui masin on peatunud, vali **More → Remove**, kirjuta kasti masina VMID ja vajuta **Remove**.
3. Oota, kuni masin kaob vasakust menüüst. Siis koosta plaan:

```bash
tofu plan -out=tfplan 2>&1 | tee logid/05-kasitsi-kustutatud.txt
```

Loe plaan läbi. Kui plaan vastab sellele, mida kood kirjeldab, rakenda see:

```bash
tofu apply tfplan 2>&1 | tee -a logid/05-kasitsi-kustutatud.txt
```

Proxmoxis on masin `tofu-<kasutaja>` jälle olemas ja töötab.

**Küsimus:** mida näitas plaan ja kas sinu ennustus pidas paika? (README 4.1)

??? success "Oodatav tulemus"
    ```text
      # proxmox_virtual_environment_vm.veeb will be created
    ...
    Plan: 1 to add, 0 to change, 0 to destroy.
    ...
    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    ```
    Plaani alguses küsis OpenTofu Proxmoxilt masinat, mis olekufailis oli. Proxmox vastas, et sellist masinat ei ole, ja OpenTofu eemaldas selle olekust. Kood nõuab ühte masinat, seega näitas plaan uut masinat ja `apply` lõi selle. Uuel masinal on sama nimi ja VMID, aga võib olla teine IP-aadress. Samamoodi loob Docker Compose uuesti konteineri, mis kustutati käsitsi.

## Osa 5 · Ennustus 2: kirjeldus eemaldatakse failist

Loe README 0. osast oma teine ennustus.

OpenTofu loeb kaustast ainult `.tf` laiendiga faile. Kui nimetad faili `vm.tf` ümber, kaob masina kirjeldus koodist, aga fail jääb alles ja saad selle hiljem tagasi panna.

**Ennusta:** Masina kirjeldust koodis enam ei ole. Mida näitab plaan?

```bash
mv vm.tf vm.tf.off
tofu plan 2>&1 | tee logid/06-kirjeldus-eemaldatud.txt
```

Ära käivita `apply` käsku, sest see kustutaks masina. Pane kirjeldus tagasi ja koosta plaan uuesti:

```bash
mv vm.tf.off vm.tf
tofu plan 2>&1 | tee -a logid/06-kirjeldus-eemaldatud.txt
```

**Küsimus:** mida näitas esimene plaan ja kas sinu ennustus pidas paika? Mida teeks Ansible, kui kustutaksid playbook'ist nginx'i paigaldamise ülesande? (README 5.1)

??? success "Oodatav tulemus"
    ```text
      # proxmox_virtual_environment_vm.veeb will be destroyed
      # (because proxmox_virtual_environment_vm.veeb is not in configuration)
    ...
    Plan: 0 to add, 0 to change, 1 to destroy.
    ```
    Pärast `mv vm.tf.off vm.tf` näitab teine plaan `No changes.`

    Olekufailis on masin, mida kood enam ei kirjelda. OpenTofu peab seda masinat enda loodud masinaks ja kustutaks selle. Ansible ei salvesta, mida ta eelmisel korral tegi: kui ülesanne kaob playbook'ist, jääb nginx masinasse alles.

## Osa 6 · Olekufail ja destroy

### 6.1 Mida OpenTofu mäletab

Olekufailis on kirjas, millised masinad on OpenTofu hallata ja mis on nende andmed. Vaata selle sisu:

```bash
tofu state list 2>&1 | tee logid/07-state.txt
tofu state show proxmox_virtual_environment_vm.veeb | head -30
```

Käsk `tofu state list` näitab kõiki ressursse olekufailis ja `tofu state show` näitab ühe ressursi atribuute, mille OpenTofu viimati Proxmoxist luges.

??? success "Oodatav tulemus"
    `tofu state list` näitab ühte rida: `proxmox_virtual_environment_vm.veeb`.

### 6.2 Masina kustutamine

**Ennusta:** Proxmoxis on sinu pool'is üks masin ja klassis kümned masinad. Mida kustutab `tofu destroy`?

`tofu destroy` näitab, mida kustutatakse, ja küsib kinnitust. Seal peab olema ainult sinu masin (`1 to destroy`). Alles siis kirjuta `yes`:

```bash
tofu destroy 2>&1 | tee logid/08-destroy.txt
tofu state list 2>&1 | tee -a logid/08-destroy.txt
ls terraform.tfstate*
```

Proxmoxis ei ole enam masinat `tofu-<kasutaja>` ja pool `tofu-<kasutaja>` on tühi.

**Küsimus:** mida näitas `tofu state list` pärast `destroy` käsku ja miks on fail `terraform.tfstate` endiselt kaustas? (README 6.1)

??? success "Oodatav tulemus"
    ```text
    Plan: 0 to add, 0 to change, 1 to destroy.
    ...
    proxmox_virtual_environment_vm.veeb: Destroying... [id=4100]
    proxmox_virtual_environment_vm.veeb: Destruction complete after 6s

    Destroy complete! Resources: 1 destroyed.
    ```
    `tofu state list` ei trüki midagi. `destroy` kustutab ainult olekufailis olevad ressursid. Olekufail jääb alles, aga selles ei ole enam ühtegi ressurssi. Fail `terraform.tfstate.backup` on eelmise oleku koopia.

Kood on alles ja käsk `tofu apply` loob sama masina uuesti.

## Töö esitamine

README-s on vastused kõigile küsimustele (igas vastuses üks rida logist ja üks lause selgitust), kood on vormindatud ja kõik kaheksa logifaili on GitHubis:

```text
logid/
├── 01-plan.txt
├── 02-apply.txt
├── 03-plan-uuesti.txt
├── 04-malu.txt
├── 05-kasitsi-kustutatud.txt
├── 06-kirjeldus-eemaldatud.txt
├── 07-state.txt
└── 08-destroy.txt
```

Vorminda kood ja vaata enne commit'i, mis faile lisad. Seal ei tohi olla `terraform.tfvars`, `terraform.tfstate*`, `tfplan` ega `.terraform/`:

```bash
tofu fmt
git add .
git status --short
git commit -m "N10: plaanid, käsitsi kustutamine, destroy ja vastused"
git push
```

Tulemuse näed Classroom 50-s.

??? warning "Kui `terraform.tfvars` jõudis Giti"
    Eemalda fail Gitist (`git rm --cached terraform.tfvars`, commit ja push). Kustuta Proxmoxis token ja loo uus, sest vana on GitHubi ajaloos alles.

## Lisaülesanded

??? example "A · Olekufail kaob (keskmine)"
    Tee see siis, kui masin on olemas: enne sammu 6.2 või pärast uut `tofu apply` käsku.

    ```bash
    cp terraform.tfstate /tmp/olek-varu.tfstate
    rm terraform.tfstate terraform.tfstate.backup
    tofu plan
    ```

    Mida tahab OpenTofu teha? Mis juhtuks `apply` käsuga, kui masin VMID-ga `vm_id` on Proxmoxis juba olemas? Pane olek tagasi (`cp /tmp/olek-varu.tfstate terraform.tfstate`) ja kontrolli, et `tofu plan` näitab `No changes.` Kirjuta README-sse Lisa A alla kaks lauset.

??? example "B · Olemasolev masin olekusse (raskem)"
    OpenTofu saab hakata haldama masinat, mille keegi lõi käsitsi. Masin peab Proxmoxis olemas olema, nii et pärast `destroy` loo see uuesti (`tofu apply`). Käivita lisaülesande A kaks esimest käsku ja kontrolli, et varukoopia `/tmp/olek-varu.tfstate` on olemas. Siis loe [import plokki](https://opentofu.org/docs/language/import/) ja lisa faili `vm.tf`:

    ```hcl
    import {
      to = proxmox_virtual_environment_vm.veeb
      id = "SR630V3-2/4100"
    }
    ```

    Asenda `SR630V3-2` oma muutuja `node_name` väärtusega ja `4100` oma VMID-ga. Mida näitab `tofu plan`? Miks võib plaanis olla lisaks impordile ka muudatusi? Eemalda pärast `apply` käsku plokk `import` failist ja kirjuta README-sse Lisa B alla kaks lauset.
