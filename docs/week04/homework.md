---
tags:
  - Ansible
  - Konfiguratsioonihaldus
  - Kodutöö
---

# Kodutöö: dev ja prod keskkonnad

**Eeldused:** N4 praktikum tehtud: `bash kontroll.sh` testid 1–6 ✅.

---

## Ülesanne

Praegu kehtivad muutujad kõigile hostidele ühtemoodi (`group_vars/all/`). Päris elus on dev ja prod erinevad, dev-serveril on debug-info nähtav, prod-serveril mitte. Tekita see erinevus **ainult muutujatega**, `nginx.yml`-i puutumata.

Kasutad oma kahte ülejäänud sõlme: **`proxmox2` = dev**, **`proxmox3` = prod**.

---

**Samm 1, inventory: grupid grupi sees**

```ini
[web]
proxmox1

[dev]
proxmox2

[prod]
proxmox3

[web:children]
dev
prod
```

`[web:children]` teeb `dev` ja `prod` grupi `web` alamgruppideks (vanem-laps, N3 loeng). Playbooki `hosts: web` jõuab nüüd kõigi kolmeni, playbooki ei muuda.

**Samm 2, vaikeväärtused kõigile**

Lisa `group_vars/all/main.yml`-i:

```yaml
keskkond_nimi: LABOR
naita_debug: false
```

**Samm 3, grupi-spetsiifilised muutujad**

`group_vars/dev.yml`:

```yaml
keskkond_nimi: ARENDUS
naita_debug: true
```

`group_vars/prod.yml`:

```yaml
keskkond_nimi: PRODUKTSIOON
naita_debug: false
```

!!! tip
    Muutujate nimedes ainult ladina tähed, numbrid ja `_`: **mitte** `ä`, `õ`, `ü`. Ansible ei pruugi neid muutujanimena aktsepteerida.

**Samm 4, mall**

Lisa `templates/index.html.j2`-sse:

```html
<p>Keskkond: {{ keskkond_nimi }}</p>
{% if naita_debug %}
<p>Debug: {{ inventory_hostname }}, {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}</p>
{% endif %}
```

**Samm 5, käivita ja salvesta tõendid**

```bash
ansible-playbook -i inventory.ini nginx.yml --vault-password-file .vault_pass
ssh proxmox2 "curl -s localhost" > logid/dev.html
ssh proxmox3 "curl -s localhost" > logid/prod.html
```

`dev.html` näitab ARENDUS + debug-rida, `prod.html` PRODUKTSIOON ilma debug'ita, `proxmox1` LABOR.

??? question "Mõtle"
    `proxmox2` kuulub nii gruppi `all` (LABOR) kui `dev` (ARENDUS). Miks võitis ARENDUS? Mis juhtuks, kui lisaksid `host_vars/proxmox2.yml` kolmanda väärtusega?

??? question "Mõtle"
    Kolm serverit, üks playbook, üks mall. Kus peaks keskkonnaspetsiifiline info hea Ansible projekti struktuuris elama, ja kus mitte?

!!! tip
    `no hosts matched`, kontrolli, et `[web:children]` all on grupinimed (`dev`), mitte hostinimed (`proxmox2`).

---

## Esitamine

1. Käivita uuesti midagi muutmata ja uuenda praktikumi tõendid (`logid/play_recap.txt`, `leht.html`, `pais.txt`): `changed=0` kõigil kolmel sõlmel.
2. `bash kontroll.sh`, kõik 7 ✅
3. Commit samasse haru `n04-vault`, push. PR uueneb ise.

---

## Enesekontroll

- [ ] `[web:children]` sisaldab `dev` ja `prod`
- [ ] `group_vars/dev.yml` ja `group_vars/prod.yml` erinevad
- [ ] `logid/dev.html` → ARENDUS + debug, `logid/prod.html` → PRODUKTSIOON, debug'ita
- [ ] `nginx.yml` jäi muutmata
- [ ] `bash kontroll.sh` kõik ✅
