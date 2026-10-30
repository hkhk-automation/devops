---
tags:
  - Ansible
  - Playbook
  - Kodutöö
---

# Kodutöö: Ansible'i playbooki laiendamine

**Eeldused:** praktikum „Esimene Ansible playbook“ on tehtud: `nginx.yml` töötab ning paigaldab nginx'i ja kohandatud lehe `index.html`.

---

## Ülesanne

Võta aluseks praktikumis loodud fail `nginx.yml` ja laienda seda.

### 1. Lisa teine pakett

Lisa playbooki uus task, mis paigaldab lisaks nginx'ile veel ühe paketi, näiteks `curl` või `git` (vali üks). Kasuta sama `apt` moodulit mis praktikumis.

### 2. Kohanda index.html

Muuda faili `index.html` nii, et see sisaldaks sinu nime:

```html
<h1>Ansible töötab: [sinu nimi]</h1>
```

Käivita playbook uuesti ja kontrolli tulemust brauseris.

### 3. Testi idempotentsust kolm korda

```bash
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
```

Esimesel käivitusel on uus task tõenäoliselt **changed**. Teisel ja kolmandal käivitusel peavad **kõik** task'id olema **ok**: see tõendab idempotentsust. Kopeeri kolmanda käivituse `PLAY RECAP` tõendiks oma PR-i kirjeldusse.

!!! tip
    Kui mõni task on ka kolmandal käivitusel `changed`, vaata üle praktikumi Osa 5 ja veaotsingu tabel. Tavaliselt on põhjuseks `shell:` või `command:` moodul ilma `creates` tingimuseta või parameeter, mis muutub igal käivitusel (nt ajatempel).

---

## Esitamine: GitHub PR

1. Loo haru `n03-lab`.
2. Lisa muudetud failid `nginx.yml` ja `index.html` ning tee commit.
3. Tee push ja ava **Pull Request** haru `main` vastu.
4. Lisa PR-i kirjeldusse kolmanda käivituse `PLAY RECAP` tekstina (ekraanipilt ei sobi).
5. Pärast ülevaatust tee merge. Esita **PR-i link GitHub Projectis**.

!!! tip
    Kasuta oma kursuse repositooriumi. Kui see puudub, loo organisatsiooni `hkhk-automation` alla repositoorium `ansible-nginx-<eesnimi>`, kaitse haru `main` (nagu 2. nädalal) ja tee kõik muudatused PR-i kaudu.

---

## Hindamiskriteeriumid

| Kriteerium | Nõue |
|---|---|
| Teine pakett | `nginx.yml` sisaldab täiendavat `apt` task'i (curl või git) |
| Kohandatud index.html | Leht sisaldab õpilase nime, `copy` task korrektne |
| Idempotentsus tõestatud | PR-is kolmanda käivituse väljund, kõik **ok** |
| Playbook töötab veata | `ansible-playbook` käivitub veata |
| PR-i protsess | Haru → PR → merge; otse `main` harusse muudatusi ei tehta |

*Tabel 3.1. Kodutöö hindamiskriteeriumid.*

---

## Allikad

| Allikas | URL |
|---|---|
| Ansible apt module | <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html> |
| GitHub PR juhend | <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request> |
