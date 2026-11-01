---
tags:
  - Ansible
  - Playbook
  - Kodutöö
---

# Kodutöö: Ansible'i playbooki laiendamine

**Eeldused:** praktikum „Esimene Ansible playbook“ on tehtud: `nginx.yml` töötab ning paigaldab nginx'i ja kohandatud lehe `index.html`.

## Ülesanne

Võta aluseks praktikumis loodud fail `nginx.yml` ja laienda seda.

### 1. Lisa teine pakett

Lisa playbooki uus task, mis paigaldab lisaks nginx'ile veel ühe paketi, näiteks `curl` või `git` (vali üks). Kasuta sama [`ansible.builtin.package`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/package_module.html) moodulit mis praktikumis. Koolisõlmed on Alma, seal `apt` ei tööta.

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
ansible-playbook -i inventory.ini nginx.yml | tee logid/play_recap.txt
```

Esimesel käivitusel on uus task tõenäoliselt changed. Teisel ja kolmandal käivitusel peavad kõik task'id olema ok: see tõendab idempotentsust. Kolmanda käivituse väljund läheb faili `logid/play_recap.txt`, mida automaatkontroll loeb. Kopeeri sama `PLAY RECAP` ka oma PR-i kirjeldusse.

!!! tip
    Kui mõni task on ka kolmandal käivitusel `changed`, vaata üle praktikumi osa 5. Tavaliselt on põhjuseks `shell:` või `command:` moodul ilma `creates` tingimuseta või parameeter, mis muutub igal käivitusel (nt ajatempel).

## Esitamine: GitHub PR

1. Praktikumi haru `n03-nginx` on juba `main`-i liidetud. Võta `main` uuesti alla (`git switch main && git pull`) ja loo kodutöö jaoks uus haru: `git switch -c n03-lab`.
2. Lisa muudetud failid `nginx.yml`, `index.html` ja `logid/play_recap.txt` ning tee commit.
3. Tee push ja ava **Pull Request** haru `main` vastu ([GitHubi juhend](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)).
4. Lisa PR-i kirjeldusse kolmanda käivituse `PLAY RECAP` tekstina (ekraanipilt ei sobi).
5. Pärast ülevaatust tee merge. Automaatkontroll hindab haru `main`, seega kodutöö läheb arvesse alles pärast merge'i. Esita PR-i link GitHub Projectis.

!!! tip
    Kasuta oma kursuse repositooriumi. Kui see puudub, loo organisatsiooni `hkhk-automation` alla repositoorium `ansible-nginx-<eesnimi>`, kaitse haru `main` (nagu 2. nädalal) ja tee kõik muudatused PR-i kaudu.

## Hindamiskriteeriumid

??? note "Kodutöö hindamiskriteeriumid"
    | Kriteerium | Nõue |
    |---|---|
    | Teine pakett | `nginx.yml` sisaldab täiendavat `ansible.builtin.package` task'i (curl või git) |
    | Kohandatud index.html | Leht sisaldab õpilase nime, `copy` task korrektne |
    | Idempotentsus tõestatud | `logid/play_recap.txt`-is ja PR-is kolmanda käivituse väljund, kõik ok |
    | Playbook töötab veata | `ansible-playbook` käivitub veata |
    | PR-i protsess | Haru → PR → merge; otse `main` harusse muudatusi ei tehta |

