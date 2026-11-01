---
tags:
  - CD
  - GHCR
  - GitHubActions
  - Praktikum
---

# N8 · Praktikum: katkine konveier korda

N7 lõpus kontrollis konveier koodi ja konteinerit. Tänases repositooriumis on sama kood ja kolleeg on lisanud konveierile kolmanda job'i `build-and-push`, mis peaks image'i GHCR-i saatma, ning skripti, mis peaks selle serveris käivitama. Mõlemas on vigu. Leiad ja parandad need ükshaaval, kuni server näitab sama versiooni, mis on registris.

Töötad masinas `proxmox1` VS Code'i kaudu nagu N7-s. Serveri rollis on samuti `proxmox1`, sest seal töötab Docker (N5). Töökohas on server eraldi masin, käsud on samad.

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

| Osa | Töö | Aeg |
|---|---|---|
| 1 | Ettevalmistus: repositoorium, testid, esimene push | 20 min |
| 2 | Viga 1 koos õpetajaga: registrisse kirjutamine | 30 min |
| 3 | Viga 2: katkine kood jõuab registrisse | 25 min |
| 4 | Viga 3: pull request jõuab registrisse | 30 min |
| 5 | Vead 4 ja 5: server | 45 min |
| 6 | Töö esitamine | 15 min |

*Tabel 8.3. Praktikumi osad.*

Iga vea juures on samad sammud samas järjekorras ([loengu §7](lecture.md#7-vea-leidmine-sumptom-hupotees-toend-parandus)):

- **Sümptom:** mida näed (punane job, rida logis, käsu väljund).
- **Ennusta:** mis on põhjus ja mis failis see on. Ütle oma oletus naabrile. Kirja seda panema ei pea.
- **Uuri:** kust leida tõend, mis oletuse kinnitab või ümber lükkab. Enne tõendit ära midagi muuda.
- **Paranda** ja **Kontrolli:** üks muudatus, siis sama sümptom uuesti. Põhjus ja parandus on kokkuvolditud plokis. Ava see alles siis, kui oled ise proovinud.
- **Küsimus:** üks lause README-sse ja rida vigade tabelisse.

Esimese vea teete koos õpetajaga. Ülejäänud neli teed paaris naabriga, kumbki oma repositooriumis.

??? note "Õpetajale: viga 1 tahvlil (umbes 15 minutit)"
    Kõigil õpilastel on pärast sammu 1.3 sama punane käivitus. Ava oma repositooriumis sama käivitus projektoril ja mõtle valjult, ilma et ütleksid põhjust enne tõendit:

    1. **Sümptom.** Loe ette, mis on roheline ja mis punane. Ava punane samm ja loe viimane rida lõpuni. Ütle, mis on veateates oluline sõna (`denied`).
    2. **Hüpotees.** Ütle kaks oletust ja küsi klassilt, kumb on tõenäolisem: vale parool või puuduv õigus. Rõhuta, et sisselogimise samm oli roheline.
    3. **Tõend.** Ava sama job'i samm **Set up job** → `GITHUB_TOKEN Permissions`. Näita rida `Packages: read`. Võrdle job'iga `konteiner`.
    4. **Parandus.** Lisa `permissions` plokk, ütle, miks `contents: read` jääb alles. Commit, push, näita rohelist käivitust ja paketti **Packages** all.

    Õpilased teevad sama parandust samal ajal oma repositooriumis. Siis paaris edasi osaga 3.

??? abstract "Õpiväljundid"

    1. Oskad lugeda Actions'i logist, mis samm kukkus ja miks.
    2. Oskad anda job'ile õiguse kirjutada GHCR-i ja põhjendada, miks ainult sellele job'ile.
    3. Oskad seada image'i ehituse testide järele ja jätta selle pull request'is vahele.
    4. Oskad tõmmata privaatse image'i serverisse ja käivitada selle õige pordiga.
    5. Oskad leida vea järjekorras: sümptom, hüpotees, tõend, parandus.

<figure markdown="span">
  ![ci.yml-is jobid test, konteiner ja build-and-push. Punased numbrid: 1 build-and-push kirjutamisõigus, 2 konteineri ja build-and-push vahel puuduv järjekord, 3 millal workflow käivitub. build-and-push saadab image'i GHCR-i, kus pakett on privaatne. proxmox1-s server/paigalda.sh: 4 docker pull, 5 docker run -p](../images/n08_viis_viga.svg)
  <figcaption>Joonis 8.4. Viis viga: kolm workflow'is, kaks serveri skriptis (Talvik, 2026).</figcaption>
</figure>

---

## Osa 1 · Ettevalmistus

### 1.1 Repositoorium

**Ülesanne**

Võta Classroom 50-s vastu ülesanne **Lab 08 - CD ja GHCR** ([Classroom 50](https://classroom50.org/hkhk-automation/it24-automatiseerimine/assignments)) ja klooni repositoorium masinasse `proxmox1`:

```bash
cd ~
git clone <sinu-repo-url> lab08 && cd lab08
ls -a . flask server
```

**Kontrolli**

Kaustas `flask/` on N7 failid: `app.py`, `test_app.py`, `requirements.txt` ja `Dockerfile`. Kaustas `server/` on skript `paigalda.sh`. Ava `.github/workflows/ci.yml` ja leia kolm job'i. Kaks esimest on sinu N7 omad, kolmas on uus.

Rakendusel on uus route `/versioon`. Ava `flask/Dockerfile` ja leia read `ARG VERSIOON` ja `ENV VERSIOON`. Pipeline annab ehitamisel siia commit'i lühiräsi ([loengu §3](lecture.md#3-tagid-rasi-ja-latest)).

### 1.2 Testid kohapeal

Virtuaalkeskkond on sama, mis N7 Osa 0-s, ainult uues kaustas:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r flask/requirements.txt pytest
pytest flask -v
```

**Kontrolli**

Väljundi lõpus on `4 passed`. Neljas test kontrollib, et ilma pipeline'ita annab `/versioon` vastuse `kohalik`.

### 1.3 Esimene push

Kirjuta README-s rea `**Sinu nimi:**` järele oma nimi. Salvesta muudatus repositooriumi ja saada see GitHubi:

```bash
git add README.md
git commit -m "N8: nimi README-sse"
git push
```

Push harusse `main` käivitab konveieri. Ava repositooriumi vahekaart **Actions** ja oota, kuni käivitus lõpeb. **Ära veel midagi paranda**: osa 2 teete koos.

---

## Osa 2 · Viga 1: registrisse kirjutamine

Seda viga uurib õpetaja tahvlil ja sina teed samu samme oma repositooriumis.

**Sümptom**

Käivituse lehel on `test` ja `konteiner` rohelised ning `build-and-push` punane. Ava `build-and-push` ja leia punane samm.

**Ennusta.** Samm `Logi GHCR-i sisse` on roheline, samm `Saada image GHCR-i` punane. Mis on põhjus ja mis failis?

**Uuri**

1. Ava punane samm ja loe viimased read lõpuni.
2. Ava sama job'i esimene samm **Set up job** ja selles lõik `GITHUB_TOKEN Permissions`.
3. Ava `.github/workflows/ci.yml` ja otsi job'ist `build-and-push` sõna `permissions`.

??? success "Põhjus ja parandus"
    Logi lõpus on:

    ```text
    denied: installation not allowed to Create organization package
    Error: Process completed with exit code 1.
    ```

    Sõnastus võib erineda, aga sõna `denied` on alati. Lõigus `GITHUB_TOKEN Permissions` on `Packages: read`. Sisselogimine õnnestus, sest token kehtib. Kirjutada ei tohtinud, sest organisatsioonis `hkhk-automation` on tokenil vaikimisi ainult lugemisõigus ja workflow ei küsinud rohkem ([loengu §4](lecture.md#4-oigused-github_token-ja-permissions)).

    Lisa job'ile `build-and-push` õigused, sama taandega nagu `runs-on`:

    ```yaml
      build-and-push:
        runs-on: ubuntu-latest
        permissions:
          contents: read
          packages: write
    ```

    `contents: read` peab alles jääma: kui `permissions` on kirjas, on kõik loetlemata õigused keelatud ja `actions/checkout` ei saaks koodi lugeda.

**Paranda**

```bash
git add .github/workflows/ci.yml
git commit -m "N8 viga 1: build-and-push saab kirjutada GHCR-i"
git push
```

**Kontrolli**

Kõik kolm job'i on rohelised. Repositooriumi avalehel paremal jaotises **Packages** on pakett sinu repositooriumi nimega. Ava see: tag'id on `latest` ja seitsmemärgiline räsi. Võrdle räsi oma viimase commit'iga:

```bash
git log --oneline -1
```

??? warning "Kui `docker push` on ikka `denied`"
    - Kontrolli, et `permissions` on job'i `build-and-push` all, mitte `steps` all, ja et taane on sama mis real `runs-on`.
    - Ava uuesti **Set up job**. Kui seal on `Packages: write` ja push ikka kukub, ütle õpetajale: siis on organisatsiooni seadetes paketi loomine piiratud.
    - Kui hoopis `actions/checkout` kukub (`Repository not found`), puudub `contents: read`.

**Küsimus:** miks oli `GITHUB_TOKEN`-il vaikimisi õigus pakette ainult lugeda? (README küsimus 1 ja tabeli rida 1)

---

## Osa 3 · Viga 2: katkine kood jõuab registrisse

Nüüd on konveier roheline. Järgmisena kontrolli, kas registrisse jõuab ainult testitud kood. Kolleeg muudab tervitust ega käivita teste.

**Ülesanne**

Muuda failis `flask/app.py` rida `return "Tere konteinerist!"` reaks `return "Tervist konteinerist!"`. Ära käivita `pytest`-i. Saada muudatus GitHubi:

```bash
git add flask/app.py
git commit -m "N8: uus tervitus"
git push
```

**Sümptom**

`test` on punane ja `konteiner` hall (`skipped`). Vaata, mis on `build-and-push` olekus. Ava **Packages** ja vaata tag'e.

**Ennusta.** Test kukkus. Kas registrisse jõudis uus image? Kui jõudis, siis miks ja mis failis on põhjus?

**Uuri**

1. Käivituse lehel on job'ide skeem. Vaata, millised job'id on noolega ühendatud.
2. Ava job'id `test` ja `build-and-push` ning võrdle, mis kell kumbki alustas.
3. Võrdle failis `ci.yml` job'i `konteiner` algust job'i `build-and-push` algusega.

??? success "Põhjus ja parandus"
    `build-and-push` on roheline ja **Packages** all on uus räsi. `latest` näitab nüüd koodi, mille test kukkus. Skeemil on nool ainult `test` ja `konteiner` vahel, `build-and-push` alustas samal ajal kui `test`. Job'il `build-and-push` puudub `needs`, seega ei oota see teisi job'e ([loengu §5](lecture.md#5-millal-image-ehitatakse)).

    Lisa `build-and-push` job'ile järjekord. `konteiner` ootab juba `test`-i, seega piisab `konteiner`-ist:

    ```yaml
      build-and-push:
        needs: konteiner
        runs-on: ubuntu-latest
    ```

**Paranda**

Jäta tervitus veel katki, et näeksid, kas parandus töötab:

```bash
git add .github/workflows/ci.yml
git commit -m "N8 viga 2: image alles pärast teste"
git push
```

**Kontrolli**

`test` on punane, `konteiner` ja `build-and-push` on hallid (`skipped`). **Packages** all uut räsi ei ole. Skeemil on nool kõigi kolme job'i vahel.

Pane tervitus tagasi (`Tere konteinerist!`), kontrolli `pytest flask -v` ja saada parandus GitHubi:

```bash
git add flask/app.py
git commit -m "N8: tervitus tagasi"
git push
```

Kõik kolm job'i on rohelised ja järjest.

**Küsimus:** miks peab image'i ehitus ootama testide järel? (README küsimus 2 ja tabeli rida 2)

---

## Osa 4 · Viga 3: pull request jõuab registrisse

N7-s läks kood `main` harusse pull request'i kaudu. Pull request'i kood on veel üle vaatamata, seega ei tohi see registrisse jõuda. Kontrolli, kas see nii on.

**Ülesanne**

Tee uus haru, muuda tervitust ja ava pull request. Testi tekst `Tere` jääb tervitusse alles, seega test läbib:

```bash
git switch -c n08-tervitus
```

Muuda failis `flask/app.py` tervitus kujule `Tere konteinerist, N8!` ja saada haru GitHubi:

```bash
pytest flask -v
git add flask/app.py
git commit -m "N8: tervitus N8"
git push -u origin n08-tervitus
```

Ava GitHubis pull request `n08-tervitus` → `main`. **Ära seda veel liida.**

**Sümptom**

Vaata vahekaarti **Actions** ja pull request'i lehel kasti **Checks**. Vaata ka **Packages** all tag'e.

**Ennusta.** Kood on ainult harus `n08-tervitus`. Kas see jõudis registrisse? Kui jõudis, siis mis selle käivitas ja mis failis?

**Uuri**

1. Vahekaardi **Actions** nimekirjas on iga käivituse all sündmus ja haru. Mitu käivitust tekkis sinu viimase commit'i kohta ja mis sündmused need olid?
2. Võrdle **Packages** all uusimat räsi oma haru commit'iga:

    ```bash
    git log --oneline -1
    git log --oneline -1 origin/main
    ```

3. Ava failis `ci.yml` plokk `on:` ja job'i `build-and-push` päis. Kas miski seal ütleb, millises harus või millise sündmusega see job käivitub?

??? success "Põhjus ja parandus"
    Sama commit'i kohta on kaks käivitust: `push` harus `n08-tervitus` ja `pull_request`. Mõlemas oli `build-and-push` roheline. **Packages** all on haru commit'i räsi ja `latest` näitab nüüd koodi, mida keegi pole üle vaadanud ega `main` harusse liitnud. Trigger `push:` ilma harudeta käivitab workflow'i iga haru igal push'il ja job'il `build-and-push` ei ole tingimust, mis jätaks selle pull request'is vahele ([loengu §5](lecture.md#5-millal-image-ehitatakse)).

    Parandusi on kaks. Trigger `push` ainult harus `main`:

    ```yaml
    on:
      push:
        branches: [main]
      pull_request:
    ```

    `build-and-push` ainult push'i korral:

    ```yaml
      build-and-push:
        needs: konteiner
        if: github.event_name == 'push'
        runs-on: ubuntu-latest
    ```

    `pull_request` jääb alles, sest pull request'is peavad testid käivituma.

**Paranda**

Tee parandus samas harus, et see läbiks pull request'i nagu iga teine muudatus:

```bash
git add .github/workflows/ci.yml
git commit -m "N8 viga 3: pull request ei saada image'it registrisse"
git push
```

**Kontrolli**

Uue commit'i kohta on üks käivitus, sündmusega `pull_request`. Selles on `test` ja `konteiner` rohelised ja `build-and-push` hall (`skipped`). **Packages** all uut räsi ei ole.

Liida pull request GitHubis (**Merge pull request**). Liitmine on push harusse `main`: tekib uus käivitus, kus `build-and-push` on roheline ja **Packages** all on liitmise commit'i räsi. Too see oma masinasse:

```bash
git switch main
git pull
git log --oneline -1
```

Viimase commit'i räsi on sama, mis **Packages** all uusim tag.

**Küsimus:** miks ei tohi pull request'i kood registrisse jõuda? (README küsimus 3 ja tabeli rida 3)

---

## Osa 5 · Server

Image on registris. Nüüd tõmbab server selle sealt ja käivitab. Seda teeb skript `server/paigalda.sh`, et nime, tag'i ja porti ei peaks iga kord käsitsi sisestama ([loengu §6](lecture.md#6-server-tombab-imagei)). Loe skript enne käivitamist läbi:

```bash
cat server/paigalda.sh
```

### 5.1 Viga 4: server ei saa image'it

**Ülesanne**

```bash
bash server/paigalda.sh
```

**Sümptom**

Skript lõpetab pärast rida `== image ...` veaga.

**Ennusta.** Image on registris olemas, sa nägid seda **Packages** all. Miks ei saa server seda kätte?

**Uuri**

1. Loe veateade lõpuni. Mis sõna on viimane?
2. Ava GitHubis pakett. Paremal on paketi nähtavus (**Private** või **Public**).
3. Kontrolli, kas Docker on sinu kasutajana `ghcr.io`-sse sisse logitud:

    ```bash
    grep ghcr.io ~/.docker/config.json
    ```

??? success "Põhjus ja parandus"
    Veateade on kujul:

    ```text
    Error response from daemon: Head "https://ghcr.io/v2/hkhk-automation/.../manifests/latest": unauthorized
    ```

    Sõnastus võib erineda (`denied`), aga see tähendab alati, et registrisse ei ole sisse logitud. Pakett on privaatne nagu repositoorium ja `grep` ei leia failist `~/.docker/config.json` rida `ghcr.io`. Pipeline'i `GITHUB_TOKEN` kehtib ainult workflow'i ajal, serveris seda ei ole.

    Tee GitHubis isiklik token, millel on ainult lugemisõigus:

    1. Profiilipilt → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** → **Generate new token (classic)** ([juhend](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)).
    2. **Note**: `proxmox1 GHCR`, **Expiration**: 30 päeva, õigus ainult **read:packages**.
    3. Kopeeri token. GitHub näitab seda ainult üks kord.

    Logi sisse. Kasutajanimi on sinu GitHubi kasutajanimi ja parooli asemel kleebi token. Ekraanil seda ei näidata:

    ```bash
    docker login ghcr.io -u <sinu-github-kasutaja>
    ```

**Kontrolli**

`docker login` lõpetab reaga `Login Succeeded`. `grep ghcr.io ~/.docker/config.json` leiab nüüd rea. Käivita skript uuesti:

```bash
bash server/paigalda.sh
```

`docker pull` õnnestub. Skript läheb edasi järgmise veani.

??? warning "Kui sisselogimine ei õnnestu"
    - `unauthorized: authentication required` pärast `docker login`-i: tokenil puudub õigus `read:packages` või kopeerisid selle poolikult. Tee uus token.
    - `permission denied while trying to connect to the Docker daemon socket`: sinu kasutaja pole grupis `docker` (N5 Osa 0).

**Küsimus:** miks on serveri tokenil ainult õigus `read:packages`? (README küsimus 4 ja tabeli rida 4)

### 5.2 Viga 5: konteiner ei vasta

**Sümptom**

Skript jõuab rea `== versioon` juurde, `curl` proovib mitu korda ja lõpetab veaga.

**Ennusta.** Konteiner käivitus. Miks ei saa `curl` vastust? Kus failis on põhjus?

**Uuri**

```bash
docker ps --filter name=flask-cd
docker logs flask-cd
```

Võrdle veergu PORTS ja logi rida `Running on`. Mis port on kummaski?

??? success "Põhjus ja parandus"
    `curl` annab `curl: (56) Recv failure: Connection reset by peer` või `curl: (52) Empty reply from server`. Sama sümptomit nägid N5 Osa 10-s. `docker ps` näitab `0.0.0.0:8088->80/tcp`, aga logis on `Running on http://...:5000`. Skript suunab serveri pordi 8088 konteineri porti 80, kus keegi ei kuula. Flask kuulab konteineris pordil 5000.

    Paranda failis `server/paigalda.sh` real `docker run` pordi suunamine: `-p 8088:5000`.

**Kontrolli**

```bash
bash server/paigalda.sh
curl localhost:8088
```

Skripti viimane rida on seitsmemärgiline räsi ja `curl localhost:8088` vastab tervitusega.

**Küsimus:** mida tähendavad `-p 8088:5000` kaks numbrit? (README küsimus 5 ja tabeli rida 5)

### 5.3 Viimane versioon serverisse

Skripti parandus peab jõudma ka repositooriumi. Push harusse `main` ehitab samas uue image'i. Kui pipeline on roheline, paigalda see serverisse ja salvesta väljund logifaili:

```bash
git add server/paigalda.sh
git commit -m "N8 viga 5: konteineri port 5000"
git push
```

Oota, kuni käivitus vahekaardil **Actions** on roheline. Siis:

```bash
bash server/paigalda.sh 2>&1 | tee logid/server.txt
git log --oneline -1
```

**Kontrolli**

`logid/server.txt` viimane rida on sama räsi, mis `git log --oneline -1` alguses ja mis **Packages** all uusim tag. Server töötab nüüd koodiga, mille sa just GitHubi saatsid, ja sa ei ehitanud serveris midagi.

??? warning "Kui räsi on vanem kui viimane commit"
    Käivitasid skripti enne, kui `build-and-push` lõpetas, ja `latest` näitas veel eelmist image'it. Oota rohelist käivitust ja käivita skript uuesti.

**Küsimus:** mis versioon töötab serveris ja kust tead, et see on sama mis GHCR-is? (README küsimus 6)

---

## Osa 6 · Töö esitamine

**Ülesanne**

1. Täida README-s vigade tabel. Sümptomi lahtrisse kopeeri logist või käsu väljundist rida, mis viga näitas. Põhjus ja parandus on kumbki üks lühike lause.
2. Vasta README küsimustele 1-6, igaühele üks lause.
3. Salvesta kõik repositooriumi ja saada GitHubi:

    ```bash
    git add README.md logid/server.txt
    git status --short
    git commit -m "N8: vigade tabel, vastused ja serveri logi"
    git push
    ```

**Kontrolli**

Töö on esitatud, kui kõik muudatused on `main` harus GitHubis. Automaatkontrolli tulemuse näed repositooriumi vahekaardil **Actions** ja Classroom 50-s. Tahvlil on N8 vahelehel näha, kas masinas `proxmox1` on Docker `ghcr.io`-sse sisse logitud, kas image on tõmmatud GHCR-ist ja kas `/versioon` vastab pordil 8088.

??? note "Automaatkontroll (100 punkti)"

    | Kontroll | Punktid |
    |---|---|
    | Failid olemas, N7 osa töötab (`pytest`, jobid `test` ja `konteiner`), `logid/server.txt` olemas | 10 |
    | Viga 1: `build-and-push` saab kirjutada GHCR-i, image'i nimi väiketähtedega, tag'id räsi ja `latest` | 20 |
    | Viga 2: `build-and-push` ootab teste (`needs`) | 15 |
    | Viga 3: `push` ainult harus `main`, `build-and-push` jääb pull request'is vahele (`if`) | 15 |
    | Viga 5: `server/paigalda.sh` suunab pordi 5000 | 10 |
    | `logid/server.txt`: image GHCR-ist, viimane rida on räsi | 15 |
    | Nimi, vigade tabel ja küsimused README-s | 15 |

    Automaatkontroll ei ühendu sinu serveriga ega GHCR-iga. See loeb sinu faile ja käivitab teste. Viga 4 (sisselogimine) on näha logist `logid/server.txt` ja tahvlilt.

??? warning "Kui automaatkontroll annab vea"
    - `pytest kukub`: tervitus failis `flask/app.py` peab sisaldama sõna `Tere` (osa 3).
    - `logid/server.txt viimane rida peab olema /versioon vastus`: skript lõpetas veaga. Paranda see ja käivita uuesti käsuga `tee` (samm 5.3).
    - `Vigade tabelis ja küsimustes on N vastust puudu`: README-s on `_vastus_` alles.

---

## Lisaülesanded

??? example "A · Tagasipööramine (lihtne)"
    Registris on iga commit'i image alles. Leia **Packages** alt või käsuga `git log --oneline` mõne varasema image'i räsi, näiteks osa 2 oma, ja käivita see:

    ```bash
    bash server/paigalda.sh <varasem-räsi>
    curl localhost:8088
    ```

    Mis tervitust näed? Pane viimane versioon tagasi (`bash server/paigalda.sh`). Mitu käsku kulus tagasipööramiseks ja mida oleks pidanud tegema, kui server oleks image'i ise ehitanud?

??? example "B · Vähim õigus kogu failis (keskmine)"
    Lisa faili `ci.yml` algusesse, enne rida `jobs:`, õigused, mis kehtivad kõigile job'idele:

    ```yaml
    permissions:
      contents: read
    ```

    Ava pärast push'i job'i `test` samm **Set up job**. Mis on lõigus `GITHUB_TOKEN Permissions` muutunud? Mis on nüüd job'i `build-and-push` õigused ja miks?

---

*Edasi: [kodutöö](homework.md), kus leiad ise vead väljalaske workflow'is. N9 teema on infrastruktuur koodina.*
