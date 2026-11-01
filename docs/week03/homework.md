---
tags:
  - Ansible
  - Playbook
  - Kodutöö
---

# Kodutöö: Ansible'i playbook'i laiendamine

Kodutöös täiendad praktikumi playbook'i `nginx.yml` veel ühe paketi paigaldamisega ja kontrollid, et laiendatud playbook on endiselt idempotentne. Kodutöö on boonusülesanne.

Praktikumi lahendus peab olema harusse `main` liidetud. Tee kodutöö jaoks uus haru enne muudatusi:

```bash
git switch main && git pull
git switch -c n03-lab
```

## Osa 1 · Lisa teine pakett

Lisa playbook'i uus task, mis paigaldab lisaks nginx'ile veel ühe paketi, näiteks `curl` või `git` (vali üks). Kasuta sama moodulit [`ansible.builtin.package`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/package_module.html) mis praktikumis. Kooli sõlmedes töötab AlmaLinux, seal `apt` ei tööta.

## Osa 2 · Kohanda index.html

Kui lehel on veel kohatäide `[sinu nimi]`, asenda see oma nimega:

```html
<h1>Ansible töötab: [sinu nimi]</h1>
```

Lehte vaatad pärast järgmist käivitust käsuga `ssh proxmox1 "curl -s localhost"`.

## Osa 3 · Testi idempotentsust kolm korda

Uus task peab olema idempotentne nagu praktikumi task'id. Käivita playbook kolm korda järjest ja salvesta kolmanda käivituse väljund logifaili:

```bash
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml | tee logid/play_recap.txt
```

??? success "Oodatav tulemus"
    Esimesel käivitusel võivad uus task ja leht olla `changed`, kui paketti veel polnud ja leht muutus. Teise ja kolmanda käivituse kokkuvõttes on `changed=0`.

??? warning "Kui mõni task on ka kolmandal käivitusel `changed`"
    Vaata üle praktikumi osa 5. Tavaliselt on põhjuseks `shell:` või `command:` moodul ilma `creates` tingimuseta või parameeter, mis muutub igal käivitusel (näiteks ajatempel).

## Töö esitamine

Salvesta muudatused harus `n03-lab` ja saada need GitHubi. Ava pull request harusse `main`, kopeeri kirjeldusse kolmanda käivituse `PLAY RECAP` tekstina, liida pull request ja lisa selle link GitHub Projecti. Automaatkontroll kontrollib haru `main`, seega tulemus ilmub pärast liitmist.

```bash
git add nginx.yml index.html logid/play_recap.txt
git commit -m "N3 kodutöö: teine pakett"
git push -u origin n03-lab
```

Tulemuse näed Classroom 50-s.
