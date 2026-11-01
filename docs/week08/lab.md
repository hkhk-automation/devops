---
tags:
  - CD
  - GHCR
  - GitHubActions
  - Jenkins
  - Praktikum
---

# N8 · Praktikum: katkine konveier korda

N7 lõpus kontrollis konveier koodi ja konteinerit. Tänases repositooriumis on sama kood. Kolleeg on lisanud konveierile kolmanda töö `build-and-push`. See peaks saatma image'i registrisse GHCR. Ta on kirjutanud ka skripti, mis peaks image'i serveris käivitama. Mõlemas on vigu.

Leiad ja parandad vead ükshaaval. Lõpus näitab server sama versiooni, mis on registris. Viimases osas käivitad sama konveieri Jenkinsis.

Töötad masinas `proxmox1` VS Code'i kaudu nagu N7-s. Serveri rollis on samuti `proxmox1`, sest seal töötab Docker (N5). Töökohas on server eraldi masin, aga käsud on samad.

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

| Osa | Töö | Aeg |
|---|---|---|
| 1 | Ettevalmistus ja issue'de mall | 15 min |
| 2 | Viga 1: registrisse kirjutamine | 15 min |
| 3 | Viga 2: katkine kood jõuab registrisse | 20 min |
| 4 | Viga 3: pull request jõuab registrisse | 25 min |
| 5 | Vead 4 ja 5: server, tagasi vanale versioonile | 45 min |
| 6 | Sama konveier Jenkinsis, viga 6 | 45 min |
| 7 | Korrektne lahendus | 5 min |
| 8 | Töö esitamine | 10 min |

*Tabel 8.5. Praktikumi osad. Koos vahetunniga kokku 3 h 15 min.*

Iga vea juures on samad sammud samas järjekorras ([loengu §7](lecture.md#7-vea-leidmine-sumptom-hupotees-toend-parandus)):

- **Sümptom:** mida näed. See võib olla punane töö, rida logis või käsu väljund.
- **Ennusta:** mis on põhjus ja mis failis see on. Kirjuta oletus vea issue väljale **Hüpotees**, enne kui tõendit otsid.
- **Uuri:** kust leida tõend. Tõend kinnitab oletuse või lükkab selle ümber. Enne tõendit ära midagi muuda.
- **Paranda** ja **Kontrolli:** tee üks muudatus ja vaata sama sümptomit uuesti. Põhjus ja parandus on kokkuvolditud plokis. Ava see alles siis, kui oled ise proovinud.
- **Küsimus:** kirjuta README-sse üks lause ja vigade tabelisse üks rida.
- **Issue:** iga vea kohta on repositooriumis issue (samm 1.4). Paranduse commit sulgeb selle.

Kõik vead teed iseseisvalt.

??? abstract "Õpiväljundid"

    1. Oskad lugeda Actionsi logist, mis samm kukkus ja miks.
    2. Oskad anda tööle õiguse kirjutada GHCR-i ja põhjendada, miks ainult sellele tööle.
    3. Oskad panna image'i ehituse testide järele ja jätta selle pull request'is vahele.
    4. Oskad tõmmata privaatse image'i serverisse ja käivitada selle õige pordiga.
    5. Oskad käivitada sama konveieri Jenkinsis ja võrrelda seda GitHub Actionsiga.

<figure markdown="span">
  ![ci.yml-is tööd test, konteiner ja build-and-push. Punased numbrid: 1 build-and-push kirjutamisõigus, 2 konteineri ja build-and-push vahel puuduv järjekord, 3 millal töövoog käivitub. build-and-push saadab image'i GHCR-i, kus pakett on privaatne. proxmox1-s server/paigalda.sh: 4 docker pull, 5 docker run -p](../images/n08_viis_viga.svg)
  <figcaption>Joonis 8.4. Viis viga konveieris ja serveris. Kuues viga on Jenkinsis, osas 6 (Talvik, 2026).</figcaption>
</figure>

---

## Osa 1 · Ettevalmistus

### 1.1 Repositoorium

**Ülesanne**

Võta Classroom 50-s vastu ülesanne **Lab 08 - CD ja GHCR** ([Classroom 50](https://classroom50.org/hkhk-automation/it24-automatiseerimine/assignments)). Klooni repositoorium masinasse `proxmox1`:

```bash
cd ~
git clone <sinu-repo-url> lab08 && cd lab08
ls -a . flask server jenkins
```

**Kontrolli**

Kaustas `flask/` on N7 failid. Kaustas `server/` on skript `paigalda.sh`. Kaustas `jenkins/` on Jenkinsi `Dockerfile`. Ava `.github/workflows/ci.yml` ja leia kolm tööd. Kaks esimest on sinu N7 omad. Kolmas on uus.

Rakendusel on uus aadress `/versioon`. Ava `flask/Dockerfile` ja leia read `ARG VERSIOON` ja `ENV VERSIOON`. Konveier annab ehitamisel siia commit'i lühiräsi ([loengu §3](lecture.md#3-tagid-rasi-ja-latest)).

### 1.2 Testid oma masinas

Tee virtuaalkeskkond nagu N7 Osa 0-s ja käivita testid:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r flask/requirements.txt pytest
pytest flask -v
```

**Kontrolli**

Väljundi lõpus on `4 passed`. Neljas test kontrollib aadressi `/versioon`. Kui image'it ei ehitanud konveier, vastab see `kohalik`.

### 1.3 Esimene push

Kirjuta README-s rea `**Sinu nimi:**` järele oma nimi. Salvesta muudatus ja saada see GitHubi:

```bash
git add README.md
git commit -m "N8: nimi README-sse"
git push
```

Push harusse `main` käivitab konveieri. Ava repositooriumis vahekaart **Actions** ja oota, kuni käivitus lõpeb. **Ära veel midagi paranda.**

### 1.4 Vigade issue'd

Töökohas ei parandata viga ilma kirjeta. Iga viga saab **issue**: GitHubi kirje, kus on kirjas, mida nähti ja mis oli põhjus. Paranduse commit viitab issue'le. Hiljem näeb igaüks, milline commit millise vea parandas.

Repositooriumis on issue'de mall **Viga**. Iga vea juures toimi nii:

1. Kui näed sümptomit, ava vahekaart **Issues** → **New issue** → **Viga**. Pealkirjaks kirjuta lühidalt, mida näed, näiteks `build-and-push: docker push denied`. Väljale **Sümptom** kopeeri rida logist.
2. Sammus **Ennusta** kirjuta oma oletus väljale **Hüpotees**. Kui oled tõendi leidnud, täida väli **Tõend**.
3. Pane paranduse commit'i sõnumisse teise reana `Fixes #<issue number>`. Issue number on pealkirja järel, näiteks `#2`:

    ```bash
    git commit -m "N8 viga 1: build-and-push saab kirjutada GHCR-i" -m "Fixes #2"
    ```

Kui commit jõuab harusse `main`, sulgeb GitHub issue ise ja lisab sellele lingi commit'ile ([issue sulgemine commit'iga](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword)). Pull request'i puhul pane `Fixes #<number>` pull request'i kirjeldusse. Siis sulgub issue liitmisel. Pull request'id ja issue'd kasutavad sama numbrijada, seega ei ole issue numbrid alati järjest.

Selle osa juhendis on commit'i käskudes ainult esimene rida. Teise rea `-m "Fixes #<number>"` lisa ise.

---

## Osa 2 · Viga 1: registrisse kirjutamine

Sama viga nägid loengus. Tee nüüd samad sammud oma repositooriumis.

**Sümptom**

Käivituse lehel on `test` ja `konteiner` rohelised. `build-and-push` on punane. Ava see töö ja leia punane samm.

**Ennusta.** Samm `Logi GHCR-i sisse` on roheline. Samm `Saada image GHCR-i` on punane. Mis on põhjus ja mis failis? Kirjuta oletus issue väljale **Hüpotees**.

**Uuri**

1. Ava punane samm. Loe viimased read lõpuni.
2. Ava sama töö esimene samm **Set up job**. Leia lõik `GITHUB_TOKEN Permissions`.
3. Ava `.github/workflows/ci.yml`. Otsi töö `build-and-push` juurest sõna `permissions`.

??? success "Põhjus ja parandus"
    Logi lõpus on:

    ```text
    denied: installation not allowed to Create organization package
    Error: Process completed with exit code 1.
    ```

    Sõnastus võib erineda, aga sõna `denied` on alati. Lõigus `GITHUB_TOKEN Permissions` on `Packages: read`. Sisselogimine õnnestus, sest token kehtib. Kirjutada ei tohtinud, sest organisatsioonis on tokenil vaikimisi ainult lugemisõigus ([loengu §4](lecture.md#4-oigused-github_token-ja-permissions)).

    Lisa tööle `build-and-push` õigused. Taane on sama mis real `runs-on`:

    ```yaml
      build-and-push:
        runs-on: ubuntu-latest
        permissions:
          contents: read
          packages: write
    ```

    `contents: read` peab alles jääma. Ilma selleta ei saa `actions/checkout` koodi lugeda.

**Paranda**

```bash
git add .github/workflows/ci.yml
git commit -m "N8 viga 1: build-and-push saab kirjutada GHCR-i"
git push
```

**Kontrolli**

Kõik kolm tööd on rohelised. Repositooriumi avalehel paremal, jaotises **Packages**, on pakett. Ava see. Tag'id on `latest` ja seitsmemärgiline räsi. Võrdle räsi oma viimase commit'iga:

```bash
git log --oneline -1
```

??? warning "Kui `docker push` on ikka `denied`"
    - Kontrolli, et `permissions` on töö `build-and-push` all ja taane on sama mis real `runs-on`.
    - Ava uuesti **Set up job**. Kui seal on `Packages: write` ja push ikka kukub, ütle õpetajale.
    - Kui hoopis `actions/checkout` kukub (`Repository not found`), puudub `contents: read`.

**Küsimus:** miks oli `GITHUB_TOKEN`-il vaikimisi õigus pakette ainult lugeda? (README küsimus 1 ja tabeli rida 1)

### 2.1 Olekumärk README-s

Konveier on nüüd roheline. Et seda ei peaks iga kord vahekaardilt **Actions** otsima, lisa README algusesse **olekumärk** (status badge). See on väike pilt, mis näitab töövoo viimase käivituse tulemust harus `main`: roheline `passing` või punane `failing`. Avatud lähtekoodiga projektides on see tavaliselt README esimene rida.

**Ülesanne**

1. Ava vahekaardil **Actions** viimane roheline käivitus.
2. Paremal üleval on nupp **⋯**. Vali **Create status badge**.
3. Jäta väljadele **Branch** ja **Event** vaikeväärtused (`Default branch` on `main`) ja vajuta **Copy status badge Markdown**.
4. Kleebi kopeeritud rida README-s esimese pealkirja alla. Rida on kujul:

    ```markdown
    [![CI/CD](https://github.com/hkhk-automation/<sinu-repo>/actions/workflows/ci.yml/badge.svg)](https://github.com/hkhk-automation/<sinu-repo>/actions/workflows/ci.yml)
    ```

5. Salvesta muudatus ja saada see GitHubi:

    ```bash
    git add README.md
    git commit -m "N8: olekumärk README-s"
    git push
    ```

**Kontrolli**

Ava repositooriumi avaleht. README all on roheline märk `CI/CD passing`. Märgil klõpsates avaneb töövoo käivituste nimekiri.

Repositoorium on privaatne, seega näevad märki ainult need, kellel on repositooriumile ligipääs. Avalikus repositooriumis näeb seda igaüks.

**Ennusta.** Osas 3 kukub test. Mida näitab märk siis?

---

## Osa 3 · Viga 2: katkine kood jõuab registrisse

Konveier on nüüd roheline. Kontrolli, kas registrisse jõuab ainult testitud kood. Kolleeg muudab tervitust ja ei käivita teste.

**Ülesanne**

Muuda failis `flask/app.py` tervitus kujule `Tervist konteinerist!`. Ära käivita `pytest`-i. Saada muudatus GitHubi:

```bash
git add flask/app.py
git commit -m "N8: uus tervitus"
git push
```

**Sümptom**

`test` on punane. `konteiner` on hall (`skipped`). Vaata, mis olekus on `build-and-push`. Ava **Packages** ja vaata tag'e.

**Ennusta.** Test kukkus. Kas registrisse jõudis uus image? Kui jõudis, siis miks? Kirjuta oletus issue väljale **Hüpotees**.

**Uuri**

1. Käivituse lehel on tööde skeem. Vaata, millised tööd on noolega ühendatud.
2. Ava tööd `test` ja `build-and-push`. Võrdle, mis kell kumbki alustas.
3. Võrdle failis `ci.yml` töö `konteiner` algust töö `build-and-push` algusega.

??? success "Põhjus ja parandus"
    `build-and-push` on roheline ja **Packages** all on uus räsi. `latest` näitab nüüd koodi, mille test kukkus. Skeemil on nool ainult `test` ja `konteiner` vahel. `build-and-push` alustas samal ajal kui `test`. Tööl puudub `needs`, seega ei oota see teisi ([loengu §5](lecture.md#5-millal-image-ehitatakse)).

    Lisa tööle järjekord. `konteiner` ootab juba `test`-i, seega piisab `konteiner`-ist:

    ```yaml
      build-and-push:
        needs: konteiner
        runs-on: ubuntu-latest
    ```

**Paranda**

Jäta tervitus veel katki. Nii näed, kas parandus töötab:

```bash
git add .github/workflows/ci.yml
git commit -m "N8 viga 2: image alles pärast teste"
git push
```

**Kontrolli**

`test` on punane. `konteiner` ja `build-and-push` on hallid. **Packages** all uut räsi ei ole. Skeemil on nool kõigi kolme töö vahel.

Pane tervitus tagasi (`Tere konteinerist!`). Käivita `pytest flask -v` ja saada parandus GitHubi:

```bash
git add flask/app.py
git commit -m "N8: tervitus tagasi"
git push
```

Kõik kolm tööd on rohelised ja järjest.

**Küsimus:** miks peab image'i ehitus testide järel ootama? (README küsimus 2 ja tabeli rida 2)

---

## Osa 4 · Viga 3: pull request jõuab registrisse

N7-s läks kood harusse `main` pull request'i kaudu. Pull request'i koodi pole keegi veel üle vaadanud. Seega ei tohi see registrisse jõuda. Kontrolli, kas see nii on.

**Ülesanne**

Tee uus haru:

```bash
git switch -c n08-tervitus
```

Muuda failis `flask/app.py` tervitus kujule `Tere konteinerist, N8!`. Sõna `Tere` jääb alles, seega test läbib. Saada haru GitHubi:

```bash
pytest flask -v
git add flask/app.py
git commit -m "N8: tervitus N8"
git push -u origin n08-tervitus
```

Ava GitHubis pull request `n08-tervitus` → `main`. **Ära seda veel liida.**

**Sümptom**

Vaata vahekaarti **Actions**. Vaata pull request'i lehel kasti **Checks**. Vaata ka **Packages** all tag'e.

**Ennusta.** Kood on ainult harus `n08-tervitus`. Kas see jõudis registrisse? Kui jõudis, siis mis selle käivitas? Kirjuta oletus issue väljale **Hüpotees**.

**Uuri**

1. Vahekaardil **Actions** on iga käivituse all sündmus ja haru. Mitu käivitust tekkis viimase commit'i kohta? Mis sündmused need olid?
2. Võrdle **Packages** all uusimat räsi kahe commit'iga:

    ```bash
    git log --oneline -1
    git log --oneline -1 origin/main
    ```

3. Ava failis `ci.yml` plokk `on:` ja töö `build-and-push` päis. Kas miski ütleb, millises harus või millise sündmusega see töö käivitub?

??? success "Põhjus ja parandus"
    Sama commit'i kohta on kaks käivitust. Üks on `push` harus `n08-tervitus`, teine on `pull_request`. Mõlemas oli `build-and-push` roheline. **Packages** all on haru commit'i räsi. `latest` näitab nüüd koodi, mida keegi pole üle vaadanud.

    Põhjuseid on kaks. `push:` ilma harudeta käivitab töövoo iga haru igal push'il. Tööl `build-and-push` ei ole tingimust, mis jätaks selle pull request'is vahele ([loengu §5](lecture.md#5-millal-image-ehitatakse)).

    Paranda sündmus. Push käivitab töövoo ainult harus `main`:

    ```yaml
    on:
      push:
        branches: [main]
      pull_request:
    ```

    Lisa tööle tingimus. `build-and-push` käivitub ainult push'i korral:

    ```yaml
      build-and-push:
        needs: konteiner
        if: github.event_name == 'push'
        runs-on: ubuntu-latest
    ```

    `pull_request` jääb alles. Pull request'is peavad testid käivituma.

**Paranda**

Tee parandus samas harus. Nii läbib see pull request'i nagu iga teine muudatus:

```bash
git add .github/workflows/ci.yml
git commit -m "N8 viga 3: pull request ei saada image'it registrisse"
git push
```

**Kontrolli**

Uue commit'i kohta on üks käivitus sündmusega `pull_request`. Selles on `test` ja `konteiner` rohelised. `build-and-push` on hall. **Packages** all uut räsi ei ole.

Liida pull request GitHubis (**Merge pull request**). Liitmine on push harusse `main`. Uues käivituses on `build-and-push` roheline. Too muudatus oma masinasse:

```bash
git switch main
git pull
git log --oneline -1
```

Viimase commit'i räsi on sama, mis **Packages** all uusim tag.

**Küsimus:** miks ei tohi pull request'i kood registrisse jõuda? (README küsimus 3 ja tabeli rida 3)

---

## Osa 5 · Server

Image on registris. Nüüd tõmbab server selle sealt ja käivitab. Seda teeb skript `server/paigalda.sh` ([loengu §6](lecture.md#6-server-tombab-imagei)). Loe skript enne käivitamist läbi:

```bash
cat server/paigalda.sh
```

### 5.1 Viga 4: server ei saa image'it

**Ülesanne**

```bash
bash server/paigalda.sh
```

**Sümptom**

Pärast rida `== image ...` lõpetab skript veaga.

**Ennusta.** Image on registris olemas, sa nägid seda **Packages** all. Miks ei saa server seda kätte? Kirjuta oletus issue väljale **Hüpotees**.

**Uuri**

1. Loe veateade lõpuni. Mis on viimane sõna?
2. Ava GitHubis pakett. Paremal on näha, kas pakett on **Private** või **Public**.
3. Kontrolli, kas Docker on `ghcr.io`-sse sisse logitud:

    ```bash
    grep ghcr.io ~/.docker/config.json
    ```

??? success "Põhjus ja parandus"
    Veateade on umbes selline:

    ```text
    Error response from daemon: Head "https://ghcr.io/v2/hkhk-automation/.../manifests/latest": unauthorized
    ```

    Viimane sõna võib olla ka `denied`. Mõlemad tähendavad, et server pole registrisse sisse logitud. Pakett on privaatne. `grep` ei leia failist rida `ghcr.io`. Konveieri `GITHUB_TOKEN` kehtib ainult käivituse ajal, serveris seda pole.

    Tee GitHubis isiklik token, mis tohib ainult lugeda ([juhend](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)):

    1. Vali profiilipilt → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** → **Generate new token (classic)**.
    2. **Note**: `proxmox1 GHCR`. **Expiration**: 30 päeva. Õigus ainult **read:packages**.
    3. Kopeeri token. GitHub näitab seda ainult üks kord.

    Logi sisse. Kasutajanimi on sinu GitHubi kasutajanimi. Parooli asemel kleebi token. Ekraanil seda ei näidata:

    ```bash
    docker login ghcr.io -u <sinu-github-kasutaja>
    ```

**Kontrolli**

`docker login` lõpetab reaga `Login Succeeded`. `grep ghcr.io ~/.docker/config.json` leiab nüüd rea. Käivita skript uuesti:

```bash
bash server/paigalda.sh
```

`docker pull` õnnestub. Skript jõuab järgmise veani.

??? warning "Kui sisselogimine ei õnnestu"
    - `unauthorized: authentication required`: tokenil puudub õigus `read:packages` või kopeerisid selle poolikult. Tee uus token.
    - `permission denied while trying to connect to the Docker daemon socket`: sinu kasutaja pole grupis `docker` (N5 Osa 0).

**Küsimus:** miks on serveri tokenil ainult õigus `read:packages`? (README küsimus 4 ja tabeli rida 4)

### 5.2 Viga 5: konteiner ei vasta

**Sümptom**

Skript jõuab reani `== versioon`. `curl` proovib mitu korda ja lõpetab veaga.

**Ennusta.** Konteiner käivitus. Miks ei saa `curl` vastust? Kirjuta oletus issue väljale **Hüpotees**.

**Uuri**

```bash
docker ps --filter name=flask-cd
docker logs flask-cd
```

Vaata `docker ps` veergu PORTS. Vaata logis rida `Running on`. Mis port on kummaski?

??? success "Põhjus ja parandus"
    `curl` annab `curl: (56) Recv failure: Connection reset by peer` või `curl: (52) Empty reply from server`. Sama sümptomit nägid N5 Osa 10-s.

    `docker ps` näitab `0.0.0.0:8088->80/tcp`. Logis on `Running on http://...:5000`. Skript suunab serveri pordi 8088 konteineri porti 80. Seal ei kuula keegi. Flask kuulab pordil 5000.

    Paranda failis `server/paigalda.sh` rida `docker run`:

    ```bash
    docker run -d --name flask-cd --restart unless-stopped -p 8088:5000 "$IMAGE:$TAG"
    ```

**Kontrolli**

```bash
bash server/paigalda.sh
curl localhost:8088
```

Skripti viimane rida on seitsmemärgiline räsi. `curl localhost:8088` vastab tervitusega.

**Küsimus:** mida tähendavad `-p 8088:5000` kaks numbrit? (README küsimus 5 ja tabeli rida 5)

### 5.3 Viimane versioon serverisse

Skripti parandus peab jõudma ka repositooriumi. Push harusse `main` ehitab samas uue image'i:

```bash
git add server/paigalda.sh
git commit -m "N8 viga 5: konteineri port 5000"
git push
```

Oota, kuni käivitus vahekaardil **Actions** on roheline. Siis paigalda uus versioon ja salvesta väljund logifaili:

```bash
bash server/paigalda.sh 2>&1 | tee logid/server.txt
git log --oneline -1
```

**Kontrolli**

`logid/server.txt` viimane rida on sama räsi, mis `git log --oneline -1` alguses. Sama räsi on ka **Packages** all uusim tag. Server töötab koodiga, mille sa just GitHubi saatsid. Serveris ei ehitatud midagi.

??? warning "Kui räsi on vanem kui viimane commit"
    Käivitasid skripti enne, kui `build-and-push` lõpetas. Siis näitas `latest` veel eelmist image'it. Oota rohelist käivitust ja käivita skript uuesti.

**Küsimus:** mis versioon töötab serveris ja kust tead, et see on sama mis GHCR-is? (README küsimus 6)

### 5.4 Räsi järgi: issue, commit, image, server

Commit'i räsi seob kõik kokku. Issue viitab commit'ile, image'i tag on sama räsi ja server näitab seda aadressil `/versioon`. Selles sammus liigud räsi järgi tagasi ja edasi.

**Ülesanne**

Ava suletud issue, mis on osa 3 vea kohta (katkine kood jõudis registrisse). Selles on link paranduse commit'ile. Leia sama räsi käsurealt:

```bash
git log --oneline
git show --stat <räsi>
```

`git log --oneline` näitab iga commit'i räsi ja esimest rida. `git show --stat <räsi>` näitab, mis failid selles commit'is muutusid.

Osa 3 alguses jõudis registrisse image, mille test kukkus. Leia `git log --oneline` väljundist selle commit'i räsi. Vaata, mis selles muutus:

```bash
git show <räsi> -- flask/app.py
```

**Ennusta.** Kui käivitad serveris selle räsiga image'i, mida vastab `curl localhost:8088`?

Käivita see versioon serveris:

```bash
bash server/paigalda.sh <räsi>
curl localhost:8088
```

??? success "Oodatav tulemus"
    `paigalda.sh` viimane rida on sama räsi ja `curl` vastab `Tervist konteinerist!`. Registris on iga ehitatud image alles. Vana versiooni käivitamiseks piisab selle räsist. Serveris ei ehitatud midagi.

Pane viimane versioon tagasi:

```bash
bash server/paigalda.sh
curl localhost:8088/versioon
git log --oneline -1
```

**Kontrolli**

`/versioon` vastus ja `git log --oneline -1` räsi on samad.

**Küsimus:** tootmises läks viga käima. Kuidas leiad räsi järgi, mis commit selle tõi ja millise issue parandus seda puudutab? Kuidas lähed eelmisele versioonile tagasi?

---

## Osa 6 · Sama konveier Jenkinsis

GitHub Actions on teenus: GitHub haldab masinaid, mis konveierit käivitavad. **Jenkins** on programm, mille paigaldad ise ([loengu §8](lecture.md#8-cicd-tooriistad-ja-litsentsid)). Selles osas käivitad Jenkinsi konteinerina ja paned sinna sama konveieri: testid ja image'i ehituse.

Jenkins töötab masinas `proxmox1`, sest seal on Docker. Masinas `proxmox2` on N5-st ainult Podman.

### 6.1 Jenkinsi failid

Repositooriumis on kaks uut faili. Ava mõlemad:

```bash
cat jenkins/Dockerfile
cat Jenkinsfile
```

`jenkins/Dockerfile` ehitab Jenkinsi image'i. Alus on ametlik image `jenkins/jenkins:lts-jdk21` ([Jenkins Dockeris](https://www.jenkins.io/doc/book/installing/docker/)). Käsk `jenkins-plugin-cli` paigaldab plugin'id juba ehitamisel. **Plugin** on Jenkinsi lisamoodul. Ilma plugin'iteta ei oska Jenkins isegi Git'i kasutada.

| Plugin | Mida teeb |
|---|---|
| [`git`](https://plugins.jenkins.io/git/) | toob koodi Git'i repositooriumist |
| [`workflow-aggregator`](https://plugins.jenkins.io/workflow-aggregator/) | lubab kirjutada konveieri faili `Jenkinsfile` |
| [`pipeline-graph-view`](https://plugins.jenkins.io/pipeline-graph-view/) | näitab konveieri samme graafiliselt |
| [`dark-theme`](https://plugins.jenkins.io/dark-theme/) | tume teema |

*Tabel 8.6. Plugin'id failis `jenkins/Dockerfile`.*

`Jenkinsfile` on konveier. See on sama mõttega kui `ci.yml`, aga teises keeles ([Jenkinsfile'i süntaks](https://www.jenkins.io/doc/book/pipeline/syntax/)):

| `ci.yml` (GitHub Actions) | `Jenkinsfile` (Jenkins) |
|---|---|
| `jobs:` ja tööd `test`, `konteiner` | `stages` ja etapid `test`, `konteiner` |
| `runs-on: ubuntu-latest` | `agent any`: konveier töötab Jenkinsi enda masinas |
| `actions/setup-python` paigaldab Pythoni | Python peab Jenkinsi image'is olemas olema |
| `needs: test` | etapid käivad järjest, kirjutatud järjekorras |
| `on: push` | `pollSCM`: Jenkins küsib ise, kas on uus commit (samm 6.6) |

*Tabel 8.7. Sama konveier kahes tööriistas.*

### 6.2 Jenkins käima

Jenkins vajab umbes 1 GB mälu. Kontrolli, kui palju mälu on vaba:

```bash
free -h
```

Kui veerus `available` on alla 1,5 GB, peata N6 rakendus: `cd ~/lab06 && docker compose down`, siis `cd ~/lab08`.

**Ülesanne**

Ehita Jenkinsi image ja käivita konteiner:

```bash
docker build -t minu-jenkins jenkins/
docker run -d --name jenkins --restart unless-stopped \
  -p 8081:8080 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "$(stat -c %g /var/run/docker.sock)" \
  minu-jenkins
```

| Võti | Miks |
|---|---|
| `-p 8081:8080` | Jenkins kuulab pordil 8080. Masinas on port 8080 N6 käes, seega kasutame 8081 |
| `-v jenkins_home:/var/jenkins_home` | Jenkinsi seaded on volume'is. Need jäävad alles, kui konteiner tehakse uuesti |
| `-v /var/run/docker.sock:...` | Jenkins saab kasutada masina Dockerit, et ehitada image'it |
| `--group-add ...` | Jenkinsi kasutaja saab õiguse Dockeri soklit kasutada |

*Tabel 8.8. Jenkinsi konteineri võtmed.*

**Kontrolli**

Jenkins käivitub umbes minutiga. Oota, kuni logis on rida `Jenkins is fully up and running`:

```bash
docker logs -f jenkins
```

Vajuta `Ctrl+C`, et logi vaatamine lõpetada. Ava brauseris `http://<proxmox1-IP>:8081`.

??? warning "Kui brauser Jenkinsit ei ava"
    Ava VS Code'is all vahekaart **PORTS** ja vali **Forward a Port**. Kirjuta `8081`. Siis ava brauseris `http://localhost:8081`.

### 6.3 Esimene sisselogimine

Jenkins küsib esimesel korral parooli. See on konteineri failis:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

1. Kleebi parool ja vajuta **Continue**.
2. Vali **Select plugins to install**, siis üleval **None** ja **Install**. Plugin'id on image'is juba olemas.
3. Loo administraatori kasutaja. Kirjuta parool üles.
4. **Jenkins URL** jäta samaks. Vajuta **Save and Finish** ja **Start using Jenkins**.

### 6.4 Konveier Jenkinsisse

Sinu repositoorium on privaatne. Jenkins vajab koodi lugemiseks tokenit. Tee GitHubis uus token (classic), nagu sammus 5.1. **Note**: `jenkins`. **Expiration**: 7 päeva. Õigus: **repo**.

Seadista Jenkinsis konveier:

1. Vali **New Item**. Nimi `lab08`, tüüp **Pipeline**, vajuta **OK**.
2. Keri lõiku **Pipeline**. **Definition**: `Pipeline script from SCM`. **SCM**: `Git`.
3. **Repository URL**: `https://github.com/hkhk-automation/<sinu-repo>.git`.
4. **Credentials** → **Add** → **Jenkins**. **Kind**: `Username with password`. **Username**: sinu GitHubi kasutajanimi. **Password**: token. **ID**: `github`. Vajuta **Add** ja vali see.
5. **Branch Specifier**: `*/main`. **Script Path**: `Jenkinsfile`. Vajuta **Save**.

### 6.5 Viga 6: Jenkinsis pole Pythonit

**Ülesanne**

Vajuta vasakul **Build Now**.

**Sümptom**

Käivitus on punane. Ava see ja vali **Pipeline Overview**. Plugin `pipeline-graph-view` näitab etappe graafiliselt. Etapp `test` on punane.

**Ennusta.** Samad testid läbisid sinu masinas ja GitHub Actionsis. Miks kukuvad need Jenkinsis? Kirjuta oletus issue väljale **Hüpotees**.

**Uuri**

1. Vali punane etapp ja loe logi viimased read.
2. Võrdle Pythonit masinas ja Jenkinsi konteineris:

    ```bash
    python3 --version
    docker exec jenkins python3 --version
    ```

3. Vaata tabelit 8.7. Kes paigaldas Pythoni GitHub Actionsis?

??? success "Põhjus ja parandus"
    Logis on rida `python3: not found`. Masinas `proxmox1` Python on, Jenkinsi konteineris mitte. GitHub Actionsis paigaldas Pythoni action `setup-python`. Jenkinsis peab selle paigaldama see, kes Jenkinsit haldab.

    Lisa failis `jenkins/Dockerfile` pärast rida `FROM` Pythoni paigaldus. Paigaldamiseks on vaja root'i õigusi. Pärast seda tuleb kasutaja `jenkins` tagasi, et Jenkins ei töötaks root'ina:

    ```dockerfile
    FROM jenkins/jenkins:lts-jdk21

    USER root
    RUN apt-get update \
        && apt-get install -y --no-install-recommends python3 python3-venv \
        && rm -rf /var/lib/apt/lists/*
    USER jenkins
    ```

    `python3-venv` on vajalik, sest `Jenkinsfile` teeb testide jaoks virtuaalkeskkonna.

**Paranda**

Image muutus. Ehita see uuesti ja tee konteiner uuesti, nagu N5 Osa 4-s. Seaded jäävad volume'isse alles:

```bash
docker build -t minu-jenkins jenkins/
docker rm -f jenkins
docker run -d --name jenkins --restart unless-stopped \
  -p 8081:8080 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "$(stat -c %g /var/run/docker.sock)" \
  minu-jenkins
```

**Kontrolli**

Logi uuesti Jenkinsisse ja vajuta **Build Now**. **Pipeline Overview** näitab kahte rohelist etappi. Etapp `konteiner` ehitas image'i masina Dockeriga:

```bash
docker images flask-jenkins
```

??? warning "Kui etapp `konteiner` kukub"
    - `docker: not found`: `jenkins/Dockerfile` real `COPY --from=docker:27-cli` on viga. Võrdle starteriga.
    - `permission denied while trying to connect to the Docker daemon socket`: `docker run` käsus puudub `--group-add`.

Salvesta parandus GitHubi:

```bash
git add jenkins/Dockerfile
git commit -m "N8 viga 6: Python Jenkinsi image'isse"
git push
```

**Küsimus:** lisa vigade tabelisse rida 6.

### 6.6 Jenkins ilma webhook'ita

GitHub Actions käivitub kohe pärast push'i. GitHub teab push'ist ise. Jenkinsile saab GitHub saata teate (**webhook**). Teade on HTTP päring Jenkinsi aadressile. Sinu Jenkins on kooli võrgus VPN-i taga. GitHub ei pääse sinna.

Seepärast on `Jenkinsfile`-is plokk `triggers` ja seal `pollSCM('H/5 * * * *')`. Jenkins küsib ise iga 5 minuti järel, kas harus `main` on uus commit. Täht `H` hajutab küsimise aja, et kõik konveierid ei küsiks samal minutil.

**Ennusta.** Sammu 6.5 lõpus saatsid GitHubi uue commit'i. Mis juhtub Jenkinsis järgmise 5 minuti jooksul?

**Kontrolli**

Oota kuni 5 minutit. Vasakul tekib uus käivitus. Ava see. Üleval on kirjas `Started by an SCM change`.

**Küsimus:** miks ei saa GitHub Jenkinsit ise käivitada ja mida teeb selle asemel `pollSCM`? (README küsimus 7)

### 6.7 Tume teema

Vali **Manage Jenkins** → **Appearance**. Lõigus **Themes** vali `Dark` ja vajuta **Save**. Selle võimaluse lisas plugin `dark-theme`.

Mõtle tagasi tabelile 8.7. GitHub Actionsis ei pidanud sa paigaldama serverit, plugin'eid ega Pythonit. Jenkinsis tegid kõike seda ise. Vastutasuks töötab Jenkins sinu võrgus ja seda saab seadistada nii, nagu firma vajab.

---

## Osa 7 · Korrektne lahendus

Kõik kuus parandust on nüüd sinu failides. Siin on need koos, nii nagu seda töökohas tehakse. Võrdle oma faile nendega. Kui midagi erineb, mõtle, kas sinu variant teeb sama asja. Näiteks `needs: [test, konteiner]` on samaväärne.

Rea selgituse näed, kui klõpsad numbril koodi kõrval.

```yaml
name: CI/CD

on:
  push:
    branches: [main] # (1)!
  pull_request: # (2)!

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
      - run: pip install -r flask/requirements.txt pytest
      - run: pytest flask -v

  konteiner:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: docker build -t flask-app ./flask
      - run: docker run -d -p 5000:5000 --name flask1 flask-app
      - run: curl -fsS --retry 10 --retry-all-errors --retry-delay 1 localhost:5000/health
      - if: failure()
        run: docker logs flask1

  build-and-push:
    needs: konteiner # (3)!
    if: github.event_name == 'push' # (4)!
    runs-on: ubuntu-latest
    permissions: # (5)!
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v7
      - name: Image'i nimi ja versioon # (6)!
        run: |
          echo "IMAGE=ghcr.io/${GITHUB_REPOSITORY,,}" >> "$GITHUB_ENV"
          echo "VERSIOON=${GITHUB_SHA::7}" >> "$GITHUB_ENV"
      - name: Ehita image # (7)!
        run: >
          docker build
          --build-arg VERSIOON=$VERSIOON
          --label org.opencontainers.image.source=$GITHUB_SERVER_URL/$GITHUB_REPOSITORY
          -t "$IMAGE:$VERSIOON" -t "$IMAGE:latest"
          ./flask
      - name: Logi GHCR-i sisse
        env:
          GHCR_TOKEN: ${{ secrets.GITHUB_TOKEN }} # (8)!
        run: echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin
      - name: Saada image GHCR-i
        run: docker push --all-tags "$IMAGE" # (9)!
```

1.  Push käivitab töövoo ainult harus `main`. Teiste harude push ei ehita image'it (viga 3).
2.  Pull request'is käivituvad testid. N7 lukk vajab neid enne liitmist.
3.  Image ehitatakse alles siis, kui `konteiner` on roheline. `konteiner` ootab omakorda `test`-i (viga 2).
4.  Pull request'i käivituses jääb töö vahele. Registrisse jõuab ainult liidetud kood (viga 3).
5.  Kirjutamisõigus registrisse ainult sellele tööle. `contents: read` on vajalik, et `actions/checkout` saaks koodi lugeda (viga 1).
6.  Image'i nimes on ainult väiketähed: `${GITHUB_REPOSITORY,,}`. Tag on commit'i lühiräsi: `${GITHUB_SHA::7}`.
7.  Samale image'ile kaks tag'i: räsi ja `latest`. `--build-arg` annab rakendusele versiooni. Silt `org.opencontainers.image.source` seob paketi repositooriumiga.
8.  Ajutine token, mis kehtib ainult selle käivituse ajal. Faili ei kirjutata ühtegi saladust.
9.  Saadab registrisse mõlemad tag'id.

Serveris logitakse sisse üks kord. Iga paigaldus on siis üks käsk:

```bash
docker login ghcr.io -u <sinu-github-kasutaja>   # token õigusega read:packages (viga 4)
bash server/paigalda.sh                          # docker pull ja docker run -p 8088:5000 (viga 5)
curl localhost:8088/versioon
```

| Rida skriptis `server/paigalda.sh` | Miks |
|---|---|
| `IMAGE="ghcr.io/hkhk-automation/${REPO,,}"` | sama nimi, mille konveier andis, väiketähtedega |
| `docker pull "$IMAGE:$TAG"` | server ei ehita, ta tõmbab registrist valmis image'i |
| `docker rm -f flask-cd` | vana konteiner eemaldatakse enne uue käivitamist |
| `--restart unless-stopped` | konteiner käivitub uuesti ka pärast masina taaskäivitust |
| `-p 8088:5000` | serveri port 8088 läheb konteineri porti 5000, kus Flask kuulab |

*Tabel 8.9. Serveri skripti read.*

Jenkinsi image (viga 6):

```dockerfile
FROM jenkins/jenkins:lts-jdk21

# (1)!
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-venv \
    && rm -rf /var/lib/apt/lists/*
# (2)!
USER jenkins

# (3)!
COPY --from=docker:27-cli /usr/local/bin/docker /usr/local/bin/docker

# (4)!
RUN jenkins-plugin-cli --plugins git workflow-aggregator pipeline-graph-view dark-theme
```

1.  Paketi paigaldamiseks on vaja root'i õigusi.
2.  Jenkins töötab jälle tavakasutajana. Kui keegi saab Jenkinsi üle kontrolli, ei ole tal konteineris root'i õigusi.
3.  Dockeri käsurea klient kopeeritakse ametlikust image'ist. Etapp `konteiner` kasutab seda.
4.  Plugin'id paigaldatakse ehitamisel. Iga uus Jenkinsi konteiner on kohe samade plugin'itega.

---

## Osa 8 · Töö esitamine

**Ülesanne**

1. Täida README-s vigade tabel. Sümptomi lahtrisse kopeeri rida logist või käsu väljundist. Põhjus ja parandus on kumbki üks lühike lause.
2. Vasta README küsimustele 1-7. Igaühele piisab ühest lausest.
3. Salvesta kõik ja saada GitHubi:

    ```bash
    git add README.md logid/server.txt
    git status --short
    git commit -m "N8: vigade tabel, vastused ja serveri logi"
    git push
    ```

**Kontrolli**

Töö on esitatud, kui kõik muudatused on GitHubis harus `main`. Automaatkontrolli tulemust näed vahekaardil **Actions** ja Classroom 50-s. Tahvlil on N8 vahelehel näha, mis masinas `proxmox1` töötab: sisselogimine `ghcr.io`-sse, image GHCR-ist, `/versioon` pordil 8088 ja Jenkins pordil 8081.

??? note "Automaatkontroll (100 punkti)"

    | Kontroll | Punktid |
    |---|---|
    | Failid olemas, N7 osa töötab, `logid/server.txt` olemas | 10 |
    | Viga 1: `build-and-push` saab kirjutada GHCR-i, image'i nimi ja tag'id õiged | 15 |
    | Viga 2: `build-and-push` ootab teste (`needs`) | 15 |
    | Viga 3: push ainult harus `main`, pull request'is töö vahele (`if`) | 15 |
    | Viga 5: `server/paigalda.sh` suunab pordi 5000 | 10 |
    | `logid/server.txt`: image GHCR-ist, viimane rida on räsi | 10 |
    | Nimi, vigade tabel ja küsimused README-s | 15 |
    | Viga 6: `Jenkinsfile` korras, `jenkins/Dockerfile` paigaldab Pythoni | 10 |

    Automaatkontroll ei ühendu sinu masinaga ega GHCR-iga. See loeb sinu faile ja käivitab teste. Viga 4 näitavad logi `logid/server.txt` ja tahvel.

??? warning "Kui automaatkontroll annab vea"
    - `pytest kukub`: tervitus failis `flask/app.py` peab sisaldama sõna `Tere` (osa 3).
    - `logid/server.txt viimane rida peab olema /versioon vastus`: skript lõpetas veaga. Paranda see ja käivita uuesti käsuga `tee` (samm 5.3).
    - `Vigade tabelis ja küsimustes on N vastust puudu`: README-s on `_vastus_` alles.

---

## Lisaülesanded

??? example "A · Vähim õigus kogu failis (keskmine)"
    Lisa faili `ci.yml` algusesse, enne rida `jobs:`, õigus, mis kehtib kõigile töödele:

    ```yaml
    permissions:
      contents: read
    ```

    Pärast push'i ava töö `test` samm **Set up job**. Mis muutus lõigus `GITHUB_TOKEN Permissions`? Mis õigused on nüüd tööl `build-and-push` ja miks?

??? example "B · Seinaekraan Jenkinsile (keskmine)"
    Lisa failis `jenkins/Dockerfile` plugin'ite loendisse [`build-monitor-plugin`](https://plugins.jenkins.io/build-monitor-plugin/). Ehita image ja tee konteiner uuesti (samm 6.5). Loo Jenkinsis uus vaade: **+** → **Build Monitor View** → vali `lab08`. Sellist vaadet näidatakse kontorites seinal suurel ekraanil. Mis värvi on `lab08`, kui konveier kukub?

---

*Edasi: [kodutöö](homework.md). Seal leiad ise vead väljalaske töövoos. N9 teema on infrastruktuur koodina.*
