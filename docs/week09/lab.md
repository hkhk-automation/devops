---
tags:
  - IaC
  - Docker
  - Ansible
  - Iseseisev
  - Praktikum
---

# Praktikum: infrastruktuur koodina

Sel nädalal õpid iseseisvalt brauseris. Proxmoxi ega VPN-i pole vaja.

Kohustuslik on läbida KodeKloudi Dockeri kursus, laadida repositooriumi sertifikaat või ekraanipilt ja kirjutada oma nimi README-sse. Valikulistes lisaülesannetes katsetad [loengu](lecture.md) mõtteid: mille poolest Bashi skript, Ansible ja Docker Compose erinevad.

Repositooriumi lingi leiad kursuse teadetest.

??? abstract "Õpiväljundid"

    1. Oskad selgitada, millist olekut Bash, Git, Ansible, Dockerfile ja Docker Compose haldavad.
    2. Oskad Docker Compose'i väljundist välja lugeda, millised konteinerid Compose lõi, uuesti lõi või muutmata jättis.
    3. Oskad näidata, miks konteineri olemasolu kontrolliv skript ei taga veel soovitud olekut.
    4. Oskad tekitada triivi ja võrrelda, kuidas Ansible ja Docker Compose sellele reageerivad.

## Osa 1 · KodeKloudi kursus

1. Ava kursus [Docker for the Absolute Beginner: Crash Course](https://kodekloud.com/courses/crash-course-docker-for-absolute-beginner) ja vajuta **Enroll for Free**.
2. Vaata kursuse videoid ja tee KodeKloudi laboris läbi kõik neli harjutust.
3. Laadi sertifikaat oma repositooriumi kausta `kodekloud/`: **Add file → Upload files**, failinime ette kirjuta `kodekloud/`.
4. Ava GitHubis fail `README.md`, klõpsa muutmiseks pliiatsiikoonil ja kirjuta rea `**Sinu nimi:**` järele `_vastus_` asemele oma nimi.

??? warning "Kui midagi ei tööta"
    - KodeKloud küsib maksmist: logi sisse ja vajuta uuesti **Enroll for Free**. Kui see ei aita, tee lehest ekraanipilt ja küsi õpetajalt abi.
    - Tasuta kontoga ei anta sertifikaati: laadi üles ekraanipilt kursuse lehest, millel on näha kursuse läbimine 100% ja sinu nimi.

## Töö esitamine

Repositooriumis on kaustas `kodekloud/` sertifikaat või ekraanipilt ja README-s sinu nimi. Tulemuse ja tähtaja näed Classroom 50-s.

## Lisaülesanded

Lisaülesanded on boonusülesanded. Kirjuta vastused faili `BOONUS.md`. Rida **Ennusta** tähendab, et enne käsku mõtled läbi, mis juhtub. Vastus on kokkuvolditud plokis.

### Võrdlustabel (`BOONUS.md` 2. osa)

Täida faili `BOONUS.md` 2. osa tabel. Iga tööriista kohta vasta neljale küsimusele: kas fail kirjeldab samme või tulemust, millist olekut tööriist haldab, kas korduv käivitamine on ohutu ja kas tööriist võrdleb olemasolevat olekut soovitud olekuga. Vastused leiad [loengu](lecture.md) osadest 2–4.

Lisa viimasesse veergu link oma varasema praktikumi (N2–N6) failile GitHubis. Ava fail oma repositooriumis ja kopeeri aadress brauseri aadressiribalt.

??? tip "Millist faili linkida"

    | Tööriist | Fail |
    |---|---|
    | Bash | N2 `monitor.sh` |
    | Git | N2 commit'ide leht (**Commits**) |
    | Ansible | N3 `nginx.yml` või `logid/play_recap.txt` |
    | Dockerfile | N5 `nginx/Dockerfile` |
    | Docker Compose | N6 `docker-compose.yml` |

### Docker Compose'i ja Bashi katse (`BOONUS.md` 3. osa)

Selle ja järgmise lisaülesande teed KodeKloudi labori terminalis, kus Docker on olemas. Ava selleks uuesti mõni osa 1 harjutus. Käskude väljund salvestatakse kausta `logid/` ja lõpus paned kõik logid GitHubis ühte faili.

!!! warning "Labori terminal suletakse, kui aeg saab täis"
    Kui laboriaeg hakkab lõppema, tee kohe samm [Logid GitHubi](#logid-githubi). Kui terminal suleti, ava harjutus uuesti ja loo töökaust uuesti.

#### Töökaust

Töökausta lood Compose'i faili kahe teenusega ja Bashi skripti, mis käivitab konteineri käsuga `docker run`. Kleebi terminali kogu plokk korraga:

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

Käsk `docker compose version` näitab Compose'i versiooni. Kui näed teadet `'compose' is not a docker command`, kirjuta kõigis käskudes `docker compose` asemel `docker-compose`.

#### Kaks käivitust järjest

**Ennusta:** Mis juhtub, kui käivitad sama käsu kaks korda järjest?

```bash
docker compose up -d 2>&1 | tee logid/01-up.txt
docker compose up -d 2>&1 | tee logid/02-up-uuesti.txt
```

Vasta faili `BOONUS.md` punktis 3.1: kas Compose lõi teisel käivitusel mõne konteineri ja mille järgi seda väljundist näed?

??? success "Oodatav tulemus"
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Running
    ```
    Compose võrdles faili `compose.yaml` töötavate konteineritega. Nende konfiguratsioonis ei olnud muudatust, seega ei loonud ta midagi uuesti.

#### Konteiner kustutatakse käsitsi

**Ennusta:** Kustutad konteineri `cache` käsitsi. Mida teeb Compose järgmisel käivitusel?

```bash
docker rm -f lab09-cache-1 2>&1 | tee logid/03-taastamine.txt
docker compose up -d 2>&1 | tee -a logid/03-taastamine.txt
docker compose ps
```

Vasta punktis 3.2: mida tegi Compose konteineriga `cache` ja mida konteineriga `web`?

??? success "Oodatav tulemus"
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Created
     Container lab09-cache-1  Started
    ```
    Kui näed teadet `No such container`, on konteineri nimi teine, näiteks `lab09_cache_1`. Vaata nime käsuga `docker ps`.

#### Konfiguratsiooni muudatus

**Ennusta:** Muudad failis `compose.yaml` konteineri `web` porti. Millise konteineri loob Compose uuesti?

```bash
sed -i 's/8080:80/8081:80/' compose.yaml
docker compose up -d 2>&1 | tee logid/04-port.txt
curl -s localhost:8081 | head -4
```

Vasta punktis 3.3: millise konteineri Compose uuesti lõi ja miks ainult selle? Muuda port 8081 ka oma GitHubi repositooriumi failis `compose.yaml` (fail on algmaterjalis olemas).

??? success "Oodatav tulemus"
    ```text
     Container lab09-cache-1  Running
     Container lab09-web-1  Recreated
     Container lab09-web-1  Started
    ```
    Töötava konteineri porti muuta ei saa. Compose lõi konteineri `web` uuesti, `cache` konfiguratsioon ei muutunud.

#### Sama Bashi skriptiga

**Ennusta:** Skript `run.sh` käivitab konteineri käsuga `docker run`. Mis juhtub teisel käivitusel?

```bash
bash run.sh 2>&1 | tee logid/05-run-kaks-korda.txt
bash run.sh 2>&1 | tee -a logid/05-run-kaks-korda.txt
```

Vasta punktis 3.4: mis veateate andis teine käivitus ja mida skript lõpus ikkagi kirjutas?

??? success "Oodatav tulemus"
    ```text
    docker: Error response from daemon: Conflict. The container name "/lab09-skript" is already in use by container "4f2a...".
    valmis
    ```
    Veateates on sama konteineri ID, mis tekkis esimesel käivitusel.

#### Skripti parandus

Muuda GitHubis faili `run.sh` nii, et skript kontrollib enne käsku `docker run`, kas sellise nimega konteiner on juba olemas.

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

Kopeeri parandatud skript terminali samamoodi nagu töökausta loomisel (`cat > run.sh <<'EOF'` ... `EOF`). Kustuta vana konteiner ja käivita skript kaks korda. Teisel käivitusel ei ole väljundis teadet `Conflict`.

```bash
docker rm -f lab09-skript
bash run.sh 2>&1 | tee logid/06-run-parandatud.txt
bash run.sh 2>&1 | tee -a logid/06-run-parandatud.txt
```

Vasta punktis 3.5: skript kontrollib ainult, kas sellise nimega konteiner on olemas. Too näide olukorrast, kus skript kirjutab „juba olemas“, kuigi konteiner ei vasta skriptis kirjeldatule.

??? success "Mida see näitab"
    Konteiner võib olla peatatud, loodud teisest image'ist või käivitatud teise pordisuunamisega. Skript kontrollib ainult seda, kas konteiner on olemas. Compose võrdleb konteineri konfiguratsiooni failiga ja loob konteineri vajaduse korral uuesti.

Faili `BOONUS.md` 3. osa igasse vastusesse kopeeri logist üks rida ja kirjuta selle juurde üks lause.

### Triiv Ansible'i ja Compose'iga (`BOONUS.md` 4. osa)

Jätka samas terminalis ja kaustas `~/lab09`.

#### Ansible

Paigalda Ansible ja loo playbook, mis hoiab failis `/tmp/lab09-nginx.conf` väärtust `1m`. Seejärel muuda faili käsitsi nagu loengus toodud triivi näites:

```bash
python3 -m pip install ansible-core || apt-get install -y ansible

cat > triiv.yml <<'EOF'
- hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - name: konfiguratsioonifail on soovitud olekus
      ansible.builtin.copy:
        dest: /tmp/lab09-nginx.conf
        content: |
          client_max_body_size 1m;
EOF

ansible-playbook triiv.yml
sed -i 's/1m/50m/' /tmp/lab09-nginx.conf
```

Kui Ansible'i paigaldamine KodeKloudi laboris ei õnnestu, võid selle valikulise osa teha oma arvuti WSL-i Ubuntus (`sudo apt install ansible`).

**Ennusta:** Mida näitab `--check --diff` ja kas see muudab faili?

```bash
ansible-playbook triiv.yml --check --diff 2>&1 | tee logid/07-triiv-ansible.txt
cat /tmp/lab09-nginx.conf
ansible-playbook triiv.yml 2>&1 | tee -a logid/07-triiv-ansible.txt
cat /tmp/lab09-nginx.conf
```

Vasta faili `BOONUS.md` punktis 4.1: mis oli failis pärast käivitust võtmega `--check` ja mis pärast tavalist käivitust?

??? success "Oodatav tulemus"
    `--check --diff` näitab ridu `-client_max_body_size 50m;` ja `+client_max_body_size 1m;`, aga failis on endiselt `50m`. Tavaline käivitus taastab failis väärtuse `1m`.

#### Docker Compose

Muuda töötava konteineri `web` avalehte otse konteineri sees:

```bash
docker compose exec web sh -c 'echo "KÄSITSI MUUDETUD" > /usr/share/nginx/html/index.html'
curl -s localhost:8081 2>&1 | tee logid/08-triiv-konteiner.txt
```

**Ennusta:** Ansible taastas faili sisu. Kas `docker compose up -d` taastab nginx'i avalehe? Kirjuta ennustus faili `BOONUS.md` punkti 4.2 välja „Ennustus“ enne järgmisi käske.

```bash
docker compose up -d 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
docker compose up -d --force-recreate 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
```

Punkti 4.2 välja „Tulemus“ kirjuta: mida näitas `curl` pärast tavalist `up -d` ja mida pärast `--force-recreate`? Millist olekut Compose haldab ja millist mitte?

??? success "Mida see näitab"
    Pärast `up -d` on avalehel endiselt `KÄSITSI MUUDETUD`. Compose võrdleb konteineri konfiguratsiooni (image, pordid, keskkonnamuutujad) failiga `compose.yaml`. Faile konteineri sees ta ei võrdle. `--force-recreate` loob konteineri image'ist uuesti ja käsitsi tehtud muudatus kaob.

    Ansible ja Compose on mõlemad deklaratiivsed, aga nad haldavad eri olekut: Ansible haldab selles näites faili sisu, Compose aga konteinerite olemasolu ja konfiguratsiooni.

#### Logid GitHubi

Koonda kõik logid ühte faili. Käsk jätab välja image'ite allalaadimise read:

```bash
for f in logid/0*.txt; do
  echo "===== $(basename $f) ====="
  grep -v -E 'Pull|Waiting|Download|Extract|Verifying|Already exists' "$f"
done > koik.txt
cat koik.txt
```

Kopeeri väljund terminalist. Vali GitHubis **Add file → Create new file**, kirjuta failinimeks `logid/koik.txt`, kleebi sisu ja vajuta **Commit changes**. Failis peab olema kaheksa rida, mis algavad märkidega `=====`.

Kui pead jätkama uues terminalis, salvesta enne praeguse terminali sulgumist senised logid GitHubi faili `logid/koik.txt`. Uues terminalis tehtud sammude logid salvesta faili `logid/koik2.txt`. Automaatkontroll loeb mõlemat faili.

### 12-Factor (`BOONUS.md` lisa A)

Loe [12-Factor App](https://12factor.net/) peatükid **III Config**, **IV Backing services** ja **V Build, release, run**. Täida faili `BOONUS.md` lisa A tabel: kas Docker Compose ja Ansible aitavad seda põhimõtet järgida? Kirjuta igasse lahtrisse „jah“, „osaliselt“ või „ei“ ja üks lause põhjenduseks.

### Öine triivikontroll (`BOONUS.md` lisa B)

Kirjuta skript `triivikontroll.sh`, mis käivitab `ansible-playbook triiv.yml --check`. Kui väljundis on `changed=0`, kirjutab skript `triivi ei ole` ja lõpetab väljumiskoodiga 0. Muul juhul kirjutab skript `TRIIV!` ja lõpetab väljumiskoodiga 1. Proovi mõlemat olukorda.

Pane skript GitHubi faili `lisa/triivikontroll.sh` ja väljund faili `logid/lisa-b.txt`. Lisa faili `BOONUS.md` crontab'i rida (`crontab -e`), mis käivitab skripti igal ööl kell 3.
