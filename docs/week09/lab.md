---
tags:
  - IaC
  - Docker
  - Ansible
  - Iseseisev
  - Praktikum
---

# N9 · Praktikum: infrastruktuur koodina (iseseisev)

Täna töötad iseseisvalt brauseris. Proxmoxi ja VPN-i ei ole vaja.

Selles praktikumis võrdled Bashi, Docker Compose'i ja Ansible'it ühe küsimuse kaudu: **millist olekut see tööriist haldab ja mida ta teeb, kui tegelik olek erineb kirjeldatust?**

| Osa | Töö | Aeg |
|---|---|---|
| 0 | Loe [loeng](lecture.md) läbi | 60 min |
| 1 | KodeKloudi Dockeri kursus | 45 min |
| 2 | Võrdlustabel | 30 min |
| 3 | Docker Compose'i ja Bashi katse | 50 min |
| 4 | Triiv Ansible'i ja Compose'iga | 30 min |
| 5 | Ennustus ja esitamine | 15 min |

*Tabel 9.9. Praktikumi osad*

Vastused kirjuta oma Lab 09 repositooriumi faili `README.md`: asenda iga `_vastus_` oma tekstiga. Repositooriumi lingi leiad kursuse teadetest.

??? abstract "Õpiväljundid"

    1. Oskad öelda, millist olekut Bash, Git, Ansible, Dockerfile, Docker Compose ja GitHub Actions haldavad.
    2. Oskad Docker Compose'i väljundist välja lugeda, milliseid konteinereid ta lõi, lõi uuesti või jättis puutumata.
    3. Oskad näidata, miks konteineri olemasolu kontrolliv skript ei taga veel soovitud olekut.
    4. Oskad tekitada triivi ja võrrelda, kuidas Ansible ja Docker Compose sellele reageerivad.

---

## Osa 1 · KodeKloudi kursus

**Ülesanne**

1. Ava kursus [Docker for the Absolute Beginner: Crash Course](https://kodekloud.com/courses/crash-course-docker-for-absolute-beginner) ja vajuta **Enroll for Free**.
2. Vaata videod ja tee läbi neli laborit.
3. Laadi sertifikaat oma repositooriumi kausta `kodekloud/`: **Add file → Upload files**, failinime ette kirjuta `kodekloud/`.

**Kontrolli**

Repositooriumis on kaust `kodekloud/` ja selles `.pdf`, `.png` või `.jpg` fail.

??? warning "Kui midagi ei tööta"
    - KodeKloud küsib maksmist: logi sisse ja vajuta uuesti **Enroll for Free**. Kui see ei aita, tee lehest ekraanipilt ja kirjuta õpetajale.
    - Tasuta kontoga ei anta sertifikaati: laadi üles ekraanipilt kursuse lehest, millel on näha 100% ja sinu nimi.

---

## Osa 2 · Võrdlustabel

**Ülesanne**

Täida README-s Osa 2 tabel. Iga tööriista kohta vasta neljale küsimusele:

- Kas fail kirjeldab samme või tulemust?
- Millist olekut tööriist haldab (näiteks faile serveris, konteinereid, koodi versioone)?
- Kas sama käsu korduv käivitamine on ohutu?
- Kas tööriist võrdleb olemasolevat olekut soovitud olekuga?

Viimasesse veergu pane link oma Lab 02-07 failile GitHubis. Ava fail oma repositooriumis ja kopeeri aadress brauseri aadressiribalt.

??? tip "Millist faili linkida"

    | Tööriist | Fail |
    |---|---|
    | Bash | Lab 02 `monitor.sh` |
    | Git | Lab 02 commit'ide leht (**Commits**) |
    | Ansible | Lab 03 `nginx.yml` või `logid/play_recap.txt` |
    | Dockerfile | Lab 05 `nginx/Dockerfile` |
    | Docker Compose | Lab 06 `docker-compose.yml` |
    | GitHub Actions | Lab 07 `.github/workflows/ci.yml` |

Põhjendusi README-sse ei kirjuta. N10 alguses küsin igaühelt suuliselt ühe lahtri kohta.

---

## Osa 3 · Docker Compose'i ja Bashi katse

Osad 3 ja 4 tee KodeKloudi labori terminalis. Ava selleks uuesti mõni Osa 1 labor.

Käskude väljund salvestatakse kausta `logid/`. Sammus 3.7 kopeerid failid GitHubi.

!!! warning "Labori terminal suletakse, kui aeg saab täis"
    Kopeeri logifailid GitHubi pärast iga osa. Kui terminal suleti, ava labor uuesti ja tee samm 3.1 uuesti.

### 3.1 Töökaust

**Ülesanne**

Kleebi terminali kogu plokk korraga:

```bash
mkdir -p ~/lab09/logid && cd ~/lab09

cat > compose.yaml <<'EOF'
services:
  web:
    image: nginx:1.27-alpine
    ports:
      - "8080:80"
  cache:
    image: redis:7-alpine
EOF

cat > run.sh <<'EOF'
#!/bin/bash
docker run -d --name lab09-skript -p 8090:80 nginx:1.27-alpine
echo "valmis"
EOF
```

**Kontrolli**

```bash
docker compose version
ls
```

Väljundis on Compose'i versioon ning failid `compose.yaml` ja `run.sh`.

??? warning "Kui näed teadet `'compose' is not a docker command`"
    Terminalis on Compose'i vana versioon. Kirjuta kõigis käskudes `docker compose` asemel `docker-compose`.

### 3.2 Kaks käivitust järjest

**Ennusta.** Mis juhtub, kui käivitad sama käsu kaks korda järjest?

**Ülesanne**

```bash
docker compose up -d 2>&1 | tee logid/01-up.txt
docker compose up -d 2>&1 | tee logid/02-up-uuesti.txt
```

**Kontrolli**

```bash
cat logid/02-up-uuesti.txt
```

**Küsimus:** kas Compose lõi teisel käivitusel mõne konteineri? Mille järgi seda väljundist näed? (README 3.1)

??? success "Oodatav tulemus"
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Running
    ```
    Compose võrdles faili `compose.yaml` jooksvate konteineritega. Nende konfiguratsioonis ei olnud muudatust, seega ei loonud ta midagi uuesti.

### 3.3 Konteiner kustutatakse käsitsi

**Ennusta.** Kustutad konteineri `cache` käsitsi. Mida teeb Compose järgmisel käivitusel?

**Ülesanne**

```bash
docker rm -f lab09-cache-1 2>&1 | tee logid/03-taastamine.txt
docker compose up -d 2>&1 | tee -a logid/03-taastamine.txt
```

**Kontrolli**

```bash
docker compose ps
```

**Küsimus:** mida tegi Compose konteineriga `cache` ja mida konteineriga `web`? (README 3.2)

??? success "Oodatav tulemus"
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Created
     Container lab09-cache-1  Started
    ```

??? warning "Kui näed teadet `No such container`"
    Konteineri nimi on sinu terminalis teine, näiteks `lab09_cache_1`. Vaata nime käsuga `docker ps`.

### 3.4 Konfiguratsiooni muudatus

**Ennusta.** Muudad faili `compose.yaml`-is konteineri `web` porti. Millise konteineri Compose uuesti loob?

**Ülesanne**

```bash
sed -i 's/8080:80/8081:80/' compose.yaml
docker compose up -d 2>&1 | tee logid/04-port.txt
```

**Kontrolli**

```bash
cat logid/04-port.txt
curl -s localhost:8081 | head -4
```

**Küsimus:** millise konteineri Compose uuesti lõi ja miks ainult selle? (README 3.3)

??? success "Oodatav tulemus"
    ```text
     Container lab09-cache-1  Running
     Container lab09-web-1  Recreated
     Container lab09-web-1  Started
    ```
    Töötava konteineri porti muuta ei saa. Compose lõi konteineri `web` uuesti, `cache` konfiguratsioon ei muutunud.

Muuda port 8081 ka oma GitHubi repositooriumi failis `compose.yaml`.

### 3.5 Sama Bashi skriptiga

**Ennusta.** Skript `run.sh` käivitab konteineri käsuga `docker run`. Mis juhtub teisel käivitusel?

**Ülesanne**

```bash
bash run.sh 2>&1 | tee logid/05-run-kaks-korda.txt
bash run.sh 2>&1 | tee -a logid/05-run-kaks-korda.txt
```

**Kontrolli**

```bash
cat logid/05-run-kaks-korda.txt
```

**Küsimus:** mis veateate andis teine käivitus ja mida skript lõpus ikkagi kirjutas? (README 3.4)

??? success "Oodatav tulemus"
    ```text
    docker: Error response from daemon: Conflict. The container name "/lab09-skript" is already in use by container "4f2a...".
    valmis
    ```
    Veateates on sama konteineri ID, mis tekkis esimesel käivitusel.

### 3.6 Skripti parandus

**Ülesanne**

Muuda GitHubis faili `run.sh` nii, et skript kontrollib enne `docker run` käsku, kas sellise nimega konteiner on juba olemas.

??? tip "Lahendus (proovi enne ise)"
    ```bash
    #!/bin/bash
    if docker ps -a --format '{{.Names}}' | grep -qx lab09-skript; then
      echo "lab09-skript on juba olemas"
    else
      docker run -d --name lab09-skript -p 8090:80 nginx:1.27-alpine
      echo "valmis"
    fi
    ```

Kopeeri parandatud skript terminali samamoodi nagu sammus 3.1 (`cat > run.sh <<'EOF'` ... `EOF`). Kustuta vana konteiner ja käivita skript kaks korda:

```bash
docker rm -f lab09-skript
bash run.sh 2>&1 | tee logid/06-run-parandatud.txt
bash run.sh 2>&1 | tee -a logid/06-run-parandatud.txt
```

**Kontrolli**

Teisel käivitusel ei ole väljundis teadet `Conflict`.

**Küsimus:** skript kontrollib ainult, kas sellise nimega konteiner on olemas. Too olukord, kus skript kirjutab „juba olemas“, kuigi konteiner ei vasta skriptis kirjeldatule. (README 3.5)

??? success "Mida see näitab"
    Konteiner võib olla peatatud, teise image'i või teise pordiga. Skript kontrollib olemasolu, mitte olekut. Compose võrdleb konteineri konfiguratsiooni failiga ja loob konteineri vajaduse korral uuesti, nagu nägid sammus 3.4.

### 3.7 Logifailid GitHubi

**Ülesanne**

Iga logifaili kohta:

1. Käivita terminalis `cat logid/01-up.txt` ja kopeeri väljund.
2. Vali GitHubis **Add file → Create new file**, kirjuta failinimeks `logid/01-up.txt`, kleebi sisu ja vajuta **Commit changes**.

Tee sama failidega `02` kuni `06`. Seejärel vasta README-s küsimustele 3.1-3.5. Igas vastuses kopeeri logist üks rida ja kirjuta selle juurde üks lause.

---

## Osa 4 · Triiv

Jätka samas terminalis ja kaustas `~/lab09`.

### 4.1 Ansible

**Ülesanne**

Paigalda Ansible ja loo playbook, mis hoiab failis `/tmp/lab09-nginx.conf` väärtust `1m`:

```bash
python3 -m pip install ansible-core || apt-get install -y ansible

cat > triiv.yml <<'EOF'
- hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - name: konfifail on soovitud olekus
      ansible.builtin.copy:
        dest: /tmp/lab09-nginx.conf
        content: |
          client_max_body_size 1m;
EOF

ansible-playbook triiv.yml
```

Muuda faili käsitsi, nagu tegi loengus Mati:

```bash
sed -i 's/1m/50m/' /tmp/lab09-nginx.conf
```

**Ennusta.** Mida näitab `--check --diff` ja kas see muudab faili?

```bash
ansible-playbook triiv.yml --check --diff 2>&1 | tee logid/07-triiv-ansible.txt
cat /tmp/lab09-nginx.conf
```

Käivita playbook ilma `--check`-ita:

```bash
ansible-playbook triiv.yml 2>&1 | tee -a logid/07-triiv-ansible.txt
cat /tmp/lab09-nginx.conf
```

**Küsimus:** mis oli failis pärast `--check` käivitust ja mis pärast tavalist käivitust? (README 4.1)

??? success "Oodatav tulemus"
    `--check --diff` näitab ridu `-client_max_body_size 50m;` ja `+client_max_body_size 1m;`, aga failis on endiselt `50m`. Tavaline käivitus kirjutab faili sisu tagasi väärtusele `1m`.

??? warning "Kui `pip` ja `apt-get` ei tööta"
    Tee see osa oma arvuti WSL Ubuntus. Paigalda Ansible käsuga `sudo apt install ansible` ja käivita samad käsud.

### 4.2 Docker Compose

**Ülesanne**

Muuda töötava konteineri `web` avalehte otse konteineri sees:

```bash
docker compose exec web sh -c 'echo "MATI PARANDAS" > /usr/share/nginx/html/index.html'
curl -s localhost:8081 2>&1 | tee logid/08-triiv-konteiner.txt
```

**Ennusta.** Ansible taastas faili sisu. Kas `docker compose up -d` taastab nginx'i avalehe? Kirjuta ennustus README-sse (4.2 Ennustus) enne järgmist käsku.

```bash
docker compose up -d 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
```

**Kontrolli.** Loo konteiner uuesti:

```bash
docker compose up -d --force-recreate 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
```

**Küsimus:** mida näitas `curl` pärast tavalist `up -d` ja mida pärast `--force-recreate`? Millist olekut Compose haldab ja millist mitte? (README 4.2 Tulemus)

??? success "Mida see näitab"
    Pärast `up -d` on avalehel endiselt `MATI PARANDAS`. Compose võrdleb konteineri konfiguratsiooni (image, pordid, keskkonnamuutujad) failiga `compose.yaml`. Faile konteineri sees ta ei võrdle. `--force-recreate` loob konteineri image'ist uuesti ja käsitsi tehtud muudatus kaob.

    Ansible ja Compose on mõlemad deklaratiivsed, aga nad haldavad eri olekut: Ansible faili sisu serveris, Compose konteinerite olemasolu ja konfiguratsiooni.

Kopeeri failid `logid/07-triiv-ansible.txt` ja `logid/08-triiv-konteiner.txt` GitHubi samamoodi nagu sammus 3.7.

---

## Osa 5 · Ennustus ja esitamine

**Ülesanne**

OpenTofu on samuti deklaratiivne tööriist. Vasta README Osa 5 kahele küsimusele oma katsete ja loengu osa 6 põhjal:

1. Keegi kustutab Proxmoxis käsitsi masina, mille OpenTofu lõi. Mis juhtub OpenTofu järgmisel käivitusel?
2. Kustutad OpenTofu failist ühe masina kirjelduse. Mis juhtub järgmisel käivitusel? Kas Ansible teeks sama?

Kirjuta kokku vähemalt 40 sõna. N10 alguses loed vastused ette ja kontrollime neid OpenTofuga.

**Kontrolli**

Otsi README-st (Ctrl+F) sõna `_vastus_`. Osades 2-5 ei tohi seda enam olla. Automaatkontrolli tulemuse näed repositooriumi vahekaardil **Actions**.

??? note "Automaatkontroll (100 punkti)"

    | Kontroll | Punktid |
    |---|---|
    | Failid `logid/01`-`08` on olemas | 5 |
    | Nimi ja Osade 3-4 vastused on kirjas | 5 |
    | KodeKloudi sertifikaat või ekraanipilt | 10 |
    | Võrdlustabel ja 6 linki oma repositooriumidesse | 15 |
    | `compose.yaml` on korrektne | 10 |
    | Teise käivituse väljundis on `Running` | 10 |
    | Taastamise väljundis on `Created` või `Started` | 10 |
    | Skripti teisel käivitusel on `Conflict` sama konteineriga | 10 |
    | Skript on parandatud | 5 |
    | Ansible'i triivi logi | 10 |
    | Compose'i triivi logi | 5 |
    | Ennustus | 5 |

---

## Lisaülesanded

??? example "A · 12-Factor (kerge)"
    Loe [12-Factor App](https://12factor.net/) peatükid **III Config**, **IV Backing services** ja **V Build, release, run**. Täida README tabel Lisa A: kas Docker Compose, GitHub Actions ja Ansible aitavad seda põhimõtet järgida? Kirjuta igasse lahtrisse „jah“, „osaliselt“ või „ei“ ja üks lause põhjenduseks.

??? example "B · Öine triivikontroll (keskmine)"
    Kirjuta skript `triivikontroll.sh`, mis käivitab `ansible-playbook triiv.yml --check`. Kui väljundis on `changed=0`, kirjutab skript `triivi ei ole` ja lõpetab koodiga 0. Muul juhul kirjutab skript `TRIIV!` ja lõpetab koodiga 1. Proovi mõlemat olukorda.

    Pane skript GitHubi faili `lisa/triivikontroll.sh` ja väljund faili `logid/lisa-b.txt`. Kirjuta README-sse, kuidas paneksid skripti igal ööl käima. Vihje: N7 `on: schedule`.

??? example "C · Kubernetes'e kontroller (raskem)"
    Loe Kubernetes'e dokumentatsioonist lehte [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/) (umbes 10 minutit). Kirjuta README-sse, mille poolest on kontroller sarnane käsuga `docker compose up -d` ja mille poolest erineb.

---

*N10-s lood OpenTofuga Proxmoxi masina ja kontrollime, kas su ennustus pidas paika.*
