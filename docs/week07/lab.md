---
tags:
  - CI
  - GitHubActions
  - Praktikum
---

# GitHub Actions CI — Labor

**Kestus:** 4 tundi
**Eeldused:** Loeng antud (CI, trigger/job/step). GitHub repo nädalast 5–6 (Dockerfile + rakenduse kood), push-õigus. Kui udu — [tagasi loengusse](lecture.md).
**Keskkond:** kood **VS Code'is**, CI jookseb GitHubi runneris (mitte su masinas — see ongi mõte). `git push` viib töö käima.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Lood ja laiendad `.github/workflows/ci.yml` samm-sammult
    2. **Loed Actions-logi** ja tuvastad miks üks samm kukkus
    3. Tekitad punase X-i meelega ja tunned ära, kas viga on koodis või workflow's
    4. Lisad teise job'i (lint), mis jookseb paralleelselt
    5. Selgitad miks `checkout` on vajalik

---

Labi loogika: **baas → laienda → viga → paranda → laienda.** Ehitad workflow'i samm-sammult, tekitad punase X-i ise, õpid logi lugema. Tervet faili kokku ei kopeeri — lisad ridu.

---

## Osa 1 · Baas — trigger ja echo

Workflow on YAML-fail kaustas `.github/workflows/`. Alusta millestki, mis ei tee midagi kasulikku peale ühe teksti — nii näed kõigepealt kuidas mehhanism töötab.

Loo struktuur ja fail VS Code'is:

```bash
mkdir -p .github/workflows
```

`.github/workflows/ci.yml`:

```yaml
name: CI

on: push

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - run: echo "hello"
```

- `on: push` — trigger, käivitub iga push peale.
- `jobs.hello` — üks job, jookseb eraldi VM-is.
- `runs-on: ubuntu-latest` — värske Ubuntu masin.
- `steps` — praegu üks: `echo "hello"`.

!!! tip
    Workflow ei käivitu üldse? Kontrolli kausta teed: täpselt `.github/workflows/`, mitte `.github/workflow/` ega `github/workflows/`. GitHub otsib ainult sellest täpsest kohast.

```bash
git add .github/workflows/ci.yml
git commit -m "ci: minimaalne workflow"
git push
```

---

## Osa 2 · Actions tab — vaata mis juhtus

Ava repo GitHubis → **Actions** tab. Näed push'i järgi käivitunud "CI". Ava see, kliki job'il `hello`, ava samm `Run echo "hello"` — logis peab olema `hello`.

??? question "Mõtle"
    Miks kulub isegi selle üherealise `echo` käivitamiseks kümmekond sekundit? Mis kõik peab enne juhtuma, et su käsk üldse jookseks?

!!! tip
    Actions tab tühi, ühtegi run'i pole? Tavaliselt fail vales kaustas või YAML-taane katki. Vaata repo pealehel kas `.github/workflows/ci.yml` üldse on ja sisu klapib.

---

## Osa 3 · Checkout — too kood masinasse

Praegu workflow ei tee midagi su koodiga — käivitab `echo` tühjas masinas. Testimiseks peab runner su koodi alla laadima. Selleks on valmis action `actions/checkout` — `uses:` kutsub kellegi teise valmis koodi, `run:` käivitab bash-käsu.

Asenda `steps` osa:

```yaml
    steps:
      - uses: actions/checkout@v4
      - run: echo "hello"
      - run: ls -la
```

Pushi, vaata `ls -la` logi — nüüd näed oma repo faile (Dockerfile, kood), mitte tühja kausta.

??? question "Diagnoosi"
    Enne `checkout` sammu polnud masinas su koodi. Mida `actions/checkout` täpselt tegi, mida `echo` üksi ei suutnud?

!!! tip
    `checkout` punase X-iga? Tavaliselt vale versioon (`@v4` täpselt, koos `@`) või taandeviga. YAML on tühikutundlik, tab-e ei tohi.

---

## Osa 4 · Päris test

Nüüd samm, mis päriselt midagi kontrollib. Vali oma rakenduse järgi:

**Variant A — Python/Flask (pytest):**

```yaml
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt
      - run: python -m pytest
```

Kui testifaili pole, loo minimaalne, mis kontrollib et rakendus importub:

```python
# test_app.py
from app import app

def test_app_exists():
    assert app is not None
```

**Variant B — shellikontroll (igale rakendusele, ilma Pythonita):**

```yaml
      - name: Kontrolli et Dockerfile on olemas
        run: test -f Dockerfile
```

Lisa valitud variant olemasolevate sammude järele, pushi. Uus samm peab olema roheline.

??? question "Mõtle"
    `test -f Dockerfile` on primitiivne "test" — ei kontrolli kas rakendus töötab, ainult et fail on. Mida see samm sulle siiski kindlustab, mida käsitsi kontroll kergesti unustab?

---

## Osa 5 · Punane X — kuidas näeb ebaõnnestumine

Enne kui CI-d usaldad, pead nägema kuidas näeb **ebaõnnestumine**. Riku test meelega:

- Variant A: `assert app is None` (vale).
- Variant B: `test -f Dockerfille` (kirjaviga).

Pushi. Actions tab — viimane run **punase X-iga**. Ava kukkunud samm, loe veateade lõpuni. GitHub näitab täpselt mis real ja mis põhjusel — sarnaselt terminali veateatele, mida oskad juba lugeda.

??? question "Mõtle"
    Töötad meeskonnas, pushid koodi mis **sinu** masinas töötas, aga CI näitab punast. Mis võib olla põhjus, et asi töötab su arvutis, aga mitte runneris? (Sama "töötab minu masinas", teiselt poolt.)

!!! tip
    Punane X, aga veateadet ei leia? Kliki konkreetsel **sammul**, mitte ainult job'i nimel — logi on sammude kaupa kokku volditud.

---

## Osa 6 · Paranda — roheline linnuke

Tühista meelega tehtud viga, pushi uuesti. Uus run roheline, eelmine (katki) jääb ajalukku punasena. See ajalugu on kasulik: näed täpselt millise commiti juures asjad katki läksid ja millise juures paranesid — nagu `git log`, aga tervise kohta.

---

## Osa 7 · Teine job — lint

Üks job testib loogikat. Lisa teine, mis kontrollib Dockerfile'i **kvaliteeti** (linting) — mitte kas kood töötab, vaid kas see on hästi kirjutatud (nt kas kasutad `latest` tag'i, mis on halb tava).

Lisa `jobs:` alla (**samal** tasemel kui esimene job, mitte selle sisse):

```yaml
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Hadolint
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile
```

Pushi — nüüd näed run'i sees **kahte job'i paralleelselt**: testijob ja `lint`.

!!! tip
    `lint` leiab palju vigu? Normaalne — hadolint on range. Vead on konkreetsed soovitused (nt "pin versions" — fikseeri versioonid `apt install`-is). Kõiki pole vaja praegu parandada, oluline on mõista mida linter kontrollib.

??? question "Mõtle"
    Testijob kontrollib kas rakendus **töötab**. Lint-job kas Dockerfile on **hästi kirjutatud**. Miks hoida need eraldi job'idena, mitte üksteise järel ühes?

---

## Lõppkontroll — oskad ilma juhendita

- [ ] Repos on `.github/workflows/ci.yml`
- [ ] Actions tab'is vähemalt üks roheline run
- [ ] Ajaloos ka vähemalt üks **punane** run (Osa 5, kustutamata)
- [ ] Workflow'is kaks job'i: test (checkout + test) ja `lint` (checkout + hadolint)
- [ ] Selgitad miks `checkout` on vajalik
- [ ] Oskad avada kukkunud sammu logi ja leida konkreetse veateate

---

## Lisaülesanded (kui jõuad ette)

- Lisa `pull_request` trigger (`on: [push, pull_request]`), loo haru, ava PR — vaata kuidas CI run ilmub PR-i lehele (ja meenuta nädal 2 branch protection'it: CI + lukk = katkine kood ei jõua `main`-i).
- Lisa `yamllint` samm, mis kontrollib su enda `ci.yml` korrektsust.
- Piira trigger: `on: push: branches: [main]`.
- Uuri `needs:` — kuidas panna `lint` jooksma ainult siis kui test läbis?

---

## Veaotsing

| Probleem | Lahendus |
|---|---|
| Actions tab tühi | Fail täpselt `.github/workflows/ci.yml`; kontrolli GitHubi veebis |
| YAML süntaksiviga, run ei alga | Taane vale — ainult tühikud, mitte tab; sama taseme read sama arvu tühikutega |
| `actions/checkout` kukub | Versiooni kirjapilt (`@v4`), rida `uses` all mitte `run` |
| Test läbib su masinas, mitte CI-s | Erinev Python/paketi versioon, puuduv `requirements.txt`, või ainult su masinas olev sõltuvus |
| Hadolint leiab kümneid vigu | Normaalne — paranda olulisemad, ülejäänud lisaülesandeks |
| Kaks job'i ei jookse paralleelselt | Mõlemad `jobs:` all samal taandel, mitte üks teise sees |

*Tabel 7.1. Levinumad tõrked ja lahendused.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| GitHub Actions dokumentatsioon | <https://docs.github.com/en/actions> | Ametlik süntaks |
| Understanding GitHub Actions | <https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions> | workflow/job/step mõisted |
| actions/checkout | <https://github.com/actions/checkout> | Action ja versioonid |
| Hadolint Action | <https://github.com/hadolint/hadolint-action> | Dockerfile linter |
| Hadolint reeglid | <https://github.com/hadolint/hadolint#rules> | Lint-vigade seletused |
