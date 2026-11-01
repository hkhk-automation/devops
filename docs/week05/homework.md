---
tags:
  - Docker
  - Ansible
  - Kodutöö
---

# Kodutöö: Ansible paigaldab sinu konteineri

Praktikumis käivitasid konteinereid käsitsi käsuga `docker run`. Töökohas saab selle automatiseerida: Ansible valmistab serveri ette ja käivitab konteineri. Selles kodutöös kirjutad playbook'i, mis käivitab konteineri praktikumis Docker Hubi saadetud image'i `<kasutaja>/minu-nginx:v1` põhjal. Kodutöö on boonusülesanne.

## Osa 1 · Playbook

Kirjuta playbook `ansible/deploy.yml`, mis teeb sinu esimeses virtuaalmasinas (selles, kus on Docker) järgmist:

1. tagab, et Dockeri teenus töötab ja käivitub automaatselt (`service`: `docker`, `started`, `enabled`);
2. paigaldab Pythoni Docker SDK, mida Ansible'i moodul sihtmasinas vajab: kõigepealt mooduliga `ansible.builtin.dnf` paketi `python3-pip` ja seejärel mooduliga `ansible.builtin.pip` paketi `docker`;
3. käivitab konteineri sinu Docker Hubis oleva image'i põhjal mooduliga [`community.docker.docker_container`](https://docs.ansible.com/ansible/latest/collections/community/docker/docker_container_module.html): nimi `web-ansible`, image `<kasutaja>/minu-nginx:v1`, port `8085:80`, `restart_policy: always`, `state: started`.

Paigalda kollektsioon, käivita playbook ja kontrolli lehte:

```bash
ansible-galaxy collection install community.docker
cd ansible
ansible-playbook -i inventory.ini deploy.yml
curl <VM-IP>:8085
```

??? warning "Kui playbook'i käivitamine ebaõnnestub"

    | Viga | Lahendus |
    |---|---|
    | `couldn't resolve module/action 'community.docker.docker_container'` | `ansible-galaxy collection install community.docker` |
    | `Failed to import the required Python library (Docker SDK for Python)` | Punkt 2: moodul `pip`, `name: docker` sihtmasinas |
    | `permission denied ... docker.sock` | Lisa playbook'i võti `become: true` |
    | `port is already allocated` | Port 8085 on juba kasutusel. Vaata käsu `docker ps` väljundit ja vali teine port |

## Osa 2 · Idempotentsus

Käivita playbook teist korda ja salvesta tulemus. Teise käivituse kokkuvõttes peab olema `changed=0`. Kui ei ole, leia väljundist ülesanne olekuga `changed` ja selgita välja, miks see uuesti muudatuse tegi. Kontrolli muu hulgas, kas konteinerit haldab moodul `docker_container` ja kas image'il on konkreetne tag.

```bash
ansible-playbook -i inventory.ini deploy.yml | tee ../logid/deploy_recap.txt
```

`community.docker.docker_container` on deklaratiivne: playbook kirjeldab soovitud olekut („konteiner töötab määratud image'i põhjal“) ja Ansible teeb ainult vajalikud muudatused. Moodulile `ansible.builtin.command` antud käsk `docker run --name web-ansible ...` prooviks konteinerit igal käivitusel uuesti luua. Kui sama nimega konteiner on juba olemas, lõpeks käsk veaga nagu praktikumi osas 5.

??? question "Kontrolli ennast"
    1. Ehitad uue versiooni `v2` ja laadid selle Docker Hubi. Mida muudad playbook'is ja mida Ansible siis konteineriga teeb?
    2. Kuidas taastad versiooni `v1`, kui `v2` on katki?

??? note "Kontrollnimekiri"

    - [ ] `ansible-playbook --syntax-check` ei anna viga
    - [ ] Playbook kasutab moodulit `community.docker.docker_container` ja sinu Docker Hubi image'i konkreetse tag'iga
    - [ ] `curl <VM-IP>:8085` näitab sinu lehte
    - [ ] Teisel käivitusel on `changed=0`

## Töö esitamine

Esita kodutöö praktikumi harus `n05-docker`. Repositooriumis peavad olema failid `ansible/inventory.ini`, `ansible/deploy.yml` ja `logid/deploy_recap.txt`. Liigu tagasi repositooriumi juurkausta ja salvesta muudatused:

```bash
cd ..
git add ansible logid/deploy_recap.txt
git commit -m "N5 kodutöö: Ansible deploy"
git push
```

Kui praktikumi pull request on veel avatud, uueneb see ise. Kui see on juba liidetud, ava samast harust uus pull request. Kirjuta pull request'i kirjeldusse 2–3 lauset selle kohta, miks kasutasid moodulit `docker_container` ja mitte `command: docker run`. Liida pull request harusse `main`. Tulemuse näed Classroom 50-s.
