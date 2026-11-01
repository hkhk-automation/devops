---
tags:
  - CD
  - GHCR
  - GitHubActions
---

# Loeng: automaatne ehitamine ja levitamine (CD)

**Kestus:** umbes 40 minutit tunni alguses, siis [praktikum](lab.md).
**Eeldus:** N7 praktikum: jobid `test` ja `konteiner`, `needs`, trigger'id `push` ja `pull_request`. N5: `docker build`, `docker run -p`.

N7-s kontrollis GitHub Actions iga push'i järel, kas kood ja konteiner töötavad. Image jäi aga runnerisse ja kadus koos sellega. Täna lisame konveierile kolmanda job'i: see ehitab image'i, paneb selle registrisse ja server tõmbab selle sealt. Praktikumis saad konveieri, mille kolleeg on juba kirjutanud, aga milles on viis viga. Loengu mõisted on need, mida vigade leidmiseks vaja läheb.

!!! abstract "Õpiväljundid"
    Pärast loengut ja praktikumi oskad:

    - selgitada, mis vahe on CI-l ja pideval tarnel (continuous delivery)
    - kirjeldada, mis on image'ite register ja kuidas on üles ehitatud image'i nimi GHCR-is
    - põhjendada, miks image saab tag'iks commit'i räsi ja miks ainult `latest` ei piisa
    - anda workflow'le `permissions` abil täpselt need õigused, mida see vajab
    - leida viga järjekorras: sümptom, hüpotees, tõend, parandus

---

## 1. CI-st pideva tarneni

N7 loengu tabelis 7.3 olid kolm astet. **CI** (continuous integration) kontrollib iga muudatust automaatselt. **Pidev tarne** (continuous delivery) läheb edasi: iga roheline muudatus `main` harus on automaatselt pakitud ja valmis paigaldamiseks. Paigalduse käivitab inimene. **Pidev paigaldus** (continuous deployment) paigaldab ka ise, inimest vahel ei ole. Sellega tegeleme N13-s.

Ilma pideva tarneta ehitab keegi image'i oma arvutis, saadab selle kuhugi ja käivitab serveris. Iga käsitsi samm on koht, kus võib eksida: image ehitati vanast harust, testid jäid käivitamata või serveris töötab versioon, mida keegi ei oska nimetada. Pideva tarne korral teeb need sammud alati sama workflow, ja Actions'i ajaloost näeb, mis commit'ist iga image tehti.

<figure markdown="span">
  ![GitHub Actions push'i peale harusse main: test, siis konteiner, siis build-and-push, igaühe vahel needs. build-and-push saadab image'i GHCR-i kahe tag'iga, 3f2a9c1 ja latest. Server proxmox1 tõmbab image'i, käivitab selle pordil 8088 ja curl /versioon vastab 3f2a9c1](../images/n08_cd_ahel.svg)
  <figcaption>Joonis 8.1. Pidev tarne: kolmas job paneb testitud image'i registrisse, server tõmbab selle sealt (Talvik, 2026).</figcaption>
</figure>

Serveri jaoks on oluline põhimõte **ehita üks kord, paigalda mitu korda**. Server ei ehita image'it ega vaja koodi. Ta tõmbab registrist täpselt sama faili, mille pipeline ehitas ja testis. Kui sama image läheb testserverisse ja tootmisse, on mõlemas sama tarkvara.

??? question "Kontrolli ennast"
    1. Kumb on N8 tulemus, pidev tarne või pidev paigaldus? Kes käivitab paigalduse?
    2. N6-s ehitas `docker compose up --build` image'i serveris. Mis võib minna valesti, kui kaks serverit ehitavad sama koodi ise?

---

## 2. Register ja GHCR

**Register** (container registry) on server, kus hoitakse image'eid. `docker push` saadab image'i registrisse ja `docker pull` tõmbab selle sealt. N5-s kasutasid Docker Hubi. Täna kasutame **GHCR**-i (GitHub Container Registry, aadress `ghcr.io`), sest kood ja pipeline on juba GitHubis ning pipeline saab sinna sisse logida ilma eraldi paroolita ([GHCR dokumentatsioon](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)).

Image'i nimi GHCR-is on kujul:

```text
ghcr.io/<omanik>/<nimi>:<tag>
ghcr.io/hkhk-automation/it24-automatiseerimine-lab-08-cd-ghcr-mtamm:3f2a9c1
```

Sinu repositoorium on organisatsioonis `hkhk-automation`, seega on omanik organisatsioon ja image'i nimi on repositooriumi nimi. Pipeline võtab selle muutujast `GITHUB_REPOSITORY`, nii et nime ei pea faili kirjutama.

Image'i nimes on lubatud ainult väiketähed. GitHubi kasutajanimes ja repositooriumi nimes võib olla suurtähti, ja siis annab `docker build` vea `repository name must be lowercase`. Seepärast teeb workflow nime enne kasutamist Bashi teisendusega `${GITHUB_REPOSITORY,,}` väiketähtedeks.

GHCR-is nimetatakse image'it **paketiks** (package). Pakett on repositooriumi avalehel paremal jaotises **Packages**. Kui repositoorium on privaatne, on ka pakett privaatne: tõmbamiseks peab sisse logima (§6). Silt `org.opencontainers.image.source` image'is seob paketi repositooriumiga, nii et repositooriumi õigused kehtivad ka paketile ([paketi sidumine repositooriumiga](https://docs.github.com/en/packages/learn-github-packages/connecting-a-repository-to-a-package)).

??? question "Kontrolli ennast"
    1. Kasutaja `MariTamm` repositooriumist tuleb image'i nimi `ghcr.io/hkhk-automation/lab-MariTamm`. Mis juhtub `docker build` käsuga?
    2. Miks ei pea pipeline'is olema kirjas sinu GitHubi kasutajanimi?

---

## 3. Tag'id: räsi ja `latest`

Tag on image'i silt. Ühel image'il võib olla mitu tag'i ja sama tag'i saab hiljem teisele image'ile ümber tõsta.

| Tag | Näide | Mida ütleb |
|---|---|---|
| `latest` | `:latest` | viimane ehitatud image; homme võib see olla teine image |
| commit'i lühiräsi | `:3f2a9c1` | täpselt see commit, millest image ehitati; ei muutu |
| versioon | `:v1.0.0` | väljalase, mille inimene märkis (kodutöö) |

*Tabel 8.1. Tag'id, mida N8 pipeline kasutab.*

Pipeline paneb igale image'ile kaks tag'i: räsi ja `latest`. Räsi tuleb muutujast `GITHUB_SHA`, Bashi teisendus `${GITHUB_SHA::7}` võtab sellest seitse esimest märki, sama mida näitab `git log --oneline`. Kui serveris töötab `:3f2a9c1`, tead täpselt, mis koodiga on tegu. Tagasipööramine eelmisele versioonile on eelmise räsiga image'i käivitamine.

Ainult `latest`-ist ei piisa, sest see ei ütle, mis versioon töötab. Kui kaks serverit tõmbasid `latest`-i eri päevadel, võib neis olla erinev tarkvara.

Starteris on rakendusel uus route `/versioon`. Pipeline annab ehitamisel `docker build --build-arg VERSIOON=<räsi>` ja `Dockerfile` paneb selle keskkonnamuutujaks. Nii ütleb töötav rakendus ise, mis commit'ist ta on tehtud.

---

## 4. Õigused: `GITHUB_TOKEN` ja `permissions`

Iga workflow'i käivituse jaoks loob GitHub ajutise tokeni `GITHUB_TOKEN`. See kehtib ainult selle käivituse ajal ja kaob pärast. Seda ei pea looma ega hoidma: workflow kasutab seda kujul `${{ secrets.GITHUB_TOKEN }}` ([GITHUB_TOKEN](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token)).

Tokenil on vaikimisi õigused, mille määrab organisatsioon. Organisatsioonis `hkhk-automation` saab token vaikimisi ainult lugeda: koodi ja pakette. Registrisse kirjutamiseks peab workflow õiguse ise küsima võtmega `permissions` ([õiguste määramine](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)):

```yaml
    permissions:
      contents: read
      packages: write
```

Kui `permissions` on kirjas, on tokenil ainult loetletud õigused ja kõik teised on keelatud. Seepärast peab `contents: read` jääma alles: ilma selleta ei saa `actions/checkout` privaatse repositooriumi koodi lugeda. Kui `permissions` on job'i all, kehtib see ainult selles job'is. See on **vähima õiguse põhimõte**: `test` ja `konteiner` ei vaja registrisse kirjutamist, seega ei saa ka nendes kasutatav võõras action registrit muuta.

Mis õigused tokenil tegelikult olid, näed iga job'i logis esimese sammu **Set up job** all: lõik `GITHUB_TOKEN Permissions`.

!!! warning "Saladus ei lähe workflow'i faili"
    Tokeneid ja paroole ei kirjutata `.yml` faili. Git'i ajalugu jääb alles ja kord commit'itud saladus on nähtav ka pärast kustutamist (N2, N7 kodutöö). `GITHUB_TOKEN` ei vaja faili üldse, muud saladused lähevad GitHub Secretsisse.

??? question "Kontrolli ennast"
    1. Sisselogimine GHCR-i õnnestub, aga `docker push` kukub sõnaga `denied`. Mida see ütleb tokeni kohta?
    2. Miks ei anna me kõigile job'idele `packages: write`?

---

## 5. Millal image ehitatakse

Registrisse peab jõudma ainult kood, mis on testitud ja üle vaadatud. Selle eest vastutavad workflow'is kolm asja.

**Järjekord: `needs`.** Ilma `needs`-ita käivituvad job'id korraga. Siis ehitatakse image ka siis, kui test kukub, ja `latest` hakkab näitama katkist koodi. N7 loengus lubasime: kolmas job tuleb ritta `needs: konteiner` taha. Actions'i lehel on järjekord näha noolena job'ide vahel.

**Trigger: `on`.** `push` ilma piiranguta käivitab workflow'i iga haru igal push'il. `push: branches: [main]` käivitab selle ainult `main` harus. `pull_request` käivitab testid pull request'is, ja seda on vaja, sest N7 lukk nõuab rohelist testi enne liitmist.

**Tingimus: `if`.** Pull request'i käivitus kasutab sama workflow'i. Et `build-and-push` jääks seal vahele, on job'il tingimus. Muutuja `github.event_name` ütleb, mis sündmus workflow'i käivitas: `push` või `pull_request` ([sündmused](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)). Kui tingimus ei kehti, on job hall ja märgitud `skipped`.

<figure markdown="span">
  ![Ülemine rida pull_request: test ja konteiner rohelised, build-and-push hall ja skipped, registrisse ei jõua midagi. Alumine rida push harusse main: test, konteiner ja build-and-push, mis saadab image'i GHCR-i. All read on: push: branches: [main], pull_request ja if: github.event_name == 'push'](../images/n08_pr_vs_main.svg)
  <figcaption>Joonis 8.2. Pull request'is käivad testid, registrisse jõuab ainult liidetud kood (Talvik, 2026).</figcaption>
</figure>

??? question "Kontrolli ennast"
    1. Push'id harusse `n08-tervitus` ja avad pull request'i. Mitu workflow'i käivitust tekib, kui trigger on `push:` ilma harudeta ja `pull_request:`?
    2. Miks on pull request'i koodi registrisse saatmine ohtlik, kuigi testid olid rohelised?

---

## 6. Server tõmbab image'i

Server ei näe GitHubi runnerit ja runner ei pääse kooli võrku. Seepärast ei saada pipeline image'it serverisse. Server tõmbab selle ise registrist. Selleks on vaja kolme asja.

**Sisselogimine.** Pakett on privaatne, seega küsib GHCR tõmbamisel tokenit. `GITHUB_TOKEN` kaob pärast workflow'i lõppu ja serveris seda pole. Server kasutab sinu isiklikku tokenit (personal access token, classic), millel on ainult õigus `read:packages`. Kui token lekib, saab sellega image'eid tõmmata, aga mitte muuta ([autentimine tokeniga](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic)). `docker login` salvestab tokeni faili `~/.docker/config.json`, seega anna tokenile ka lühike aegumise tähtaeg.

**Tõmbamine ja käivitamine.** `docker pull` ja `docker run` on samad käsud, mis N5-s. Võti `-p 8088:5000` tähendab: serveri port 8088 suunatakse konteineri porti 5000. Konteineri port peab olema see, kus rakendus kuulab. N5 Osa 10-s nägid, mis juhtub, kui nii ei ole.

**Skript.** Kaks käsku saab iga kord käsitsi sisestada, aga siis peab meeles pidama nime, tag'i, porti ja vana konteineri eemaldamist. Starteris on skript `server/paigalda.sh`, mis teeb need sammud alati samas järjekorras. N13-s käivitab sama sammu pipeline ise.

??? question "Kontrolli ennast"
    1. Miks ei piisa serveris tokenist õigusega `write:packages`, kuigi see lubab ka lugeda?
    2. `docker ps` näitab veerus PORTS `0.0.0.0:8088->80/tcp`, rakendus kuulab pordil 5000. Mida vastab `curl localhost:8088`?

---

## 7. Vea leidmine: sümptom, hüpotees, tõend, parandus

Praktikumis on konveier juba kirjutatud, aga katki. Kõige aeglasem viis seda parandada on muuta juhuslikult ridu ja vaadata, kas läheb roheliseks. Kiirem on sama järjekord iga vea juures.

<figure markdown="span">
  ![Neli kasti järjest: 1 Sümptom (punane job, rida logis, curl vastus), 2 Hüpotees (mis võib olla põhjus, mis failis, mis real), 3 Tõend (Set up job, docker ps, logs), 4 Parandus (üks muudatus korraga, siis kontroll uuesti). Tõendist tagasi hüpoteesini katkendlik nool: tõend ei klapi, uus hüpotees](../images/n08_veaotsing.svg)
  <figcaption>Joonis 8.3. Vea otsimise järjekord. Kui tõend hüpoteesi ei kinnita, tuleb uus hüpotees (Talvik, 2026).</figcaption>
</figure>

1. **Sümptom** on see, mida näed: mis job on punane, mis samm, mis rida logis. Loe veateade lõpuni, sest olulisim sõna on tihti viimane.
2. **Hüpotees** on oletus põhjuse kohta koos kohaga: „tokenil pole kirjutamisõigust, `ci.yml` job `build-and-push`“.
3. **Tõend** on kontroll, mis hüpoteesi kinnitab või lükkab ümber, enne kui midagi muudad.
4. **Parandus** on üks muudatus. Pärast seda kontrolli sama sümptomit uuesti.

| Kus vaadata | Mida näitab |
|---|---|
| Actions → käivitus → job → samm | veateade ja sammu väljund |
| job'i samm **Set up job** → `GITHUB_TOKEN Permissions` | mis õigused tokenil olid |
| käivituse leht, job'ide skeem | järjekord: kas job'ide vahel on nool (`needs`) |
| käivituse pealkiri ja sündmus (`push`, `pull_request`) | mis sündmus workflow'i käivitas ja mis harus |
| **Packages** → pakett → tag'id | mis image'id registrisse jõudsid |
| `docker ps`, veerg PORTS | kuhu port on suunatud |
| `docker logs <konteiner>` | mida rakendus konteineris ise ütleb |

*Tabel 8.2. Kust leida tõend.*

Kõik vead ei tee pipeline'i punaseks. Kui image jõuab registrisse katkisest koodist, on kõik rohelised. Sellist viga näeb ainult siis, kui kontrollid tulemust: mis registris on ja mis serveris töötab.

---

## Kokkuvõte

??? abstract "Kokkuvõte"

    | Mõiste | Lühidalt |
    |---|---|
    | pidev tarne | iga roheline muudatus `main` harus on registris paigaldamiseks valmis |
    | ehita üks kord | image ehitatakse pipeline'is, server ainult tõmbab |
    | GHCR | `ghcr.io/<omanik>/<nimi>:<tag>`, nimi väiketähtedega |
    | tag | räsi ütleb täpse versiooni, `latest` ainult viimase |
    | `permissions` | `packages: write` ainult job'il, mis registrisse kirjutab |
    | `needs`, `on`, `if` | ehitus pärast teste, ainult `main` harus, mitte pull request'is |
    | serveri token | isiklik token õigusega `read:packages` |
    | vea otsimine | sümptom, hüpotees, tõend, parandus |

*Edasi: [praktikum](lab.md). Esimese vea teete koos õpetajaga, ülejäänud neli paaris. Seejärel [kodutöö](homework.md).*
