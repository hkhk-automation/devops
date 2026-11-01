---
tags:
  - Ansible
  - Rollid
  - Kodutöö
---

# Kodutöö: Ansible'i rollid

Praktikumis tegid nginx'i rolli, millel on mall ja handler. Kodutöös lisad rollile teise muutuja ja kontrollid, et handler käivitub ainult muutuse korral. Kodutöö on boonusülesanne.

Tee uus haru praktikumi harust:

```bash
cd ~/lab11
git switch n11-rollid && git pull
git switch -c n11-kodu
```

## Osa 1 · Teine muutuja

Lisa faili `roles/nginx/defaults/main.yml` muutuja:

```yaml
nginx_server_name: localhost
```

Kasuta seda mallis `roles/nginx/templates/lab11.conf.j2` ploki `server` sees:

```jinja2
    server_name {{ nginx_server_name }};
```

## Osa 2 · Handler käivitub ainult muutuse korral

Anna muutujale failis `site.yml` uus väärtus (rolli `vars:` all), näiteks `nginx_server_name: proxmox1.lab`. Käivita playbook kaks korda:

```bash
ansible-playbook -i inventory.ini site.yml | tee logid/k1-muutus.txt
ansible-playbook -i inventory.ini site.yml | tee logid/k2-uuesti.txt
ssh proxmox1 "grep server_name /etc/nginx/conf.d/lab11.conf"
```

??? success "Oodatav tulemus"
    Failis `k1-muutus.txt` on mall `changed` ja handler `laadi nginx uuesti` käivitus. Failis `k2-uuesti.txt` on `changed=0` ja handlerit pole. Sõlmes on failis rida `server_name proxmox1.lab;`.

## Osa 3 · Küsimus

Kirjuta faili `vastus.md` 3–5 lauset: kuidas sarnaneb Ansible'i roll programmeerimise funktsioonile? Mis on rolli „parameetrid“ ja mis jääb rolli sisse?

## Töö esitamine

Harus on muudetud mall, uus muutuja, logid `k1-muutus.txt` ja `k2-uuesti.txt` ning fail `vastus.md`.

```bash
git add roles site.yml logid vastus.md
git commit -m "N11 kodutöö: nginx_server_name ja handler'i kontroll"
git push -u origin n11-kodu
```

Ava pull request harusse `main`, kirjuta kirjeldusse, mida muutsid ja kuidas kontrollisid, ning liida see. Tulemuse näed Classroom 50-s.
