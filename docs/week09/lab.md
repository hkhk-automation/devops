---
tags:
  - IaC
  - Docker
  - Ansible
  - Iseseisev
  - Praktikum
---

# N9 · Praktikum: infrastruktuur koodina (iseseisev)

Täna töötad üksi ja kõik tööd saab teha brauseris. Proxmoxi ega VPN-i sul täna vaja ei lähe.

| Osa | Mida teed | Aeg |
|---|---|---|
| 0 | Loed [loengu](lecture.md) läbi | 60 min |
| 1 | Läbid KodeKloudi Docker'i kursuse | 45 min |
| 2 | Täidad võrdlustabeli | 30 min |
| 3 | Teed Docker Compose'iga katse | 50 min |
| 4 | Tekitad triivi | 30 min |
| 5 | Kirjutad ennustuse ja esitad töö | 15 min |

*Tabel 9.9. Tänase töö osad ja ajakulu*

Vastused kirjutad oma Lab 09 repo faili `README.md`. Asenda seal iga `_vastus_` oma tekstiga. Lingi, millega repo saad, leiad kursuse teadetest.

??? abstract "Õpiväljundid"

    1. Oskad paigutada iga seni kasutatud tööriista imperatiivse ja deklaratiivse lähenemise skaalale.
    2. Näed Docker Compose'i väljundist, kuidas tööriist viib tegeliku oleku kooskõlla soovitud olekuga.
    3. Oskad näidata, miks lihtne bash-skript ei ole idempotentne, ja oskad selle parandada.
    4. Oskad tekitada triivi ja näed, mida Ansible ja Compose sellega teevad.

---

## Osa 1 · KodeKloudi kursus

1. Ava kursus [Docker for the Absolute Beginner: Crash Course](https://kodekloud.com/courses/crash-course-docker-for-absolute-beginner) ja vajuta nuppu **Enroll for Free**.
2. Vaata videod läbi ja tee kõik neli laborit.
3. Kui kursus on läbitud, laadi sertifikaat oma repo kausta `kodekloud/`. Vali **Add file → Upload files** ja kirjuta failinime ette `kodekloud/`. Kui sertifikaati ei anta, laadi üles ekraanipilt, millel on näha 100% ja sinu nimi.

??? warning "Mis teha, kui midagi ei tööta?"
    - Kui KodeKloud küsib maksmist, logi sisse ja vajuta uuesti **Enroll for Free**. Kui see ei aita, tee lehest ekraanipilt ja kirjuta õpetajale.
    - Kui tasuta kontoga sertifikaati ei anta, tee ekraanipilt kursuse lehest, millel on näha 100%.

---

## Osa 2 · Võrdlustabel

Ava README-s **Osa 2**. Kirjuta iga tööriista kohta lühike vastus (näiteks `deklaratiivne`, `jah` või `ei`). Viimasesse veergu pane link oma labori failile GitHubis.

Lingi saad nii: ava fail oma Lab 02-07 repos ja kopeeri brauseri aadressiribalt selle aadress.

??? tip "Millise faili lingin?"

    | Tööriist | Fail |
    |---|---|
    | Bash | Lab 02 `monitor.sh` |
    | Git | Lab 02 commit'ide leht (**Commits**) |
    | Ansible | Lab 03 `nginx.yml` või `logid/play_recap.txt` |
    | Dockerfile | Lab 05 `nginx/Dockerfile` |
    | Docker Compose | Lab 06 `docker-compose.yml` |
    | GitHub Actions | Lab 07 `.github/workflows/ci.yml` |

Põhjendusi README-sse kirjutama ei pea. N10 alguses küsin igaühelt suuliselt ühe lahtri kohta, miks ta nii vastas.

---

## Osa 3 · Docker Compose'i katse

Selle osa teed KodeKloudi labori terminalis. Ava selleks uuesti mõni Osa 1 labor. Iga käsu väljund salvestatakse kausta `logid/`, ja hiljem kopeerid need failid GitHubi.

### 3.1 Valmista töökaust ette

Kleebi terminali kogu allolev plokk korraga:

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

docker compose version
```

??? warning "Mis teha, kui näed teadet `'compose' is not a docker command`?"
    See tähendab, et terminalis on Compose'i vana versioon. Kirjuta siis kõigis käskudes `docker compose` asemel `docker-compose` (sidekriipsuga).

### 3.2 Käivita teenused kaks korda

```bash
docker compose up -d 2>&1 | tee logid/01-up.txt
docker compose up -d 2>&1 | tee logid/02-up-uuesti.txt
```

Esimesel korral loob Compose konteinerid. Teisel korral ei tee ta midagi, sest kõik on juba olemas.

??? success "Oodatav tulemus"
    Esimese käsu väljundis on read `Created` ja `Started`. Teise käsu väljund on selline:
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Running
    ```
    Compose võrdles faili jooksvate konteineritega ja nägi, et need klapivad. Ansible'is näitaks sama olukorda `changed=0`.

### 3.3 Kustuta üks konteiner

```bash
docker rm -f lab09-cache-1 2>&1 | tee logid/03-taastamine.txt
docker compose up -d 2>&1 | tee -a logid/03-taastamine.txt
```

Compose loob puuduva konteineri uuesti, aga konteinerit `web` ta ei puutu.

??? success "Oodatav tulemus"
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Created
     Container lab09-cache-1  Started
    ```

??? warning "Mis teha, kui näed teadet `No such container`?"
    Sinu terminalis on konteineril teine nimi, näiteks `lab09_cache_1`. Vaata nime käsuga `docker ps` ja kasuta seda.

### 3.4 Muuda porti

```bash
sed -i 's/8080:80/8081:80/' compose.yaml
docker compose up -d 2>&1 | tee logid/04-port.txt
```

Jooksva konteineri porti muuta ei saa. Seepärast eemaldab Compose konteineri `web` ja loob selle asemele uue. Konteiner `cache` jääb alles, sest selle kirjeldus ei muutunud.

??? success "Oodatav tulemus"
    ```text
     Container lab09-cache-1  Running
     Container lab09-web-1  Recreated
     Container lab09-web-1  Started
    ```

Muuda port 8081 peale ka oma GitHubi repo failis `compose.yaml` (pliiatsi ✏️ nupuga).

### 3.5 Tee sama bash-skriptiga

```bash
bash run.sh 2>&1 | tee logid/05-run-kaks-korda.txt
bash run.sh 2>&1 | tee -a logid/05-run-kaks-korda.txt
```

Teisel käivitamisel tuleb veateade, aga skript kirjutab lõpus ikkagi `valmis`.

??? success "Oodatav tulemus"
    ```text
    docker: Error response from daemon: Conflict. The container name "/lab09-skript" is already in use by container "4f2a...".
    valmis
    ```

### 3.6 Paranda skript

Muuda oma GitHubi repos faili `run.sh` nii, et skript kontrollib enne käivitamist, kas konteiner on juba olemas.

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

Kopeeri parandatud skript terminali samamoodi nagu sammus 3.1 (`cat > run.sh <<'EOF'` ... `EOF`). Seejärel kustuta vana konteiner ja käivita skript kaks korda:

```bash
docker rm -f lab09-skript
bash run.sh 2>&1 | tee logid/06-run-parandatud.txt
bash run.sh 2>&1 | tee -a logid/06-run-parandatud.txt
```

Teisel korral kirjutab skript `lab09-skript on juba olemas` ja veateadet ei tule.

### 3.7 Kopeeri logid GitHubi

Tee iga logifailiga järgmist:

1. Käivita terminalis `cat logid/01-up.txt` ja kopeeri väljund.
2. Vali GitHubis **Add file → Create new file**, kirjuta failinimeks `logid/01-up.txt`, kleebi sisu ja vajuta **Commit changes**.

Korda seda failidega `01` kuni `06`. Seejärel vasta README-s küsimustele 3.1-3.4. Igas vastuses kopeeri logist üks rida ja kirjuta selle juurde üks lause.

!!! warning "Labori terminal kaob, kui aeg saab täis"
    Kopeeri logid GitHubi kohe pärast iga osa. Kui terminal kadus, ava labor uuesti ja tee samm 3.1 uuesti.

---

## Osa 4 · Tekita triiv

Jätka samas terminalis ja samas kaustas `~/lab09`.

### 4.1 Ansible

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
sed -i 's/1m/50m/' /tmp/lab09-nginx.conf
ansible-playbook triiv.yml --check --diff 2>&1 | tee logid/07-triiv-ansible.txt
ansible-playbook triiv.yml 2>&1 | tee -a logid/07-triiv-ansible.txt
cat /tmp/lab09-nginx.conf
```

Esmalt loob Ansible faili. Seejärel muudad faili käsitsi (`50m`), nagu Mati loengus. Käsk `--check --diff` näitab erinevust, aga ei muuda midagi. Tavaline käivitus kirjutab faili tagasi väärtusele `1m`.

??? success "Oodatav tulemus"
    Väljundis on need kaks rida:
    ```text
    -client_max_body_size 50m;
    +client_max_body_size 1m;
    ```
    Viimane käsk `cat` näitab, et failis on jälle `1m`.

??? warning "Mis teha, kui `pip` ja `apt-get` ei tööta?"
    Tee see osa oma arvuti WSL Ubuntus. Paigalda Ansible käsuga `sudo apt install ansible` ja käivita samad käsud.

### 4.2 Konteiner

```bash
docker compose exec web sh -c 'echo "MATI PARANDAS" > /usr/share/nginx/html/index.html'
curl -s localhost:8081 2>&1 | tee logid/08-triiv-konteiner.txt
docker compose up -d 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
docker compose up -d --force-recreate 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
```

Kõigepealt muudad konteineri sees avalehte. Tavaline `up -d` jätab selle muudatuse alles, sest konteineri kirjeldus ei muutunud. Võti `--force-recreate` loob uue konteineri ja käsitsi tehtud muudatus kaob.

??? success "Oodatav tulemus"
    Kaks esimest `curl` käsku näitavad `MATI PARANDAS`. Viimane `curl` näitab nginx'i lehte `Welcome to nginx!`.

Kopeeri failid `logid/07` ja `logid/08` GitHubi samamoodi nagu sammus 3.7 ja vasta README-s küsimustele 4.1 ja 4.2.

---

## Osa 5 · Ennustus ja esitamine

Kirjuta README osasse 5 vähemalt 40 sõna (3-5 lauset) selle kohta, mida teeb OpenTofu teisiti kui Ansible. Kirjuta oma sõnadega, sest N10 alguses loed ennustuse klassile ette.

Lõpuks otsi README-st (Ctrl+F) sõna `_vastus_`. Osades 2-5 ei tohi seda enam olla. Automaatkontrolli tulemuse näed oma repo vahekaardil **Actions**.

??? note "Automaatkontroll (100 punkti)"

    | Kontroll | Punktid |
    |---|---|
    | Failid `logid/01`-`08` on olemas | 5 |
    | Nimi ja Osade 3-4 vastused on kirjas | 5 |
    | KodeKloudi sertifikaat või ekraanipilt on üles laaditud | 10 |
    | Võrdlustabel on täidetud ja seal on 6 linki sinu repodesse | 15 |
    | `compose.yaml` on korrektne | 10 |
    | Teise `up` käsu väljundis on `Running` | 10 |
    | Taastamise väljundis on `Created` või `Started` | 10 |
    | Skripti teisel käivitamisel tuli `Conflict` sama konteineriga | 10 |
    | Skript on parandatud | 5 |
    | Ansible'i triivi logi on olemas | 10 |
    | Konteineri triivi logi on olemas | 5 |
    | Ennustus on kirjutatud | 5 |

---

## Lisaülesanded

??? example "A · 12-Factor (kerge)"
    Loe [12-Factor App](https://12factor.net/) lehelt peatükid **III Config**, **IV Backing services** ja **V Build, release, run**. Täida README tabel **Lisa A**: kas Compose, GitHub Actions ja Ansible aitavad seda põhimõtet järgida? Igasse lahtrisse kirjuta „jah“, „osaliselt“ või „ei“ ja üks lause põhjenduseks.

    Näide: Docker Compose ja IV Backing services: **jah**, sest `cache` on eraldi teenus, mille saab teise vastu vahetada ilma rakenduse koodi muutmata.

??? example "B · Öine triivikontroll (keskmine)"
    Kirjuta skript `triivikontroll.sh`, mis käivitab käsu `ansible-playbook triiv.yml --check`. Kui väljundis on `changed=0`, kirjutab skript `triivi ei ole` ja lõpetab koodiga 0. Muul juhul kirjutab skript `TRIIV!` ja lõpetab koodiga 1. Proovi mõlemat olukorda.

    Pane skript GitHubi faili `lisa/triivikontroll.sh` ja selle väljund faili `logid/lisa-b.txt`. Kirjuta README-sse, kuidas paneksid skripti igal ööl käima. Vihje: meenuta N7-st võtit `on: schedule`.

??? example "C · Kubernetes'e kontroller (raskem)"
    Loe Kubernetes'e dokumentatsioonist lehte [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/). Lugemine võtab umbes 10 minutit ja leht algab sama termostaadi näitega nagu loeng. Kirjuta README-sse, mille poolest on kontroller sarnane käsuga `docker compose up -d` ja mille poolest erineb.

    Vihje: Compose viib oleku kooskõlla ainult siis, kui sina käivitad `up`. Kubernetes teeb seda pidevalt.

---

*N10-s lood OpenTofu'ga Proxmoxi masina ja vaatame koos, kuidas sinu ennustus läks.*
