---
tags:
  - Docker
  - Ansible
  - Kodutöö
---

# Kodutöö — Ansible paigaldab sinu konteineri

**Eeldused:** 5. nädala lab on tehtud (sinu image on Docker Hubis: `<kasutaja>/minu-nginx:v1`), N3–N4 Ansible.
**Esitamine:** sama repo ja haru mis labis (`n05-docker`), kaust `ansible/`, sama PR.

---

## Ülesanne

Labis käivitasid konteinereid käsitsi (`docker run`). Päris töös teeb seda **automatiseerimine**: Ansible valmistab serveri ette ja käivitab konteineri. Nii paned loengu põhimõtte "Ansible haldab serverit, Docker rakendust" praktikasse.

Kirjuta playbook `ansible/deploy.yml`, mis sinu **esimeses** VM-is (selles, kus on Docker):

1. tagab, et Docker töötab (`service`: `docker`, `started`, `enabled`);
2. paigaldab Pythoni Docker SDK (Ansible'i moodul vajab seda sihtmasinas): kõigepealt `ansible.builtin.dnf` → `python3-pip`, siis `ansible.builtin.pip` → `docker`;
3. käivitab **sinu Docker Hubi image'i** mooduliga `community.docker.docker_container`: nimi `web-ansible`, image `<kasutaja>/minu-nginx:v1`, port `8085:80`, `restart_policy: always`, `state: started`.

```bash
ansible-galaxy collection install community.docker
cd ansible
ansible-playbook -i inventory.ini deploy.yml
curl <VM-IP>:8085
```

Käivita playbook **teist korda** ja salvesta tulemus. Idempotentsus (N3): teisel korral peab olema `changed=0`.

```bash
ansible-playbook -i inventory.ini deploy.yml | tee ../logid/deploy_recap.txt
```

!!! tip
    `community.docker.docker_container` on deklaratiivne: sa kirjeldad, **milline olek** peab olema ("konteiner töötab sellest image'ist"), mitte ei anna käsku. Võrdle sellega: `ansible.builtin.command: docker run ...` — mis juhtuks teisel käivitusel? (Meenuta labi 5. osa viga!)

??? question "Mõtle"
    Tuleb uus versioon: ehitad `v2` ja laadid selle Docker Hubi. Mida muudad playbookis ja mida Ansible siis konteineriga teeb? Kuidas lähed tagasi `v1` juurde, kui `v2` on katki?

## Repo

```text
ansible/
├── inventory.ini
└── deploy.yml
logid/
└── deploy_recap.txt     # teine käivitus, changed=0
```

```bash
git add ansible logid/deploy_recap.txt
git commit -m "N5 kodutöö: Ansible deploy"
git push
```

PR uueneb automaatselt. Kirjuta PR-i kirjeldusse 2–3 lauset: miks kasutasid `docker_container`-it, mitte `command: docker run`-i.

## Enesekontroll

- [ ] `ansible-playbook --syntax-check` läbib
- [ ] Playbook kasutab `community.docker.docker_container` ja sinu Docker Hubi image'i konkreetse tag'iga
- [ ] `curl <VM-IP>:8085` näitab sinu lehte
- [ ] Teisel käivitusel on `changed=0`

## Veaotsing

| Probleem | Lahendus |
|---|---|
| `couldn't resolve module/action 'community.docker.docker_container'` | `ansible-galaxy collection install community.docker` |
| `Failed to import the required Python library (Docker SDK for Python)` | Samm 2: moodul `pip`, `name: docker` sihtmasinas |
| `permission denied ... docker.sock` | Lisa playbooki `become: true` |
| `port is already allocated` | Port 8085 on juba kasutusel — vaata `docker ps` ja vali teine port |
| Teisel korral `changed=1` | Kas kasutad `command`-i? Või on tag `latest`? |
