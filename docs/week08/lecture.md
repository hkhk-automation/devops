---
tags:
  - CD
  - GHCR
  - GitHubActions
  - Jenkins
---

# Loeng: automaatne ehitamine ja levitamine (CD)

**Eeldus:** N7 praktikum ja N5 Docker (`docker build`, `docker run -p`).

N7-s kontrollis GitHub Actions iga muudatust. Konveier käivitas testid ja ehitas image'i. Kui käivitus lõppes, kadus image koos runneriga. Täna jõuab image registrisse ja sealt serverisse.

Praktikumis parandad konveierit, milles on vead. Loengus on mõisted, mida vigade leidmiseks vaja läheb.

??? abstract "Õpiväljundid"
    Pärast loengut ja praktikumi oskad:

    - selgitada, mis vahe on CI-l ja pideval tarnel
    - kirjeldada, mis on image'ite register ja kuidas on image'i nimi GHCR-is üles ehitatud
    - põhjendada, miks image saab tag'iks commit'i räsi
    - anda töövoole täpselt need õigused, mida see vajab
    - leida viga järjekorras: sümptom, hüpotees, tõend, parandus
    - võrrelda GitHub Actionsit, GitLabi ja Jenkinsit ning nende litsentse

## 1. CI-st pideva tarneni

Meenuta N7 sõnu. **Töövoog** (workflow) on fail kaustas `.github/workflows/`. Töövoos on **tööd** (jobs), näiteks `test` ja `konteiner`. Igas töös on **sammud** (steps). Iga kord, kui töövoog käivitub, tekib vahekaardile **Actions** uus **käivitus** (run).

<figure markdown="span">
  ![Vasakul sündmused (on:): push harusse main, pull_request, schedule, workflow_dispatch. Sündmus käivitab töövoo .github/workflows/ci.yml. Töövoos on kolm tööd: test, konteiner ja build-and-push, nende vahel nooled needs. Iga töö all on sammud, näiteks checkout, docker build, docker push. Paremal märkus: ilma needs'ita käivituvad kõik tööd korraga](../images/n08_moisted.svg)
  <figcaption>Joonis 8.1. Sündmus käivitab töövoo, töövoos on tööd, töös on sammud. `needs` paneb tööd järjekorda (Talvik, 2026).</figcaption>
</figure>

Automaatne tarne käib kolmes astmes. **CI** (continuous integration) kontrollib iga muudatust automaatselt: testid ja ehitus. **Pidev tarne** (continuous delivery) tähendab, et iga roheline muudatus on pakitud ja paigaldamiseks valmis, aga paigalduse käivitab inimene. **Pidev paigaldus** (continuous deployment) paigaldab ise ja inimest vahel ei ole.

??? note "Tabel 8.1. CI ja CD astmed"
    | Aste | Mida teeb | Millal |
    |---|---|---|
    | CI (continuous integration) | kontrollib iga muudatust automaatselt | N7 |
    | pidev tarne (continuous delivery) | iga roheline muudatus on pakitud ja paigaldamiseks valmis | täna |
    | pidev paigaldus (continuous deployment) | paigaldab ka ise, inimest vahel pole | N13 |

Täna teeme pideva tarne. Konveier ehitab image'i ja paneb selle registrisse. Paigalduse käivitab inimene.

Miks seda vaja on? Kui image'i ehitab inimene oma arvutis, võib ta eksida. Ta võib ehitada vale haru. Ta võib unustada testid. Hiljem ei tea keegi, mis versioon serveris töötab. Konveier teeb samad sammud iga kord ühtemoodi ja jätab ajaloo.

<figure markdown="span">
  ![GitHub Actions push'i peale harusse main: test, siis konteiner, siis build-and-push, igaühe vahel needs. build-and-push saadab image'i GHCR-i kahe tag'iga, 3f2a9c1 ja latest. Server proxmox1 tõmbab image'i, käivitab selle pordil 8088 ja curl /versioon vastab 3f2a9c1](../images/n08_cd_ahel.svg)
  <figcaption>Joonis 8.2. Pidev tarne: kolmas töö paneb testitud image'i registrisse, server tõmbab selle sealt (Talvik, 2026).</figcaption>
</figure>

Server ei ehita image'it. Ta tõmbab registrist sama faili, mille konveier ehitas ja testis. Seda põhimõtet nimetatakse **ehita üks kord, paigalda mitu korda**. Kui sama image läheb testserverisse ja tootmisse, töötab mõlemas sama tarkvara.

??? question "Kontrolli ennast"
    1. Kas täna teeme pideva tarne või pideva paigalduse? Kes käivitab paigalduse?
    2. N6-s ehitas `docker compose up --build` image'i serveris. Mis võib minna valesti, kui kaks serverit ehitavad sama koodi ise?

## 2. Register ja GHCR

Miks registrit üldse vaja on? Iga töö saab GitHubis uue tühja virtuaalmasina (runneri). Kui töö lõpeb, kustutatakse masin koos kõigega, mis seal tehti. Ka image kaob. Alles jääb ainult see, mis saadeti masinast välja.

<figure markdown="span">
  ![Ühes käivituses kolm runnerit: runner 1 teeb testi, runner 2 ehitab konteineri ja image kaob koos masinaga, runner 3 ehitab image'i uuesti ja saadab selle push'iga GHCR-i, kus tag'id 3f2a9c1 ja latest jäävad alles. Server proxmox1 tõmbab image'i GHCR-ist pull'iga. All märkus: runnerisse tuleb väljast ainult see, mida töövoog küsib](../images/n08_runnerid.svg)
  <figcaption>Joonis 8.3. Runner kustutatakse pärast tööd. Image jääb alles ainult registris (Talvik, 2026).</figcaption>
</figure>

**Register** on server, kus hoitakse image'eid. Käsk `docker push` saadab image'i registrisse. Käsk `docker pull` tõmbab selle sealt.

N5-s kasutasid Docker Hubi. Täna kasutame **GHCR**-i (GitHub Container Registry, aadress `ghcr.io`). Kood ja konveier on juba GitHubis. Seepärast saab konveier GHCR-i sisse logida ilma eraldi paroolita ([GHCR dokumentatsioon](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)).

Image'i nimi GHCR-is on kolmeosaline:

```text
ghcr.io/<omanik>/<nimi>:<tag>
ghcr.io/hkhk-automation/it24-automatiseerimine-lab-08-cd-ghcr-mtamm:3f2a9c1
```

Sinu repositoorium on organisatsioonis `hkhk-automation`. Seega on omanik organisatsioon ja nimi on repositooriumi nimi. Konveier võtab selle muutujast `GITHUB_REPOSITORY`. Sinu nime ei pea faili kirjutama.

Image'i nimes on lubatud ainult väiketähed. Repositooriumi nimes võib olla suurtähti, näiteks kasutajanimest. Siis annab `docker build` vea `repository name must be lowercase`. Seepärast teeb konveier nime enne kasutamist väiketähtedeks: `${GITHUB_REPOSITORY,,}`. Kaks koma on Bashi märk, mis muudab tähed väikesteks.

GitHub nimetab image'it **paketiks** (package). Pakett on repositooriumi avalehel paremal, jaotises **Packages**. Kui repositoorium on privaatne, on ka pakett privaatne. Siis peab server enne tõmbamist sisse logima (§6).

Registreid on palju. Konveier logib igasse neist sisse veidi teisiti:

??? note "Tabel 8.2. Levinud registrid"
    | Register | Kes haldab | Kuidas konveier sisse logib | Millal valitakse |
    |---|---|---|---|
    | [Docker Hub](https://docs.docker.com/docker-hub/) | Docker Inc | [juurdepääsutoken](https://docs.docker.com/security/for-developers/access-tokens/) GitHub Secretis ([näide](https://docs.docker.com/build/ci/github-actions/)) | avalikud image'id, mida kõik saavad tõmmata |
    | GHCR | GitHub | `GITHUB_TOKEN`, eraldi saladust pole | kood ja konveier on GitHubis |
    | [AWS ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html) | Amazon | IAM-roll [OIDC kaudu](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws), siis [`amazon-ecr-login`](https://github.com/aws-actions/amazon-ecr-login) | serverid töötavad AWS-is |
    | [GitLab Container Registry](https://docs.gitlab.com/user/packages/container_registry/build_and_push_images/) | GitLab | muutujad `CI_REGISTRY_USER` ja `CI_REGISTRY_PASSWORD`, mille GitLab annab igale tööle | kood ja konveier on GitLabis |

**OIDC** tähendab, et konveier ei hoia AWS-i parooli üldse. GitHub annab käivitusele lühiajalise tõendi ja AWS vahetab selle ajutiste õiguste vastu. Põhimõte on sama mis `GITHUB_TOKEN`-il: ajutine võti on parem kui püsiv saladus.

??? question "Kontrolli ennast"
    1. Repositooriumi nimi on `lab-MariTamm`. Mis juhtub, kui image'i nimeks saab `ghcr.io/hkhk-automation/lab-MariTamm`?
    2. Miks ei pea konveieri failis olema sinu GitHubi kasutajanimi?

## 3. Tag'id: räsi ja `latest`

**Tag** on image'i nimi pärast koolonit. Ühel image'il võib olla mitu tag'i. Tag'i saab hiljem teisele image'ile ümber tõsta.

??? note "Tabel 8.3. Tag'id, mida N8 konveier kasutab"
    | Tag | Näide | Mida ütleb |
    |---|---|---|
    | `latest` | `:latest` | viimane ehitatud image; homme võib see olla teine |
    | commit'i lühiräsi | `:3f2a9c1` | täpselt see commit, millest image ehitati |
    | versioon | `:v1.0.0` | väljalase, mille inimene märkis (kodutöö) |

Konveier paneb igale image'ile kaks tag'i: räsi ja `latest`. Räsi tuleb muutujast `GITHUB_SHA`. Kirjutis `${GITHUB_SHA::7}` võtab sellest seitse esimest märki. Sama lühiräsi näitab ka `git log --oneline`.

Ainult `latest`-ist ei piisa. See ei ütle, mis versioon töötab. Kui kaks serverit tõmbasid `latest`-i eri päevadel, võib neis olla erinev kood. Räsi järgi tead täpselt, mis koodiga on tegu. Vanale versioonile tagasi minek tähendab vana räsiga image'i käivitamist.

Starteris on rakendusel uus aadress `/versioon`. Konveier annab ehitamisel räsi `Dockerfile`-ile. Nii ütleb töötav rakendus ise, mis commit'ist see on tehtud.

## 4. Õigused: `GITHUB_TOKEN` ja `permissions`

**Token** on parooli moodi võti, mida kasutab programm. Iga käivituse jaoks loob GitHub ajutise tokeni nimega `GITHUB_TOKEN`. See kehtib ainult käivituse ajal ja kaob pärast. Seda ei pea ise looma ega kuhugi salvestama ([GITHUB_TOKEN](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token)).

Tokeni vaikimisi õigused määrab organisatsioon. Organisatsioonis `hkhk-automation` saab token ainult lugeda. Registrisse kirjutamiseks peab töö õigust ise küsima. Seda tehakse võtmega `permissions` ([süntaks](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)):

```yaml
    permissions:
      contents: read
      packages: write
```

`packages: write` lubab registrisse kirjutada. `contents: read` lubab koodi lugeda. Kui `permissions` on kirjas, on kõik muud õigused keelatud. Seepärast peab `contents: read` alles jääma. Muidu ei saa `actions/checkout` koodi kätte.

Õigus antakse ainult tööle, mis seda vajab. Seda nimetatakse **vähima õiguse põhimõtteks**. Tööd `test` ja `konteiner` ei kirjuta registrisse, seega neil seda õigust pole. Kui neis kasutatav võõras action oleks pahatahtlik, ei saaks see registrit muuta.

Iga töö logi esimene samm on **Set up job**. Selle all on lõik `GITHUB_TOKEN Permissions`. Sealt näed, mis õigused tokenil tegelikult olid.

!!! warning "Saladus ei lähe töövoo faili"
    Tokeneid ja paroole ei kirjutata `.yml` faili. Git'i ajalugu jääb alles. Kord commit'itud saladust näeb ka pärast kustutamist (N2, N7 kodutöö).

??? question "Kontrolli ennast"
    1. Sisselogimine GHCR-i õnnestub, aga `docker push` kukub sõnaga `denied`. Mida see tokeni kohta ütleb?
    2. Miks ei anna me kõigile töödele `packages: write`?

## 5. Millal image ehitatakse

Registrisse tohib jõuda ainult kood, mis on testitud ja üle vaadatud. Selle eest hoolitsevad töövoos kolm asja.

**Järjekord: `needs`.** Ilma `needs`-ita käivituvad tööd korraga. Siis ehitatakse image ka siis, kui test kukub. `latest` hakkab näitama katkist koodi. Käivituse lehel on järjekord näha noolena tööde vahel.

**Sündmus: `on`.** Sündmus on see, mis töövoo käivitab. `push` ilma piiranguta käivitab töövoo iga haru igal push'il. `push: branches: [main]` käivitab selle ainult harus `main`. `pull_request` käivitab testid pull request'is. Seda on vaja, sest N7 lukk ei luba enne rohelist testi liita.

**Tingimus: `if`.** Pull request'i käivitus kasutab sama töövoogu. Töö `build-and-push` peab seal vahele jääma. Selleks on tööl tingimus. Muutuja `github.event_name` ütleb, mis sündmus töövoo käivitas: `push` või `pull_request` ([sündmused](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)). Kui tingimus ei kehti, on töö hall ja tal on märge `skipped`.

<figure markdown="span">
  ![Ülemine rida pull_request: test ja konteiner rohelised, build-and-push hall ja skipped, registrisse ei jõua midagi. Alumine rida push harusse main: test, konteiner ja build-and-push, mis saadab image'i GHCR-i. All read on: push: branches: [main], pull_request ja if: github.event_name == 'push'](../images/n08_pr_vs_main.svg)
  <figcaption>Joonis 8.4. Pull request'is käivad testid, registrisse jõuab ainult liidetud kood (Talvik, 2026).</figcaption>
</figure>

**Failide filter: `paths`.** Vahel pole mõtet image'it ehitada, kui muutus ainult README. Võti `paths` käivitab töövoo ainult siis, kui muutusid kindlad failid ([`paths` süntaks](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore)). Näiteks `paths: ["flask/**", ".github/workflows/ci.yml"]` jätab README muudatused vahele. Ettevaatust: kui pull request'i kohustuslik kontroll jääb filtri tõttu käivitamata, jääb see ootele ja liita ei saa.

??? question "Kontrolli ennast"
    1. Saadad GitHubi haru `n08-tervitus` ja avad pull request'i. Töövoos on `push:` ilma harudeta ja `pull_request:`. Mitu käivitust tekib?
    2. Miks on pull request'i koodi registrisse saatmine ohtlik, kui testid olid rohelised?

## 6. Server tõmbab image'i

GitHubi runner ei pääse kooli võrku. Seepärast ei saada konveier image'it serverisse. Server tõmbab selle ise registrist. Selleks on vaja kolme asja.

**Sisselogimine.** Pakett on privaatne. `GITHUB_TOKEN` kaob pärast käivitust ja serveris seda pole. Server kasutab sinu isiklikku tokenit (personal access token, classic). Sellel on ainult õigus `read:packages`. Kui token lekib, saab sellega image'eid ainult tõmmata ([token GHCR-i jaoks](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic)). `docker login` salvestab tokeni faili `~/.docker/config.json`. Seepärast anna tokenile lühike kehtivusaeg.

**Tõmbamine ja käivitamine.** Käsud `docker pull` ja `docker run` on samad mis N5-s. Võti `-p 8088:5000` suunab serveri pordi 8088 konteineri porti 5000. Teine number peab olema port, kus rakendus kuulab.

**Skript.** Käske saab iga kord käsitsi sisestada. Siis tuleb meeles pidada nime, tag'i, porti ja vana konteineri eemaldamist. Starteris on skript `server/paigalda.sh`, mis teeb need sammud alati samas järjekorras. N13-s käivitab sama sammu konveier ise.

### Keskkonnad: test ja tootmine

Töökohas on sageli kaks või enam keskkonda. **Testkeskkond** (staging) on server, kus uus versioon enne kontrollitakse. **Tootmine** on server, mida kasutavad firma kliendid ja töötajad. GitHubis kirjeldatakse need **keskkondadena** (environments) ([keskkonnad](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)). Paigaldustöö märgib, kuhu see paigaldab: `environment: tootmine`.

Keskkonnal võivad olla oma saladused. Tootmise parooli näeb ainult töö, mis paigaldab tootmisse. Keskkonnale saab lisada ka kinnitajad (required reviewers). Siis jääb töö ootama, kuni inimene vajutab nupule. Mõlemasse keskkonda läheb sama räsiga image ja tootmise jaoks midagi uuesti ei ehitata.

<figure markdown="span">
  ![build-and-push ehitab image'i ühe korra ja saadab selle GHCR-i tag'iga 3f2a9c1. Sealt läheb see automaatselt testkeskkonda (staging), kus on testserveri saladused. Tootmisse läheb sama image alles pärast inimese kinnitust (required reviewers). Tootmisel on oma saladused, mida teised tööd ei näe](../images/n08_keskkonnad.svg)
  <figcaption>Joonis 8.5. Sama image testis ja tootmises. Tootmisse alles pärast kinnitust (Talvik, 2026).</figcaption>
</figure>

Siin on näha ka pideva tarne ja pideva paigalduse vahe (tabel 8.1). Kui tootmise ees on kinnitus, on tegu pideva tarnega. Kui kinnitust pole ja iga roheline muudatus läheb kohe tootmisse, on tegu pideva paigaldusega. Praktikumis keskkondi ei seadista.

Paigalduse juures kasutatakse veel kahte võimalust ([pidev paigaldus GitHub Actionsiga](https://docs.github.com/en/actions/get-started/continuous-deployment)). Võti `concurrency` lubab korraga ainult ühe paigalduse: kui kaks muudatust tulevad järjest, ei paigalda kaks käivitust samal ajal samasse serverisse. Pilveteenusesse (AWS, Azure) saab konveier sisse logida **OIDC** abil. Siis ei hoita pilve parooli GitHubi saladustes, vaid konveier saab iga käivituse jaoks lühiajalise loa.

??? question "Kontrolli ennast"
    1. Miks ei anna me serveri tokenile õigust `write:packages`, kuigi see lubaks ka lugeda?
    2. `docker ps` näitab pordiks `0.0.0.0:8088->80/tcp`. Rakendus kuulab pordil 5000. Mida vastab `curl localhost:8088`?

## 7. Vea leidmine: sümptom, hüpotees, tõend, parandus

Praktikumi konveier on kirjutatud, aga katki. Kõige aeglasem viis on muuta ridu juhuslikult ja vaadata, kas läheb roheliseks. Kiirem on iga vea juures sama järjekord.

<figure markdown="span">
  ![Neli kasti järjest: 1 Sümptom (punane töö, rida logis, curl vastus), 2 Hüpotees (mis võib olla põhjus, mis failis, mis real), 3 Tõend (Set up job, docker ps, logs), 4 Parandus (üks muudatus korraga, siis kontroll uuesti). Tõendist tagasi hüpoteesini katkendlik nool: kui tõend ei kinnita hüpoteesi, tee uus hüpotees](../images/n08_veaotsing.svg)
  <figcaption>Joonis 8.6. Vea otsimise järjekord (Talvik, 2026).</figcaption>
</figure>

1. **Sümptom** on see, mida näed: punane töö, punane samm, rida logis. Loe veateade lõpuni. Tähtsaim sõna on tihti viimane.
2. **Hüpotees** on oletus põhjuse kohta. Hea hüpotees ütleb ka koha: „tokenil pole kirjutamisõigust, fail `ci.yml`, töö `build-and-push`“.
3. **Tõend** on kontroll, mis oletuse kinnitab või ümber lükkab. Tee see enne, kui midagi muudad.
4. **Parandus** on üks muudatus. Pärast seda vaata sama sümptomit uuesti.

??? note "Tabel 8.4. Kust leida tõend"
    | Kus vaadata | Mida näitab |
    |---|---|
    | Actions → käivitus → töö → samm | veateade ja sammu väljund |
    | töö samm **Set up job**, lõik `GITHUB_TOKEN Permissions` | mis õigused tokenil olid |
    | käivituse lehel tööde skeem | kas tööde vahel on nool (`needs`) |
    | käivituse pealkirja all sündmus ja haru | mis töövoo käivitas |
    | **Packages** → pakett → tag'id | mis image'id registrisse jõudsid |
    | `docker ps`, veerg PORTS | kuhu port on suunatud |
    | `docker logs <konteiner>` | mida rakendus konteineris ise ütleb |

Kõik vead ei tee konveierit punaseks. Kui katkine kood jõuab registrisse, on kõik tööd rohelised. Sellist viga näed ainult siis, kui kontrollid tulemust: mis on registris ja mis töötab serveris.

**Viga saab issue.** Töökohas pannakse iga viga kirja **issue**'na: mida nähti, mis oli hüpotees ja mis oli tõend. Kui paranduse commit'i sõnumis on rida `Fixes #12`, sulgeb GitHub issue numbriga 12 siis, kui commit jõuab harusse `main`, ja lisab issue'le lingi sellele commit'ile ([issue sulgemine võtmesõnaga](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword)). Nii saab hiljem minna ahelat pidi: issue, commit'i räsi, image'i tag sama räsiga ja server, mis näitab seda räsi. Praktikumis teed iga vea kohta issue ja leiad räsi järgi vana versiooni üles (`git log --oneline`, `git show <räsi>`).

**Olekumärk.** README algusesse saab panna olekumärgi (status badge): väikese pildi, mis näitab töövoo viimase käivituse tulemust harus `main`. Märgi rea annab GitHub käivituse lehel menüüst **⋯ → Create status badge** ([olekumärk](https://docs.github.com/en/actions/how-tos/monitor-workflows/add-a-status-badge)).

## 8. CI/CD tööriistad ja litsentsid

GitHub Actions ei ole ainus CI/CD tööriist. Töökohas kohtad tõenäoliselt ka GitLabi või Jenkinsit. Mõisted on samad: konveier, sammud, järjekord, saladused. Erinevad koht, kus konveier töötab, ja see, kes seda haldab.

**GitHub Actions** on GitHubi teenus. Konveier töötab GitHubi masinates (runner). Firma võib paigaldada runneri ka oma serverisse ([oma runner](https://docs.github.com/en/actions/concepts/runners/self-hosted-runners)). Siis töötab konveier firma võrgus, aga juhtimine jääb GitHubile.

**GitLab** on terve platvorm ühes: Git'i hoidla, CI/CD, konteinerite register, ülesanded (issues) ja turvakontrollid. Seda saab kasutada teenusena aadressil gitlab.com või paigaldada oma serverisse ([paigaldus](https://docs.gitlab.com/install/)). Konveier on failis `.gitlab-ci.yml`.

**Jenkins** on vanim neist kolmest. Projekt alustas 2004. aastal nime all Hudson. 2011. aastal tekkis vaidlus Oracle'iga nime pärast ja projekt nimetati ümber Jenkinsiks ([ajalugu](https://en.wikipedia.org/wiki/Jenkins_(software))). Jenkinsi paigaldad alati ise. Selle võimalused tulevad plugin'itest. Plugin'eid on üle kahe tuhande ([Jenkinsi plugin'id](https://plugins.jenkins.io/)).

Jenkinsit kasutatakse endiselt palju, eriti suurtes firmades ja vanades süsteemides. Uutes projektides valitakse seda harvem. Server, plugin'id ja nende uuendused on firma enda hallata. Iga plugin on võimalik turvaauk ja vanad plugin'id ei pruugi uue versiooniga töötada. GitHub Actions ja gitlab.com hoiavad selle töö enda käes. Praktikumi osas 6 käivitad Jenkinsi ise ja näed, mida see haldamine tähendab.

Jenkinsi konveier on repositooriumi failis `Jenkinsfile` ([Jenkinsfile'i süntaks](https://www.jenkins.io/doc/book/pipeline/syntax/)). Ülesehitus on sama mis töövoo failil, ainult nimed on teised: `pipeline` on terve konveier, `agent` ütleb, kus see töötab (nagu `runs-on`), `stages` ja `stage` on etapid (nagu tööd) ning `steps` on käsud. Jenkins ise oskab vähe. Git'i tugi, konveierid ja graafiline vaade tulevad **plugin'itest**, mis paigaldatakse Jenkinsi image'isse. GitHub teatab push'ist Jenkinsile **webhook**'iga: GitHub saadab Jenkinsi aadressile päringu. Kui Jenkins on VPN-i taga, ei jõua päring kohale. Siis kontrollib Jenkins ise repositooriumi kindla aja tagant (`pollSCM`).

### Litsentsid

**Litsents** ütleb, mida tarkvaraga tohib teha: kas seda tohib tasuta kasutada, muuta, oma serverisse paigaldada ja edasi müüa. Firma jaoks on see sama oluline kui tehnilised omadused.

??? note "Tabel 8.5. CI/CD tööriistade litsentsid"
    | Tööriist | Litsents | Mida see firmale tähendab |
    |---|---|---|
    | Jenkins | [MIT](https://github.com/jenkinsci/jenkins/blob/master/LICENSE.txt) | tohib tasuta kasutada, muuta ja edasi müüa |
    | GitLab Community Edition | [MIT](https://gitlab.com/gitlab-org/gitlab/-/blob/master/LICENSE) | nagu Jenkins: tasuta ja vaba |
    | GitLab Enterprise Edition | [kommertslitsents](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/LICENSE) | tootmises tohib kasutada ainult tasulise tellimusega |
    | GitHub Actions (teenus) | suletud, GitHubi kasutustingimused | koodi ei näe ega tohi ise paigaldada; maksad kasutuse eest |
    | GitHub Actionsi runner | [MIT](https://github.com/actions/runner/blob/main/LICENSE) | runneri programmi tohib vabalt kasutada ja muuta |

**MIT** on lühike ja vaba litsents. See lubab tarkvara kasutada, muuta, levitada ja müüa. Tingimus on üks: autoriõiguse teade peab jääma koopiasse alles.

GitLab kasutab mudelit **open core**. Põhiosa on avatud (Community Edition, MIT). Lisavõimalused on kaustas `ee/` ja nende kasutamiseks tootmises on vaja tasulist tellimust ([CE või EE](https://about.gitlab.com/install/ce-or-ee/)).

Litsents võib ka muutuda. HashiCorp muutis 2023. aastal Terraformi litsentsi (Terraformi ja OpenTofuga töötad N10-s). Uus litsents BSL ei luba Terraformi kasutada HashiCorpiga konkureerivas tootes ([HashiCorpi teade](https://www.hashicorp.com/blog/hashicorp-adopts-business-source-license)). Kogukond jätkas viimase vaba versiooniga ja nii tekkis OpenTofu. Seega tasub enne tööriista valimist vaadata ka litsentsi ja seda, kes projekti juhib.

??? question "Kui palju GitHub Actions maksab?"
    Litsentsi kõrval tuleb vaadata ka hinda. Leia vastused GitHubi dokumentatsioonist, lehelt [GitHub Actionsi arveldus](https://docs.github.com/en/billing/concepts/product-billing/github-actions), ja võrdle plaane lehel [github.com/pricing](https://github.com/pricing):

    1. Kas GitHubi runnerid on avalikus repositooriumis tasuta?
    2. Kui palju kasutust on privaatse repositooriumi jaoks plaanis hinna sees? Mitu Linuxi minutit see umbes on?
    3. Mis maksab üks Linuxi runneri minut?
    4. Kas oma runner (self-hosted) maksab midagi?
    5. Sinu konveier kestab umbes 2 minutit ja klassis on 15 õpilast. Igaüks teeb tunnis 20 push'i. Mitu minutit kulub ühe tunniga?

    ??? success "Vastused"
        1. Jah. Tavalised GitHubi runnerid on avalikus repositooriumis tasuta ja ei vähenda hinna sees olevat kogust.
        2. Hinna sees on summa dollarites: Free plaanis 12 $, Team plaanis 18 $. Linuxi hinnaga teeb see umbes 2000 ja 3000 minutit kuus. Lisaks on artefaktide ja pakettide hoidmiseks 500 MB (Free) või 2 GB (Team).
        3. 0,006 $ minut (Linux, 2 tuuma). Windows ja macOS on kallimad.
        4. Ei. Oma runneri minutid on tasuta. Maksad ainult oma serveri eest.
        5. 15 × 20 × 2 = 600 minutit. Viie sellise tunniga saavad Team plaani minutid otsa.

        Organisatsioon saab määrata kulude piiri (budget). Kooli organisatsioonis on piir 0 $: kui hinna sees olev kogus saab otsa, töövoogusid kuu lõpuni enam ei käivitata ja arvet ei tule.

??? question "Kontrolli ennast"
    1. Firma tahab CI/CD-d, mis töötab ainult tema enda serverites ja on tasuta. Milliseid tabeli 8.5 tööriistu ta saab kasutada?
    2. Mida peab firma Jenkinsi puhul ise tegema, mida GitHub Actionsi puhul teeb GitHub?

## Kokkuvõte

??? abstract "Kokkuvõte"

    | Mõiste | Lühidalt |
    |---|---|
    | pidev tarne | iga roheline muudatus harus `main` on registris paigaldamiseks valmis |
    | ehita üks kord | image ehitatakse konveieris, server ainult tõmbab |
    | GHCR | `ghcr.io/<omanik>/<nimi>:<tag>`, nimi väiketähtedega |
    | tag | räsi ütleb täpse versiooni, `latest` ainult viimase |
    | `permissions` | `packages: write` ainult tööle, mis registrisse kirjutab |
    | `needs`, `on`, `if` | ehitus pärast teste, ainult harus `main`, mitte pull request'is |
    | serveri token | isiklik token õigusega `read:packages` |
    | vea otsimine | sümptom, hüpotees, tõend, parandus |
    | tööriistad | GitHub Actions on teenus, GitLab on platvorm, Jenkinsit haldad ise |
    | litsents | ütleb, kas tohib kasutada, muuta, paigaldada ja müüa |

*Edasi: [praktikum](lab.md). Seejärel [kodutöö](homework.md).*
