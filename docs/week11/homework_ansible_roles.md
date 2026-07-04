---
tags:
  - Ansible
  - Rollid
  - Kodutöö
---

# Kodutöö — Ansible rollid (Valik 2)

**Tähtaeg:** pühapäev 23:59
**Esitamine:** GitHub repo link — PR peab olema "Merged"

---

## Ülesanne

Labi lõpuks sul on töötav nginx roll. Nüüd laiendad seda.

### 1. Lisa handler

Praegu taaskäivitab nginx teenuse iga kord kui playbook jookseb. Handler käivitub ainult siis kui konfiguratsioon päriselt muutus.

`tasks/main.yml`-is lisa `notify`:

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

Testi: käivita playbook kaks korda järjest. Teisel korral ei tohi "restart nginx" handler käivituda kui konfiguratsioon ei muutunud.

### 2. Lisa teine muutuja

`defaults/main.yml`-is on praegu `nginx_port`. Lisa juurde `nginx_server_name` (vaikimisi `localhost`).

Kasuta seda muutujat oma Jinja2 mallis.

### 3. Kirjalik küsimus

Kirjuta `vastus.md` faili 3–5 lauset:

> Kuidas sarnaneb Ansible roll programmeerimise funktsioonile? Too üks konkreetne näide kus roll annab eelise võrreldes tavalise playbookiga.

---

## Esitamine

Kõik muudatused eraldi harus, PR `main`-i vastu. PR description: mis muutsid ja miks.

---

## Mida hinnatakse

- Handler töötab — teine käivitus ei taaskäivita nginx't tarbetult
- `nginx_server_name` on kasutusel mallis
- `vastus.md` vastab küsimusele konkreetselt, mitte üldiselt
- PR on korrektselt esitatud feature branchist
