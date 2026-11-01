---
tags:
  - CD
  - GHCR
  - Docker
  - Ansible
  - Kodutöö
---

# Kodutöö: oma failid konveierisse

Praktikumis said konveieri, mille kolleeg oli kirjutanud. Kodutöös paned konveierisse oma failid: `Dockerfile` N5-st, Compose'i faili N6-st ja Ansible'i playbook'i N4-st. Reeglid on samad mis praktikumis:

- registrisse kirjutab ainult töö, millel on `permissions: packages: write`;
- image ehitatakse alles pärast kontrolli (`needs`);
- pull request ei saada midagi registrisse (`push: branches: [main]` ja `if`);
- tag on commit'i lühiräsi.

Kodutöö on boonus. Classroom 50-s on igal osal oma BOONUS-kontroll, mis annab 0 punkti. Kohustuslik on K1. K2 ja K3 on valikulised.

Töötad samas repositooriumis `~/lab08` masinas `proxmox1`. Failid lähevad kausta `oma/`. Konveieri kirjutad faili `.github/workflows/oma.yml`.

---

## 0. Vanad failid kätte

Sinu varasemad praktikumid on GitHubis. Kui kausta `~/lab05`, `~/lab06` või `~/lab04` masinas pole, klooni repositoorium uuesti. Repositooriumi aadressi leiad Classroom 50-st või GitHubist organisatsioonist `hkhk-automation`:

```bash
cd ~
git clone https://github.com/hkhk-automation/it24-automatiseerimine-lab-05-docker-rakenduse-pakkimine-<kasutaja>.git lab05
git clone https://github.com/hkhk-automation/it24-automatiseerimine-lab-06-docker-compose-<kasutaja>.git lab06
git clone https://github.com/hkhk-automation/it24-automatiseerimine-lab-04-muutujad-jinja2-ja-vault-<kasutaja>.git lab04
```

N5 ja N6 töö võis olla harus. Kui failid puuduvad, vaata harusid: `git -C ~/lab05 branch -a`.

Ära kopeeri faile `.vault_pass` ja `.env`. Need on saladused. `.gitignore` jätab need Gitist välja.

---

## K1 · Docker (kohustuslik)

### K1.1 Fail kohale

Vali N5-st üks image: `nginx/` (minu-nginx) või `flask/` (flask-app). Kopeeri kausta sisu:

```bash
cd ~/lab08
cp -r ~/lab05/nginx/. oma/docker/
ls oma/docker
```

Kontrolli, et image ehitub ja konteiner vastab ka siin. Port sõltub sellest, mis image valisid (nginx 80, Flask 5000):

```bash
docker build -t oma-test oma/docker
docker run -d --rm -p 8090:80 --name oma-test oma-test
curl localhost:8090
docker stop oma-test
```

### K1.2 Kontrolltöö

Loo fail `.github/workflows/oma.yml`. Alusta sündmustest ja tööst, mis ehitab image'i ja kontrollib, et konteiner vastab:

```yaml
name: Oma failid

on:
  push:
    branches: [main]
  pull_request:

jobs:
  docker-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: docker build -t oma-image oma/docker
      - run: docker run -d -p 8080:80 --name oma oma-image
      - run: curl -fsS --retry 10 --retry-all-errors --retry-delay 1 localhost:8080
```

Kui valisid Flaski, muuda `-p 8080:80` kujule `-p 8080:5000`.

### K1.3 Töö, mis saadab image'i GHCR-i

Lisa teine töö `docker`. Võta eeskujuks praktikumi osa 7 töö `build-and-push`. Erinevused:

- töö ootab tööd `docker-test`;
- image'i nimi on `ghcr.io/${GITHUB_REPOSITORY,,}-<nimi>`, näiteks `...-minu-nginx`. Nii ei lähe see segi praktikumi image'iga;
- ehituskontekst on `oma/docker`;
- `--build-arg VERSIOON` pole vaja, kui sinu image seda ei kasuta.

Saada fail GitHubi ja vaata vahekaarti **Actions**:

```bash
git add oma/docker .github/workflows/oma.yml
git commit -m "N8 kodutöö K1: oma image GHCR-i"
git push
```

**Kontrolli:** töövoos `Oma failid` on kaks rohelist tööd ja nende vahel nool. **Packages** all on uus pakett, mille nimi lõpeb `-<nimi>`. Selle tag on sama mis `git log --oneline -1` alguses.

Kui töö on punane, kasuta praktikumi järjekorda: sümptom, hüpotees, tõend, parandus. Vead on tõenäoliselt samad, mis praktikumis.

**Küsimus:** täida README kodutöö tabelis rida K1.

---

## K2 · Docker Compose (valikuline)

N6-s ehitas `docker compose up --build` image'i masinas. Nüüd kontrollib konveier, et stack käivitub. Serveris tuleb rakenduse image registrist ja serveris midagi ei ehitata.

### K2.1 Failid kohale

```bash
cd ~/lab08
cp ~/lab06/docker-compose.yml oma/compose/
cp -r ~/lab06/app ~/lab06/nginx oma/compose/
```

### K2.2 Stack konveieris

Lisa failile `oma.yml` töö `compose`. Nõuded:

1. Töö käib kaustas `oma/compose` (`defaults: run: working-directory:`).
2. Runneris pole faili `.env`. Anna muutujad, mida sinu Compose'i fail kasutab, töö tasemel `env:` all. Testiparool `ci-ainult-test` ei ole saladus, sest see kehtib ainult runneris (N7 kodutöö).
3. `docker compose config -q` kontrollib faili.
4. `docker compose up -d --build` käivitab stacki.
5. `curl` küsib nginx'i porti, mis sinu failis on (N6-s tavaliselt 8080). Kasuta `--retry`, sest andmebaas käivitub aeglaselt.
6. Kukkumisel näitab `docker compose logs` logi (`if: failure()`). Lõpus käib alati `docker compose down -v` (`if: always()`).

### K2.3 Serveris image registrist

Lisa töö `compose-web`, mis ootab tööd `compose` ja saadab rakenduse image'i (`oma/compose/app`) GHCR-i nimega `ghcr.io/${GITHUB_REPOSITORY,,}-web`, tag'iks räsi. Reeglid on samad mis K1-s.

Tee Compose'i failist serveri variant `oma/compose/compose.server.yaml`. Selles on teenusel `web` rida `build:` asendatud reaga `image:`:

```yaml
  web:
    image: ghcr.io/hkhk-automation/<sinu-repo>-web:${VERSIOON}
```

Kui konveier on roheline, käivita stack serveris registris oleva image'iga. Peata enne N6 stack, sest see kasutab samu porte. Fail `.env` tuleb N6-st:

```bash
cd ~/lab06 && docker compose down
cd ~/lab08/oma/compose
cp ~/lab06/.env .
VERSIOON=$(git log --oneline -1 | cut -c1-7) docker compose -f compose.server.yaml up -d
curl localhost:8080
```

**Kontrolli:** `docker compose -f compose.server.yaml images` näitab teenusel `web` image'it `ghcr.io/...-web`.

**Küsimus:** täida README kodutöö tabelis rida K2.

---

## K3 · Ansible (valikuline)

Konveier ei saa playbook'i serveris käivitada, sest runner ei pääse kooli võrku. Ta saab aga kontrollida, et playbook on korras, enne kui keegi seda käivitab.

### K3.1 Failid kohale

```bash
cd ~/lab08
cp -r ~/lab04/nginx.yml ~/lab04/inventory.ini ~/lab04/group_vars ~/lab04/templates oma/ansible/
git status --short oma/ansible
```

`git status` ei tohi näidata faili `.vault_pass`.

### K3.2 Kontroll konveieris

Lisa failile `oma.yml` töö `ansible`. Nõuded:

1. `actions/setup-python` ja `pip install ansible-core ansible-lint`.
2. [`ansible-lint --profile min oma/ansible`](https://ansible.readthedocs.io/projects/lint/profiles/). Profiil `min` kontrollib ainult vigu, mis takistavad käivitamist. Kui tahad rohkem, proovi hiljem profiili `basic`.
3. `ansible-playbook -i oma/ansible/inventory.ini oma/ansible/nginx.yml --syntax-check`.

Vault'i fail `group_vars/all/vault.yml` on krüptitud ja konveieril pole parooli. `--syntax-check` kontrollib ainult playbook'i ülesehitust ja ei loe muutujate väärtusi, seega parooli pole vaja.

**Kontrolli:** töö `ansible` on roheline. Tee playbook'is meelega taandeviga ja vaata, kumb samm selle leiab. Pane siis taane tagasi.

### K3.3 Paigaldus Ansible'iga (lisasamm)

Praktikumis käivitas image'i skript `server/paigalda.sh`. Sama saab teha Ansible'iga nii, et versioon tuleb käsurealt. Loo `oma/ansible/paigalda.yml`:

```yaml
- name: Rakendus GHCR-ist
  hosts: proxmox1   # nimi nagu sinu inventory.ini-s
  vars:
    app_image: ghcr.io/hkhk-automation/<sinu-repo>
  tasks:
    - name: Konteiner flask-cd töötab soovitud versiooniga
      community.docker.docker_container:
        name: flask-cd
        image: "{{ app_image }}:{{ versioon }}"
        pull: true
        restart_policy: unless-stopped
        published_ports:
          - "8088:5000"
```

Moodul [`community.docker.docker_container`](https://docs.ansible.com/ansible/latest/collections/community/docker/docker_container_module.html) ei kuulu `ansible-core`'i. Paigalda kollektsioon ja käivita playbook seal, kus sa N4-s Ansible'it käivitasid:

```bash
ansible-galaxy collection install community.docker
ansible-playbook -i oma/ansible/inventory.ini oma/ansible/paigalda.yml -e versioon=$(git log --oneline -1 | cut -c1-7)
curl <proxmox1-IP>:8088/versioon
```

Kui konveieri töö `ansible` kontrollib ka faili `paigalda.yml`, lisa sinna samm `ansible-galaxy collection install community.docker`.

**Ennusta.** Käivita sama käsk teist korda. Mida näitab `PLAY RECAP`?

**Küsimus:** täida README kodutöö tabelis rida K3.

---

## Lisaülesanne · Väljalase tag'iga

**Väljalase** (release) on versioon, mille inimene märgib, näiteks `v1.0.0`. Git'is tehakse see tag'iga ([Git'i tag'id](https://git-scm.com/book/en/v2/Git-Basics-Tagging)). Starteri failis `kodutoo/release.yml` on kolleegi töövoog, mis peaks väljalaske ehitama. Selles on kolm viga.

Kopeeri fail õigesse kausta ja saada GitHubi. Siis märgi viimane commit versiooniks:

```bash
cp kodutoo/release.yml .github/workflows/release.yml
git add .github/workflows/release.yml
git commit -m "N8 lisaülesanne: release.yml"
git push
git tag v1.0.0
git push origin v1.0.0
```

Leia vead ükshaaval. Töövoog võetakse sellest commit'ist, millele tag näitab. Iga paranduse järel tõsta tag uuele commit'ile:

```bash
git tag -f v1.0.0
git push -f origin v1.0.0
```

Tõendeid leiad vahekaardilt **Actions**, punase sammu logist, [GitHubi muutujate](https://docs.github.com/en/actions/reference/workflows-and-actions/variables) lehelt (võrdle `github.ref` ja `github.ref_name`) ning [tag'ide mustrite](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushbranchestagsbranches-ignoretags-ignore) juhendist. Üks viga ei lase töövool üldse käivituda.

Kui `Release` on roheline, paigalda väljalase:

```bash
bash server/paigalda.sh v1.0.0 2>&1 | tee logid/kodu-server.txt
```

Logi viimane rida peab olema `v1.0.0`. Täida README tabel R1-R3.

---

## Esitamine

Saada kõik GitHubi:

```bash
git add oma .github/workflows README.md logid/kodu-server.txt
git status --short
git commit -m "N8 kodutöö: oma failid konveieris"
git push
```

Praktikumi faile (`ci.yml`, `logid/server.txt`) ära muuda. Põhikontrollid loevad neid.

??? note "Automaatkontroll (BOONUS)"
    Kontrollid loevad faili `.github/workflows/oma.yml` ja kausta `oma/`. Sinu `Dockerfile`-i ega playbook'i sisu nad ei hinda.

    | Kontroll | Mida vaatab |
    |---|---|
    | BOONUS K1 | `oma/docker/Dockerfile`; töö, mis ehitab `oma/docker` ja teeb `docker push`; sellel `permissions: packages: write`, `needs`, `if`; push ainult harus `main`; nimi `ghcr.io/${GITHUB_REPOSITORY,,}-<nimi>`; tag räsiga; README rida K1 |
    | BOONUS K2 | Compose'i fail kaustas `oma/compose`; töö teeb `docker compose config`, `up` ja `curl`; `compose.server.yaml`-is on `image: ghcr.io/...` ja pole `build:`; README rida K2 |
    | BOONUS K3 | playbook kaustas `oma/ansible`; töö teeb `ansible-lint` ja `--syntax-check`; `.vault_pass` ei ole Gitis; README rida K3 |
    | BOONUS Lisaülesanne | `release.yml` parandatud, `logid/kodu-server.txt` viimane rida `v1.0.0`, README tabel R1-R3 |

??? warning "Kui midagi ei tööta"
    - `docker push` annab `denied`: töö `permissions` puudub. Vaata praktikumi osa 2.
    - Compose'i töö kukub ja logis on `POSTGRES_PASSWORD is not specified`: muutuja puudub töö `env:` all.
    - `ansible-lint` leiab vigu: loe reegli nime ja rida. Profiilis `min` on ainult vead, mis takistavad käivitamist.
    - `.vault_pass` jõudis Gitti: `git rm --cached oma/ansible/.vault_pass`, commit ja vaheta Vault'i parool, sest vana on GitHubis ajaloos.
