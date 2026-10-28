---
tags:
  - IaC
  - Docker
  - Ansible
  - Iseseisev
  - Praktikum
---

# Infrastruktuur koodina: mõtteviis · Praktikum (iseseisev)

**Kestus:** ~3 h praktikumi + ~60 min [loengu](lecture.md) lugemist. Lisaülesanded neile, kes tahavad rohkem.
**Eeldused:** loeng läbi loetud. Sinu varasemad laborirepod (Lab 02-07) on GitHubis, sest Osa 2-s viitad neile.
**Keskkond:** brauser. Docker'i katsed teed KodeKloudi tasuta laborikeskkonnas, vastused ja logid kirjutad GitHubi veebis. Proxmoxi ega VPN-i täna vaja ei ole.

Täna töötad üksi ja õpetajat kõrval ei ole. Iga sammu järel on kirjas, mida peaksid nägema. Kui näed midagi muud, vaata lehe lõpus olevat tabelit **Veaotsing**.

---

!!! abstract "Õpiväljundid"

    Selle praktikumi lõpuks sa:

    1. Kordad Docker'i põhikäsud KodeKloudi kursusel ja saad selle eest tõendi
    2. Paigutad iga seni kasutatud tööriista imperatiivse ja deklaratiivse skaalale ja näitad seda oma laborifailiga
    3. Näed Docker Compose'i väljundist, kuidas tööriist ühtlustab tegeliku oleku soovitud olekuga
    4. Näitad, miks lihtne bash-skript ei ole idempotentne, ja parandad selle
    5. Tekitad triivi ja näed, mida Ansible ja Docker Compose sellega järgmisel jooksul teevad
    6. Paned kirja ennustuse, mida N10-s kontrollime

---

## Tänane plaan

| Aeg | Osa | Mida teed |
|---|---|---|
| 0-60 min | Loeng | Loe [loeng](lecture.md), vasta „Kontrolli ennast“ küsimustele vihikus |
| 60-70 min | Osa 0 | Võta ülesanne vastu, tee KodeKloudi konto |
| 70-115 min | Osa 1 | KodeKloudi Docker'i kursus |
| 115-145 min | Osa 2 | Võrdlustabel oma failide linkidega |
| 145-195 min | Osa 3 | Ühtlustamise katse KodeKloudi terminalis |
| 195-225 min | Osa 4 | Tekita triiv: Ansible ja konteiner |
| 225-240 min | Osa 5-6 | Ennustus ja esitamine |

*Tabel 9.9. Ajakava. Pause tee siis, kui vaja.*

---

## Osa 0 · Repo ja KodeKloudi konto

### 0.1 Võta ülesanne vastu

Ava [Classroom 50](https://classroom50.org/hkhk-automation/it24-automatiseerimine/assignments) ja võta vastu **Lab 09 - IaC mõtteviis (iseseisev)**. Saad oma repo, kus on `README.md`, `compose.yaml`, `run.sh`, kaust `logid/` ja kaust `lisa/`.

Täna töötad repoga **GitHubi veebis**: faili muutmiseks ava fail ja vajuta pliiatsit ✏️, uue faili jaoks **Add file → Create new file**, pildi jaoks **Add file → Upload files**. Iga muudatuse lõpus **Commit changes** otse `main`-i.

### 0.2 KodeKloudi konto

Ava [Docker for the Absolute Beginner: Crash Course](https://kodekloud.com/courses/crash-course-docker-for-absolute-beginner) ja vajuta **Enroll for Free**. Logi sisse oma GitHubi või kooli Google'i kontoga.

✅ **Kontrollpunkt:** kursuse leht avaneb ja näed tundide nimekirja.

---

## Osa 1 · KodeKloudi Docker'i kursus

Kursus on umbes 30 minutit videot ja neli laborit: `docker run`, `docker ps` ja `stop`, `docker rm` ja `rmi`, `docker pull` ja `exec`. Enamik on sulle N5-st tuttav. Seekord vaata iga käsku N9 pilguga: kas see käsk on imperatiivne või deklaratiivne? Mis juhtub, kui käivitad selle kaks korda?

1. Vaata videod läbi ja tee kõik neli laborit. Laboris avaneb brauseris terminal, kus Docker on olemas.
2. Kui kursus on lõpetatud, laadi alla sertifikaat. Kui tasuta kontoga sertifikaati ei anta, tee ekraanipilt kursuse lehest, kus on näha 100% ja sinu nimi.
3. Laadi fail oma Lab 09 reposse kausta `kodekloud/`: **Add file → Upload files**, lohista fail sisse, kirjuta failinime ette `kodekloud/` (nt `kodekloud/sertifikaat.pdf`) ja **Commit changes**.

!!! success "Oodatav tulemus"
    Repos on kaust `kodekloud/` ja selles `.pdf`, `.png` või `.jpg` fail.

!!! info "KodeKloudi terminal on ajutine"
    Labori terminal kustub, kui labor lõpeb või aeg saab täis. Osades 3-4 kasutad sama terminali oma katseteks. Kopeeri iga logi GitHubi kohe, kui osa on tehtud, mitte alles päeva lõpus.

---

## Osa 2 · Võrdlustabel

Ava `README.md` ja leia **Osa 2**. Tabelis on kuus tööriista ja kolm küsimust. Lahtritesse lühike vastus (`deklaratiivne`, `jah`, `ei` jne). Viimasesse veergu **Tõend** paned lingi oma labori failile GitHubis.

### 2.1 Leia oma failid

Ava GitHubis oma Lab 02-07 repod. Iga tööriista kohta leia fail, mis sinu vastust kõige paremini näitab, ja kopeeri brauseri aadressiriba. Kui tahad näidata konkreetset rida, kliki rea numbril: link saab lõppu `#L12`.

| Tööriist | Kust otsida | Mida vaadata |
|---|---|---|
| Bash | Lab 02 `monitor.sh` | kas skript kontrollib enne midagi? |
| Git | Lab 02 commit'ide ajalugu (**Commits**) | kus Git oma ajalugu hoiab? |
| Ansible | Lab 03 `logid/play_recap.txt` või `nginx.yml` | `changed=0` |
| Dockerfile | Lab 05 `nginx/Dockerfile` | `RUN` read: sammud või tulemus? |
| Docker Compose | Lab 06 `docker-compose.yml` | sammud või tulemus? |
| GitHub Actions | Lab 07 `.github/workflows/ci.yml` või mõni **Actions** jooks | `on:` ja `run:` |

*Tabel 9.10. Kust iga tööriista kohta tõendit leiad.*

Link peab viima **sinu enda** repo juurde (repo nime lõpus on sinu GitHubi kasutajanimi). Automaatkontroll vaatab seda.

### 2.2 Täida tabel

Toetu loengu osadele 2-8. Ära kopeeri tabelit 9.6 pimesi: mõni vastus sõltub sellest, kuidas **sina** oma faili kirjutasid. Kui su `monitor.sh` kontrollib enne `mkdir`-i, kas kaust on olemas, on see idempotentsem kui Märteni oma.

!!! warning "Põhjendus on suuline"
    Põhjendusi README-sse kirjutama ei pea. N10 alguses küsib õpetaja igaühelt ühe-kaks lahtrit: „miks sa kirjutasid Compose'i juurde *jah*? Näita oma failist.“ Valmistu selleks: iga vastuse kohta pead oskama ühe lausega öelda, mida oma failis nägid.

!!! success "Oodatav tulemus"
    Osa 2-s ei ole ühtegi `_vastus_` sõna alles ja igas tabelireas on link `https://github.com/hkhk-automation/...`.

---

## Osa 3 · Ühtlustamise katse

Nüüd vaatad oma silmaga, mida tähendab loengu joonis 9.2. Kasuta KodeKloudi labori terminali (ava uuesti mõni Osa 1 labor, kui eelmine on kinni).

### 3.1 Valmista ette

Kontrolli, kumb Compose terminalis on:

```bash
docker compose version || docker-compose version
```

Kui esimene töötab, kasuta allpool `docker compose`. Kui töötab ainult teine, kirjuta igal pool `docker-compose` (sidekriipsuga). Väljund näeb siis veidi teistsugune välja (`Creating lab09_web_1 ... done`), aga mõte on sama.

Tee töökaust ja kopeeri sinna oma repo `compose.yaml` ja `run.sh`. Kõige lihtsam on kleepida see plokk terminali tervikuna:

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
# Imperatiivne: "käivita konteiner". Skript ei vaata, mis juba olemas on.
docker run -d --name lab09-skript -p 8090:80 nginx:1.27-alpine
echo "valmis"
EOF

ls
```

Kausta nimi `lab09` on oluline: Compose paneb konteineritele nimed kausta järgi (`lab09-web-1`).

!!! info "Miks `2>&1 | tee`?"
    Docker Compose kirjutab oma teated veavoogu (stderr). `2>&1` suunab need tavaväljundisse ja `tee` näitab väljundi ekraanil ning kirjutab samal ajal faili. Ilma `2>&1`-ta jääb logifail tühjaks.

### 3.2 Esimene `up`

Kaks teenust: `web` (nginx, port 8080) ja `cache` (redis). See on soovitud olek. Käivita:

```bash
docker compose up -d 2>&1 | tee logid/01-up.txt
```

!!! success "Oodatav tulemus"
    Kõigepealt laaditakse image'id alla (`Pulling`, `Pulled`), siis umbes nii:

    ```text
     Network lab09_default  Created
     Container lab09-web-1  Created
     Container lab09-cache-1  Created
     Container lab09-web-1  Started
     Container lab09-cache-1  Started
    ```

    `docker compose ps` näitab kahte konteinerit olekus `Up`, `curl -s localhost:8080 | head -4` näitab nginx'i lehte.

### 3.3 Teine `up`, midagi muutmata

```bash
docker compose up -d 2>&1 | tee logid/02-up-uuesti.txt
```

!!! success "Oodatav tulemus"
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Running
    ```

    (`docker-compose` puhul `lab09_web_1 is up-to-date`.) Ühtegi `Created` ega `Started` rida pole. Compose võrdles faili ja tegelikkust, nägi, et need klapivad, ega teinud midagi. See on Compose'i `changed=0`.

### 3.4 Kustuta konteiner käsitsi

Nüüd tekitad meelega erinevuse soovitud ja tegeliku oleku vahele, nagu keegi, kes logib serverisse ja peatab teenuse. Vaata `docker ps` väljundist `cache` konteineri nimi (`lab09-cache-1` või `lab09_cache_1`):

```bash
docker rm -f lab09-cache-1 2>&1 | tee logid/03-taastamine.txt
docker compose ps
docker compose up -d 2>&1 | tee -a logid/03-taastamine.txt
```

`tee -a` lisab faili lõppu, nii et mõlemad sammud on samas logis.

!!! success "Oodatav tulemus"
    ```text
     Container lab09-web-1  Running
     Container lab09-cache-1  Created
     Container lab09-cache-1  Started
    ```

    `web` jäi puutumata, `cache` loodi uuesti. Compose muutis ainult vahet.

### 3.5 Muuda soovitud olekut

Muuda `web` port 8080 → 8081 ja käivita uuesti:

```bash
sed -i 's/"8080:80"/"8081:80"/' compose.yaml
grep 808 compose.yaml
docker compose up -d 2>&1 | tee logid/04-port.txt
```

!!! success "Oodatav tulemus"
    ```text
     Container lab09-cache-1  Running
     Container lab09-web-1  Recreate
     Container lab09-web-1  Recreated
     Container lab09-web-1  Started
    ```

    Jooksva konteineri porti muuta ei saa, seega Compose viskas vana `web` konteineri ära ja tegi uue. See on loengu osa 7, muutumatu infrastruktuur. `cache` jäi alles, sest tema kirjeldus ei muutunud.

Muuda port ka oma GitHubi repo `compose.yaml`-is 8081 peale (pliiats ✏️).

### 3.6 Sama asi bash-skriptiga

Käivita `run.sh` **kaks korda** järjest:

```bash
bash run.sh 2>&1 | tee logid/05-run-kaks-korda.txt
bash run.sh 2>&1 | tee -a logid/05-run-kaks-korda.txt
```

!!! success "Oodatav tulemus"
    Esimene kord trükib pika konteineri ID ja `valmis`. Teine kord:

    ```text
    docker: Error response from daemon: Conflict. The container name "/lab09-skript" is already in use by container "4f2a...".
    You have to remove (or rename) that container to be able to reuse that name.
    valmis
    ```

    Skript kukkus ja trükkis ikkagi `valmis`. Kui see oleks öine automaatika, ei märkaks keegi viga. Pane tähele: veateates on **sama ID**, mis esimesel korral tekkis. Automaatkontroll vaatab seda.

### 3.7 Tee skript idempotentseks

Muuda oma GitHubi repos `run.sh` nii, et see kontrollib enne, kas konteiner on juba olemas, ja käivitab ainult siis, kui ei ole. Vihje: loengu tabel 9.3, rida `docker run`. Käsk `docker ps -a --format '{{.Names}}'` näitab kõigi konteinerite nimesid.

??? tip "Lahendus, kui jääd kinni (proovi enne ise 10 minutit)"
    ```bash
    #!/bin/bash
    if docker ps -a --format '{{.Names}}' | grep -qx lab09-skript; then
      echo "lab09-skript on juba olemas, ei tee midagi"
    else
      docker run -d --name lab09-skript -p 8090:80 nginx:1.27-alpine
      echo "valmis"
    fi
    ```

Kopeeri parandatud skript terminali (`cat > run.sh <<'EOF'` ... `EOF`, nagu sammus 3.1), kustuta vana konteiner ja käivita kaks korda:

```bash
docker rm -f lab09-skript
bash run.sh 2>&1 | tee logid/06-run-parandatud.txt
bash run.sh 2>&1 | tee -a logid/06-run-parandatud.txt
```

!!! success "Oodatav tulemus"
    Esimene kord: konteineri ID ja `valmis`. Teine kord: `lab09-skript on juba olemas, ei tee midagi`. Ühtegi `Conflict` rida ei ole.

Mõtle: sinu skript kontrollib ainult seda, kas nimi on olemas. Mis juhtub, kui keegi muudab skriptis pordi 8090 → 8091 ja käivitab uuesti? Mida teeks samal juhul Compose (samm 3.5)?

### 3.8 Logid GitHubi

Iga logifaili jaoks:

1. Terminalis: `cat logid/01-up.txt` ja kopeeri väljund (hiirega märgista, Ctrl+Shift+C või parem klõps → Copy).
2. GitHubis: **Add file → Create new file**, nimeks `logid/01-up.txt`, kleebi sisu, **Commit changes**.

Tee seda failidega `01-up.txt` kuni `06-run-parandatud.txt`. Siis kirjuta README-sse vastused **3.1-3.4**: igas vastuses kopeeri logist üks rida, mis seda näitab, ja kirjuta selle järele üks lause.

✅ **Kontrollpunkt:** GitHubis on kaustas `logid/` kuus faili ja ükski neist ei ole tühi.

---

## Osa 4 · Tekita triiv

Loengu osas 5 muutis Mati serveris faili käsitsi. Nüüd teed sama kahel moel ja vaatad, mida tööriist järgmisel jooksul teeb. Jätka samas terminalis ja samas kaustas `~/lab09`.

### 4.1 Ansible: käsitsi muudatus failis

Paigalda Ansible ja tee väike playbook, mis haldab faili `/tmp/lab09-nginx.conf`. Sama fail on sinu repos `lisa/triiv.yml`.

```bash
python3 -m pip install ansible-core || apt-get install -y ansible
ansible-playbook --version | head -1

cat > triiv.yml <<'EOF'
- name: triivi katse
  hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - name: konfifail on soovitud olekus
      ansible.builtin.copy:
        dest: /tmp/lab09-nginx.conf
        content: |
          # hallatud Ansible'iga, ära muuda käsitsi
          client_max_body_size 1m;
EOF

ansible-playbook triiv.yml
ansible-playbook triiv.yml
cat /tmp/lab09-nginx.conf
```

!!! success "Oodatav tulemus"
    Esimene jooks: `changed=1` (fail loodi). Teine: `changed=0`. Failis on `client_max_body_size 1m;`.

Nüüd oled Mati, kell on 2 öösel:

```bash
sed -i 's/1m/50m/' /tmp/lab09-nginx.conf
```

Kati tahab enne jooksu teada, kas server on triivinud. `--check` jooksutab playbooki ilma midagi muutmata, `--diff` näitab erinevust:

```bash
ansible-playbook triiv.yml --check --diff 2>&1 | tee logid/07-triiv-ansible.txt
cat /tmp/lab09-nginx.conf 2>&1 | tee -a logid/07-triiv-ansible.txt
```

!!! success "Oodatav tulemus"
    ```text
    --- before: /tmp/lab09-nginx.conf
    +++ after: /root/.ansible/tmp/...
    @@ -1,2 +1,2 @@
     # hallatud Ansible'iga, ära muuda käsitsi
    -client_max_body_size 50m;
    +client_max_body_size 1m;

    changed: [localhost]
    ```

    `changed=1` tähendab „muudaksin“. `cat` näitab, et failis on ikka `50m`: `--check` ainult vaatas.

Nüüd tavaline jooks ilma `--check`-ita, nagu Kati esmaspäeval:

```bash
ansible-playbook triiv.yml 2>&1 | tee -a logid/07-triiv-ansible.txt
cat /tmp/lab09-nginx.conf 2>&1 | tee -a logid/07-triiv-ansible.txt
```

Failis on jälle `1m`. Mati parandus kadus.

### 4.2 Konteiner: käsitsi muudatus jooksvas konteineris

Sama trikk Dockeriga. Muuda jooksva `web` konteineri avalehte otse konteineri sees:

```bash
docker compose exec web sh -c 'echo "MATI PARANDAS" > /usr/share/nginx/html/index.html'
curl -s localhost:8081 2>&1 | tee logid/08-triiv-konteiner.txt
```

Ekraanile tuleb `MATI PARANDAS`. Nüüd käivita tavaline ühtlustamine:

```bash
docker compose up -d 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
```

!!! success "Oodatav tulemus"
    Compose ütleb `Running` ja `curl` näitab ikka `MATI PARANDAS`. Compose võrdleb konteineri **kirjeldust** (image, pordid), mitte faile konteineri sees. Triiv jäi alles.

Nüüd ehita konteiner uuesti, nagu muutumatus infrastruktuuris kombeks:

```bash
docker compose up -d --force-recreate 2>&1 | tee -a logid/08-triiv-konteiner.txt
curl -s localhost:8081 2>&1 | tee -a logid/08-triiv-konteiner.txt
```

!!! success "Oodatav tulemus"
    `Recreate`, `Started` ja `curl` näitab `<title>Welcome to nginx!</title>`. Uus konteiner tehti image'ist ja käsitsi muudatusest pole jälgegi.

Kopeeri `logid/07-triiv-ansible.txt` ja `logid/08-triiv-konteiner.txt` GitHubi (nagu samm 3.8) ja kirjuta README-sse vastused **4.1-4.2**.

Mõtle: kumb on parem, kas Ansible, mis kirjutab triivi üle, või konteiner, mis viskab selle koos konteineriga minema? Mida peaks Mati mõlemal juhul tegema, et tema parandus alles jääks? (Seda küsitakse N10-s.)

---

## Osa 5 · Ennustus

README-s on küsimus: **Mida teeb OpenTofu teisiti kui Ansible?**

Kirjuta 3-5 lauset, vähemalt 40 sõna, oma sõnadega loengu põhjal. Vigu tohib teha. N10 alguses loed oma ennustuse klassile ette ja arutame, mis klappis, seega kirjuta nii, nagu ise räägiksid.

Mõtlemiseks:

- Ansible muudab serveri **sisu**. Mida muudab OpenTofu?
- Ansible ei mäleta, mida ta tegi. Mida tähendab olekufail, kui kustutad koodist rea?
- `tofu plan` näitab enne, mida ta teeks. Kus oled Ansible'is midagi sarnast näinud?

---

## Osa 6 · Esitamine

1. Ava GitHubis `README.md` ja otsi (Ctrl+F) sõna `_vastus_`. Osades 2-5 ei tohi seda olla. Rida **Sinu nimi** peab olema täidetud.
2. Ava repo **Actions** vahekaart: automaatkontroll jookseb iga commit'i järel. Vaata viimast jooksu ja paranda punased kohad.
3. Vajadusel tee muudatus ja commit uuesti. Hinnatakse viimast seisu `main`-is tähtaja hetkel.

### Automaatkontroll

| Kontroll | Mida vaadatakse | Punktid |
|---|---|---|
| Failid olemas | `README.md`, `compose.yaml`, `run.sh`, `logid/01`-`08` | 5 |
| Nimi ja vastused | nimi kirjas, Osades 3-4 pole `_vastus_` | 5 |
| KodeKloud | kaustas `kodekloud/` on sertifikaat või ekraanipilt | 10 |
| Võrdlustabel | Osa 2-s pole `_vastus_`, vähemalt 6 linki sinu enda repodesse | 15 |
| `compose.yaml` korras | `docker compose config` õnnestub, vähemalt 2 teenust | 10 |
| Teine `up` | `logid/02` sisaldab `Running` või `up-to-date` ega sisalda `Created` | 10 |
| Taastamine | `logid/03` sisaldab `Created`, `Creating` või `Started` | 10 |
| Skript kaks korda | `logid/05` `Conflict` viga sisaldab sama konteineri ID-d, mis esimesel jooksul tekkis | 10 |
| Parandatud skript | `run.sh` kontrollib enne käivitamist, `logid/06` ei sisalda `Conflict` | 5 |
| Triiv Ansible'iga | `logid/07` sisaldab diff'i read `-client_max_body_size` ja `+client_max_body_size 1m` | 10 |
| Triiv konteineris | `logid/08` sisaldab `MATI PARANDAS` ja `Welcome to nginx` | 5 |
| Ennustus | Osa 5 vähemalt 40 sõna | 5 |
| **Kokku** | | **100** |
| BOONUS | Lisa A tabel täidetud; Lisa B `lisa/triivikontroll.sh` läbib `bash -n` ja logi on olemas | 0 |

*Tabel 9.11. Automaatkontroll. BOONUS-read ei anna punkte, aga õpetaja näeb neid.*

---

## Veaotsing

| Mida näed | Põhjus | Mida teha |
|---|---|---|
| KodeKloud küsib maksmist | kursus vajab kontot, mitte tellimust | Logi sisse ja vajuta **Enroll for Free**; kui ikka küsib, kirjuta õpetajale ja tee ekraanipilt sellest lehest |
| KodeKloud ei anna sertifikaati | tasuta kontol ei pruugi olla | Ekraanipilt kursuse lehest, kus on näha 100% ja sinu nimi |
| Labori terminal kadus | labori aeg sai täis | Ava labor uuesti ja korda sammu 3.1 (kaust ja failid); juba GitHubi kopeeritud logid jäävad alles |
| `docker: 'compose' is not a docker command` | terminalis on vana Compose | Kasuta `docker-compose` (sidekriipsuga) |
| `No such container: lab09-cache-1` | konteineri nimi on teine (nt `lab09_cache_1`) | Vaata `docker ps` ja kasuta seal näidatud nime |
| Logifail on tühi | `2>&1` jäi käsust välja | Käivita sama samm uuesti koos `2>&1 \| tee ...` |
| `Bind for 0.0.0.0:8080 failed: port is already allocated` | mõni teine konteiner kasutab porti (nt KodeKloudi laborist) | `docker ps`, `docker rm -f` see konteiner |
| Teises `up`-is on `Created`/`Recreated` | muutsid vahepeal `compose.yaml`-i | Taasta port 8080, tee `up -d` ja siis uuesti samm 3.3 |
| `pip: command not found` ja `apt-get` ei tööta | laboris pole Pythoni paigaldajat | Tee Osa 4.1 oma arvutis WSL Ubuntus (`sudo apt install ansible`) |
| Osas 3.7 tuleb ikka `Conflict` | kontroll ei leia nime (trükiviga või `grep -x` puudub) | Käivita `docker ps -a --format '{{.Names}}'` ja võrdle nime |
| `curl: (7) Failed to connect` Osas 4.2 | teenused on maas või port on 8080 | `docker compose up -d`, kontrolli porti `docker compose ps` |
| Automaatkontroll punane: `_vastus_` alles | mõni lahter jäi täitmata | Otsi README-st Ctrl+F `_vastus_` |

*Tabel 9.12. Veaotsing.*

---

## Lisaülesanded

Kergest raskeni. Vastused samasse README-sse, jaotisse **Lisaülesanded**.

### Lisa A · 12-Factor (kerge)

Loe [12-Factor App](https://12factor.net/et/) kolm peatükki: **III Config** (seadistus keskkonnamuutujates), **IV Backing services** (andmebaas ja vahemälu kui lisatavad ressursid) ja **V Build, release, run** (ehitamine, väljalase ja käivitamine eraldi). Täida README-s tabel: kas tööriist aitab seda põhimõtet järgida? Iga lahter: jah / osaliselt / ei + üks lause.

??? tip "Näidislahter"
    Docker Compose, IV Backing services: **jah**, `cache` on eraldi teenus, mille saab `compose.yaml`-is teise vastu vahetada ilma rakenduse koodi muutmata.

### Lisa B · Öine triivikontroll (keskmine)

Osas 4.1 vaatasid triivi käsitsi. Kirjuta skript `triivikontroll.sh`, mis:

1. jooksutab `ansible-playbook triiv.yml --check`;
2. kui väljundis on `changed=0`, trükib `triivi ei ole` ja väljub koodiga 0;
3. muidu trükib `TRIIV!` ja väljub koodiga 1.

Kirjuta skript KodeKloudi terminalis kausta `~/lab09` (`cat > triivikontroll.sh <<'EOF'` ... `EOF`). Testi mõlemat olukorda:

```bash
ansible-playbook triiv.yml                         # soovitud olekusse
bash triivikontroll.sh; echo "kood: $?"       # triivi ei ole, kood: 0
sed -i 's/1m/50m/' /tmp/lab09-nginx.conf
bash triivikontroll.sh; echo "kood: $?"       # TRIIV!, kood: 1
```

Kopeeri skript GitHubi faili `lisa/triivikontroll.sh` ja terminali väljund faili `logid/lisa-b.txt`. README-sse kirjuta, kuidas paneksid selle igal ööl jooksma (vihje: N7 `on:` võtmes on ka `schedule`).

??? tip "Osaline lahendus"
    ```bash
    #!/bin/bash
    valjund=$(ansible-playbook triiv.yml --check 2>&1)
    if echo "$valjund" | grep -q 'changed=0'; then
      echo "triivi ei ole"
    else
      echo "TRIIV!"
      # mis koodiga välja?
    fi
    ```

### Lisa C · Kubernetes'e kontroller (raskem)

Loe Kubernetes'e dokumentatsioonist leht [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/) (inglise keeles, ~10 min). Leht algab sama termostaadi näitega, mis loengus.

Vasta README-s: kuidas on kontroller sarnane termostaadi ja `docker compose up -d`-ga? Mis on vahe? Vihje: mitu korda käivitab Compose ühtlustamise ja mitu korda Kubernetes?

??? tip "Osaline lahendus"
    Kõik kolm võrdlevad soovitud ja tegelikku olekut ja muudavad vahet. Compose teeb seda ainult siis, kui sina käivitad `up`. Kubernetes'e kontroller teeb seda pidevalt, lõputus tsüklis. Kui kustutad Kubernetes'is konteineri käsitsi, on see mõne sekundi pärast tagasi, ilma et keegi midagi käivitaks. Kirjuta oma sõnadega, mida see tähendab triivi jaoks.

---

*N10-s paned OpenTofu'ga Proxmoxi masina püsti ja vaatame koos üle, kuidas su Osa 4 ennustus klappis.*
