---
tags:
  - Ansible
  - Rollid
  - Kodutöö
---

# Kodutöö: Ansible rollid

Praktikumi lõpuks on sul töötav nginx'i roll. Kodutöös laiendad seda rolli.

Töö esitatakse GitHubi repositooriumi lingiga ja pull request peab olema liidetud (*Merged*). Tähtaja näed Classroom 50-s.

## Ülesanne

### 1. Lisa handler

Praegu taaskäivitatakse nginx'i teenus iga kord, kui playbook käivitatakse. Handler käivitub ainult siis, kui konfiguratsioon muutus.

Lisa failis `tasks/main.yml` ülesandele rida `notify`:

```yaml
- name: kopeeri nginx konfiguratsioon
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: restart nginx
```

`handlers/main.yml`:

```yaml
- name: restart nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
```

Testi tulemust: käivita playbook kaks korda järjest. Kui konfiguratsioon ei muutunud, ei tohi teisel korral handler `restart nginx` käivituda. Handlerite kirjeldus on lehel [Handlers](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_handlers.html).

### 2. Lisa teine muutuja

Failis `defaults/main.yml` on praegu `nginx_port`. Lisa sinna muutuja `nginx_server_name` (vaikimisi `localhost`) ja kasuta seda oma Jinja2 mallis.

### 3. Kirjalik küsimus

Kirjuta faili `vastus.md` 3–5 lauset:

> Kuidas sarnaneb Ansible roll programmeerimise funktsioonile? Too üks konkreetne näide kus roll annab eelise võrreldes tavalise playbookiga.

## Esitamine

Tee kõik muudatused eraldi harus ja ava pull request haru `main` vastu. Kirjuta pull request'i kirjeldusse, mida muutsid ja miks.

## Mida hinnatakse

- Handler töötab: teine käivitus ei taaskäivita nginx'i tarbetult.
- `nginx_server_name` on mallis kasutusel.
- `vastus.md` vastab küsimusele konkreetselt, mitte üldiselt.
- Pull request on korrektselt esitatud eraldi harust.
