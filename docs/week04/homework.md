---
tags:
  - Ansible
  - Konfiguratsioonihaldus
  - Kodutöö
---

# Kodutöö: arendus- ja tootmiskeskkond

Praktikumis kehtisid muutujad kõigile hostidele ühtemoodi (`group_vars/all/`). Arendus- ja tootmiskeskkonna seadistused on sageli erinevad: arenduskeskkonnas (dev) kuvatakse silumisinfot, tootmiskeskkonnas (prod) mitte. Selles kodutöös tekitad selle erinevuse muutujate ja malliga, playbook'i `nginx.yml` muutmata. Kodutöö on boonusülesanne.

Lisad kaks ülejäänud sõlme: `proxmox2` on arenduskeskkond ja `proxmox3` tootmiskeskkond.

## Osa 1 · Rühmad inventory's

Täienda olemasolevat faili `inventory.ini` järgmise näite järgi. Hostide ühenduse seaded jäävad alles. Lisa rühmad `dev` ja `prod` ning tee need rühma `web` alamrühmadeks:

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

`[web:children]` teeb rühmad `dev` ja `prod` rühma `web` alamrühmadeks. Playbook'i rida `hosts: web` hõlmab nüüd kõiki kolme sõlme ja playbook'i muuta pole vaja.

??? warning "Kui tuleb `no hosts matched`"
    Kontrolli, et `[web:children]` all on rühmade nimed (`dev`), mitte hostinimed (`proxmox2`).

## Osa 2 · Vaikeväärtused kõigile

Lisa `group_vars/all/main.yml`-i väärtused, mis kehtivad, kui rühma muutujad neid ei asenda:

```yaml
keskkond_nimi: LABOR
naita_debug: false
```

## Osa 3 · Rühma muutujad

Loo kummalegi rühmale oma fail. `group_vars/dev.yml`:

```yaml
keskkond_nimi: ARENDUS
naita_debug: true
```

`group_vars/prod.yml`:

```yaml
keskkond_nimi: PRODUKTSIOON
naita_debug: false
```

Muutujate nimedes kasuta ainult ladina tähti, numbreid ja alakriipsu `_`. Ansible ei luba muutuja nimes täpitähti.

## Osa 4 · Mall

Lisa `templates/index.html.j2`-sse keskkonna nimi ja silumisinfo rida, mida kuvatakse ainult siis, kui `naita_debug` on tõene:

```html
<p>Keskkond: {{ keskkond_nimi }}</p>
{% if naita_debug %}
<p>Debug: {{ inventory_hostname }}, {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}</p>
{% endif %}
```

## Osa 5 · Käivitamine ja tõendid

Käivita playbook ning salvesta arendus- ja tootmiskeskkonna leht:

```bash
ansible-playbook -i inventory.ini nginx.yml --vault-password-file .vault_pass
ssh proxmox2 "curl -s localhost" > logid/dev.html
ssh proxmox3 "curl -s localhost" > logid/prod.html
```

??? success "Oodatav tulemus"
    Failis `dev.html` on keskkond ARENDUS ja silumisinfo rida, `prod.html` näitab PRODUKTSIOON ilma debug-reata ja `proxmox1` näitab LABOR.

??? question "Kontrolli ennast"
    1. `proxmox2` kuulub nii rühma `all` (LABOR) kui ka `dev` (ARENDUS). Miks kehtib ARENDUS? Milline väärtus kehtiks, kui määraksid failis `host_vars/proxmox2.yml` väärtuse `keskkond_nimi: KATSE`?
    2. Kolm serverit, üks playbook ja üks mall. Kus peaks keskkonnast sõltuv info Ansible'i projektis olema ja kus mitte?

Lõpuks käivita playbook uuesti, ilma et vahepeal faile muudaksid, ja uuenda praktikumi tõendid `logid/play_recap.txt`, `leht.html` ja `pais.txt` praktikumi osa 13 käskudega (leht ja päis tulevad endiselt sõlmest `proxmox1`). Tulemus peab olema `changed=0` kõigil kolmel sõlmel ja `bash kontroll.sh` peab näitama, et kõik 7 testi õnnestusid.

??? note "Kontrollnimekiri"
    - [ ] `[web:children]` sisaldab rühmi `dev` ja `prod`
    - [ ] `group_vars/dev.yml` ja `group_vars/prod.yml` erinevad
    - [ ] `logid/dev.html` näitab ARENDUS ja silumisinfo rida, `logid/prod.html` näitab PRODUKTSIOON ilma debug-reata
    - [ ] `nginx.yml` jäi muutmata
    - [ ] `bash kontroll.sh` näitab, et kõik testid õnnestusid

## Töö esitamine

Salvesta muudatused harus `n04-vault` ja saada need GitHubi. Kui praktikumi pull request on veel avatud, lisanduvad muudatused sellesse ise. Kui see on juba liidetud, ava samast harust uus pull request harusse `main`. Kui kontrollid on rohelised, liida pull request.

```bash
git add -A && git commit -m "Kodutöö: arendus- ja tootmiskeskkond" && git push
```

Faili `.vault_pass` repositooriumi ei panda. Tulemuse näed Classroom 50-s.
