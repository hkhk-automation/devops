---
tags:
  - Ansible
  - Rollid
  - Kodutöö
---

# Kodutöö: Ansible rollid

Praktikumi lõpuks on sul töötav nginx'i roll ja kodutöös lisad sellele handleri ja teise muutuja. Kodutöö on boonus.

Tee kõik muudatused eraldi harus, sest töö esitatakse pull request'iga.

## Osa 1 · Handler

Handler käivitub ainult siis, kui ülesanne midagi muutis. Nii taaskäivitatakse nginx ainult siis, kui konfiguratsioonifail muutus.

Lisa failis `tasks/main.yml` malli ülesandele rida `notify`:

```yaml
- name: kopeeri nginx konfiguratsioon
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: restart nginx
```

Kirjuta handler faili `handlers/main.yml`:

```yaml
- name: restart nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
```

Käivita playbook kaks korda järjest. Handlerite kirjeldus on lehel [Handlers](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_handlers.html).

??? success "Oodatav tulemus"
    Esimesel käivitusel, kui fail muutus, käivitub handler `restart nginx`. Teisel käivitusel fail ei muutu ja handlerit ei käivitata.

## Osa 2 · Teine muutuja

Failis `defaults/main.yml` on praegu `nginx_port`. Lisa sinna muutuja `nginx_server_name` (vaikimisi `localhost`) ja kasuta seda oma Jinja2 mallis.

## Osa 3 · Küsimus

Kirjuta faili `vastus.md` 3–5 lauset: kuidas sarnaneb Ansible'i roll programmeerimise funktsioonile? Too üks konkreetne näide, kus roll on parem kui tavaline playbook.

## Töö esitamine

Harus on handler, uus muutuja mallis ja fail `vastus.md`. Ava pull request haru `main` vastu, kirjuta kirjeldusse, mida muutsid ja miks, ning liida pull request (*Merged*).

Tulemuse näed Classroom 50-s.
