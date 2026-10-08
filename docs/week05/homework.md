---
tags:
  - Docker
  - Ansible
  - Kodutöö
---

# Kodutöö — Ansible paigaldab sinu konteineri

**Eeldused:** nädala 5 lab (sinu image Docker Hubis: `<kasutaja>/minu-nginx:v1`), N3–N4 Ansible.
**Esitamine:** sama repo ja haru mis labis (`n05-docker`), kaust `ansible/`. Sama PR.

---

## Ülesanne

Labis käivitasid konteinerit käsitsi (`docker run`). Päris elus teeb seda **automatiseerimine**: Ansible valmistab serveri ette ja käivitab konteineri — loengu "Ansible haldab serverit, Docker rakendust" praktikas.

Kirjuta playbook `ansible/deploy.yml`, mis sinu VM-is (või teises Proxmoxi masinas):

1. tagab, et Docker töötab (`service`: `docker`, `started`, `enabled`);
2. paigaldab Pythoni Docker SDK (Ansible'i moodul vajab seda sihtmasinas): `ansible.builtin.dnf` → `python3-pip`, siis `ansible.builtin.pip` → `docker`;
3. käivitab **sinu Docker Hubi image'i** mooduliga `community.docker.docker_container`: nimi `web-ansible`, image `<kasutaja>/minu-nginx:v1`, port `8085:80`, `restart_policy: always`, `state: started`.

```bash
ansible-galaxy collection install community.docker
cd ansible
ansible-playbook -i inventory.ini deploy.yml
curl <VM-IP>:8085
```

Käivita **teist korda** ja salvesta tulemus — idempotentsus (N3): teisel korral `changed=0`.

```bash
ansible-playbook -i inventory.ini deploy.yml | tee ../logid/deploy_recap.txt
```

!!! tip
    `community.docker.docker_container` on deklaratiivne: sa ütled **mis olek** peab olema ("konteiner jookseb sellest image'ist"), mitte käsku. Võrdle `ansible.builtin.command: docker run ...` — mis juhtuks teisel käivitusel? (Osa 5 viga!)

??? question "Mõtle"
    Uus versioon: ehitad `v2`, pushid Docker Hubi. Mida muudad playbookis ja mida Ansible siis konteineriga teeb? Kuidas lähed tagasi `v1` peale, kui `v2` on katki?

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

PR uueneb ise. PR kirjeldusse 2–3 lauset: miks `docker_container`, mitte `command: docker run`.

## Enesekontroll

- [ ] `ansible-playbook --syntax-check` läbib
- [ ] Playbook kasutab `community.docker.docker_container` ja sinu Docker Hubi image'i konkreetse tag'iga
- [ ] `curl <VM-IP>:8085` näitab sinu lehte
- [ ] Teine käivitus: `changed=0`

## Veaotsing

| Probleem | Lahendus |
|---|---|
| `couldn't resolve module/action 'community.docker.docker_container'` | `ansible-galaxy collection install community.docker` |
| `Failed to import the required Python library (Docker SDK for Python)` | Samm 2: `pip` moodul `name: docker` sihtmasinas |
| `permission denied ... docker.sock` | `become: true` playbookis |
| `port is already allocated` | 8085 juba kasutusel — `docker ps`, vali teine port |
| Teisel korral `changed=1` | Kas kasutad `command`-i? Või tag on `latest`? |
