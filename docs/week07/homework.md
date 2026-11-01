---
tags:
  - CI
  - GitHubActions
  - DockerCompose
  - Kodutöö
---

# Kodutöö: CI testib rakendust koos andmebaasiga

**Eeldus:** praktikum on tehtud. Failis `ci.yml` on tööd `test` ja `konteiner` ning pull request `n07-ci` on roheline. N6 praktikumist on vaja teenuseid `web` ja `db`, aadressi `/db-check` ja faili `.env`.

## Ülesanne

Praktikumis kontrollis CI üht konteinerit üksinda. Rakendus vajab aga ka andmebaasi. N6-s nägid, et Flask ja andmebaas võivad mõlemad töötada, aga nad ei saa omavahel ühendust, näiteks vale hostinime või puuduva parooli tõttu. Selliseid vigu ei leia ühiktest ega üksiku konteineri suitsutest.

Selles kodutöös lisad töövoogu kolmanda töö `stack`. See käivitab Compose'iga Flaski koos PostgreSQL-iga ja kontrollib, et aadress `/db-check` vastab `DB OK`.

<figure markdown="span">
  ![Kolm tööd järjest: test, konteiner ja stack. Töö stack käivitab Compose'iga konteinerid web ja db ning curl küsib aadressi /db-check. Esimene katse on punane, sest db lõpetab töö ilma paroolita. Parool tuleb GitHubi saladusest](../images/n07_kodutoo_stack.svg)
  <figcaption>Joonis 7.8. Kolmas töö kontrollib teenuste koostööd, mitte üht teenust. Esimene katse on punane meelega (Talvik, 2026).</figcaption>
</figure>

## Sammud

### 1. Haru

Kodutöö teed eraldi harus, et praktikumi töö jääks muutmata. Tee uus haru `n07-kodu` haru `n07-ci` uusima seisu pealt:

```bash
git switch n07-ci && git pull
git switch -c n07-kodu
```

### 2. Rakendus küsib andmebaasilt

Töö `stack` kontrollib aadressi `/db-check`, seega peab see aadress olema rakenduses olemas. Too N6 praktikumi osast 3 aadressi `/db-check` kood oma repositooriumi faili `flask/app.py`. Lisa faili `flask/requirements.txt` rida `psycopg2-binary`, sest selle teegiga ühendub Flask PostgreSQL-iga. N6-s oli kood kaustas `~/lab06/app`, nüüd tuleb see repositooriumi kausta `flask/`.

Kontrolli oma masinas, et praktikumi testid töötavad edasi:

```bash
source .venv/bin/activate
pip install -r flask/requirements.txt
pytest flask -v
```

Väljundi lõpus peab olema `3 passed`.

!!! question "Kas uus aadress vajab ka testi?"
    Aadress `/db-check` vajab töötavat andmebaasi. Seepärast ei saa seda testida testkliendiga `test_client()` ilma andmebaasita. Selle kontrollib töö `stack`. Mõtle, mis vahe on testil, mis vajab ainult koodi, ja testil, mis vajab kogu rakendust koos andmebaasiga.

### 3. Fail `compose.yaml`

Compose'i fail kirjeldab, mis konteinerid koos käivitatakse. Kirjuta repositooriumi juurkausta fail `compose.yaml` N6 praktikumi põhjal. Vaja on ainult kaht teenust, `web` ja `db`. Nginx'i ei ole siin vaja. Erinevused N6 failist:

??? note "Tabel"
    | N6 praktikumis | Siin |
    |---|---|
    | `build: ./app` | `build: ./flask` |
    | `depends_on: [db]` | `db` vajab [`healthcheck`](https://docs.docker.com/reference/compose-file/services/#healthcheck)-i (`pg_isready`) ja `web` ootab tingimust `condition: service_healthy` (N6 lisaülesanne 1) |
    | parool failist `.env` | sama: `${POSTGRES_PASSWORD}`, `${POSTGRES_DB}` |

Võti `healthcheck` laseb Compose'il kontrollida, kas andmebaas on päringuteks valmis. Ilma selleta võib `web` käivituda enne, kui andmebaas ühendusi vastu võtab.

Proovi faili oma masinas enne, kui paned selle CI-sse. Võti [`--wait`](https://docs.docker.com/reference/cli/docker/compose/up/) ootab, kuni teenused on olekus `healthy`. Käsu `pg_isready` kirjelduse leiad [PostgreSQL-i image'i lehelt](https://hub.docker.com/_/postgres).

```bash
docker compose up -d --build --wait
curl localhost:5000/db-check
docker compose down -v
```

Käsk `curl` peab vastama `DB OK`. Viimane käsk peatab konteinerid ja kustutab andmebaasi andmeköite.

### 4. Töö `stack`

Lisa failis `ci.yml` võtme `jobs:` alla kolmas töö `stack`. Selle sammud kirjutad ise praktikumi töö `konteiner` eeskujul. Töö peab vastama järgmistele nõuetele:

1. töö käivitub alles pärast tööd `konteiner` (`needs`);
2. üks samm käivitab käsu [`docker compose up -d --build --wait`](https://docs.docker.com/reference/cli/docker/compose/up/);
3. üks samm küsib `curl`-iga aadressi `/db-check` samade võtmetega `-f` ja `--retry` nagu praktikumi osas 6;
4. kui mõni samm kukub, näitab samm `docker compose logs` konteinerite logi (`if: failure()`);
5. viimane samm käivitab **alati** käsu `docker compose down -v` (`if: always()`).

Tingimus `if: always()` tähendab, et samm käivitub ka siis, kui mõni eelmine samm kukkus.

Saada muudatus GitHubi. Töö `stack` peab olema **punane**.

### 5. Leia põhjus

Ava vahekaardil **Actions** töö `stack` logi. Keri sammu `docker compose logs` väljundini. Sealt leiad rea, mida nägid juba N6 praktikumi osas 2.

??? question "Küsimus"
    Sinu masinas töötas sama `compose.yaml`. Mis fail on sinu masinas olemas, aga runneris mitte? Miks seda faili runneris ei ole ja miks on hea, et ei ole?

### 6. Paranda

Runner vajab andmebaasi parooli, aga faili `.env` ei tohi GitHubi panna. Selleks on **GitHubi saladused** (Secrets). Saladus on krüpteeritud muutuja, mida töövoog saab kasutada, aga mida ei ole koodis ja mida GitHub logis ei näita. Miks see oluline on, loe loengu osast [„Konveier hoiab võtmeid“](lecture.md#konveier-hoiab-votmeid) ja GitGuardiani koomiksist [Compromising CI/CD Pipelines](https://blog.gitguardian.com/security-zines-2-compromising-ci-cd-pipelines/).

Lisa saladus repositooriumi seadetes: ava [**Settings → Secrets and variables → Actions → New repository secret**](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) ja pane nimeks `POSTGRES_PASSWORD`. Praktikumi repositooriumis on sul administraatori õigus, seega saad saladuse ise lisada.

**Leia dokumentatsioonist:** leia lehelt [Secrets](https://docs.github.com/en/actions/reference/security/secrets), kas saladus jõuab töövoogu, mis käivitub teisest repositooriumist (*fork*) tehtud pull request'ist.

??? success "Vastus"
    Ei jõua. Kui pull request tuleb fork'ist, ei anta saladusi (välja arvatud `GITHUB_TOKEN`) töövoole edasi. Nii ei saa võõras inimene pull request'iga saladusi välja lugeda.

Anna saladus töövoole töö `stack` tasemel võtmega `env:`. Võti `env:` on töö all sama taandega kui `runs-on`, nii näevad muutujat kõik selle töö sammud. Väärtus on `${{ secrets.POSTGRES_PASSWORD }}`. Loengu [§5](lecture.md#5-toovoo-fail-rida-realt) on selle kohta näide.

Compose loeb muutujaid shelli keskkonnast samamoodi nagu failist `.env`. Kui muutuja on mõlemas, kasutatakse shelli väärtust ([Compose: muutujate järjekord](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/)). Muutuja `POSTGRES_DB` võib kirjutada otse võtme `env:` alla, sest andmebaasi nimi ei ole saladus.

Saada muudatus GitHubi. Kõik kolm tööd peavad olema rohelised.

??? question "Küsimus"
    Lisa ajutiselt samm `run: echo $POSTGRES_PASSWORD`. Mida näed logis? Paljud meeskonnad kirjutavad CI testibaasi parooli otse faili `ci.yml`, näiteks `POSTGRES_PASSWORD: ci-ainult-test`. Millal on see lubatav ja millal mitte? Võrdle N4 Vaulti parooliga.

## Töö esitamine

Tee pull request harust `n07-kodu` harusse `main`. Kirjuta pull request'i kirjeldusse:

- link **punasele** töö `stack` käivitusele sammust 4 ja **rohelisele** käivitusele sammust 6;
- 2–3 lauset: mis rida logis näitas vea põhjust ja mida nägid sammu `echo $POSTGRES_PASSWORD` logis.

Oota, kuni kõik kontrollid on rohelised, ja liida pull request. Autograderi kontroll „BOONUS 8“ näitab tulemust ja lisapunktid paneb õpetaja.

## Enesekontroll enne esitamist

- [ ] `pytest flask -v` läbib sinu masinas.
- [ ] `docker compose up -d --build --wait` ja `curl localhost:5000/db-check` annavad sinu virtuaalmasinas vastuse `DB OK`.
- [ ] Failis `ci.yml` on kolm tööd järjest: `test`, `konteiner` ja `stack`.
- [ ] Pull request'is on kõik kolm tööd rohelised.
- [ ] Faili `.env` ei ole repositooriumis. Käsk `git ls-files | grep .env` ei leia midagi.
- [ ] Töö `stack` viimane samm on `docker compose down -v` ja see käivitub ka punase käivituse järel.
- [ ] Parool on GitHubi saladuses ja failis `ci.yml` seda ei ole.
- [ ] Pull request'i kirjelduses on punase ja rohelise käivituse link ning põhjendus.
