---
tags:
  - GitHubActions
  - CI
  - CD
---

# GitHub Actions juhend

Siin on ühel lehel GitHub Actionsi põhimõisted, töövoo süntaks, näited ja veaotsing. Kui N7 või N8 praktikumis tekib küsimus, mida mõni võti teeb või miks käivitus on punane, otsi vastust siit ja seejärel ametlikust dokumentatsioonist, mille lingid on iga osa juures. Vaja on GitHubi kontot, Giti põhikäske (`add`, `commit`, `push`) ja YAML-i põhireegleid ([N7 loeng §5](week07/lecture.md#yaml-i-reeglid)).

Ülesehitus järgib freeCodeCampi artiklit [Learn to Use GitHub Actions: a Step-by-Step Guide](https://www.freecodecamp.org/news/learn-to-use-github-actions-step-by-step-guide/), mida võid lugeda ingliskeelse lisamaterjalina. Näited on selle kursuse omad: Pythoni testid, Dockeri image ja MkDocsi sait.

## 1. Põhimõisted

**Töövoog** (workflow) on YAML-fail repositooriumi kaustas `.github/workflows/`. Ühes repositooriumis võib olla mitu töövoogu, näiteks `ci.yml` testide jaoks ja `pages.yml` saidi avaldamiseks.

**Sündmus** (event) käivitab töövoo. Sündmus on näiteks `push`, uus pull request või kellaaeg. Paljudel sündmustel on **tegevuse tüübid** (activity types). Näiteks pull request võib olla avatud (`opened`), uuendatud (`synchronize`) või suletud (`closed`), ja võtmega `types` saad valida, millise tegevuse peale töövoog käivitub.

**Töö** (job) on sammude rühm, mis tehakse ühes runneris. Ühe töövoo tööd käivituvad vaikimisi korraga (paralleelselt). Kui töö peab ootama teise töö lõppu, kirjutatakse selle juurde `needs`.

**Samm** (step) on üks käsk (`run`) või üks valmis action (`uses`). Ühe töö sammud tehakse järjest samas masinas, seega näeb järgmine samm eelmise sammu loodud faile.

**Runner** on masin, kus töö tehakse. GitHubi runner (`ubuntu-latest`) on värske virtuaalmasin, mis kustutatakse pärast tööd. Oma runner (self-hosted) on sinu enda server, kuhu on paigaldatud GitHubi runneri programm.

**Käivitus** (run) on töövoo üks käivitamine. Iga käivitus on näha repositooriumi vahekaardil **Actions**.

<figure markdown="span">
  ![Vasakul ci.yml värviliste ridadega, paremal selgitused: on on sündmus ehk millal töövoog käivitub, test on töö ehk sammude rühm, runs-on on runner ehk masin, uses-read on valmis action'id ja run-read tavalised Bashi käsud. All ahel: sündmus, töövoog, töö, runner, samm](images/n07_actions_anatoomia.svg)
  <figcaption>Joonis GA.1. GitHub Actionsi osad ja read, mis neid failis tähistavad (Talvik, 2026, D. Mosyani ülevaate põhjal).</figcaption>
</figure>

<figure markdown="span">
  ![Vasakul sündmused (on:): push harusse main, pull_request, schedule, workflow_dispatch. Sündmus käivitab töövoo .github/workflows/ci.yml. Töövoos on kolm tööd: test, konteiner ja build-and-push, nende vahel nooled needs. Iga töö all on sammud, näiteks checkout, docker build, docker push. Paremal märkus: ilma needs'ita käivituvad kõik tööd korraga](images/n08_moisted.svg)
  <figcaption>Joonis GA.2. Sündmus käivitab töövoo, töövoos on tööd, töös on sammud. `needs` paneb tööd järjekorda (Talvik, 2026).</figcaption>
</figure>

Iga töö saab oma runneri. Kui töö `test` paigaldab Pythoni paketid, ei ole neid töös `konteiner` olemas. Failid, mida on vaja hiljem, tuleb runnerist välja saata: registrisse (image), artefaktina (fail) või GitHub Pagesisse (sait).

<figure markdown="span">
  ![Ühes käivituses kolm runnerit: runner 1 teeb testi, runner 2 ehitab konteineri ja image kaob koos masinaga, runner 3 ehitab image'i uuesti ja saadab selle push'iga GHCR-i, kus tag'id 3f2a9c1 ja latest jäävad alles. Server proxmox1 tõmbab image'i GHCR-ist pull'iga. All märkus: runnerisse tuleb väljast ainult see, mida töövoog küsib](images/n08_runnerid.svg)
  <figcaption>Joonis GA.3. Runner kustutatakse pärast tööd. Alles jääb ainult see, mis saadeti välja (Talvik, 2026).</figcaption>
</figure>

Ametlik kirjeldus on lehel [Understanding GitHub Actions](https://docs.github.com/en/actions/get-started/understand-github-actions).

## 2. Töövoo loomine

Töövoo saab luua kahel viisil. Mõlemal juhul tekib repositooriumi sama fail.

### GitHubi veebis

Ava repositooriumi vahekaart **Actions** ja vajuta **New workflow**. GitHub pakub malle repositooriumi koodi keele järgi, näiteks Pythoni repositooriumile Pythoni testide malli. Vali mall, vajuta **Configure**, muuda faili vajaduse korral ja vajuta **Commit changes**. Mallid on kirjeldatud lehel [Use workflow templates](https://docs.github.com/en/actions/how-tos/write-workflows/use-workflow-templates), kus on ka pildid.

### Oma redaktoris

Sellel kursusel kasutame seda viisi. Loo fail `.github/workflows/<nimi>.yml`, salvesta see repositooriumi ja saada GitHubi:

```bash
mkdir -p .github/workflows
code .github/workflows/ci.yml
git add .github/workflows/ci.yml
git commit -m "CI: testid iga push'i järel"
git push
```

Kui failis on sündmus `push`, käivitub töövoog kohe pärast `git push`-i ja käivitus ilmub vahekaardile **Actions**. Kausta nimi peab olema täpselt `.github/workflows`, muidu GitHub faili ei leia.

## 3. Süntaks võti-võtmelt

Kõige lihtsam on alustada tervest failist. Kõik võtmed ja nende täpne tähendus on lehel [Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

Selles failis on peaaegu kõik võtmed, mida kursusel kasutame. See on N7 `ci.yml`, millele on lisatud käsitsi käivitamine, õigused ja keskkonnamuutuja. Vajuta numbril, et näha selgitust.

```yaml
name: CI

on:
  push:
    branches: [main] # (1)!
  pull_request: # (2)!
  workflow_dispatch: # (3)!

permissions:
  contents: read # (4)!

env:
  PYTHON_VERSIOON: "3.12" # (5)!

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7 # (6)!
      - uses: actions/setup-python@v7
        with:
          python-version: ${{ env.PYTHON_VERSIOON }}
      - name: Paigalda sõltuvused
        run: pip install -r flask/requirements.txt pytest
      - name: Käivita testid
        run: pytest flask -v # (7)!

  konteiner:
    needs: test # (8)!
    if: github.event_name != 'workflow_dispatch' # (9)!
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Ehita image ja käivita konteiner
        shell: bash
        run: | # (10)!
          docker build -t flask-app ./flask
          docker run -d -p 5000:5000 --name flask1 flask-app
      - run: curl -fsS --retry 10 --retry-all-errors --retry-delay 1 localhost:5000/health
      - if: failure() # (11)!
        run: docker logs flask1
```

1. Push käivitab töövoo ainult harus `main`. Teistes harudes kontrollib koodi pull request.
2. Pull request'i iga uus commit käivitab töövoo uuesti. Nii on testi tulemus näha enne liitmist.
3. Lisab vahekaardile **Actions** nupu **Run workflow**. Nupp ilmub alles siis, kui fail on harus `main`.
4. `GITHUB_TOKEN` võib ainult koodi lugeda. Kui mõni töö peab kirjutama (näiteks GHCR-i), antakse õigus selle töö juures.
5. Töövoo tasemel `env` kehtib kõigis töödes. Seda loetakse kujul `${{ env.NIMI }}` või sammu käsus `$PYTHON_VERSIOON`.
6. Runner on tühi. `actions/checkout` toob repositooriumi failid runnerisse. Ilma selleta ei ole kausta `flask` olemas.
7. Kui mõni test kukub, lõpetab `pytest` väljumiskoodiga 1. Samm ja töö muutuvad punaseks ning töö `konteiner` ei käivitu.
8. Töö `konteiner` käivitub alles siis, kui `test` on roheline. Ilma võtmeta `needs` käivituksid mõlemad korraga.
9. Käsitsi käivitamisel tehakse ainult testid. Töö `konteiner` on käivituse lehel hall ja märgitud `skipped`.
10. Märk `|` tähendab mitmerealist teksti. Iga rida on eraldi käsk samas shellis.
11. Samm käivitub ainult siis, kui mõni eelmine samm kukkus. Konteineri logist näed, miks rakendus ei vastanud.

### Millal töövoog käivitub

- `on` loetleb sündmused, mis töövoo käivitavad, näiteks `push` ja `pull_request`.
- `branches` piirab sündmust: `push: branches: [main]` käivitub ainult harus `main`.
- `workflow_dispatch` lisab vahekaardile **Actions** nupu **Run workflow**.
- `schedule` käivitab töövoo kellaajal. Aeg on cron-kujul ja UTC ajas: `"30 5 * * 1-5"` on tööpäeviti 07:30 Eesti talveajal. Avaldist saad kontrollida lehel [crontab.guru](https://crontab.guru/).
- `schedule` ja `workflow_dispatch` töötavad ainult siis, kui fail on harus `main`.

Kõik sündmused on lehel [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows).

### Mida töövoog tohib

- `permissions` annab `GITHUB_TOKEN`-ile õigused, näiteks `packages: write` registrisse kirjutamiseks.
- `env` loob keskkonnamuutuja kogu töövoole, ühele tööle või ühele sammule.
- Parool ja token ei lähe faili. Need lisatakse **Settings → Secrets and variables → Actions** ja töövoos loetakse kujul `${{ secrets.NIMI }}` ([saladused](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)).

### Tööd

- `jobs` all on töövoo tööd. Töö nime valid ise, näiteks `test`.
- `runs-on` ütleb, mis masinas töö käivitub, tavaliselt `ubuntu-latest`.
- `needs` paneb töö ootama teise töö lõppu. Ilma selleta käivituvad tööd korraga.
- `if` käivitab töö ainult siis, kui tingimus kehtib, näiteks `if: github.event_name == 'push'`.

### Sammud

- `uses` käivitab valmis action'i, näiteks `actions/checkout@v7`. `with` annab sellele parameetrid.
- `run` käivitab shelli käsu, näiteks `pytest flask -v`.
- `name` on sammu nimi, mida näed logis.
- `if: failure()` käivitab sammu ainult siis, kui eelmine samm kukkus.

## 4. Näited

Iga näide on terve töövoo fail. Kopeeri see kausta `.github/workflows/` ja muuda kaustade nimed oma repositooriumi järgi.

### Pythoni testid

Lühim kasulik töövoog on N7 töö `test`: kood runnerisse, Python, sõltuvused ja `pytest`. GitHubi juhend sama mustri kohta on [Building and testing Python](https://docs.github.com/en/actions/tutorials/build-and-test-code/python).

??? example "Fail `.github/workflows/ci.yml`"

    ```yaml
    name: CI
    on: [push, pull_request]

    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v7
          - uses: actions/setup-python@v7
            with:
              python-version: "3.12"
              cache: pip
          - run: pip install -r flask/requirements.txt pytest
          - run: pytest flask -v
    ```

    Parameeter `cache: pip` hoiab allalaaditud pakette GitHubi vahemälus, nii et järgmine käivitus on kiirem.

### Testiraport artefaktina

Runner kustutatakse pärast tööd koos kõigi failidega. Kui tahad faili hiljem alla laadida, näiteks testiraportit, saada see **artefaktina** (artifact). Artefakt on käivituse lehel allosas ja seda hoitakse vaikimisi 90 päeva ([Store and share data with workflow artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data)).

??? example "Fail `.github/workflows/raport.yml`"

    ```yaml
    name: Testiraport
    on: [push, pull_request]

    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v7
          - uses: actions/setup-python@v7
            with:
              python-version: "3.12"
          - run: pip install -r flask/requirements.txt pytest
          - run: pytest flask -v --junitxml=raport.xml
          - uses: actions/upload-artifact@v7
            if: always()
            with:
              name: testiraport
              path: raport.xml
              retention-days: 7
    ```

    Tingimus `if: always()` saadab raporti ka siis, kui mõni test kukkus. Just siis on raportit kõige rohkem vaja. `retention-days` lühendab hoiuaega, et artefaktid ei võtaks salvestusruumi.

Teine töö samas käivituses saab artefakti kätte action'iga [`actions/download-artifact`](https://github.com/actions/download-artifact). Nii antakse faile ühest tööst teise.

### Dockeri image GHCR-i

N8 töö `build-and-push` ehitab image'i ja saadab selle GitHubi registrisse GHCR. Siin on selle lühem kuju. Võti `permissions: packages: write` on vajalik, sest vaikimisi võib `GITHUB_TOKEN` registrist ainult lugeda. Täielik variant tag'ide ja vahemäluga on [N8 praktikumis](week08/lab.md).

??? example "Töö `build-and-push`"

    ```yaml
      build-and-push:
        needs: test
        if: github.event_name == 'push'
        runs-on: ubuntu-latest
        permissions:
          contents: read
          packages: write
        steps:
          - uses: actions/checkout@v7
          - uses: docker/login-action@v4
            with:
              registry: ghcr.io
              username: ${{ github.actor }}
              password: ${{ secrets.GITHUB_TOKEN }}
          - id: meta
            uses: docker/metadata-action@v6
            with:
              images: ghcr.io/${{ github.repository }}
              tags: type=sha,prefix=,format=short
          - uses: docker/build-push-action@v7
            with:
              context: ./flask
              push: true
              tags: ${{ steps.meta.outputs.tags }}
    ```

    `docker/metadata-action` teeb image'i nime väiketähtedeks. Ilma selleta annab suurtähtedega kasutajanimi registris vea.

### Staatiline sait GitHub Pagesisse

Selle kursuse sait on tehtud MkDocsiga ja see avaldatakse GitHub Pagesisse töövooga [`static.yml`](https://github.com/hkhk-automation/devops/blob/main/.github/workflows/static.yml). Allolev fail järgib GitHubi ametlikku malli [pages/static.yml](https://github.com/actions/starter-workflows/blob/main/pages/static.yml), millele on lisatud MkDocsi ehitamine.

Enne esimest käivitust vali repositooriumi seadetes **Settings** → **Pages** → **Source** väärtus **GitHub Actions** ([Using custom workflows with GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)). Tasuta plaanis töötab GitHub Pages ainult avalikus repositooriumis.

??? example "Fail `.github/workflows/pages.yml`"

    ```yaml
    name: Sait GitHub Pagesisse
    on:
      push:
        branches: [main]
      workflow_dispatch:

    permissions:
      contents: read
      pages: write # (1)!
      id-token: write # (2)!

    concurrency:
      group: pages # (3)!
      cancel-in-progress: false

    jobs:
      deploy:
        environment:
          name: github-pages
          url: ${{ steps.deployment.outputs.page_url }} # (4)!
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v7
          - uses: actions/setup-python@v7
            with:
              python-version: "3.12"
          - run: pip install mkdocs-material
          - run: mkdocs build --strict # (5)!
          - uses: actions/configure-pages@v6
          - uses: actions/upload-pages-artifact@v5
            with:
              path: site # (6)!
          - id: deployment
            uses: actions/deploy-pages@v5
    ```

    1. Lubab töövool saiti GitHub Pagesisse avaldada.
    2. `deploy-pages` tõendab GitHubile lühiajalise OIDC-tokeniga, et avaldamise teeb just see töövoog.
    3. Korraga avaldatakse ainult üks versioon. Kui kaks push'i tulevad järjest, ootab teine käivitus esimese lõppu.
    4. Pärast avaldamist näitab käivituse leht saidi aadressi.
    5. `--strict` muudab iga hoiatuse (näiteks katkise lingi) veaks, nii et katkine sait jääb avaldamata.
    6. MkDocs kirjutab valmis saidi kausta `site`. Ainult see kaust avaldatakse.

### Ajastatud kontroll: kas sait vastab

Sündmus `schedule` käivitab töövoo ilma commit'ita. Allolev töövoog kontrollib iga päev kell 06:00 UTC, kas sait vastab. Kui `curl` saab vea, on käivitus punane ja GitHub saadab kirja kasutajale, kes cron-rida viimasena muutis.

??? example "Fail `.github/workflows/saidi-kontroll.yml`"

    ```yaml
    name: Saidi kontroll
    on:
      schedule:
        - cron: "0 6 * * *"
      workflow_dispatch:

    jobs:
      kontroll:
        runs-on: ubuntu-latest
        steps:
          - run: curl -fsS --max-time 15 -o /dev/null https://hkhk-automation.github.io/devops/
    ```

    Valik `-f` muudab HTTP vea (näiteks 404 või 500) väljumiskoodiks, mis ei ole 0. `-sS` peidab edenemisriba, kuid näitab veateadet. `workflow_dispatch` lubab kontrolli kohe käsitsi proovida ja ei pea ootama järgmist hommikut. Avalikus repositooriumis lülitab GitHub ajastatud töövood välja, kui repositooriumis ei ole 60 päeva jooksul ühtegi muudatust.

## 5. Töövoog oma masinas: `act`

Iga töövoo muudatuse proovimiseks tuleb tavaliselt teha commit ja push ning oodata, kuni runner käivitub. Tööriist [act](https://github.com/nektos/act) käivitab töövoo sinu masinas Dockeri konteineris. Nii näed vea mõne sekundiga, ajalugu ei täitu katsetuste commit'idega ja GitHubi minuteid ei kulu. Kasutusjuhend on lehel [nektosact.com](https://nektosact.com/).

!!! warning "Kursuse masinates proovimata"
    Seda osa ei ole kursuse masinates proovitud. Käsud on võetud act'i ametlikust juhendist (versioon v0.2.94).

`act` vajab Dockerit. Kasuta masinat, kus Docker on paigaldatud. Ametlik paigaldusskript paneb programmi kausta, mille annad valikuga `-b`:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash -s -- -b /usr/local/bin
act --version
```

Esimesel käivitusel küsib `act`, millist image'it runneri asemel kasutada. Vali **Medium**. **Micro** image'is puudub enamik tööriistu ja **Large** on üle 18 GB ([runnerid](https://nektosact.com/usage/runners.html)).

Käivita käsud repositooriumi juurkaustas:

```bash
act -l                  # kõik tööd ja sündmused, mis neid käivitavad
act push                # käivitab tööd, mis reageerivad sündmusele push
act -j test             # käivitab ainult töö test
act workflow_dispatch   # käsitsi käivitamine
act -s GITHUB_TOKEN="$(gh auth token)"   # annab saladuse
```

Kõik valikud on lehel [Usage guide](https://nektosact.com/usage/index.html).

`act` ei ole GitHubi runner ja mõni asi töötab teisiti:

- `GITHUB_TOKEN`-i ja teisi saladusi `act` ise ei loo. Need antakse valikuga `-s NIMI=väärtus` või failiga `--secret-file`.
- Medium image ei ole sama mis GitHubi `ubuntu-latest`. Kui samm töötab GitHubis, aga `act`-is annab `command not found`, puudub tööriist image'is.
- Action'id, mis vajavad GitHubi teenust, ei tööta kohalikult nagu GitHubis. Näiteks `deploy-pages` ei saa saiti avaldada ja `upload-artifact` vajab valikut `--artifact-server-path`.
- `act` kasutab kohaliku repositooriumi faile. Commit'imata muudatused on käivituses kaasas.

Lõplik kontroll on ikkagi GitHubis: roheline `act` ei tähenda, et käivitus GitHubis on roheline.

## 6. Veaotsing

Kui käivitus on punane, ava see vahekaardil **Actions**, vali punane töö ja ava punane samm. Loe logi viimased read, sest seal on veateade ja väljumiskood. Esimeses sammus **Set up job** on runneri versioon, action'ite versioonid ja lõik `GITHUB_TOKEN Permissions`.

??? warning "Kui vahekaardil Actions ei ilmu käivitust"
    Fail ei ole kaustas `.github/workflows/` (näiteks on see kaustas `.github/workflow/`) või sündmus ei vasta võtmele `on` (vale haru või `branches` piirab). Kontrolli faili teed ja võtit `on`.

??? warning "Kui tuleb viga Invalid workflow file ja rea number"
    Failis on YAML-i viga: tabulaator, vale taane või koolonile ei järgne tühikut. Vaata failis näidatud rida.

??? warning "Kui nuppu Run workflow ei ole"
    Sündmus `workflow_dispatch` puudub või fail ei ole harus `main`. Kontrolli faili harus `main`.

??? warning "Kui tuleb viga Unable to resolve action"
    Action'i nimes või versioonis on viga. Vaata sammu **Set up job** ja action'i lehel jaotist **Releases**.

??? warning "Kui tuleb viga command not found"
    Runner on tühi ja tööriist või kood puudub. Kontrolli, kas enne seda on samm `checkout` või `setup-*`.

??? warning "Kui tuleb viga Process completed with exit code 1"
    Sammu käsk lõpetas veaga. Põhjus on sama sammu logis enne seda rida.

??? warning "Kui tuleb viga denied või Resource not accessible by integration"
    `GITHUB_TOKEN`-il ei ole vajalikku õigust. Vaata sammus **Set up job** lõiku `GITHUB_TOKEN Permissions` ja kontrolli võtit `permissions`.

??? warning "Kui töö on hall ja märgitud skipped"
    Töö tingimus `if` ei kehtinud või kukkus töö, mida `needs` ootab. Kontrolli võtmeid `if` ja `needs`.

Kui logist ei piisa, käivita töö uuesti nupuga **Re-run jobs** ja vali **Enable debug logging**. Siis näitab logi iga sammu kohta rohkem ridu ([Enable debug logging](https://docs.github.com/en/actions/how-tos/monitor-workflows/enable-debug-logging)). Rohkem näiteid on lehel [Troubleshoot workflows](https://docs.github.com/en/actions/how-tos/troubleshoot-workflows). Veaotsingu järjekord (sümptom, hüpotees, tõend, parandus) on kirjeldatud [N8 loengus](week08/lecture.md#7-veaotsing-sumptom-hupotees-toend-parandus).

## 7. Hind

Avalikus repositooriumis on GitHubi runnerid tasuta. Privaatses repositooriumis on igal plaanil kuus tasuta minuteid: Team plaanis umbes 3000 Linuxi minutit kuus, Windowsi ja macOS-i runneri minut maksab rohkem. Oma runner (self-hosted) on tasuta, sest töö tehakse sinu masinas. Täpsed numbrid on lehel [GitHub Actionsi arveldus](https://docs.github.com/en/billing/concepts/product-billing/github-actions).

## 8. Kust edasi

Dokumentatsioon on inglise keeles, aga võtmete nimed on samad, mida kirjutad faili. Seetõttu leiad need lehelt otsinguga (++ctrl+f++). Veebiliidese klõpsud (seaded, saladused, käsitsi käivitamine) on ametlikel How-to lehtedel piltidega.

??? note "Tabel GA.4. GitHub Actionsi dokumentatsiooni osad"
    | Osa | Mida sealt leiad |
    |---|---|
    | [Get started → Quickstart](https://docs.github.com/en/actions/get-started/quickstart) | esimene töövoog umbes 5 minutiga |
    | [Concepts](https://docs.github.com/en/actions/concepts) | mõisted: töövood, runnerid, turvalisus |
    | [How-tos](https://docs.github.com/en/actions/how-tos) | kuidas midagi teha: töövoo kirjutamine, saladused, paigaldamine, vigade otsimine |
    | [Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) | kõik töövoo võtmed |
    | [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) | kõik sündmused ja tegevuse tüübid |
    | [Contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) | mida saab lugeda kujul `${{ github.* }}`, `${{ env.* }}`, `${{ secrets.* }}` |
    | [GitHub Marketplace → Actions](https://github.com/marketplace?type=actions) | valmis action'id, nende `with:` parameetrid on action'i README-s |

Dokumentatsiooni osade pikem kirjeldus on [N7 loengu §6](week07/lecture.md#6-kust-leida-vastus-github-actionsi-dokumentatsioon).
