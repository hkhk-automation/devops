---
tags:
  - Ansible
  - Playbook
  - Kodutöö
---

# Kodutöö: Ansible'i playbooki laiendamine

Kodutöös lisad praktikumi playbookile `nginx.yml` teise paketi ja kontrollid, et laiendatud playbook on endiselt idempotentne. Kodutöö on boonus.

## Osa 1 · Lisa teine pakett

Lisa playbooki uus task, mis paigaldab lisaks nginx'ile veel ühe paketi, näiteks `curl` või `git` (vali üks). Kasuta sama moodulit [`ansible.builtin.package`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/package_module.html) mis praktikumis. Kooli sõlmed on Alma, seal `apt` ei tööta.

## Osa 2 · Kohanda index.html

Kui lehel on veel mall `[sinu nimi]`, kirjuta sinna oma nimi:

```html
<h1>Ansible töötab: [sinu nimi]</h1>
```

Käivita playbook uuesti ja vaata lehte sõlme seest käsuga `ssh proxmox1 "curl -s localhost"`.

## Osa 3 · Testi idempotentsust kolm korda

Uus task peab olema sama idempotentne nagu praktikumi task'id. Käivita playbook kolm korda järjest ja salvesta kolmanda käivituse väljund logifaili:

```bash
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml | tee logid/play_recap.txt
```

??? success "Oodatav tulemus"
    Esimesel käivitusel on uus task tõenäoliselt `changed`. Teisel ja kolmandal käivitusel on kõik task'id `ok`.

??? warning "Kui mõni task on ka kolmandal käivitusel `changed`"
    Vaata üle praktikumi osa 5. Tavaliselt on põhjuseks `shell:` või `command:` moodul ilma `creates` tingimuseta või parameeter, mis muutub igal käivitusel (näiteks ajatempel).

## Töö esitamine

Kodutöö läheb samasse repositooriumi uue haru `n03-lab` ja pull request'i kaudu. Kopeeri kolmanda käivituse `PLAY RECAP` tekstina PR-i kirjeldusse ja pärast liitmist lisa PR-i link GitHub Projecti. Automaatkontroll kontrollib haru `main`, seega tulemus tekib pärast liitmist.

```bash
git switch main && git pull
git switch -c n03-lab
git add nginx.yml index.html logid/play_recap.txt
git commit -m "N3 kodutöö: teine pakett"
git push -u origin n03-lab
```

Tulemuse näed Classroom 50-s.
