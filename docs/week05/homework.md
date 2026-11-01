---
tags:
  - Docker
  - Ansible
  - Kodutöö
---

# Kodutöö: Ansible paigaldab sinu konteineri

Praktikumis käivitasid konteinereid käsitsi (`docker run`). Töökohas teeb seda automatiseerimine: Ansible valmistab serveri ette ja käivitab konteineri. Selles kodutöös kirjutad playbooki, mis käivitab praktikumis Docker Hubi saadetud image'i `<kasutaja>/minu-nginx:v1`. Kodutöö on boonus.

## Osa 1 · Playbook

Kirjuta playbook `ansible/deploy.yml`, mis sinu esimeses VM-is (selles, kus on Docker):

1. tagab, et Docker töötab (`service`: `docker`, `started`, `enabled`);
2. paigaldab Pythoni Docker SDK, mida Ansible'i moodul sihtmasinas vajab: kõigepealt mooduliga `ansible.builtin.dnf` paketi `python3-pip` ja seejärel mooduliga `ansible.builtin.pip` paketi `docker`;
3. käivitab sinu Docker Hubi image'i mooduliga [`community.docker.docker_container`](https://docs.ansible.com/ansible/latest/collections/community/docker/docker_container_module.html): nimi `web-ansible`, image `<kasutaja>/minu-nginx:v1`, port `8085:80`, `restart_policy: always`, `state: started`.

Paigalda kollektsioon, käivita playbook ja kontrolli lehte:

```bash
ansible-galaxy collection install community.docker
cd ansible
ansible-playbook -i inventory.ini deploy.yml
curl <VM-IP>:8085
```

??? warning "Kui playbook annab vea"

    | Viga | Lahendus |
    |---|---|
    | `couldn't resolve module/action 'community.docker.docker_container'` | `ansible-galaxy collection install community.docker` |
    | `Failed to import the required Python library (Docker SDK for Python)` | Punkt 2: moodul `pip`, `name: docker` sihtmasinas |
    | `permission denied ... docker.sock` | Lisa playbook'i `become: true` |
    | `port is already allocated` | Port 8085 on juba kasutusel, vaata `docker ps` ja vali teine port |

## Osa 2 · Idempotentsus

Käivita playbook teist korda ja salvesta tulemus. Teisel käivitusel peab olema `changed=0`. Kui on `changed=1`, kontrolli, kas kasutad moodulit `command` või tag'i `latest`.

```bash
ansible-playbook -i inventory.ini deploy.yml | tee ../logid/deploy_recap.txt
```

`community.docker.docker_container` on deklaratiivne: playbook kirjeldab soovitud olekut („konteiner töötab sellest image'ist“) ja Ansible teeb ainult vajalikud muudatused. `ansible.builtin.command: docker run ...` käivitaks iga kord uue konteineri ja teisel käivitusel tuleks sama viga nagu praktikumi osas 5.

??? question "Kontrolli ennast"
    1. Ehitad uue versiooni `v2` ja laadid selle Docker Hubi. Mida muudad playbookis ja mida Ansible siis konteineriga teeb?
    2. Kuidas lähed tagasi `v1` juurde, kui `v2` on katki?

??? note "Kontrollnimekiri"

    - [ ] `ansible-playbook --syntax-check` läbib
    - [ ] Playbook kasutab moodulit `community.docker.docker_container` ja sinu Docker Hubi image'i konkreetse tag'iga
    - [ ] `curl <VM-IP>:8085` näitab sinu lehte
    - [ ] Teisel käivitusel on `changed=0`

## Töö esitamine

Töö on samas harus `n05-docker` kaustas `ansible/` (`inventory.ini`, `deploy.yml`) ja failis `logid/deploy_recap.txt`.

```bash
git add ansible logid/deploy_recap.txt
git commit -m "N5 kodutöö: Ansible deploy"
git push
```

Kui praktikumi pull request on veel avatud, uueneb see ise; kui see on juba liidetud, ava samast harust uus pull request. Kirjuta pull request'i kirjeldusse 2–3 lauset selle kohta, miks kasutasid moodulit `docker_container` ja mitte `command: docker run`. Liida pull request harusse `main`. Tulemuse näed Classroom 50-s.
