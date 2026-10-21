---
tags:
  - CI
  - GitHubActions
  - Testimine
  - Praktikum
---

# GitHub Actions CI — Labor

**Kestus:** 3 × 45 min. Klassis jõuad Osad 0–7, Osad 8–9 (võrdlus, README ja esitamine) lõpeta kodus.
**Eeldused:** Loeng antud (CI, trigger/job/step, exit code). Nädal 5 `flask/` kaust (Flask + `Dockerfile`, `host="0.0.0.0"`). Nädal 2: ruleset ja PR. Kui udu — [tagasi loengusse](lecture.md). Siit edasi **ainult käed külge**.
**Keskkond:** kood ja testid **VS Code'is** sinu AlmaLinuxi VM-is. CI jookseb GitHubi runneris (värske Ubuntu VM, mitte sinu masin — see ongi mõte). `git push` paneb konveieri käima.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Kirjutad Flaskile automaattesti ja käivitad selle enne igat push'i lokaalselt
    2. Ehitad `.github/workflows/ci.yml` samm-sammult, testides igal sammul
    3. **Diagnoosid** Actions-logist viis tüüpilist CI-viga (puuduv tööriist, puuduv kood, puuduv sõltuvus, „töötab minu masinas", katkine konteiner)
    4. Eristad, kas punane X tuleb **koodist** või **workflow'st**
    5. Paned CI `main`-i luku külge, nii et punase testiga PR-i ei saa mergida
    6. Kirjutad testi **enne** koodi ja näed, kuidas test juhib arendust

---

Labi loogika: **baas → laienda → viga → paranda → laienda → viga → paranda.** Sa ei kopeeri valmis `ci.yml`-i. Kasvatad selle rida-realt, lõhud igal võtmekohal meelega ja saad aru **miks**. Tervet faili näed **üks kord** (Osa 2), edasi ainult „lisa see samm" / „lisa see job".

## Mida sa täna ehitad

Vaata enne alustamist seda pilti. Labi lõpuks on sul **kõik see** olemas ja töötab. Kui kaotad järje, tule siia tagasi ja vaata, millise kasti juures sa oled.

<figure markdown="span">
  ![Vasakul sinu VM: avalik repo flask/app.py, test_app.py ja ci.yml, venv'is pytest, „töötab minu masinas" näide ja GitLab/Jenkins võrdlus. git push viib GitHubi, kus PR n07-ci käivitab Actionsis job'i test (checkout, setup-python, pip install, pytest) ja sellele järgneva job'i konteiner (docker build, run, curl /health). Mõlemad rohelised: merge lubatud. Üks punane: main ruleset blokeerib merge'i](../images/n07_labi_ylevaade.svg)
  <figcaption>Joonis 7.7. Labi tervikpilt: sinu VM-ist läheb kood push'iga GitHubi, kus kaks job'i järjest otsustavad, kas PR-i võib mergida. Iga kast on üks labi osa (Talvik, 2026).</figcaption>
</figure>

---

## Osa 0 · Eeltöö — oma avalik repo ja Python-keskkond

Selle nädala töö läheb **sinu enda avalikku repo**. Avalik on see kahel põhjusel: õpetaja näeb seda ilma kutseta, ja GitHub Free jõustab `main`-i luku (Osa 5) ainult avalikes repodes. Privaatses repos saab reegli küll teha, aga seda ei kontrollita ([GitHub: rulesetid](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)).

GitHubis: **New repository** → nimi `ci-labor` → **Public** → linnuke **Add a README file** → **Create repository**. Klooni see ja too sinna oma N5 Flask:

```bash
cd ~
git clone <sinu-repo-url> ci-labor && cd ci-labor
git switch -c n07-ci
cp -r ~/lab05/flask .
ls flask/
```

!!! warning "Avalik repo = kogu maailm näeb"
    Reposse ei lähe paroole, `.env` faile, tokeneid ega sinu täisnime või isikukoodi. GitHubi kasutajanimest piisab. Kui midagi lekib, siis ainult kustutamisest ei piisa — see jääb Git'i ajalukku (meenuta nädal 2 Märteni `.env`-i).

`flask/` all peavad olema `app.py`, `requirements.txt` ja `Dockerfile`. Kontrolli, et rakendus ikka töötab (N5 Osa 10):

```bash
docker build -t flask-app ./flask
docker run --rm -d -p 5000:5000 --name flask1 flask-app
curl localhost:5000
docker stop flask1
```

Vastus `Tere konteinerist!` (või sinu Osa 11 tervitus)? Edasi.

Testid jooksevad Pythonis **väljaspool** konteinerit. Tee projektile oma virtuaalkeskkond, et Flask ja pytest ei läheks süsteemi Pythonisse:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r flask/requirements.txt pytest
echo ".venv/" >> .gitignore
```

Käsurea ette ilmub `(.venv)`. See tähendab, et `python` ja `pip` on nüüd projekti omad.

!!! tip "Kui `python3 -m venv` annab vea `No module named venv` või `ensurepip`"
    AlmaLinuxis on Python olemas, aga mõnes VM-is puudub pip: `sudo dnf install -y python3-pip` ja proovi uuesti.

!!! tip "Uus terminal, aga `pytest: command not found`"
    venv kehtib ainult terminalis, kus sa `source .venv/bin/activate` tegid. Igas uues terminalis aktiveeri uuesti. VS Code küsib all paremal „Select interpreter" — vali `.venv`.

---

## Osa 1 · Esimene test — lokaalselt

Enne kui test läheb pilve, peab see töötama sinu masinas. CI ei paranda katkist testi, ainult jooksutab seda.

Flaskil on sisseehitatud **test client**: see saadab rakendusele päringu ilma serverit käivitamata, porti avamata ja Dockerita. Test on seega kiire ja sõltumatu võrgust ([Flask: testimine](https://flask.palletsprojects.com/en/stable/testing/)).

Loo `flask/test_app.py`:

```python
from app import app


def test_avaleht_vastab():
    vastus = app.test_client().get("/")
    assert vastus.status_code == 200
    assert "Tere" in vastus.get_data(as_text=True)
```

Käivita **repo juurkaustast**:

```bash
pytest flask -v
```

Oodatav: `flask/test_app.py::test_avaleht_vastab PASSED` ja `1 passed`.

!!! tip "Kui saad `ModuleNotFoundError: No module named 'app'`"
    pytest otsib `app.py` faili testifaili kõrvalt. Test peab olema **kaustas `flask/`**, `app.py` kõrval, mitte repo juures.

Nüüd tee **meelega valesti**. Muuda testis `"Tere"` → `"Tervist"` ja käivita uuesti.

```bash
pytest flask -v
echo $?
```

**Punane.** pytest näitab täpselt, mis oli oodatud ja mis tuli ([kuidas pytest'i väljundit lugeda](https://docs.pytest.org/en/stable/how-to/assert.html)):

```text
>       assert "Tervist" in vastus.get_data(as_text=True)
E       AssertionError: assert 'Tervist' in 'Tere konteinerist!'
```

`echo $?` näitab `1`.

??? question "Diagnoosi"
    `echo $?` näitab eelmise käsu exit code'i. Edukal käsul on see `0`, kukkunud testil `1`. Miks on just see number see, mille järgi CI otsustab, kas linnuke on roheline või punane? (Meenuta loengu §5.)

**Paranda** tagasi `"Tere"`, kontrolli `1 passed`.

```bash
git add .gitignore flask/test_app.py
git commit -m "test: avaleht vastab"
```

---

## Osa 2 · Baas — workflow, mis ütleb tere

Workflow on YAML-fail kaustas `.github/workflows/` ([süntaks](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)). Alusta millestki, mis ei tee midagi kasulikku. Nii näed kõigepealt, kuidas mehhanism töötab, enne kui midagi saab katki minna.

```bash
mkdir -p .github/workflows
```

`.github/workflows/ci.yml` — **ainus kord terve fail**, edasi lisad ridu:

```yaml
name: CI

on: push

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "tere runnerist"
```

Job'i nimi on `test`. **Jäta see nimi**: nädal 8 ehitab selle peale (`needs: test`).

```bash
git add .github/workflows/ci.yml
git commit -m "ci: minimaalne workflow"
git push -u origin n07-ci
```

Ava repo GitHubis → **Actions**. Vasakul on „CI", paremal run sinu commit-sõnumiga. Kliki run'il → job'il `test` → sammul `Run echo "tere runnerist"`. Logis peab olema `tere runnerist`.

!!! tip "Actions tab'is pole ühtegi „CI" run'i"
    Kontrolli kausta teed: täpselt `.github/workflows/`, mitte `.github/workflow/` ega `github/workflows/`. Kontrolli GitHubi veebis, et fail on päriselt seal: kas push läks läbi?

!!! tip "Run on kohe punane, logi pole"
    YAML-i taane. Ainult tühikud, mitte tab'id; `steps` on `runs-on` all samal tasemel. VS Code näitab tab'e, kui all paremal on „Tab Size", mitte „Spaces".

!!! tip "Iga punane run saadab sulle meili"
    Selles labis tekitad punase X-i meelega mitu korda ja iga kord tuleb meil „CI workflow run failed“. See on normaalne, tööl tulevad CI teated just nii. Kui meilid segavad: GitHub → **Settings → Notifications → Actions** → eemalda **Email**.

Ava job'i logis kõige esimene samm **Set up job**. Seal on kirjas, mis masin see oli: `Operating System Ubuntu 24.04`, `Runner Image`.

??? question "Mõtle"
    Ühe `echo` jaoks kulus kümmekond sekundit. Mis kõik pidi enne juhtuma, et su käsk üldse jookseks? Mis juhtub selle masinaga pärast run'i lõppu?

---

## Osa 3 · Tühi masin — kolm viga järjest

Runner on **värske ja tühi** masin. Sinu VM-is on olemas kõik, mis sa N5-st peale paigaldasid. Runneris pole mitte midagi. Selles osas leiad ise, mida tal on vaja, ühe vea kaupa.

<figure markdown="span">
  ![Vasakul sinu VM, kus on kood, Python, Flask, pytest ja kunagi paigaldatud requests. Keskel ci.yml read, mis toovad igaühe runnerisse. Paremal runner, kus requests puudub](../images/n07_tyhi_masin.svg)
  <figcaption>Joonis 7.5 (loengust). Selle osa lõpuks on sul kõik neli lillat rida olemas. Viiendat (requests) näed Osa 4-s (Talvik, 2026).</figcaption>
</figure>

Asenda `steps` osa — Python on, aga muud mitte:

```yaml
    steps:
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
      - run: pytest flask -v
```

`uses:` käivitab kellegi teise valmis action'i. [`setup-python`](https://github.com/actions/setup-python) paneb runnerisse õige Pythoni versiooni. `run:` on tavaline bash-käsk.

```bash
git add .github/workflows/ci.yml && git commit -m "ci: pytest" && git push
```

### 3.1 Viga: tööriista pole

Actions tab → **punane X**. Ava samm `Run pytest flask -v`:

```text
pytest: command not found
Error: Process completed with exit code 127.
```

??? question "Diagnoosi"
    Sinu VM-is töötas sama käsk. Mis on erinevus su VM-i ja runneri vahel? Kuidas sa pytest'i oma VM-i said (Osa 0)?

!!! tip "Kui saad hoopis `file or directory not found: flask`"
    Runneri image'is oli pytest juhtumisi juba olemas. GitHub uuendab neid image'eid pidevalt. Ära sellele looda: lisa `pip install pytest` ikkagi ja mine edasi 3.2 juurde.

**Paranda** — lisa `setup-python` ja `pytest` vahele:

```yaml
      - run: pip install pytest
```

Push.

### 3.2 Viga: koodi pole

Jälle punane. Seekord:

```text
ERROR: file or directory not found: flask
no tests ran
Error: Process completed with exit code 4.
```

pytest on nüüd olemas, aga kausta `flask` ei ole.

??? question "Diagnoosi"
    Lisa ajutiselt `pytest` sammu ette `- run: ls -la` ja push. Mida runner oma töökaustas näeb? Kus su kood on, kui mitte seal?

**Paranda** — [`actions/checkout`](https://github.com/actions/checkout) laadib repo sisu runnerisse. Lisa see `steps` **esimeseks** sammuks:

```yaml
      - uses: actions/checkout@v7
```

`ls -la` võid nüüd ära kustutada või jätta. Push.

### 3.3 Viga: sõltuvust pole

Punane, kolmas kord:

```text
ImportError while importing test module '/home/runner/work/.../flask/test_app.py'.
...
E   ModuleNotFoundError: No module named 'flask'
Interrupted: 1 error during collection
```

Kood on kohal, pytest on kohal, aga Flaski ei ole.

??? question "Diagnoosi"
    Kus on kirjas, mida sinu rakendus vajab? Kes seda faili juba loeb (vihje: N5 `Dockerfile`)?

**Paranda** — `pip install pytest` rida asenda:

```yaml
      - run: pip install -r flask/requirements.txt pytest
```

Push. **Roheline.** Ava samm `Run pytest flask -v` — näed sama `PASSED` rida, mis Osa 1-s sinu masinas.

Kontrolliks peab `test` job nüüd olema selline:

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

??? question "Mõtle"
    Vaata Actions tab'is run'ide ajalugu: kolm punast, üks roheline. Iga punane parandati **ühe reaga**. Mis oli kõigi kolme vea ühine põhjus? Miks on hea, et CI just nii range on?

!!! tip "Kui `checkout` või `setup-python` on punane"
    Kirjapilt: `actions/checkout@v7`, koos `@`-ga, `uses:` all, mitte `run:` all. `with:` on `uses:` all **kahe tühiku** võrra sisse nihutatud.

---

## Osa 4 · „Töötab minu masinas"

Pinginaaber lisas rakendusse teegi, mida ta „kohe varsti" kasutama hakkab. Tema masinas on kõik roheline. Teeme sama.

Lisa `flask/app.py` algusesse, teiste importide alla:

```python
import requests
```

Paigalda see **ainult oma venv'i** (nagu pinginaaber tegi):

```bash
pip install requests
pytest flask -v
```

Lokaalselt **roheline**. Push:

```bash
git add flask/app.py && git commit -m "feat: requests" && git push
```

CI: **punane.**

```text
E   ModuleNotFoundError: No module named 'requests'
```

??? question "Diagnoosi"
    Sinu masinas läbis, CI-s kukkus. Kood on mõlemas sama — mis on erinev? Mis juhtuks, kui keegi ehitaks sellest koodist N5 Docker image'i? Mis juhtuks tootmisserveris?

Selle vea leidmiseks CI ongi olemas. Sinu VM on aja jooksul täis kogunenud asju, mida keegi ei mäleta. Runner alustab iga kord nullist ja usub ainult seda, mis on repos kirjas.

**Paranda** — kaks õiget teed, vali üks:

- teeki on vaja → lisa rida `requests` faili `flask/requirements.txt`;
- teeki ei kasutata → kustuta `import requests`.

Push → roheline.

??? question "Mõtle"
    `requirements.txt`-is on `flask==3.0.3`, versiooniga. Kui kirjutad `requests` ilma versioonita, mis võib juhtuda poole aasta pärast, kui `requests` annab välja uue suurversiooni?

---

## Osa 5 · Pull request ja lukk

Seni käivitus CI ainult push'i peale. Meeskonnas loeb aga see, mis juhtub **PR-is**: just seal otsustatakse, kas kood läheb `main`-i.

### 5.1 PR-i trigger

Muuda `on:` rida — CI käivitub nüüd ka PR-i peal:

```yaml
on:
  push:
  pull_request:
```

Push. Ava GitHubis PR `n07-ci` → `main`. PR-i lehe all on **Checks** kast: `CI / test (pull_request)`, roheline.

### 5.2 CI luku külge

Uues repos lukku veel pole. Tee see nagu nädalal 2, aga ühe reegliga rohkem: „testid peavad olema rohelised".

GitHubis: **Settings → Rules → Rulesets → New ruleset → New branch ruleset**:

- nimi `main-lukk`, **Enforcement status: Active**
- **Target branches → Add target → Include default branch**
- **Require a pull request before merging** — sisse, **Required approvals: 0** (töötad üksi, oma PR-i ise heaks kiita ei saa)
- **Require status checks to pass** — sisse → **Add checks** → kirjuta `test` → vali see nimekirjast
- **Create**

Mida iga reegel teeb, on kirjas [GitHubi rulesetide juhendis](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).

!!! tip "`test` ei ilmu „Add checks" nimekirja"
    GitHub pakub ainult neid check'e, mis on selles repos hiljuti jooksnud. Kontrolli, et Osa 5.1 run on läbi. Kui ikka ei ilmu, kirjuta nimi käsitsi täpselt nii nagu job'i nimi failis: `test`.

??? question "Mõtle"
    Nädalal 2 nõudis lukk ühte heakskiitu, nüüd null. Mis kontroll kadus ja mis tuli asemele? Kas meeskonnas jätaksid heakskiidu nõude alles?

### 5.3 Proovi lukku murda

Riku test meelega: `flask/test_app.py`-s `"Tere"` → `"Tervist"`. **Ära käivita lokaalselt.**

```bash
git add flask/test_app.py && git commit -m "test: kas lukk peab" && git push
```

Ava PR. Checks kast on punane ja merge-nupp on hall: **Merging is blocked** / `Required status check "test" is failing`.

??? question "Diagnoosi"
    Kes keelas merge'i: kas sina, õpetaja, GitHub või test? Mida see lukk kontrollib, mida nädal 2 lukk („vaja ühte heakskiitu") ei kontrollinud — ja mida see endiselt **ei** kontrolli?

**Paranda** testi tekst tagasi, push. PR muutub roheliseks ja merge-nupp roheliseks. **Ära veel mergi** — PR jääb lahti kuni Osa 9.

!!! tip "Merge-nupp on hall, kuigi kõik on roheline"
    Lukk nõuab heakskiitu (nädal 2 seadistus). Pane **Required approvals** väärtuseks `0` või palu paarilisel PR üle vaadata.

---

## Osa 6 · Laienda — konteiner CI-s

`test` job kontrollib, kas **kood** töötab. N5-s nägid, et kood võib töötada, aga konteiner ikka mitte (`127.0.0.1` vs `0.0.0.0`). Teine job kontrollib, kas **image** ehitub ja konteiner vastab.

Lisa `jobs:` alla, **samal tasemel** kui `test`, mitte selle sisse:

```yaml
  konteiner:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: docker build -t flask-app ./flask
      - run: docker run -d -p 5000:5000 --name flask1 flask-app
      - run: curl -fsS --retry 10 --retry-connrefused --retry-delay 1 localhost:5000/health
```

- [`needs: test`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idneeds) — `konteiner` alustab alles siis, kui `test` on roheline. Katkist koodi pole mõtet pakkima hakata.
- Docker on runneris juba olemas, seda ei pea paigaldama.
- `--retry` ([curl'i juhend](https://curl.se/docs/manpage.html#--retry)) — `docker run` naaseb kohe, aga Flask vajab käivitumiseks hetke. Ilma retry'ta küsib `curl` mõnikord liiga vara: test oleks vahel roheline ja vahel punane.
- `-f` — `curl` lõpetab mittenullilise exit code'iga, kui HTTP vastus on viga (4xx/5xx). Ilma `-f`-ita oleks ka `404` „edukas".

Push. Actions: `test` roheline → `konteiner` **punane**:

```text
curl: (22) The requested URL returned error: 404
```

??? question "Diagnoosi"
    Konteiner käivitus ja vastas — `404` tuli Flaskilt. Mida CI küsis ja mida su rakendus oskab? Ava `flask/app.py`: millised route'id seal on?

Rakendusel pole `/health` route'i. CI küsib asja, mida rakendus ei paku — täpselt nii näeb välja olukord, kus monitooring (või N6 healthcheck) küsib tervisekontrolli, mida arendaja pole teinud.

Enne parandamist lisa job'i lõppu samm, mis näitab kukkumise korral konteineri logi:

```yaml
      - if: failure()
        run: docker logs flask1
```

Push. Punase run'i lõpus on nüüd Flaski logi: `"GET /health HTTP/1.1" 404`. Edaspidi näed kohe, mida konteiner teel nägi, ilma et peaksid oma masinas viga uuesti tekitama.

!!! tip "`curl: (7) Failed to connect`"
    Keegi ei kuula pordil 5000. Kas `docker run`-is on `-p 5000:5000` ja kas `app.py` lõpus on `host="0.0.0.0"` (N5 Osa 10)?

!!! tip "`konteiner` on hall, „skipped""
    `test` kukkus ja `needs: test` peatas järgmise job'i. Paranda kõigepealt `test`.

??? question "Mõtle"
    Miks hoida `test` ja `konteiner` eraldi job'idena, mitte ühe job'i järjestikuste sammudena? Mida näed Actions tab'is, mida ühe job'iga ei näeks?

---

## Osa 7 · Test enne koodi

`/health` tuleb lisada. Seekord teed seda tagurpidi: **kõigepealt test, siis kood**. Test on kirjeldus sellest, mida rakendus peab tegema. Kui kood on valmis, ütleb test seda sulle ise.

### 7.1 Punane

Lisa `flask/test_app.py` lõppu:

```python
def test_health_vastab_ok():
    vastus = app.test_client().get("/health")
    assert vastus.status_code == 200
    assert vastus.get_json() == {"status": "ok"}
```

```bash
pytest flask -v
```

**Punane**, ja see on **õige**:

```text
E       assert 404 == 200
```

Test kirjeldab asja, mida veel pole.

### 7.2 Roheline

Lisa `flask/app.py`-sse, `index` route'i järele:

```python
@app.route("/health")
def health():
    return {"status": "ok"}
```

Flask teeb Pythoni sõnastikust ise JSON-vastuse.

```bash
pytest flask -v
```

`2 passed`. Push. Actions: `test` roheline → `konteiner` **roheline**. Sama route rahuldas nüüd kaks erinevat kontrolli: ühiktesti ja konteineri suitsutesti.

### 7.3 Sinu test

Kirjuta **ise** kolmas test: kui küsida aadressi, mida ei ole (nt `/olematu`), peab rakendus vastama `404`. Koodi ei pea selleks muutma — Flask teeb seda juba.

!!! tip "Test läbib kohe esimesel korral"
    Kas see test üldse kontrollib midagi? Riku see korraks meelega (`== 200`), veendu, et see läheb punaseks, ja pane tagasi. Test, mis ei saa kunagi kukkuda, ei kaitse millegi eest.

```bash
pytest flask -v
git add flask/ && git commit -m "feat: /health + testid" && git push
```

??? question "Mõtle"
    Osa 6-s tuli nõue (`/health`) väljastpoolt, CI-st. Osa 7-s kirjutasid selle kõigepealt testi kujul ja alles siis koodi. Kumb järjekord annab sulle kiiremini teada, kas sa oled valmis? Kumb sobiks paremini, kui sama route'i vajab ka N6 Compose healthcheck?

---

## Osa 8 · Sama konveier mujal

Sinu `ci.yml` töötab ainult GitHubis. Järgmisel töökohal võib olla GitLab või Jenkins. Kas peaksid siis kõik otsast õppima? Ei pea: mudel on sama, vahetub ainult süntaks.

Ava loengu [§7](lecture.md#7-sama-mote-teised-tooriistad) ja vaata kolme sakki: sama konveier GitHub Actionsis, GitLab CI-s ja Jenkinsis.

<figure markdown="span">
  ![Kolm veergu: GitHub Actions saab iga run'i jaoks uue tühja VM-i, GitLab CI uue konteineri, Jenkins kasutab sama serverit, kuhu kogunevad eelmiste run'ide jäägid](../images/n07_kolm_tooriista.svg)
  <figcaption>Joonis 7.6 (loengust). Alumine rida on sinu tabeli vihje: kood, Python ja järjekord kolmes tööriistas (Talvik, 2026).</figcaption>
</figure> Täida oma README-s tabel (kopeeri see sinna):

| Küsimus | GitHub Actions (sinu `ci.yml`) | GitLab CI | Jenkins |
|---|---|---|---|
| Mis failis konveier on? | | | |
| Mis rida toob koodi masinasse? | | | |
| Kust tuleb õige Python? | | | |
| Mis tagab, et konteinerit ei ehitata katkise testiga? | | | |
| Kas masin on iga kord värske? | | | |

??? question "Diagnoosi"
    GitLabi failis pole ühtegi checkout'i rida, Jenkinsis ka mitte. Kas see tähendab, et seal pole Osa 3.2 viga võimalik? Mis teeb seda tööd nende eest?

??? question "Mõtle"
    Jenkinsi agent on sageli server, mis jookseb kuude kaupa. Mõtle Osa 4 peale: kui keegi teeb Jenkinsi serveris korra `pip install requests`, siis mis juhtub järgmise kuu kõigi run'idega? Kas Jenkins leiaks sinu Osa 4 vea üles?

---

## Osa 9 · Esitamine

Lõpuks peab repo välja nägema nii:

```text
ci-labor/                  # avalik repo
├── .github/workflows/
│   └── ci.yml             # test + konteiner, needs, pull_request
├── .gitignore             # .venv/
├── README.md              # + jaotis "## N7 CI" ja Osa 8 tabel
└── flask/
    ├── app.py             # + /health
    ├── requirements.txt   # Osa 4 parandus sees
    ├── Dockerfile
    └── test_app.py        # 3 testi
```

`README.md` lõppu jaotis `## N7 CI` (vähemalt 100 sõna). Vasta oma sõnadega:

- miks runneris puudusid pytest, kood ja Flask, kuigi sinu VM-is olid olemas (Osa 3);
- miks Osa 4 viga oli sinu masinas nähtamatu;
- mida `needs: test` muudab ja miks `-f` on `curl`-il vajalik (Osa 6);
- link ühele **punasele** ja ühele **rohelisele** run'ile (Actions → run → aadressiriba);
- Osa 8 tabel täidetud.

```bash
git add . && git commit -m "N7 CI lab" && git push
```

PR `n07-ci` → `main` on juba lahti (Osa 5). Ära seda veel mergi. Kontrolli, et PR-i Checks kastis on `test` ja `konteiner` rohelised. **Esita PR-i link** GitHub Projectis. Repo jääb avalikuks — nädal 8 jätkab samas repos.

---

## Lõppkontroll — oskad ilma juhendita

- [ ] `pytest flask -v` sinu VM-is näitab `3 passed`
- [ ] `ci.yml`-is on kaks job'i: `test` ja `konteiner`, ning `konteiner`-il on `needs: test`
- [ ] PR-i Checks kastis on mõlemad job'id rohelised
- [ ] Actions ajaloos on näha vähemalt kolm punast run'i Osa 3-st (neid ei kustuta)
- [ ] Punase testiga commit teeb PR-i merge-nupu halliks (ruleset `main-lukk`)
- [ ] Oskad öelda punase run'i logi järgi, kas viga on koodis (`AssertionError`, `ModuleNotFoundError`) või workflow's (`file or directory not found`, `command not found`)
- [ ] Riku `/health` (nt `"status": "katki"`) ja näed, et test kukub **enne**, kui konteiner üldse ehitatakse
- [ ] Näitad GitLabi ja Jenkinsi failis rea, mis teeb sama tööd mis sinu `needs: test`

---

## Lisaülesanded (kui jõuad ette)

1. **Dockerfile'i lint.** Lisa kolmas job `lint` (ilma `needs`-ita, jookseb `test`-iga paralleelselt):

    ```yaml
      lint:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v7
          - uses: hadolint/hadolint-action@v3.5.0
            with:
              dockerfile: flask/Dockerfile
    ```

    See läheb tõenäoliselt punaseks hoiatuse [`DL3013`](https://github.com/hadolint/hadolint/wiki/DL3013) tõttu (`pip install` ilma versioonideta). Vali: kas parandad Dockerfile'i või lisad `failure-threshold: error`? Mis on kummagi hind?

2. **Mitu Pythoni versiooni.** Uuri [`strategy: matrix`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstrategymatrix). Jooksuta `test` job'i korraga Pythoni 3.11, 3.12 ja 3.13 peal. Mitu job'i Actions tab'is tekib?

3. **Kiirem install.** `setup-python`-il on [`cache: pip`](https://github.com/actions/setup-python#caching-packages-dependencies). Lisa see ja võrdle `pip install` sammu aega enne ja pärast.

4. **Ainult siis, kui vaja.** Muuda README-d ja push. Miks käivitus kogu konveier, kuigi kood ei muutunud? Uuri [`on.push.paths`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore) — kuidas panna CI käivituma ainult siis, kui muutub `flask/` või `ci.yml`?

5. **Päris Jenkins.** Käivita Jenkins oma VM-is konteinerina ([Jenkins Dockeris](https://www.jenkins.io/doc/book/installing/docker/)) (port 8080 on N6 nginx'i käes, seega 8081):

    ```bash
    docker run -d -p 8081:8080 --name jenkins jenkins/jenkins:lts-jdk21
    docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
    ```

    Ava `http://<VM-IP>:8081`, sisesta parool, vali „Install suggested plugins". Tee **New Item → Pipeline**, kleebi loengu §7 `Jenkinsfile`'i `test` stage ja käivita (**Build Now**). Mis viga tuleb ja miks? Võrdle Osa 3.1-ga: kes peab Jenkinsis Pythoni paigaldama, kui `setup-python`-it pole?

6. **CI kodus ilma VM-ita.** Ava repo [**GitHub Codespaces'is**](https://docs.github.com/en/codespaces/quickstart) (repo leht → Code → Codespaces). Seal on Python ja Docker olemas — jooksuta `pytest` ja `docker build` brauseris. Ära unusta Codespace'i pärast peatada, kvoot on piiratud.
