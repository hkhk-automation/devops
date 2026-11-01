---
tags:
  - OpenTofu
  - Ansible
  - Kodutöö
---

# Kodutöö: Ansible'i inventory OpenTofu väljundist

Praktikumis lõi OpenTofu masina ja trükkis selle IP-aadressi. Osas 4 nägid, et uuesti loodud masinal võib olla teine IP. Kui inventory on käsitsi kirjutatud, peab keegi selle iga kord parandama. Kodutöös kirjutab OpenTofu Ansible'i inventory ise ja Ansible ühendub masinaga, mille OpenTofu lõi. Nii töötavad kaks tööriista koos: OpenTofu loob masina, Ansible seadistab selle.

Kodutöö on boonus (BOONUS-kontroll Classroom 50-s, 0 punkti). Tee see samas repositooriumis `~/lab10` masinas `proxmox1`. Vaja on VPN-i.

---

## 1. Teine provider

Inventory fail luuakse provideriga [`hashicorp/local`](https://search.opentofu.org/provider/hashicorp/local/latest), mis kirjutab faile kohalikule kettale. Lisa see faili `versions.tf` plokki `required_providers`, `proxmox` ploki järele:

```hcl
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
```

Laadi uus provider alla:

```bash
tofu init
```

**Kontrolli:** `.terraform.lock.hcl` failis on nüüd kaks plokki `provider`.

## 2. Mall ja inventory ressurss

Loo fail `inventory.tftpl`. See on mall, kuhu OpenTofu paneb muutuja `ip` väärtuse:

```text
[tofu]
${ip} ansible_user=kasutaja
```

Loo fail `inventory.tf`:

```hcl
resource "local_file" "inventory" {
  filename = "${path.module}/inventory.ini"
  content = templatefile("${path.module}/inventory.tftpl", {
    ip = proxmox_virtual_environment_vm.veeb.ipv4_addresses[1][0]
  })
}
```

Funktsioon [`templatefile`](https://opentofu.org/docs/language/functions/templatefile/) loeb malli ja asendab `${ip}` masina IP-ga. Viide masina atribuudile ütleb OpenTofule ka järjekorra: fail luuakse alles siis, kui masin on olemas ja IP teada.

## 3. Masin ja inventory

**Ennusta.** Praktikumi lõpus kustutasid masina. Mitu ressurssi plaan nüüd loob?

```bash
tofu fmt
tofu plan -out=tfplan
tofu apply tfplan
cat inventory.ini
```

**Kontrolli:** failis `inventory.ini` on uue masina IP-aadress.

## 4. Ansible ühendub

Uues masinas ei ole sinu SSH-võtit. Kopeeri see sinna. Parool on sama, mis oli sinu teistel masinatel N1-s:

```bash
ssh-copy-id kasutaja@$(tofu output -raw ip)
```

Kui masinas `proxmox1` ei ole Ansible'it, paigalda see (`sudo dnf install -y ansible-core`). Siis:

```bash
ansible -i inventory.ini tofu -m ping 2>&1 | tee logid/k1-ping.txt
```

**Kontrolli:** väljundis on `"ping": "pong"`.

## 5. Koristamine ja esitamine

`tofu destroy` kustutab masina ja ka faili `inventory.ini`, sest see on samuti OpenTofu ressurss. Kopeeri inventory enne kustutamist logide kausta, siis kustuta:

```bash
cp inventory.ini logid/k1-inventory.ini
tofu destroy
```

Vasta README-s küsimusele K.1. Kontrolli vormingut ja saada kõik GitHubi:

```bash
tofu fmt -check
git add .
git commit -m "N10 kodutöö: inventory OpenTofu väljundist"
git push
```

Praktikumi logifaile ära muuda: põhikontrollid loevad neid.

??? note "Automaatkontroll (BOONUS)"
    Kontroll otsib faile `inventory.tf` (ressurss `local_file`), `inventory.tftpl`, `logid/k1-inventory.ini` (IP-aadressiga) ja `logid/k1-ping.txt` (vastusega `pong`) ning README vastust K.1.

??? warning "Kui midagi ei tööta"
    - `Inconsistent dependency lock file`: käivita `tofu init` pärast `versions.tf` muutmist.
    - `ssh-copy-id` küsib parooli ja see ei sobi: küsi õpetajalt masina algset parooli.
    - Ansible annab `UNREACHABLE`: proovi `ssh kasutaja@<ip>` käsitsi. Kui SSH ei tööta, ei tööta ka Ansible.
