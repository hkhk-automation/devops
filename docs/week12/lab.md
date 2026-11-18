---
tags:
  - OpenTofu
  - Ansible
  - Praktikum
---

# Praktikum: OpenTofu ja Ansible koos

Täna loob OpenTofu õpetaja Proxmoxi klastris kaks masinat, kirjutab nende IP-aadressid Ansible'i inventory faili ja N11 nginx'i roll paigaldab mõlemasse lehe. Lõpuks lisad kolmanda masina nii, et muutub ainult üks rida muutujate failis.

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

??? abstract "Õpiväljundid"
    Praktikumi lõpuks oskad:

    1. kirjeldada OpenTofuga mitu masinat ühe ressursiplokiga (`for_each`);
    2. panna cloud-init'iga uude masinasse oma SSH-võtme;
    3. lasta OpenToful kirjutada Ansible'i inventory masinate IP-aadressidest;
    4. seadistada Ansible'i rolliga kõik OpenTofu loodud masinad;
    5. lisada masina ja selgitada plaani ning Ansible'i väljundi põhjal, mis muutus.

Iga ülesande kood on kokkuvolditud plokis. Loe enne selgitus, siis ava plokk, lisa kood faili ja käivita. Rida **Ennusta** tähendab, et enne käsku mõtled läbi, mis juhtub. Vastus on kokkuvolditud plokis.

## Osa 1 · Ettevalmistus

Töötad nagu N10-s masinas `proxmox1` VS Code'i kaudu. Seal käivitad nii OpenTofu kui ka Ansible'i, nii et OpenTofu kirjutatud inventory on Ansible'i jaoks samas kaustas olemas.

### 1.1 Repositoorium

Võta vastu ülesanne **Lab 12 - OpenTofu ja Ansible** ([Classroom 50](https://classroom50.org/hkhk-automation/it24-automatiseerimine/assignments)) ja klooni see masinasse `proxmox1`:

```bash
cd ~
git clone <sinu-repo-url> lab12 && cd lab12
ls
```

??? success "Oodatav tulemus"
    Kaustas on OpenTofu failid `versions.tf`, `variables.tf` ja `terraform.tfvars.example`, Ansible'i failid `ansible.cfg` ja `site.yml`, kaust `roles/nginx` ning `README.md`. Roll on sama, mille tegid N11-s: see paigaldab nginx'i, kirjutab avalehe ja lisab serveri, mis kuulab porti `nginx_port` (vaikimisi 8080).

Kõik järgmised käsud käivitad kaustas `~/lab12`. Ava fail `README.md` ja kirjuta rea `**Sinu nimi:**` järele oma nimi.

### 1.2 OpenTofu ja Ansible

Kontrolli, et mõlemad tööriistad on masinas olemas:

```bash
tofu version
ansible --version
```

??? success "Oodatav tulemus"
    Esimene käsk näitab `OpenTofu v1.13...`, teine `ansible [core 2.14...]` või uuemat.

??? warning "Kui `tofu: command not found`"
    OpenTofu paigaldus on kirjas [N10 praktikumi sammus 1.3](../week10/lab.md#13-opentofu-paigaldamine).

??? warning "Kui `ansible: command not found`"
    Paigalda Ansible: `sudo dnf install -y ansible-core`.

### 1.3 Token ja muutujad

OpenTofu vajab sama API-tokenit nagu N10-s. Tee näidisfailist oma muutujate fail:

```bash
cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars
```

Kui tegid N10 praktikumi, ava VS Code'is ka fail `~/lab10/terraform.tfvars` ja kopeeri sealt read `proxmox_api_token` ja `kasutaja`. Kui tokenit veel ei ole, loo see [N10 praktikumi sammu 1.4](../week10/lab.md#14-api-token) järgi.

Muutuja `masinad` ütleb, milliseid masinaid on vaja. Võti on masina nimi ja väärtus on masina number Proxmoxis (VMID). Igal masinal peab olema oma number. Võta oma N10 number ja lisa selle lõppu 1, 2 või 3: kui sinu number on 4105, kirjuta `veeb1 = 41051` ja `veeb2 = 41052`. Salvesta fail.

```bash
git status --short
```

??? success "Oodatav tulemus"
    Väljundis ei ole faili `terraform.tfvars`, sest `.gitignore` jätab selle välja.

### 1.4 SSH-võti

Uude masinasse paneb cloud-init sinu avaliku SSH-võtme. Kontrolli, kas võti on olemas, ja kui ei ole, loo see:

```bash
ls ~/.ssh/id_ed25519.pub || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```

??? success "Oodatav tulemus"
    Käsk näitab faili nime `/home/<kasutaja>/.ssh/id_ed25519.pub` või loob uue võtmepaari.

## Osa 2 · Kaks masinat ühe plokiga

### 2.1 Muutuja

Muutuja `masinad` väärtus on juba failis `terraform.tfvars`, aga OpenTofu kasutab ainult muutujaid, mis on deklareeritud. Tüüp `map(number)` tähendab kaarti, kus iga võtme väärtus on number.

??? example "Ülesanne: lisa faili `variables.tf` lõppu"
    ```hcl
    variable "masinad" {
      type        = map(number)
      description = "Masina nimi ja VMID"
    }
    ```

### 2.2 Masinate kirjeldus

Masina kirjeldus on sama mis N10-s, erinevusi on kolm. Rida `for_each = var.masinad` loob ressursist ühe masina iga kaardi kirje kohta. Nimes on `each.key` (näiteks `veeb1`) ja VMID on `each.value`. Plokk `initialization` annab cloud-init'ile kasutaja `kasutaja`, sinu SSH-võtme ja DHCP seadistuse. Cloud-init'i ketas luuakse hoidlasse `local-zfs`, sest sinna on sul kirjutamisõigus. Rida `upgrade = false` jätab ära kõigi pakettide uuendamise esimesel käivitusel, muidu ootaks Ansible mitu minutit, kuni uuendus lõpeb.

??? example "Ülesanne: loo fail `vm.tf`"
    ```hcl
    resource "proxmox_virtual_environment_vm" "veeb" {
      for_each = var.masinad

      name            = "${var.kasutaja}-${each.key}"
      node_name       = var.node_name
      vm_id           = each.value
      pool_id         = "tofu-${var.kasutaja}"
      tags            = ["it24", "n12"]
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

      initialization {
        datastore_id = "local-zfs"
        upgrade      = false

        ip_config {
          ipv4 {
            address = "dhcp"
          }
        }

        user_account {
          username = "kasutaja"
          keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
        }
      }
    }
    ```

### 2.3 Väljund

Väljund `ip` on nüüd kaart: iga masina nime juures on selle IP-aadress. Avaldis `for` käib läbi kõik masinad.

??? example "Ülesanne: loo fail `outputs.tf`"
    ```hcl
    output "ip" {
      value = { for nimi, vm in proxmox_virtual_environment_vm.veeb : nimi => vm.ipv4_addresses[1][0] }
    }
    ```

### 2.4 Plaan

`tofu init` laeb alla kaks providerit: `bpg/proxmox` Proxmoxi jaoks ja `hashicorp/local`, mida vajad osas 3 inventory kirjutamiseks. `tofu fmt` korrastab taanded ja `tofu validate` kontrollib süntaksit enne, kui Proxmoxi poole pöördutakse.

```bash
tofu init
tofu fmt
tofu validate
```

??? success "Oodatav tulemus"
    `init` lõpetab reaga `OpenTofu has been successfully initialized!` ja `validate` näitab `Success! The configuration is valid.`

**Ennusta:** mitu ressurssi plaan loob ja mis on nende aadressid?

```bash
tofu plan -out=tfplan 2>&1 | tee logid/01-plan.txt
```

??? success "Oodatav tulemus"
    ```text
      # proxmox_virtual_environment_vm.veeb["veeb1"] will be created
    ...
      # proxmox_virtual_environment_vm.veeb["veeb2"] will be created
    ...
    Plan: 2 to add, 0 to change, 0 to destroy.

    Changes to Outputs:
      + ip = {
          + veeb1 = (known after apply)
          + veeb2 = (known after apply)
        }
    ```
    Ressursse on üks, masinaid kaks. OpenTofu tunneb iga masinat kaardi võtme järgi: `veeb["veeb1"]`.

??? warning "Kui plaan annab vea"
    - `No value for required variable "masinad"`: failis `terraform.tfvars` puudub `masinad` või on nimes kirjaviga.
    - `Reference to undeclared input variable "masinad"`: muutuja deklaratsioon (samm 2.1) puudub failist `variables.tf`.
    - `Invalid value for "path" parameter: no file exists`: SSH-võtit ei ole, tee samm 1.4.

### 2.5 Masinate loomine

Rakenda salvestatud plaan. OpenTofu loob mõlemad masinad korraga ja ootab, kuni guest agent teatab IP-aadressi:

```bash
tofu apply tfplan 2>&1 | tee logid/02-apply.txt
tofu output ip
```

??? success "Oodatav tulemus"
    ```text
    Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

    Outputs:

    ip = {
      "veeb1" = "192.168.100.58"
      "veeb2" = "192.168.100.55"
    }
    ```
    Proxmoxi veebiliideses on pool'is `tofu-<kasutaja>` kaks töötavat masinat: `<kasutaja>-veeb1` ja `<kasutaja>-veeb2`. Masina vahekaardil **Cloud-Init** on kasutaja `kasutaja`, sinu võti ja `ip=dhcp`.

??? warning "Kui apply annab vea"
    - `403 Forbidden` või `Permission check failed`: token on vale või tokenil on **Privilege Separation** sees. Loo token uuesti nagu N10 sammus 1.4.
    - `VM ... already exists`: VMID on kellegi teise number. Kontrolli, et numbri alguses on sinu N10 number.
    - `Still creating...` kestab üle 5 minuti: ava Proxmoxis masina **Console** ja vaata, kas masin käivitus.

Kontrolli, et cloud-init pani võtme masinasse. Asenda `<veeb1 IP>` väljundist `tofu output ip` saadud aadressiga:

```bash
ssh -o StrictHostKeyChecking=accept-new kasutaja@<veeb1 IP> hostname
```

??? success "Oodatav tulemus"
    Vastus on masina nimi, näiteks `mtamm-veeb1`, ja parooli ei küsita. Cloud-init pani hostinimeks Proxmoxi masina nime.

## Osa 3 · Inventory OpenTofu väljundist

### 3.1 Mall

Inventory mall kasutab OpenTofu malli süntaksit: tsükkel on `%{ for … }` ja väärtus `${ … }`. Märk `~` tsükli lõpus eemaldab tühja rea, mis muidu tekiks iga masina järel. Mall saab muutuja `masinad`, milles on kõik loodud masinad koos nende andmetega.

??? example "Ülesanne: loo fail `inventory.tftpl`"
    ```text
    # OpenTofu kirjutas selle faili, ära muuda käsitsi
    [web]
    %{ for nimi, vm in masinad ~}
    ${nimi} ansible_host=${vm.ipv4_addresses[1][0]}
    %{ endfor ~}

    [web:vars]
    ansible_user=kasutaja
    ```

### 3.2 Faili ressurss

Ressurss `local_file` kirjutab faili kohalikule kettale ja funktsioon `templatefile` täidab malli. Kuna mallile antakse masinate ressurss, kirjutab OpenTofu faili alles pärast masinaid.

??? example "Ülesanne: loo fail `inventory.tf`"
    ```hcl
    resource "local_file" "inventory" {
      filename = "${path.module}/inventory.ini"
      content = templatefile("${path.module}/inventory.tftpl", {
        masinad = proxmox_virtual_environment_vm.veeb
      })
    }
    ```

**Ennusta:** masinad on olemas. Mida plaan nüüd loob?

```bash
tofu fmt
tofu plan -out=tfplan
tofu apply tfplan
cat inventory.ini | tee logid/03-inventory.txt
```

??? success "Oodatav tulemus"
    Plaan ütleb `Plan: 1 to add, 0 to change, 0 to destroy.`: masinad jäävad samaks ja lisandub ainult fail. Failis on mõlemad masinad:
    ```ini
    # OpenTofu kirjutas selle faili, ära muuda käsitsi
    [web]
    veeb1 ansible_host=192.168.100.58
    veeb2 ansible_host=192.168.100.55

    [web:vars]
    ansible_user=kasutaja
    ```
    `inventory.ini` on `.gitignore`-is nagu olekufail, sest iga `apply` kirjutab selle uuesti.

## Osa 4 · Roll seadistab mõlemad masinad

### 4.1 Ühendus

Starteri failis `ansible.cfg` on kaks seadet. `inventory = inventory.ini` tähendab, et võtit `-i` ei pea käsus kirjutama. `host_key_checking = False` lubab esimese ühenduse uue masinaga ilma hostivõtme küsimiseta, sest iga uus masin on uue võtmega.

```bash
ansible web -m ping 2>&1 | tee logid/04-ping.txt
```

??? success "Oodatav tulemus"
    Kaks rida `SUCCESS` ja `"ping": "pong"`: `veeb1` ja `veeb2`.

??? warning "Kui tuleb `UNREACHABLE` ja `Permission denied (publickey)`"
    Masinas ei ole sinu võtit. Kontrolli, et masinal on Proxmoxis vahekaardil **Cloud-Init** sinu võti. Kui lõid võtme pärast masinaid, loo masinad uuesti: `tofu apply -replace='proxmox_virtual_environment_vm.veeb["veeb1"]'`.

### 4.2 Playbook

`site.yml` käivitab rolli `nginx` kõigis grupi `web` masinates. Sama playbook seadistas N11-s ühe masina, nüüd seadistab see kaks.

**Ennusta:** mitu rida on väljundi lõpus kokkuvõttes `PLAY RECAP`?

```bash
ansible-playbook site.yml 2>&1 | tee logid/05-site.txt
```

??? success "Oodatav tulemus"
    Kokkuvõttes on kaks rida, iga masina kohta üks, ja mõlemas `changed=5 unreachable=0 failed=0`. Nginx'i paigaldamine värskesse masinasse võtab umbes pool minutit, sest `dnf` laeb kõigepealt pakettide nimekirja. Väljundis on ka `RUNNING HANDLER [nginx : laadi nginx uuesti]`.

Ava leht mõlemast masinast. Asenda IP-d väljundist `tofu output ip` saadud aadressidega:

```bash
curl -s http://<veeb1 IP>:8080
curl -s http://<veeb2 IP>:8080
```

??? success "Oodatav tulemus"
    Esimene leht ütleb `Tere, veeb1!` ja teine `Tere, veeb2!`. Mall on sama, aga muutuja `inventory_hostname` on igas masinas inventory nimi.

**Ennusta:** mida näitab teine käivitus?

```bash
ansible-playbook site.yml 2>&1 | tee logid/06-uuesti.txt
```

??? success "Oodatav tulemus"
    Mõlemas reas on `changed=0`. Masinad on juba soovitud olekus.

## Osa 5 · Kolmas masin

Serveripargi kasvades ei muutu kood. Ava `terraform.tfvars` ja lisa kaardile `masinad` kolmas rida, näiteks `veeb3 = 41053` (sinu number ja lõppu 3). Salvesta fail.

**Ennusta:** mitu ressurssi plaan lisab ja kustutab? Kas see kustutab mõne masina?

```bash
tofu plan -out=tfplan 2>&1 | tee logid/07-veeb3-plan.txt
```

??? success "Oodatav tulemus"
    ```text
      # local_file.inventory must be replaced
    ...
      # proxmox_virtual_environment_vm.veeb["veeb3"] will be created
    ...
    Plan: 2 to add, 0 to change, 1 to destroy.
    ```
    Plaan lisab ühe masina. `1 to destroy` ei ole masin, vaid fail `inventory.ini`: faili sisu muutub, ja `local_file` kirjutatakse muutmise asemel uuesti. Masinad `veeb1` ja `veeb2` plaanis ei ole. Loe alati, mida plaan kustutab, enne kui `apply` käivitad.

```bash
tofu apply tfplan 2>&1 | tee logid/08-veeb3-apply.txt
cat inventory.ini
```

**Ennusta:** milline masin on järgmises käivituses `changed`?

```bash
ansible-playbook site.yml 2>&1 | tee logid/09-veeb3-site.txt
```

??? success "Oodatav tulemus"
    Kokkuvõttes on kolm rida. `veeb1` ja `veeb2` on `changed=0`, `veeb3` on `changed=5`. Sama playbook sobis nii uuele kui ka vanadele masinatele ja muutis ainult seda, mis erines.

## Osa 6 · Koristamine

Klastri mälu jagavad kõik õppijad, seepärast kustuta masinad pärast tööd. Kood jääb alles ja `tofu apply` loob need hiljem uuesti. `tofu destroy` näitab enne kustutamist plaani ja küsib kinnitust. Kontrolli, et plaanis on ainult sinu kolm masinat ja fail, ning kirjuta `yes`:

```bash
tofu destroy 2>&1 | tee logid/10-destroy.txt
```

??? success "Oodatav tulemus"
    ```text
    Destroy complete! Resources: 4 destroyed.
    ```
    Pool `tofu-<kasutaja>` on Proxmoxis tühi ja faili `inventory.ini` ei ole enam kaustas.

## Töö esitamine

Repositooriumis on OpenTofu failid, inventory mall ja logid. Vaata enne commit'i, et nimekirjas ei ole faile `terraform.tfvars`, `terraform.tfstate` ega `tfplan`:

```bash
tofu fmt
git add .
git status --short
git commit -m "Kolm masinat OpenTofuga, inventory OpenTofu väljundist ja nginx'i roll kõigis masinates"
git push
```

Tulemuse näed Classroom 50-s.

??? warning "Kui `terraform.tfvars` jõudis Giti"
    Eemalda fail Gitist (`git rm --cached terraform.tfvars`, commit ja push). Kustuta Proxmoxis token ja loo uus, sest vana on GitHubi ajaloos alles.

## Lisaülesanded

??? example "1 · Oma leht"
    Kopeeri N11-s kujundatud mall `~/lab11/roles/nginx/templates/index.html.j2` selle repositooriumi samasse kohta. Loo masinad uuesti (`tofu apply`) ja käivita `ansible-playbook site.yml`. Kontrolli, et kõigis masinates on sinu leht ja igas oma masina nimi.

??? example "2 · Masin kustutatakse käsitsi"
    Kustuta Proxmoxis masin `<kasutaja>-veeb2` (**Stop**, siis **More → Remove**). Käivita `tofu plan`. Mida plaan loob ja miks muutub ka `inventory.ini`? Rakenda plaan ja käivita playbook. Mitu masinat on `changed`?

    ??? success "Vastus"
        Plaan loob masina `veeb2` uuesti ja kirjutab inventory uuesti, sest uus masin saab DHCP-st tõenäoliselt uue IP-aadressi. Playbook muudab ainult uut `veeb2`, teised on `changed=0`.

??? example "3 · Igale masinale oma mälu"
    Muuda muutuja `masinad` tüüp kujule `map(object({ vm_id = number, malu = number }))` ja failis `terraform.tfvars` iga kirje kujule `veeb1 = { vm_id = 41051, malu = 1024 }`. Muuda failis `vm.tf` read `vm_id = each.value.vm_id` ja `dedicated = each.value.malu`. Anna ühele masinale 2048 MB. Mida näitab plaan: kas masin luuakse uuesti või muudetakse kohapeal?
