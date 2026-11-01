---
tags:
  - CI
  - GitHubActions
  - Testimine
  - Praktikum
---

# Praktikum: GitHub Actions CI

**Eeldus:** loeng (CI, sündmus, töö, samm, väljumiskood), N5 kaust `flask/` (Flask, `Dockerfile`, `host="0.0.0.0"`) ja N2 ruleset ning pull request. Kui mõni mõiste on segane, loe see [loengust](lecture.md) üle.

**Keskkond:** koodi ja testid kirjutad VS Code'is oma AlmaLinuxi virtuaalmasinas. CI käivitub GitHubi runneris. Runner on värske Ubuntu virtuaalmasin, mis ei ole sinu masin. Käsk `git push` käivitab konveieri.

**Teatmik:** [GitHub Actions juhend](../github-actions.md)

N5-s ehitasid Flaski rakendusest image'i ja kontrollisid käsuga `curl`, et konteiner vastab. Täna kirjutad samale rakendusele testid ja paned GitHubi need iga push'i järel ise käivitama.

Valmis faili `ci.yml` sa ei saa. Alustad töövoost, mis teeb ainult ühe `echo`, ja lisad sellele ridu ükshaaval. Iga puuduv rida annab vea. Loed veateate, leiad põhjuse ja lisad puuduva rea. Nii näed, milleks iga rida vajalik on. Terve fail on juhendis näha ainult osas 2, edasi lisad samme ja töid.

??? abstract "Õpiväljundid"

    1. Oskad kirjutada Flaskile automaattesti ja käivitada selle enne push'i oma masinas.
    2. Oskad koostada faili `.github/workflows/ci.yml` samm haaval ja kontrollida iga sammu tulemust.
    3. Oskad leida Actionsi logist viie tüüpilise CI vea põhjuse: puuduv tööriist, puuduv kood, puuduv sõltuvus, ainult enda masinas olev teek ja konteineri viga.
    4. Oskad eristada, kas punane käivitus tuleb koodist või töövoost.
    5. Oskad lisada CI haru `main` kaitsesse nii, et punase testiga pull request'i ei saa liita.
    6. Oskad kirjutada testi enne koodi.

Praktikumis on kahte tüüpi küsimusi:

- **Ennusta:** enne käsku mõtled läbi, mis juhtub. Vastus on kokkuvolditud plokis **Oodatav tulemus**. Ava see alles pärast käsu käivitamist.
- **Leia põhjus:** käivitus on punane ja plokis on küsimus, mis aitab põhjust leida. Lahendus on juhendis kohe ploki järel.

- **Leia dokumentatsioonist:** küsimus, millele leiad vastuse GitHubi dokumentatsioonist. Tavaliselt on lehe link küsimuse juures. Mõne küsimuse juures on ainult dokumentatsiooni osa nimi ja lehe leiad ise. Vastus on kokkuvolditud plokis **Vastus**. Dokumentatsiooni osad on kirjeldatud loengu [§6](lecture.md#6-kust-leida-vastus-github-actionsi-dokumentatsioon).

Joonisel on kõik, mis praktikumi lõpuks valmis on. Kui kaotad järje, vaata siit, millise osa juures oled.

<figure markdown="span">
  ![Vasakul õppija virtuaalmasin: Classroomi repositooriumis flask/app.py, test_app.py ja ci.yml, virtuaalkeskkonnas pytest, teegi requests näide ning GitLabi ja Jenkinsi võrdlus. git push viib GitHubi, kus pull request n07-ci käivitab Actionsis töö test (checkout, setup-python, pip install, pytest) ja selle järel töö konteiner (docker build, run, curl /health). Kui mõlemad on rohelised, on liitmine lubatud. Kui üks on punane, keelab haru main ruleset liitmise](../images/n07_labi_ylevaade.svg)
  <figcaption>Joonis 7.7. Praktikumi tervikpilt: sinu VM-ist läheb kood push'iga GitHubi, kus kaks tööd järjest otsustavad, kas pull request'i võib liita. Iga kast on üks praktikumi osa (Talvik, 2026).</figcaption>
</figure>

## Osa 0 · Repositoorium ja Pythoni keskkond

Selles osas teed valmis repositooriumi ja Pythoni keskkonna, kus teste käivitada.

### 0.1 Repositoorium

Võta Classroom 50-s vastu ülesanne **Lab 07 - GitHub Actions CI** ([Classroom 50](https://classroom50.org/hkhk-automation/it24-automatiseerimine/assignments)). Selles repositooriumis on sul administraatori õigus. Seda on vaja osas 5, kus seadistad haru `main` kaitse, ja kodutöös, kus lisad saladuse. N8 jätkab sama koodiga uues repositooriumis.

Klooni repositoorium oma virtuaalmasinasse, tee uus haru `n07-ci` ja kopeeri sinna N5 kaust `flask`:

```bash
cd ~
git clone <sinu-repo-url> lab07 && cd lab07
git switch -c n07-ci
cp -r ~/lab05/flask .
echo "# Lab 07 · CI" > README.md
ls flask/
```

Käsk `ls` peab näitama faile `app.py`, `requirements.txt` ja `Dockerfile`.

!!! warning "Paroolid ei lähe repositooriumi"
    Ka privaatsesse repositooriumi ei panda paroole, `.env` faile ega tokeneid. Kui saladus satub commit'i, ei piisa faili kustutamisest, sest see jääb Giti ajalukku. N2-s nägid seda Märteni `.env` faili näitel.

### 0.2 Rakendus töötab

Enne testide kirjutamist kontrolli, et N5 rakendus käivitub ka uues kaustas. Käsud on samad mis N5 osas 10:

```bash
docker build -t flask-app ./flask
docker run --rm -d -p 5000:5000 --name flask1 flask-app
curl localhost:5000
docker stop flask1
```

Käsk `curl` peab vastama `Tere konteinerist!` või tervitusega, mille kirjutasid N5 osas 11.

### 0.3 Virtuaalkeskkond

Testid käivituvad Pythonis konteinerist väljaspool. Et Flask ja pytest ei läheks süsteemi Pythonisse, tee projektile oma **virtuaalkeskkond** (venv). See on kaust `.venv`, kuhu paigaldatakse ainult selle projekti paketid. Kausta ei panda Giti, seepärast lisad selle faili `.gitignore`.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r flask/requirements.txt pytest
echo ".venv/" >> .gitignore
```

Käsurea ette ilmub `(.venv)`. See tähendab, et käsud `python` ja `pip` kasutavad nüüd projekti virtuaalkeskkonda.

!!! tip "Kui `python3 -m venv` annab vea `No module named venv` või `ensurepip`"
    AlmaLinuxis on Python olemas, aga mõnes virtuaalmasinas puudub pip. Paigalda see käsuga `sudo dnf install -y python3-pip` ja proovi uuesti.

!!! tip "Uues terminalis tuleb viga `pytest: command not found`"
    Virtuaalkeskkond kehtib ainult terminalis, kus käivitasid `source .venv/bin/activate`. Igas uues terminalis käivita see käsk uuesti. Kui VS Code küsib all paremal **Select interpreter**, vali `.venv`.

## Osa 1 · Esimene test oma masinas

Test peab enne töötama sinu masinas. CI ei paranda katkist testi, see ainult käivitab testi teises masinas.

Flaskil on sisseehitatud **testklient**. See saadab rakendusele päringu ilma serverit käivitamata, porti avamata ja Dockerita. Seepärast on test kiire ega sõltu võrgust ([Flask: testimine](https://flask.palletsprojects.com/en/stable/testing/)).

Loo fail `flask/test_app.py`. Test küsib avalehte `/` ja kontrollib kahte asja: vastuse kood on `200` ja vastuses on sõna `Tere`.

```python
from app import app

def test_avaleht_vastab():
    vastus = app.test_client().get("/")
    assert vastus.status_code == 200
    assert "Tere" in vastus.get_data(as_text=True)
```

Käivita test repositooriumi juurkaustas `lab07`:

```bash
pytest flask -v
```

Väljundis on rida `flask/test_app.py::test_avaleht_vastab PASSED` ja lõpus `1 passed`.

!!! tip "Kui tuleb viga `ModuleNotFoundError: No module named 'app'`"
    pytest otsib faili `app.py` testifaili kõrvalt. Testifail peab olema kaustas `flask/`, faili `app.py` kõrval. Repositooriumi juurkaustas see ei tööta.

Nüüd vaata, kuidas näeb välja kukkunud test. Muuda testis sõna `"Tere"` sõnaks `"Tervist"`. Seejärel käivita test uuesti ja vaata väljumiskoodi:

```bash
pytest flask -v
echo $?
```

Test on punane. pytest näitab, mida oodati ja mis tegelikult tuli ([pytest'i väljundi lugemine](https://docs.pytest.org/en/stable/how-to/assert.html)):

```text
>       assert "Tervist" in vastus.get_data(as_text=True)
E       AssertionError: assert 'Tervist' in 'Tere konteinerist!'
```

Käsk `echo $?` näitab `1`.

??? question "Küsimus"
    `echo $?` näitab eelmise käsu väljumiskoodi. Õnnestunud käsul on see `0`, kukkunud testil `1`. Miks otsustab CI just selle numbri järgi, kas samm on roheline või punane? Vaata loengu [§7](lecture.md#7-millal-konveier-katkeb).

Muuda testis sõna tagasi `"Tere"` ja käivita `pytest flask -v` uuesti. Väljundi lõpus peab olema `1 passed`.

Salvesta test ja fail `.gitignore` commit'iga:

```bash
git add .gitignore flask/test_app.py
git commit -m "test: avaleht vastab"
```

## Osa 2 · Esimene töövoog

Nüüd paned GitHubi sinu eest käske käivitama. **Töövoog** (workflow) on YAML-fail kaustas `.github/workflows/`. Faili nime valid ise, laiend on `.yml` või `.yaml`. Selles osas teed kaks töövoogu. Esimene on GitHubi dokumentatsiooni näide, mis näitab, mida GitHub runneri ja käivituse kohta teab. Teine on sinu oma `ci.yml`, mida hakkad järgmistes osades laiendama.

### 2.1 GitHubi näidistöövoog

GitHubi dokumentatsioonis on leht [Quickstart](https://docs.github.com/en/actions/get-started/quickstart), kus on esimene töövoog umbes 5 minutiga. Teed sama töövoo VS Code'is. Quickstart'is luuakse fail GitHubi veebis (**Add file → Create new file**, nimeks `.github/workflows/github-actions-demo.yml`, mis loob ka kaustad). Mõlemal viisil on tulemus sama.

Tee töövoo jaoks kaust:

```bash
mkdir -p .github/workflows
```

Loo fail `.github/workflows/github-actions-demo.yml`. Sisu on Quickstart'i näitest, ainult emojid on eemaldatud ja `checkout` on samas versioonis, mida kasutad edaspidi:

```yaml
name: GitHub Actions Demo
run-name: ${{ github.actor }} is testing out GitHub Actions
on: [push]
jobs:
  Explore-GitHub-Actions:
    runs-on: ubuntu-latest
    steps:
      - run: echo "The job was automatically triggered by a ${{ github.event_name }} event."
      - run: echo "This job is now running on a ${{ runner.os }} server hosted by GitHub!"
      - run: echo "The name of your branch is ${{ github.ref }} and your repository is ${{ github.repository }}."
      - name: Check out repository code
        uses: actions/checkout@v7
      - run: echo "The ${{ github.repository }} repository has been cloned to the runner."
      - run: echo "The workflow is now ready to test your code on the runner."
      - name: List files in the repository
        run: |
          ls ${{ github.workspace }}
      - run: echo "This job's status is ${{ job.status }}."
```

Kirjutis `${{ ... }}` on **kontekst** ([Contexts](https://docs.github.com/en/actions/concepts/workflows-and-actions/contexts)). Enne sammu käivitamist asendab GitHub selle väärtusega, mida ta käivituse kohta teab:

- `github.actor` on kasutaja, kes käivituse põhjustas. `run-name` paneb selle käivituse pealkirja.
- `github.event_name` on sündmuse nimi, siin `push`.
- `runner.os` on runneri operatsioonisüsteem, siin `Linux`.
- `github.ref` on haru, siin `refs/heads/n07-ci`.
- `github.workspace` on runneri töökaust, kuhu `checkout` repositooriumi failid paneb.
- `job.status` on töö olek selle sammu ajal, näiteks `success`.

Salvesta fail ja saada haru `n07-ci` GitHubi:

```bash
git add .github/workflows/github-actions-demo.yml
git commit -m "ci: GitHubi näidistöövoog"
git push -u origin n07-ci
```

Ava repositoorium GitHubis ja vali vahekaart **Actions**. Vasakul on töövoog **GitHub Actions Demo**. Paremal on **käivitus** (run), mille pealkiri tuleb reast `run-name`. Iga kord, kui töövoog käivitub, tekib siia uus käivitus. Klõpsa käivitusel, siis vasakul tööl `Explore-GitHub-Actions` ja ava iga samm. Iga `echo` real on konteksti asemel selle väärtus.

**Leia dokumentatsioonist:** lehelt [Contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) leia, mis konteksti kaudu saab töövoog kätte commit'i räsi.

??? success "Vastus"
    `github.sha`. N8-s paneb konveier selle räsi image'i tag'iks.

Näidistöövoogu rohkem vaja ei ole. Kustuta see, et see ei käivituks iga push'i järel koos sinu töövooga:

```bash
git rm .github/workflows/github-actions-demo.yml
```

### 2.2 Oma töövoog `ci.yml`

Nüüd kirjutad töövoo, mida hakkad järgmistes osades laiendama. Esialgu teeb see ainult ühe `echo`. Nii näed enne testide lisamist, et töövoog käivitub.

Loo VS Code'is fail `.github/workflows/ci.yml`. See on ainus koht juhendis, kus on terve fail. Edaspidi lisad sellele ridu ja iga uue rea juures on kirjas, mida see teeb. Loengu [§5](lecture.md#5-toovoo-fail-rida-realt) on peaaegu sama fail valmis kujul koos iga võtme selgitusega. Kui jääd mõne rea juures kahtlema, vaata sealt.

```yaml
name: CI

on: push

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "tere runnerist"
```

Faili read tähendavad järgmist:

- `name: CI` on töövoo nimi, mida GitHub näitab vahekaardil **Actions**.
- `on: push` on **sündmus** (trigger). Töövoog käivitub iga push'i järel.
- `jobs:` all on **tööd** (jobs). Töö on sammude rühm, mis tehakse ühes masinas. Siin on üks töö nimega `test`.
- `runs-on: ubuntu-latest` ütleb, millises masinas töö tehakse. GitHub annab iga töö jaoks uue Ubuntu virtuaalmasina. Seda masinat nimetatakse **runneriks**.
- `steps:` all on **sammud**. Rida `run:` käivitab runneris Bashi käsu.

VS Code'i laiendus **GitHub Actions** (GitHubi enda laiendus) näitab faili `ci.yml` vigu juba enne push'i, näiteks vale taanet või tundmatut võtit. Laiendus ei ole kohustuslik.

Töö nimi on `test`. Ära seda nime muuda, sest autograder ja N8 töövoog (`needs: test`) otsivad tööd selle nimega.

**Ennusta:** fail `ci.yml` on ainult harus `n07-ci`, harus `main` seda ei ole. Kas push harusse `n07-ci` käivitab töövoo **CI**?

Salvesta fail ja saada see GitHubi. Sama commit kustutab ka näidistöövoo:

```bash
git add .github/workflows/ci.yml
git commit -m "ci: minimaalne workflow"
git push -u origin n07-ci
```

??? success "Oodatav tulemus"
    Käivitab. GitHub otsib töövoo faile sellest commit'ist, mille push saatis, ja see commit on harus `n07-ci` ([loengu §4](lecture.md#kuidas-toovoog-kaivitub)). Haru `main` ei mõjuta seda.

Ava vahekaart **Actions**. Vasakul on nüüd töövoog **CI**. Paremal on uus käivitus, mille pealkiri on sinu commit'i sõnum, sest selles töövoos ei ole rida `run-name`. Klõpsa käivitusel, siis tööl `test` ja seejärel sammul `Run echo "tere runnerist"`. Logis on rida `tere runnerist`.

!!! tip "Vahekaardil Actions ei ole ühtegi käivitust"
    Kontrolli kausta nime. See peab olema täpselt `.github/workflows/`. Nimed `.github/workflow/` ja `github/workflows/` ei tööta. Kontrolli ka GitHubi veebis, kas fail jõudis repositooriumi ehk kas push õnnestus.

!!! tip "Käivitus on kohe punane ja logi ei ole"
    Tõenäoliselt on viga YAML-i taandes. Taandes tohib kasutada ainult tühikuid, tabulaatorid ei tööta. `steps` peab olema samal tasemel kui `runs-on`. VS Code'is näed all paremal, kas taane on **Spaces** või **Tab Size**.

!!! tip "Iga punane käivitus saadab meili"
    Selles praktikumis teed punaseid käivitusi meelega mitu korda ja iga kord tuleb meil „CI workflow run failed“. Töökohas tulevad CI teated samamoodi. Kui meilid segavad, ava GitHubis **Settings → Notifications → Actions** ja eemalda valik **Email**.

Ava töö logis kõige esimene samm **Set up job**. Sealt näed, mis masinas töö tehti. Read `Operating System` ja `Runner Image` näitavad, et see oli Ubuntu 24.04.

**Leia dokumentatsioonist:** lehelt [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) leia, mis Ubuntu versioon on silt `ubuntu-latest` ja kus on nimekiri runnerisse paigaldatud tarkvarast.

??? success "Vastus"
    `ubuntu-latest` on Ubuntu 24.04. Lehel olevas tabelis on silt `ubuntu-latest` link runneri image'i kirjeldusele repositooriumis [actions/runner-images](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md). Seal on kogu paigaldatud tarkvara nimekiri. Seda nimekirja vajad osades 3 ja 6.

??? question "Küsimus"
    Ühe `echo` käsu jaoks kulus kümmekond sekundit. Mis pidi enne juhtuma, et käsk saaks käivituda? Mis juhtub selle masinaga pärast käivituse lõppu?

## Osa 3 · Runner on tühi: kolm viga järjest

GitHub käivitab iga töö jaoks uue runneri. Selles on ainult operatsioonisüsteem ja mõned põhitööriistad. Sinu koodi, Pythoni õiget versiooni ja pakette (pytest, Flask) seal ei ole.

Sinu virtuaalmasinas on need olemas, sest paigaldasid need ise N5-s ja selle praktikumi osas 0. Seepärast töötab `pytest` sinu masinas, aga runneris annab vea. Pärast töö lõppu runner kustutatakse ja järgmine töö saab jälle tühja masina.

Selles osas lisad töövoogu ükshaaval kõik, mida runner vajab. Iga puuduv asi annab ühe vea. Loe veateadet ja lisa puuduv samm.

<figure markdown="span">
  ![Vasakul õppija virtuaalmasin, kus on kood, Python, Flask, pytest ja kunagi paigaldatud requests. Keskel ci.yml read, mis toovad igaühe runnerisse. Paremal runner, kus requests puudub](../images/n07_tyhi_masin.svg)
  <figcaption>Joonis 7.5 (loengust). Selle osa lõpuks on sul kõik neli lillat rida olemas. Viiendat (requests) näed Osa 4-s (Talvik, 2026).</figcaption>
</figure>

Alusta töövoost, kus Python on olemas, aga muud puudub. Asenda failis `ci.yml` kogu `steps` osa järgmisega:

```yaml
    steps:
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
      - run: pytest flask -v
```

Siin on uut tüüpi samm. Rida `uses:` käivitab **action'i**. Action on valmis programm, mille on kirjutanud keegi teine ja mis on avaldatud GitHubis. Märgi `@` järel on versioon. Action [`setup-python`](https://github.com/actions/setup-python) paigaldab runnerisse Pythoni. Võti `with:` annab action'ile parameetri, siin Pythoni versiooni `3.12`. Rida `run:` käivitab tavalise Bashi käsu nagu osas 2.

**Leia dokumentatsioonist:** ava action'i [`actions/setup-python`](https://github.com/actions/setup-python) README ja leia, mis parameetriga valitakse Pythoni versioon ja mis juhtub, kui seda parameetrit ei ole.

??? success "Vastus"
    Parameeter on `python-version`. Kui see puudub, otsib action versiooni failist `.python-version`. Kui ka seda ei ole, kasutatakse runneris juba olevat Pythoni versiooni. Seepärast kirjutatakse versioon töövoogu alati välja.

**Ennusta:** sinu masinas läbis `pytest flask -v` osas 1. Mis juhtub runneris?

Salvesta muudatus ja saada see GitHubi:

```bash
git add .github/workflows/ci.yml && git commit -m "ci: pytest" && git push
```

??? success "Oodatav tulemus"
    Käivitus on punane. Runneris ei ole pytest'i, sest seda ei ole keegi sinna paigaldanud. Vea täpse teate leiad järgmises sammus.

### 3.1 Viga: tööriista ei ole

Ava vahekaardil **Actions** viimane käivitus. Selle ees on punane rist. Ava töö `test` ja samm `Run pytest flask -v`. Logi lõpus on:

```text
pytest: command not found
Error: Process completed with exit code 127.
```

Väljumiskood `127` tähendab, et käsku ei leitud. Kui logi ei ütle põhjust nii selgelt, aitab GitHubi juhend [Troubleshoot workflows](https://docs.github.com/en/actions/how-tos/troubleshoot-workflows). Seal on kirjas, kuidas lugeda logi ja kuidas lülitada sisse põhjalikum logi.

??? question "Leia põhjus"
    Sinu virtuaalmasinas töötas sama käsk. Mille poolest erinevad sinu virtuaalmasin ja runner? Kuidas pytest sinu masinasse jõudis (osa 0)?

!!! tip "Kui tuleb hoopis viga `file or directory not found: flask`"
    Siis oli runneri image'is pytest juba olemas. GitHub uuendab runnerite image'eid pidevalt ja seal olevad tööriistad muutuvad. Ära sellele looda. Lisa allolev `pip install pytest` samm ikkagi ja jätka sammuga 3.2.

Runner vajab sama sammu, mille tegid oma masinas osas 0: pytest'i paigaldamist. Lisa sammude `setup-python` ja `pytest` vahele rida:

```yaml
      - run: pip install pytest
```

Salvesta muudatus commit'iga ja saada see GitHubi nagu eelmises sammus (`git add`, `git commit`, `git push`).

### 3.2 Viga: koodi ei ole

Uus käivitus on jälle punane. Seekord on logis:

```text
ERROR: file or directory not found: flask
no tests ran
Error: Process completed with exit code 4.
```

pytest on nüüd olemas, aga kausta `flask` ei leita.

??? question "Leia põhjus"
    Lisa ajutiselt sammu `pytest` ette samm `- run: ls -la` ja saada muudatus GitHubi. Mida näitab `ls -la` runneri töökaustas? Kus on sinu kood, kui see ei ole seal?

Runnerisse ei tule repositooriumi faile ise. Action [`actions/checkout`](https://github.com/actions/checkout) laadib repositooriumi sisu runneri töökausta. Lisa see `steps` alla **esimeseks** sammuks, sest kõik järgmised sammud vajavad faile:

```yaml
      - uses: actions/checkout@v7
```

Sammu `ls -la` võid nüüd kustutada või alles jätta. Saada muudatus GitHubi.

`actions/checkout` on esimene võõras kood, mis sinu runneris käivitub. Loengu [§9](lecture.md#9-toovoo-turvalisus) kirjeldab, mida võõra action'i juures kontrollida.

**Leia dokumentatsioonist:** leia lehelt [Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use), mis on ainus viis kinnitada action nii, et see ei saa enam muutuda.

??? success "Vastus"
    Action tuleb kinnitada täispika commit'i räsiga (*full-length commit SHA*). Tag'i, näiteks `v7`, saab action'i autor teisele commit'ile ümber tõsta. Praktikumis kasutame loetavuse pärast tag'e. Räsiga kinnitamist saad proovida lisaülesandes 8.

### 3.3 Viga: sõltuvust ei ole

Käivitus on kolmandat korda punane:

```text
ImportError while importing test module '/home/runner/work/.../flask/test_app.py'.
...
E   ModuleNotFoundError: No module named 'flask'
Interrupted: 1 error during collection
```

Kood ja pytest on nüüd runneris olemas, aga Flaski ei ole.

??? question "Leia põhjus"
    Mis failis on kirjas, milliseid pakette rakendus vajab? Mis loeb seda faili juba N5-s (vaata `Dockerfile`)?

Rakenduse paketid on kirjas failis `flask/requirements.txt`. Asenda rida `pip install pytest` reaga, mis paigaldab ka need paketid:

```yaml
      - run: pip install -r flask/requirements.txt pytest
```

Saada muudatus GitHubi. Käivitus on roheline. Ava samm `Run pytest flask -v`. Seal on sama rida `PASSED`, mida nägid osas 1 oma masinas.

Võrdle oma tööd `test` järgmisega. Kui midagi erineb, paranda:

```yaml
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
      - run: pip install -r flask/requirements.txt pytest
      - run: pytest flask -v
```

!!! tip "Kui samm `checkout` või `setup-python` on punane"
    Kontrolli kirjapilti: `actions/checkout@v7` koos märgiga `@` ja võtmega `uses:`. Võtmega `run:` see ei tööta. `with:` peab olema `uses:` suhtes kahe tühiku võrra sisse nihutatud.

Sama mustri (`setup-python`, `pip install`, `pytest`) leiad GitHubi ametlikust juhendist [Building and testing Python](https://docs.github.com/en/actions/tutorials/build-and-test-code/python). Sama töövoo saab ka mallina: vahekaardil **Actions** vajuta **New workflow** ja GitHub pakub Pythoni repositooriumile Pythoni malli.

**Leia dokumentatsioonist:** leia juhendist [Building and testing Python](https://docs.github.com/en/actions/tutorials/build-and-test-code/python), kuidas käivitada sama töö mitme Pythoni versiooniga.

??? success "Vastus"
    Töö juurde lisatakse `strategy: matrix` ja selle alla versioonide loend, näiteks `python-version: ["3.11", "3.12"]`. Sammus `setup-python` kirjutatakse versiooni asemel `${{ matrix.python-version }}`. GitHub käivitab iga versiooni jaoks eraldi töö. Proovi seda lisaülesandes 2.

??? question "Küsimus"
    Vaata vahekaardil **Actions** käivituste ajalugu. Seal on kolm punast ja üks roheline käivitus ning iga punane parandati ühe reaga. Mis oli kõigi kolme vea ühine põhjus? Miks on hea, et CI on nii range?

### 3.4 Käivitus uuesti

Kui käivitus kukkus põhjusel, mis ei ole sinu koodis (näiteks võrguühendus katkes), saab sama käivituse uuesti käivitada ilma uue commit'ita.

**Leia dokumentatsioonist:** leia dokumentatsiooni osast How-tos jaotisest Manage workflow runs, kuidas käivitada uuesti ainult käivituse kukkunud tööd.

??? success "Vastus"
    Juhend on lehel [Re-run workflows and jobs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs). Käivituse lehel paremal üleval on menüü **Re-run jobs** ja selles valik **Re-run failed jobs**. Valik **Re-run all jobs** käivitab kõik tööd uuesti.

**Ennusta:** käivita uuesti osa 3.1 punane käivitus (`pytest: command not found`). Kas see on nüüd roheline, kuna sinu praegune `ci.yml` on korras?

??? success "Oodatav tulemus"
    Ei ole, see on jälle punane. Uuesti käivitamine kasutab sama commit'i ja selle commit'i töövoo faili, kus samm `pip install` veel puudus ([loengu §4](lecture.md#kuidas-toovoog-kaivitub)). Uus töövoo fail kehtib ainult uutele commit'idele.

## Osa 4 · Teek, mis on ainult sinu masinas

Arendaja paigaldab sageli teegi, mida ta kavatseb varsti kasutada, ainult oma masinasse. Faili `requirements.txt` jääb see kirja panemata. Tema masinas on testid rohelised. Selles osas teed sama vea meelega ja vaatad, mida CI näitab.

Lisa faili `flask/app.py` algusesse, teiste `import` ridade alla:

```python
import requests
```

Paigalda teek ainult oma virtuaalkeskkonda ja käivita testid:

```bash
pip install requests
pytest flask -v
```

Sinu masinas on testid rohelised.

**Ennusta:** mis juhtub CI-s, kui saadad selle muudatuse GitHubi?

```bash
git add flask/app.py && git commit -m "feat: requests" && git push
```

??? success "Oodatav tulemus"
    Töö `test` on punane. Logis on:

    ```text
    E   ModuleNotFoundError: No module named 'requests'
    ```

??? question "Leia põhjus"
    Sinu masinas test läbis, CI-s kukkus ja kood on mõlemas sama. Mis on erinev? Mis juhtuks, kui keegi ehitaks sellest koodist N5 Docker image'i? Mis juhtuks tootmisserveris?

Just selliste vigade leidmiseks CI ongi olemas. Sinu virtuaalmasinasse koguneb aja jooksul pakette, mille paigaldamist sa ei mäleta. Runner alustab iga kord tühjast masinast ja paigaldab ainult selle, mis on repositooriumis kirjas.

Vea saab parandada kahel viisil. Vali üks:

- kui teeki on vaja, lisa rida `requests` faili `flask/requirements.txt`;
- kui teeki ei kasutata, kustuta failist `app.py` rida `import requests`.

Saada parandus GitHubi. Töö `test` on jälle roheline.

??? question "Küsimus"
    Failis `requirements.txt` on rida `flask==3.0.3` koos versiooniga. Mis võib juhtuda poole aasta pärast, kui kirjutad `requests` ilma versioonita ja teegist ilmub uus suurversioon?

## Osa 5 · Pull request ja haru `main` kaitse

Seni käivitus CI ainult push'i järel. Meeskonnas on kõige tähtsam see, mis juhtub **pull request'is**, sest seal otsustatakse, kas kood läheb harusse `main`. Selles osas paned CI käivituma ka pull request'is ja keelad punase testiga koodi liitmise.

### 5.1 Sündmus `pull_request`

Lisa töövoole teine sündmus. Muuda failis `ci.yml` rida `on:` selliseks:

```yaml
on:
  push:
  pull_request:
```

Nüüd käivitub töövoog nii push'i järel kui ka pull request'is. Saada muudatus GitHubi.

**Leia dokumentatsioonist:** leia lehelt [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) jaotisest `pull_request`, millised pull request'i tegevused käivitavad töövoo vaikimisi.

??? success "Vastus"
    Vaikimisi käivitavad töövoo tegevused `opened`, `synchronize` ja `reopened`: pull request avatakse, sellesse lisatakse uus commit või see avatakse uuesti. Muid tegevusi saab lisada võtmega `types`.

Ava GitHubis pull request harust `n07-ci` harusse `main`. Pull request'i lehe allosas on kast **Checks**. Seal on rida `CI / test (pull_request)` ja see on roheline.

### 5.2 CI haru `main` kaitsesse

Uues repositooriumis ei ole haru `main` veel kaitstud. N2-s tegid **ruleset'i**: GitHubi reeglite kogumi, mis määrab, mida harus tohib teha. Tee sama ruleset, aga lisa sellele reegel, et töö `test` peab olema roheline.

Ruleset'i loomise juhend koos piltidega on lehel [Creating rulesets for a repository](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository). Ava **Settings → Rules → Rulesets → New ruleset → New branch ruleset** ja seadista:

- **Ruleset Name:** `main-lukk`, **Enforcement status:** `Active`.
- **Target branches → Add target → Include default branch**. Nii kehtib reegel harule `main`.
- Lülita sisse **Require a pull request before merging** ja pane **Required approvals** väärtuseks `0`. Töötad üksi ja oma pull request'i ei saa ise heaks kiita.
- Lülita sisse **Require status checks to pass**, vajuta **Add checks**, kirjuta `test` ja vali see nimekirjast.
- Vajuta **Create**.

Iga reegli kirjeldus on [GitHubi ruleset'ide juhendis](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).

!!! tip "`test` ei ilmu nimekirja **Add checks**"
    GitHub pakub ainult neid kontrolle, mis on selles repositooriumis hiljuti käivitunud. Kontrolli, et sammu 5.1 käivitus on lõppenud. Kui `test` ikka ei ilmu, kirjuta nimi käsitsi täpselt nii nagu töö nimi failis: `test`.

??? question "Küsimus"
    N2-s nõudis haru kaitse ühte heakskiitu, nüüd null. Mis kontroll kadus ja mis tuli asemele? Kas meeskonnas jätaksid heakskiidu nõude alles?

### 5.3 Proovi kaitsest mööda saada

Kontrolli, kas reegel töötab. Riku test meelega: muuda failis `flask/test_app.py` sõna `"Tere"` sõnaks `"Tervist"`. Ära käivita testi oma masinas, sest tahad näha, mida teeb CI.

```bash
git add flask/test_app.py && git commit -m "test: kas lukk peab" && git push
```

**Ennusta:** mida näed pull request'i lehel?

??? success "Oodatav tulemus"
    Kast **Checks** on punane ja liitmise nupp on hall. Lehel on teade **Merging is blocked** või `Required status check "test" is failing`.

??? question "Küsimus"
    Kes keelas liitmise: sina, õpetaja, GitHub või test? Mida see reegel kontrollib, mida N2 reegel (üks heakskiit) ei kontrollinud? Mida see endiselt ei kontrolli?

Muuda testis sõna tagasi `"Tere"` ja saada muudatus GitHubi. Pull request'i kontroll muutub roheliseks ja liitmise nupp ka. **Ära veel liida.** Pull request jääb avatuks kuni osani 9.

!!! tip "Liitmise nupp on hall, kuigi kõik kontrollid on rohelised"
    Ruleset nõuab heakskiitu. Kontrolli, et **Required approvals** väärtus on `0`.

### 5.4 Käivitamine käsitsi

Mõnikord on vaja töövoog käivitada ilma uue commit'ita, näiteks selleks, et kontrollida, kas haru `main` töötab ka pärast runneri image'i uuendust. Selleks on sündmus `workflow_dispatch`. Kui see on võtme `on:` all, tekib vahekaardile **Actions** nupp **Run workflow**. Lisa see sündmus:

```yaml
on:
  push:
  pull_request:
  workflow_dispatch:
```

Saada muudatus GitHubi.

**Ennusta:** ava vahekaardil **Actions** vasakult töövoog **CI**. Kas nupp **Run workflow** on olemas?

??? success "Oodatav tulemus"
    Nuppu ei ole. Sündmus `workflow_dispatch` töötab ainult siis, kui töövoog on repositooriumi vaikeharus `main` ([Manually running a workflow](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)). Sinu `ci.yml` on praegu ainult harus `n07-ci`. Nupp ilmub pärast liitmist osas 9.

Jaotises [Manage workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs) on ka teised käivituste haldamise juhendid koos piltidega. Neid vajad töökohas sageli:

- [käivituse tühistamine](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/cancel-a-workflow-run) nupuga **Cancel workflow**, kui käivitasid vale muudatuse;
- [töövoo välja lülitamine](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows) valikuga **Disable workflow**, kui töövoogu ajutiselt vaja ei ole;
- [commit ilma käivituseta](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs): kui commit'i sõnumis on `[skip ci]`, ei käivitu sündmuste `push` ja `pull_request` töövood. Ole ettevaatlik, sest siis jääb ruleset'i nõutud kontroll ootele ja pull request'i ei saa liita;
- [artefaktide allalaadimine](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts): failid, mille töövoog salvestas, näiteks testide aruanne.

## Osa 6 · Konteineri kontroll CI-s

Töö `test` kontrollib, kas **kood** töötab. N5-s nägid, et kood võib olla korras, aga konteinerist rakendus ei vasta (`127.0.0.1` ja `0.0.0.0` erinevus). Selles osas lisad teise töö `konteiner`, mis ehitab image'i, käivitab konteineri ja küsib sellelt vastust. See on loengus kirjeldatud suitsutest.

Lisa failis `ci.yml` võtme `jobs:` alla uus töö. See peab olema töö `test` kõrval samal taandetasemel, töö `test` sisse seda ei panda:

```yaml
  konteiner:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: docker build -t flask-app ./flask
      - run: docker run -d -p 5000:5000 --name flask1 flask-app
      - run: curl -fsS --retry 10 --retry-all-errors --retry-delay 1 localhost:5000/health
```

Uued read tähendavad järgmist:

- [`needs: test`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idneeds) paneb tööd järjekorda. Töö `konteiner` alustab alles siis, kui töö `test` on roheline. Katkise koodiga image'it ei ole mõtet ehitada.
- Docker on runneris juba olemas ja seda ei pea paigaldama. Seda näed runneri tarkvara nimekirjast, mille leidsid osas 2.2.
- `--retry` ([curl'i juhend](https://curl.se/docs/manpage.html#--retry)) kordab päringut kuni 10 korda. Käsk `docker run` lõpetab kohe, aga Flask vajab käivitumiseks veidi aega. Ilma kordamiseta küsiks `curl` mõnikord liiga vara ja test oleks vahel roheline, vahel punane.
- `-f` paneb käsu `curl` lõpetama veakoodiga, kui HTTP vastus on viga (4xx või 5xx). Ilma selleta loetaks ka vastus `404` õnnestumiseks.

**Leia dokumentatsioonist:** leia lehelt [Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) jaotisest `jobs.<job_id>.needs`, mis juhtub töödega, millel ei ole võtit `needs`.

??? success "Vastus"
    Tööd käivituvad vaikimisi korraga (*in parallel*). Kui töö sõltub teisest tööst, tuleb see kirjutada võtmega `needs`. Kui töö, millest sõltutakse, kukub, jäetakse sõltuv töö vahele.

**Ennusta:** `curl` küsib aadressi `/health`. Kas sinu rakendus oskab sellele vastata?

Saada muudatus GitHubi ja ava vahekaardil **Actions** uus käivitus.

??? success "Oodatav tulemus"
    Töö `test` on roheline ja töö `konteiner` on punane. Viimase sammu logis on:

    ```text
    curl: (22) The requested URL returned error: 404
    ```

??? question "Leia põhjus"
    Konteiner käivitus ja vastas, sest vastuse `404` andis Flask. Mida CI küsis ja millistele aadressidele rakendus vastab? Ava fail `flask/app.py` ja vaata, millised aadressid (route'id) seal on.

Rakenduses ei ole aadressi `/health`. CI küsib midagi, mida rakendus ei paku. Sama juhtub siis, kui monitooring või N6 Compose'i healthcheck küsib tervisekontrolli aadressi, mida arendaja ei ole teinud.

Enne parandamist lisa töö `konteiner` lõppu samm, mis näitab kukkumise korral konteineri logi. Tingimus `if: failure()` tähendab, et samm käivitub ainult siis, kui mõni eelmine samm kukkus:

```yaml
      - if: failure()
        run: docker logs flask1
```

Saada muudatus GitHubi. Punase käivituse viimases sammus on nüüd Flaski logi ja selles rida `"GET /health HTTP/1.1" 404`. Edaspidi näed kohe, mida konteiner nägi, ja viga ei pea oma masinas uuesti tekitama.

!!! tip "Viga `curl: (7) Failed to connect`"
    Pordil 5000 ei kuula keegi. Kontrolli, et käsus `docker run` on `-p 5000:5000` ja faili `app.py` lõpus on `host="0.0.0.0"` (N5 osa 10).

!!! tip "Töö `konteiner` on hall ja selle juures on *skipped*"
    Töö `test` kukkus ja `needs: test` jättis järgmise töö käivitamata. Paranda kõigepealt töö `test`.

??? question "Küsimus"
    Miks on `test` ja `konteiner` kaks eraldi tööd? Mida näed vahekaardil **Actions**, mida ühe töö puhul ei näeks?

## Osa 7 · Test enne koodi

Rakendusele tuleb lisada aadress `/health`. Seekord teed seda vastupidises järjekorras: **kõigepealt test, siis kood**. Test kirjeldab, mida rakendus peab tegema. Kui kood on valmis, näitab test seda ise.

### 7.1 Test kukub

Lisa faili `flask/test_app.py` lõppu test, mis küsib aadressi `/health` ja ootab JSON-vastust `{"status": "ok"}`:

```python
def test_health_vastab_ok():
    vastus = app.test_client().get("/health")
    assert vastus.status_code == 200
    assert vastus.get_json() == {"status": "ok"}
```

**Ennusta:** kas uus test läbib?

```bash
pytest flask -v
```

??? success "Oodatav tulemus"
    Uus test on punane ja nii see peabki olema:

    ```text
    E       assert 404 == 200
    ```

    Test kirjeldab aadressi, mida rakenduses veel ei ole.

### 7.2 Test läbib

Lisa failis `flask/app.py` route'i `index` järele uus route. Flask teeb Pythoni sõnastikust ise JSON-vastuse.

```python
@app.route("/health")
def health():
    return {"status": "ok"}
```

Käivita testid uuesti:

```bash
pytest flask -v
```

Väljundi lõpus on `2 passed`. Saada muudatus GitHubi. Vahekaardil **Actions** on mõlemad tööd, `test` ja `konteiner`, rohelised. Sama route läbis kaks eri kontrolli: ühiktesti ja konteineri suitsutesti.

### 7.3 Sinu test

Kirjuta ise kolmas test. Kui küsida aadressi, mida rakenduses ei ole (näiteks `/olematu`), peab rakendus vastama koodiga `404`. Koodi ei pea selleks muutma, sest Flask vastab nii juba ise.

!!! tip "Test läbib kohe esimesel korral"
    Kontrolli, kas test üldse midagi kontrollib. Muuda see korraks meelega valeks (`== 200`), veendu, et test läheb punaseks, ja pane tagasi. Test, mis ei saa kunagi kukkuda, ei kaitse millegi eest.

Käivita testid ja saada kõik muudatused GitHubi:

```bash
pytest flask -v
git add flask/ && git commit -m "feat: /health + testid" && git push
```

Väljundi lõpus peab olema `3 passed` ja vahekaardil **Actions** on mõlemad tööd rohelised.

??? question "Küsimus"
    Osas 6 tuli nõue `/health` väljastpoolt, CI-st. Osas 7 kirjutasid nõude kõigepealt testiks ja alles siis koodi. Kumb järjekord annab kiiremini teada, kas töö on valmis? Kumb sobib paremini, kui sama aadressi vajab ka N6 Compose'i healthcheck?

## Osa 8 · Sama konveier teistes tööriistades

Sinu `ci.yml` töötab ainult GitHubis. Järgmises töökohas võib olla kasutusel GitLab CI või Jenkins. Kõik ei pea siis otsast peale õppima, sest mudel on sama ja muutub ainult süntaks. Ava loengu [§8](lecture.md#8-sama-mote-teised-tooriistad) ja vaata kolme vahelehte, kus on sama konveier GitHub Actionsis, GitLab CI-s ja Jenkinsis.

<figure markdown="span">
  ![Kolm veergu: GitHub Actions saab iga käivituse jaoks uue tühja virtuaalmasina, GitLab CI uue konteineri, Jenkins kasutab sama serverit, kuhu kogunevad eelmiste käivituste failid](../images/n07_kolm_tooriista.svg)
  <figcaption>Joonis 7.6 (loengust). Alumine rida on sinu tabeli vihje: kood, Python ja järjekord kolmes tööriistas (Talvik, 2026).</figcaption>
</figure>

Suurim erinevus on masinas. GitHub Actions saab iga käivituse jaoks uue virtuaalmasina ja GitLab CI uue konteineri. Jenkins kasutab sageli sama serverit, kuhu jäävad eelmiste käivituste failid ja paketid. Tööriistu ja nende litsentse võrdled N8 loengu osas [§8 „CI/CD tööriistad ja litsentsid“](../week08/lecture.md#8-cicd-tooriistad-ja-litsentsid).

??? question "Küsimus"
    GitLabi failis ei ole ühtegi checkout'i rida ja Jenkinsis samuti mitte. Kas see tähendab, et seal ei saa tekkida osa 3.2 viga? Mis teeb nende tööriistade puhul selle töö ära?

??? question "Küsimus"
    Jenkinsi agent on sageli server, mis töötab kuude kaupa. Meenuta osa 4. Kui keegi käivitab Jenkinsi serveris korra `pip install requests`, mis juhtub järgmise kuu kõigi käivitustega? Kas Jenkins leiaks osa 4 vea?

## Osa 9 · Töö esitamine

Autograder hindab haru `main`, seega pead pull request'i lõpuks liitma. Enne seda lisa README-sse lingid ja vastused.

Repositooriumis peavad olema järgmised failid:

```text
lab07/                     # Classroomi repo
├── .github/workflows/
│   └── ci.yml             # test + konteiner, needs, pull_request
├── .gitignore             # .venv/
├── README.md              # jaotis "## N7 CI": 2 linki + 3 lauset
└── flask/
    ├── app.py             # + /health
    ├── requirements.txt   # Osa 4 parandus sees
    ├── Dockerfile
    └── test_app.py        # 3 testi
```

Lisa faili `README.md` jaotis `## N7 CI`. Selles on:

- link ühele **punasele** ja ühele **rohelisele** käivitusele. Lingi saad, kui avad vahekaardil **Actions** käivituse ja kopeerid aadressiriba sisu;
- vastused kolmele küsimusele, igaüks üks lause:
    1. Miks runneris puudus pytest, kuigi sinu virtuaalmasinas oli see olemas?
    2. Miks osa 4 viga sinu masinas ei paistnud?
    3. Mida muudab `needs: test`?

Salvesta muudatused ja saada need GitHubi:

```bash
git add . && git commit -m "N7 CI lab" && git push
```

Pull request harust `n07-ci` harusse `main` on avatud osast 5. Kui kastis **Checks** on `test` ja `konteiner` rohelised, vajuta **Merge pull request**.

Nüüd on `ci.yml` harus `main`. Ava vahekaardil **Actions** töövoog **CI**. Nupp **Run workflow** on nüüd olemas (osa 5.4). Vali haruks `main` ja käivita töövoog käsitsi. Käivituse juures on sündmuseks `workflow_dispatch`.

Autograder hindab haru `main` nagu N5 ja N6 praktikumis. Tulemus on repositooriumi lehel jaotises **Releases** ja Classroom 50-s. Hinne tuleb kontrollidest 1–7 (kokku 100 punkti). Kodutöö kontroll „BOONUS 8“ annab lisapunkte.

## Lõppkontroll

Kui praktikum on tehtud, peaksid oskama järgmist ilma juhendita:

- [ ] `pytest flask -v` sinu virtuaalmasinas näitab `3 passed`.
- [ ] Failis `ci.yml` on kaks tööd, `test` ja `konteiner`, ning töös `konteiner` on `needs: test`.
- [ ] Pull request'i kastis **Checks** on mõlemad tööd rohelised.
- [ ] Vahekaardi **Actions** ajaloos on vähemalt kolm punast käivitust osast 3. Neid ei kustutata.
- [ ] Punase testiga commit teeb pull request'i liitmise nupu halliks (ruleset `main-lukk`).
- [ ] Punase käivituse logist oskad öelda, kas viga on koodis (`AssertionError`, `ModuleNotFoundError`) või töövoos (`file or directory not found`, `command not found`).
- [ ] Kui rikud aadressi `/health` (näiteks `"status": "katki"`), kukub test enne, kui konteinerit üldse ehitatakse.
- [ ] Oskad näidata GitLabi ja Jenkinsi failis rea, mis teeb sama tööd mis `needs: test`.

## Lisaülesanded

1. **Dockerfile'i kontroll.** Lisa kolmas töö `lint`. Sellel ei ole võtit `needs`, seega käivitub see korraga tööga `test`:

    ```yaml
      lint:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v7
          - uses: hadolint/hadolint-action@v3.5.0
            with:
              dockerfile: flask/Dockerfile
    ```

    Töö läheb tõenäoliselt punaseks hoiatuse [`DL3013`](https://github.com/hadolint/hadolint/wiki/DL3013) tõttu (`pip install` ilma versioonideta). Kas parandad `Dockerfile`'i või lisad parameetri `failure-threshold: error`? Mida kumbki valik maksab?

2. **Mitu Pythoni versiooni.** Uuri võtit [`strategy: matrix`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstrategymatrix) ja näidet juhendis [Building and testing Python](https://docs.github.com/en/actions/tutorials/build-and-test-code/python). Käivita töö `test` korraga Pythoni versioonidega 3.11, 3.12 ja 3.13. Mitu tööd tekib vahekaardile **Actions**?

3. **Kiirem paigaldus.** Action'il `setup-python` on parameeter [`cache: pip`](https://github.com/actions/setup-python#caching-packages-dependencies). Lisa see ja võrdle sammu `pip install` kestust enne ja pärast.

4. **Käivitus ainult siis, kui vaja.** Muuda README-d ja saada muudatus GitHubi. Miks käivitus kogu konveier, kuigi kood ei muutunud? Uuri võtit [`on.push.paths`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore). Kuidas panna CI käivituma ainult siis, kui muutub kaust `flask/` või fail `ci.yml`?

5. **Jenkins.** Käivita Jenkins oma virtuaalmasinas konteinerina ([Jenkins Dockeris](https://www.jenkins.io/doc/book/installing/docker/)). Port 8080 on N6 nginx'i kasutuses, seepärast kasuta porti 8081:

    ```bash
    docker run -d -p 8081:8080 --name jenkins jenkins/jenkins:lts-jdk21
    docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
    ```

    Teine käsk näitab administraatori algparooli. Ava brauseris `http://<VM-IP>:8081`, sisesta parool ja vali **Install suggested plugins**. Vali **New Item → Pipeline**, kleebi sinna loengu §8 `Jenkinsfile`'ist `test` etapp ja vajuta **Build Now**. Mis viga tuleb ja miks? Võrdle osaga 3.1: kes peab Jenkinsis Pythoni paigaldama, kui action'it `setup-python` ei ole?

6. **CI kodus ilma virtuaalmasinata.** Ava repositoorium [GitHub Codespaces'is](https://docs.github.com/en/codespaces/quickstart) (repositooriumi lehel **Code → Codespaces**). Seal on Python ja Docker olemas ning käske `pytest` ja `docker build` saab käivitada brauseris. Peata Codespace pärast kasutamist, sest tasuta kasutusaeg on piiratud.

7. **GitHubi Pythoni mall.** Vaata, kuidas GitHubi enda Pythoni mall sama tööd teeb, ja võrdle seda oma failiga `ci.yml`. Mallid avanevad vahekaardil **Actions** nupuga **New workflow**. Juhend piltidega on lehel [Using workflow templates](https://docs.github.com/en/actions/how-tos/write-workflows/use-workflow-templates). Otsi malli **Python application** ja ava see nupuga **Configure**, aga sulge leht ilma commit'ita. Kui commit'id malli, käivitub iga push'i järel lisaks töövoole `ci.yml` ka teine töövoog. Millised sammud on mallis ja sinu failis samad? Mida teeb mall lisaks (vihje: `flake8`)?

8. **Action'ite turvalisus.** Vali üks kahest ([loengu §9](lecture.md#9-toovoo-turvalisus)):

    - Kinnita `actions/checkout` täispika räsiga. Räsi leiad action'i repositooriumi lehelt **Releases** või käsuga `git ls-remote https://github.com/actions/checkout v7.0.1`. Kirjuta tag rea lõppu kommentaariks, näiteks `# v7.0.1`.
    - Lase Dependabotil action'eid ajakohasena hoida. Loo fail `.github/dependabot.yml` ([juhend](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot)):

        ```yaml
        version: 2
        updates:
          - package-ecosystem: "github-actions"
            directory: "/"
            schedule:
              interval: "weekly"
        ```

        Kui mõnest action'ist ilmub uus versioon, teeb Dependabot pull request'i. CI kontrollib seda nagu iga teist pull request'i.
