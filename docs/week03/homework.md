---
tags:
  - Ansible
  - Playbook
  - Kodutöö
---

# Kodutöö — Ansible playbook laiendamine

**Eeldused:** Labor "Esimene Ansible playbook" tehtud — `nginx.yml` töötab, paigaldab nginx + kohandatud index.html.

---

## Ülesanne

Lähtu oma labori `nginx.yml` failist ja laienda seda.

### 1. Lisa teine pakett

Lisa playbooki uus task, mis paigaldab lisaks nginx'ile veel ühe paketi — nt `curl` või `git` (vali üks). Kasuta sama `apt` moodulit mis laboris.

### 2. Kohanda index.html

Muuda `index.html` nii, et see sisaldab su enda nime:

```html
<h1>Ansible töötab — [sinu nimi]</h1>
```

Käivita playbook uuesti ja kontrolli brauseris.

### 3. Testi idempotentsust kolm korda

```bash
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
```

Esimesel käivitusel on uus task tõenäoliselt **changed**. Teisel ja kolmandal peavad **kõik** task'id olema **ok** — see tõestab idempotentsust. Kopeeri kolmanda käivituse `PLAY RECAP` oma PR-i kirjeldusse tõestuseks.

!!! tip
    Kui mõni task näitab `changed` ka kolmandal käivitusel — vaata labori Osa 5 ja veaotsingu tabelit. Tavaliselt on põhjus parameetris, mis muutub iga kord (nt ajatempel).

---

## Esitamine — GitHub PR

1. Uus branch, nt `week03-homework`
2. Lisa muudetud `nginx.yml` + `index.html`, commit
3. Push ja ava **Pull Request** `main` vastu
4. PR kirjeldusse kolmanda käivituse `PLAY RECAP` (tekstina, mitte pilt)
5. Pärast review'd merge

!!! tip
    Kasuta oma kursuse repot. Kui pole veel — loo `ansible-nginx-<eesnimi>` `hkhk-automation` alla, kaitse `main` (nagu nädal 2), tee kõik läbi PR-i.

---

## Hindamiskriteeriumid

| Kriteerium | Nõue |
|---|---|
| Teine pakett | `nginx.yml` sisaldab täiendavat `apt` task'i (curl või git) |
| Kohandatud index.html | Leht sisaldab õpilase nime, `copy` task korrektne |
| Idempotentsus tõestatud | PR-is kolmanda käivituse väljund, kõik **ok** |
| Playbook jookseb veata | `ansible-playbook` käivitub veata |
| PR protsess | Branch → PR → merge, mitte otse `main` |

*Tabel 3.1. Kodutöö hindamiskriteeriumid.*

---

## Allikad

| Allikas | URL |
|---|---|
| Ansible apt module | <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html> |
| GitHub PR juhend | <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request> |
