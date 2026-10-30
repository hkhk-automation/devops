---
tags:
  - IaC
  - Docker
  - Ansible
  - Iseseisev
  - Praktikum
---

# N9 · Praktikum: infrastruktuur koodina (iseseisev)

Täna töötad üksi, brauseris. Proxmoxi ja VPN-i pole vaja.

| Osa | Mida teed | Aeg |
|---|---|---|
| 0 | Loe [loeng](lecture.md) | 60 min |
| 1 | KodeKloudi Docker'i kursus | 45 min |
| 2 | Täida võrdlustabel | 30 min |
| 3 | Docker Compose'i katse | 50 min |
| 4 | Tekita triiv | 30 min |
| 5 | Ennustus ja esitamine | 15 min |

*Tabel 9.9. Tänane töö*

Vastused kirjutad oma Lab 09 repo faili `README.md`: asenda iga `_vastus_` oma tekstiga. Repo saad Classroom 50 lingiga, mis on kursuse teadetes.

??? abstract "Õpiväljundid"

    1. Paigutad iga seni kasutatud tööriista imperatiivse ja deklaratiivse skaalale
    2. Näed Docker Compose'i väljundist, kuidas tööriist ühtlustab tegeliku oleku soovitud olekuga
    3. Näitad, miks lihtne bash-skript ei ole idempotentne, ja parandad selle
    4. Tekitad triivi ja näed, mida Ansible ja Compose sellega teevad

---

## Osa 1 · KodeKloudi kursus

1. Ava [Docker for the Absolute Beginner: Crash Course](https://kodekloud.com/courses/crash-course-docker-for-absolute-beginner) ja vajuta **Enroll for Free**.
2. Vaata videod ja tee kõik neli laborit.
3. Laadi sertifikaat (või ekraanipilt, kus on 100% ja sinu nimi) oma repo kausta `kodekloud/`: **Add file → Upload files**, failinime ette kirjuta `kodekloud/`.

??? warning "Ei tööta?"
    - **KodeKloud küsib raha:** logi sisse ja vajuta uuesti **Enroll for Free**. Kui ikka küsib, tee sellest ekraanipilt ja kirjuta õpetajale.
    - **Sertifikaati ei anta:** tee ekraanipilt kursuse lehest, kus on näha 100%.

---

## Osa 2 · Võrdlustabel

Ava README-s **Osa 2**. Iga tööriista kohta kirjuta lühike vastus (`deklaratiivne`, `jah`, `ei`) ja viimasesse veergu **link oma labori failile** GitHubis.

Lingi saad nii: ava fail oma Lab 02-07 repos ja kopeeri brauseri aadressiriba.

??? tip "Millise faili lingin?"

    | Tööriist | Fail |
    |---|---|
    | Bash | Lab 02 `monitor.sh` |
    | Git | Lab 02 commit'ide leht (**Commits**) |
    | Ansible | Lab 03 `nginx.yml` või `logid/play_recap.txt` |
    | Dockerfile | Lab 05 `nginx/Dockerfile` |
    | Docker Compose | Lab 06 `docker-compose.yml` |
    | GitHub Actions | Lab 07 `.github/workflows/ci.yml` |

Põhjendusi ei kirjuta. N10 alguses küsin igaühelt suuliselt ühe lahtri kohta: „miks just nii?“

---

## Osa 3 · Docker Compose'i katse

Kasuta KodeKloudi labori terminali (ava mõni Osa 1 labor). Iga käsu väljund läheb faili kausta `logid/`, hiljem kopeerid need GitHubi.

### 3.1 Valmista ette

Kleebi terminali tervikuna:

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

??? warning "Ei tööta? `'compose' is not a docker command`"
    Terminalis on vana Compose. Kirjuta kõigis käskudes `docker-compose` (sidekriipsuga) `docker compose` asemel.

### 3.2 Käivita kaks korda

```bash
docker compose up -d 2>&1 | tee logid/01-up.txt
docker compose up -d 2>&1 | tee logid/02-up-uuesti.txt
```

Esimene kord loob konteinerid, teine kord ei tee midagi.

??? success "Oodatav tulemus"
    Esimene: `Created` ja `Started`. Teine:
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Running
    ```
    Compose võrdles faili ja jooksvaid konteinereid, need klappisid. See on Compose'i `changed=0`.

### 3.3 Kustuta üks konteiner

```bash
docker rm -f lab09-cache-1 2>&1 | tee logid/03-taastamine.txt
docker compose up -d 2>&1 | tee -a logid/03-taastamine.txt
```

Compose loob puuduva uuesti ja `web`-i ei puutu.

??? success "Oodatav tulemus"
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Created
     Container lab09-cache-1  Started
    ```

??? warning "Ei tööta? `No such container`"
    Konteineri nimi on teine (nt `lab09_cache_1`). Vaata `docker ps` ja kasuta seda nime.

### 3.4 Muuda porti

```bash
sed -i 's/8080:80/8081:80/' compose.yaml
docker compose up -d 2>&1 | tee logid/04-port.txt
```

Compose viskab `web` konteineri ära ja teeb uue, `cache` jääb alles.

??? success "Oodatav tulemus"
    ```text
     Container lab09-cache-1  Running
     Container lab09-web-1  Recreated
     Container lab09-web-1  Started
    ```

Muuda port ka oma GitHubi repo `compose.yaml`-is 8081 peale (pliiats ✏️).

### 3.5 Sama asi bash-skriptiga

```bash
bash run.sh 2>&1 | tee logid/05-run-kaks-korda.txt
bash run.sh 2>&1 | tee -a logid/05-run-kaks-korda.txt
```

Teine kord tuleb viga, aga skript ütleb ikka `valmis`.

??? success "Oodatav tulemus"
    ```text
    docker: Error response from daemon: Conflict. The container name "/lab09-skript" is already in use by container "4f2a...".
    valmis
    ```

### 3.6 Paranda skript

Muuda oma GitHubi repos `run.sh` nii, et see kontrollib enne, kas konteiner on olemas.

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

Kopeeri parandatud skript terminali (`cat > run.sh <<'EOF'` ... `EOF`) ja käivita kaks korda:

```bash
docker rm -f lab09-skript
bash run.sh 2>&1 | tee logid/06-run-parandatud.txt
bash run.sh 2>&1 | tee -a logid/06-run-parandatud.txt
```

Teine kord: `lab09-skript on juba olemas`, viga ei tule.

### 3.7 Logid GitHubi

Iga faili kohta: terminalis `cat logid/01-up.txt`, kopeeri väljund, GitHubis **Add file → Create new file**, nimeks `logid/01-up.txt`, kleebi, **Commit changes**. Tee seda failidega `01` kuni `06`.

Siis vasta README-s küsimustele **3.1-3.4**: kopeeri logist üks rida ja kirjuta üks lause.

!!! warning "Labori terminal kustub, kui aeg saab täis"
    Kopeeri logid kohe GitHubi. Kui terminal kadus, ava labor uuesti ja korda sammu 3.1.

---

## Osa 4 · Tekita triiv

Jätka samas terminalis kaustas `~/lab09`.

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

Sa muutsid faili käsitsi (`50m`). `--check --diff` näitab vahet ega muuda midagi. Tavaline jooks kirjutab faili tagasi `1m`-ks.

??? success "Oodatav tulemus"
    ```text
    -client_max_body_size 50m;
    +client_max_body_size 1m;
    ```
    ja lõpus `cat` näitab `1m`.

??? warning "Ei tööta? `pip` ja `apt-get` puuduvad"
    Tee see osa oma arvuti WSL Ubuntus: `sudo apt install ansible`, siis samad käsud.

### 4.2 Konteiner

```bash
docker compose exec web sh -c 'echo "MATI PARANDAS" > /usr/share/nginx/html/index.html'
curl -s localhost:8081 2>&1 | tee logid/08-triiv-konteiner.txt
docker compose up -d 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
docker compose up -d --force-recreate 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
```

Tavaline `up -d` jätab käsitsi muudatuse alles. `--force-recreate` teeb uue konteineri ja muudatus kaob.

??? success "Oodatav tulemus"
    Kaks korda `MATI PARANDAS`, viimane kord `Welcome to nginx!`.

Kopeeri `logid/07` ja `logid/08` GitHubi (nagu 3.7) ja vasta README-s **4.1-4.2**.

---

## Osa 5 · Ennustus ja esitamine

README **Osa 5**: kirjuta 3-5 lauset, **mida teeb OpenTofu teisiti kui Ansible**. Oma sõnadega, vähemalt 40 sõna. N10 alguses loed selle ette.

Lõpuks otsi README-st (Ctrl+F) `_vastus_`: Osades 2-5 ei tohi seda olla. Automaatkontrolli tulemus on repo **Actions** all.

??? note "Automaatkontroll (100 punkti)"

    | Kontroll | Punktid |
    |---|---|
    | Failid olemas (`logid/01`-`08`) | 5 |
    | Nimi ja vastused Osades 3-4 | 5 |
    | KodeKloudi sertifikaat või ekraanipilt | 10 |
    | Võrdlustabel ja 6 linki oma repodesse | 15 |
    | `compose.yaml` korras | 10 |
    | Teine `up`: `Running` | 10 |
    | Taastamine: `Created`/`Started` | 10 |
    | Skript kaks korda: `Conflict` sama konteineriga | 10 |
    | Parandatud skript | 5 |
    | Triiv Ansible'iga | 10 |
    | Triiv konteineris | 5 |
    | Ennustus | 5 |

---

## Lisaülesanded

??? example "A · 12-Factor (kerge)"
    Loe [12-Factor App](https://12factor.net/) peatükid **III Config**, **IV Backing services** ja **V Build, release, run**. Täida README tabel **Lisa A**: kas Compose, GitHub Actions ja Ansible aitavad seda põhimõtet järgida? Iga lahter: jah / osaliselt / ei + üks lause.

    Näide: Docker Compose, IV: **jah**, `cache` on eraldi teenus, mille saab teise vastu vahetada ilma rakenduse koodi muutmata.

??? example "B · Öine triivikontroll (keskmine)"
    Kirjuta skript `triivikontroll.sh`, mis jooksutab `ansible-playbook triiv.yml --check`. Kui väljundis on `changed=0`, trükib `triivi ei ole` ja väljub koodiga 0, muidu trükib `TRIIV!` ja väljub koodiga 1. Testi mõlemat olukorda.

    Pane skript GitHubi `lisa/triivikontroll.sh` ja väljund `logid/lisa-b.txt`. README-sse: kuidas paneksid selle igal ööl jooksma? (Vihje: N7 `on: schedule`.)

??? example "C · Kubernetes'e kontroller (raskem)"
    Loe [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/) (~10 min, algab termostaadi näitega). README-sse: kuidas on kontroller sarnane `docker compose up -d`-ga ja mis on vahe?

    Vihje: Compose ühtlustab ainult siis, kui sina käivitad `up`. Kubernetes teeb seda pidevalt.

---

*N10-s paned OpenTofu'ga Proxmoxi masina püsti ja vaatame, kuidas su ennustus klappis.*
