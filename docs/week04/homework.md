---
tags:
  - Ansible
  - Konfiguratsioonihaldus
  - Kodutöö
---

# Kodutöö: dev ja prod keskkonnad

Praktikumis kehtisid muutujad kõigile hostidele ühtemoodi (`group_vars/all/`). Töökohas on dev ja prod erinevad: dev-serveril on debug-info nähtav, prod-serveril mitte. Selles kodutöös tekitad selle erinevuse ainult muutujatega, `nginx.yml`-i muutmata. Kodutöö on boonus.

Kasutad kahte ülejäänud sõlme: `proxmox2` on dev ja `proxmox3` on prod.

## Osa 1 · Grupid inventory's

Lisa inventory'sse grupid `dev` ja `prod` ning tee need grupi `web` alamgruppideks:

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

`[web:children]` teeb grupid `dev` ja `prod` grupi `web` alamgruppideks. Playbooki rida `hosts: web` hõlmab nüüd kõiki kolme sõlme ja playbooki muuta pole vaja.

??? warning "Kui tuleb `no hosts matched`"
    Kontrolli, et `[web:children]` all on grupinimed (`dev`), mitte hostinimed (`proxmox2`).

## Osa 2 · Vaikeväärtused kõigile

Lisa `group_vars/all/main.yml`-i väärtused, mis kehtivad, kui grupp neid üle ei kirjuta:

```yaml
keskkond_nimi: LABOR
naita_debug: false
```

## Osa 3 · Grupi muutujad

Loo kummalegi grupile oma fail. `group_vars/dev.yml`:

```yaml
keskkond_nimi: ARENDUS
naita_debug: true
```

`group_vars/prod.yml`:

```yaml
keskkond_nimi: PRODUKTSIOON
naita_debug: false
```

Muutujate nimedes kasuta ainult ladina tähti, numbreid ja alakriipsu `_`. Täpitähti Ansible muutuja nimes ei luba.

## Osa 4 · Mall

Lisa `templates/index.html.j2`-sse keskkonna nimi ja debug-rida, mis on lehel ainult siis, kui `naita_debug` on tõene:

```html
<p>Keskkond: {{ keskkond_nimi }}</p>
{% if naita_debug %}
<p>Debug: {{ inventory_hostname }}, {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}</p>
{% endif %}
```

## Osa 5 · Käivitamine ja tõendid

Käivita playbook ja salvesta mõlema sõlme leht:

```bash
ansible-playbook -i inventory.ini nginx.yml --vault-password-file .vault_pass
ssh proxmox2 "curl -s localhost" > logid/dev.html
ssh proxmox3 "curl -s localhost" > logid/prod.html
```

??? success "Oodatav tulemus"
    `dev.html` näitab keskkonda ARENDUS ja debug-rida, `prod.html` näitab PRODUKTSIOON ilma debug-reata ja `proxmox1` näitab LABOR.

??? question "Kontrolli ennast"
    1. `proxmox2` kuulub nii gruppi `all` (LABOR) kui ka `dev` (ARENDUS). Miks kehtib ARENDUS? Mis juhtuks, kui lisaksid faili `host_vars/proxmox2.yml` kolmanda väärtusega?
    2. Kolm serverit, üks playbook ja üks mall. Kus peaks keskkonnast sõltuv info Ansible'i projektis olema ja kus mitte?

Lõpuks käivita playbook uuesti midagi muutmata ja uuenda praktikumi tõendid (`logid/play_recap.txt`, `leht.html`, `pais.txt`). Tulemus peab olema `changed=0` kõigil kolmel sõlmel ja `bash kontroll.sh` peab näitama kõiki 7 testi läbituna.

??? note "Kontrollnimekiri"
    - [ ] `[web:children]` sisaldab gruppe `dev` ja `prod`
    - [ ] `group_vars/dev.yml` ja `group_vars/prod.yml` erinevad
    - [ ] `logid/dev.html` näitab ARENDUS ja debug-rida, `logid/prod.html` näitab PRODUKTSIOON ilma debug-reata
    - [ ] `nginx.yml` jäi muutmata
    - [ ] `bash kontroll.sh` näitab kõiki teste läbituna

## Töö esitamine

Töö on harus `n04-vault`: tee commit ja saada see GitHubi. Kui praktikumi pull request on veel avatud, uueneb see ise; kui see on juba liidetud, ava samast harust uus pull request ja liida see harusse `main`.

```bash
git add -A && git commit -m "Kodutöö: dev ja prod keskkonnad" && git push
```

Faili `.vault_pass` repositooriumi ei panda. Tulemuse näed Classroom 50-s.
