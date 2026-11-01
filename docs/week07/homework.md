---
tags:
  - CI
  - GitHubActions
  - DockerCompose
  - Kodutöö
---

# Kodutöö: CI testib rakendust koos andmebaasiga

Praktikumis kontrollis CI üht konteinerit. Rakendus vajab aga ka andmebaasi. Flask ja andmebaas võivad mõlemad töötada, aga Flask ei pruugi andmebaasiga ühendust saada, näiteks vale hostinime või puuduva parooli tõttu. Selliseid ühendusvigu ei leia praktikumi ühiktest ega üksiku konteineri suitsutest.

Selles kodutöös lisad praktikumi töövoogu kolmanda töö `stack`. See käivitab Compose'iga Flaski koos PostgreSQL-iga ja kontrollib, et aadress `/db-check` vastab `DB OK`. Kodutöö on boonusülesanne.

<figure markdown="span">
  ![Kolm tööd järjest: test, konteiner ja stack. Töö stack käivitab Compose'iga konteinerid web ja db ning curl küsib aadressi /db-check. Esimene katse on punane, sest db lõpetab töö ilma paroolita. Parool tuleb GitHubi saladusest](../images/n07_kodutoo_stack.svg)
  <figcaption>Joonis 7.8. Kolmas töö kontrollib, kas teenused töötavad koos. Esimene katse on meelega punane (Talvik, 2026).</figcaption>
</figure>

## Osa 1 · Haru

Kodutöö teed eraldi harus, et muudatused oleksid praktikumi lahendusest eraldi ja neid saaks enne harusse `main` liitmist üle vaadata. Tee uus haru `n07-kodu` haru `n07-ci` viimase commit'i põhjal:

```bash
git switch n07-ci && git pull
git switch -c n07-kodu
```

## Osa 2 · Rakendus küsib andmebaasilt

Töö `stack` kontrollib aadressi `/db-check`, seega peab see aadress olema rakenduses olemas. Sama kood oli [N6 praktikumis](../week06/lab.md#osa-3-vale-aadress-andmebaasile). Lisa see faili `flask/app.py`: impordilaused faili algusesse ja uus route teiste route'ide juurde. Funktsioon loeb andmebaasi ühendusstringi keskkonnamuutujast `DATABASE_URL`.

??? example "Lisa faili `flask/app.py`"

    ```python
    import os
    import psycopg2

    @app.route("/db-check")
    def db_check():
        try:
            conn = psycopg2.connect(os.environ["DATABASE_URL"], connect_timeout=3)
            conn.close()
            return "DB OK\n"
        except Exception as e:
            return f"DB viga: {e}\n", 500
    ```

Lisa faili `flask/requirements.txt` rida `psycopg2-binary`, sest rakendus kasutab seda teeki PostgreSQL-iga ühendumiseks.

Kontrolli oma masinas, et praktikumi testid töötavad edasi:

```bash
source .venv/bin/activate
pip install -r flask/requirements.txt
pytest flask -v
```

Väljundi lõpus peab olema `3 passed`.

??? question "Kas uus aadress vajab ka testi?"
    Aadress `/db-check` vajab töötavat andmebaasi. Seepärast ei saa seda testida testkliendiga `test_client()` ilma andmebaasita. Seda kontrollib töö `stack`. Mõtle, mis vahe on testil, mis vajab ainult koodi, ja testil, mis vajab kogu rakendust koos andmebaasiga.

## Osa 3 · Fail `compose.yaml`

Compose'i fail kirjeldab, millised konteinerid koos käivitatakse. Kirjuta repositooriumi juurkausta fail `compose.yaml` [N6 praktikumi](../week06/lab.md) põhjal. Vaja on ainult kaht teenust: `web` ja `db`. Nginx'i pole siin vaja. Teenusel `web` peab olema keskkonnamuutuja `DATABASE_URL`, mis viitab hostinimele `db`.

??? note "Tabel 7.11. Erinevused võrreldes N6 praktikumi failiga"
    | N6 praktikumis | Siin |
    |---|---|
    | `build: ./app` | `build: ./flask` |
    | `depends_on: [db]` | `db` vajab [`healthcheck`](https://docs.docker.com/reference/compose-file/services/#healthcheck)-i (`pg_isready`) ja `web` ootab tingimust `condition: service_healthy` |
    | parool failist `.env` | samuti failist `.env`: `${POSTGRES_PASSWORD}` ja `${POSTGRES_DB}` |

Võti `healthcheck` laseb Compose'il kontrollida, kas andmebaas on päringuteks valmis. Ilma selleta võib `web` käivituda enne, kui andmebaas ühendusi vastu võtab.

Proovi faili oma masinas enne, kui paned selle CI-sse. Loo repositooriumi juurkausta fail `.env` muutujatega `POSTGRES_PASSWORD` ja `POSTGRES_DB` ning lisa see faili `.gitignore`, et parool repositooriumi ei satuks:

```bash
printf 'POSTGRES_PASSWORD=kohalik-test\nPOSTGRES_DB=app\n' > .env
echo ".env" >> .gitignore
```

Võti [`--wait`](https://docs.docker.com/reference/cli/docker/compose/up/) ootab, kuni teenused töötavad. Kui teenusel on `healthcheck`, ootab Compose ka olekut `healthy`. Käsu `pg_isready` kirjelduse leiad [PostgreSQL-i image'i lehelt](https://hub.docker.com/_/postgres).

```bash
docker compose up -d --build --wait
curl localhost:5000/db-check
docker compose down -v
```

Käsk `curl` peab vastama `DB OK`. Viimane käsk peatab konteinerid ja kustutab andmebaasi andmeköite.

## Osa 4 · Töö `stack`

Lisa failis `ci.yml` võtme `jobs:` alla kolmas töö `stack`. Selle sammud kirjutad ise praktikumi töö `konteiner` eeskujul. Töö peab vastama järgmistele nõuetele:

1. töö käivitub alles pärast tööd `konteiner` (`needs`) ja toob esimese sammuna repositooriumi failid runnerisse (`actions/checkout`);
2. üks samm käivitab käsu [`docker compose up -d --build --wait`](https://docs.docker.com/reference/cli/docker/compose/up/);
3. üks samm saadab käsuga `curl` päringu aadressile `/db-check` samade veakäsitluse ja korduskatsete võtmetega nagu praktikumi osas 6;
4. kui mõni eelmine samm ebaõnnestub, näitab samm `docker compose logs` konteinerite logisid (`if: failure()`);
5. viimane samm käivitab alati käsu `docker compose down -v` (`if: always()`).

Tingimus `if: always()` tähendab, et samm käivitub ka siis, kui mõni eelmine samm kukkus.

Saada muudatus GitHubi. Töö `stack` peab olema punane.

## Osa 5 · Leia põhjus

Ava vahekaardil **Actions** töö `stack` logid ja keri sammu `docker compose logs` väljundini. Sealt leiad rea, mis näitab, miks andmebaas ei käivitunud.

??? question "Küsimus"
    Sinu masinas töötas sama `compose.yaml`. Mis fail on sinu masinas olemas, aga runneris mitte? Miks seda faili runneris ei ole ja miks on hea, et ei ole?

## Osa 6 · Paranda

Runner vajab andmebaasi parooli, aga faili `.env` ei tohi GitHubi panna. Selleks on **GitHubi saladused** (Secrets). Saladus on krüpteeritud väärtus, mille GitHub annab töövoole ilma, et see oleks koodis. Logis asendab GitHub saladuse väärtuse märkidega `***`, aga saladust ei tohi ka meelega logisse väljastada. Saladuste kaitsmise kohta loe loengu osast [„Konveier hoiab võtmeid“](lecture.md#konveier-hoiab-votmeid) ja GitGuardiani koomiksist [Compromising CI/CD Pipelines](https://blog.gitguardian.com/security-zines-2-compromising-ci-cd-pipelines/).

Lisa saladus repositooriumi seadetes: ava [**Settings → Secrets and variables → Actions → New repository secret**](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) ja pane nimeks `POSTGRES_PASSWORD`. Praktikumi repositooriumis on sul administraatori õigused, seega saad saladuse ise lisada.

**Leia dokumentatsioonist:** leia lehelt [Secrets](https://docs.github.com/en/actions/reference/security/secrets), kas saladus jõuab töövoogu, mis käivitub teisest repositooriumist (*fork*) tehtud pull request'ist.

??? success "Vastus"
    Ei jõua. Kui pull request tuleb fork'ist, ei anta saladusi (välja arvatud `GITHUB_TOKEN`) töövoole edasi. Nii ei saa võõras inimene pull request'iga saladusi välja lugeda.

Anna saladus töövoole töö `stack` tasemel võtmega `env:`. Võti `env:` on töö all sama taandega kui `runs-on`, nii saavad muutujat kasutada kõik selle töö sammud. Väärtus on `${{ secrets.POSTGRES_PASSWORD }}`. Loengu [5. osas](lecture.md#5-toovoofail-rida-realt) on selle kohta näide.

Compose loeb muutujaid shelli keskkonnast samamoodi nagu failist `.env`. Kui muutuja on mõlemas, kasutatakse shelli väärtust ([Compose: muutujate järjekord](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/)). Muutuja `POSTGRES_DB` võib kirjutada otse võtme `env:` alla, sest andmebaasi nimi ei ole saladus.

Saada muudatus GitHubi. Kõik kolm tööd peavad olema rohelised.

??? question "Küsimus"
    Lisa ajutiselt samm `run: echo $POSTGRES_PASSWORD`. Kasuta selles katses ainult CI testandmebaasi parooli. Mida näed logis? Pärast katset eemalda see samm. Paljud meeskonnad kirjutavad CI testibaasi parooli otse faili `ci.yml`, näiteks `POSTGRES_PASSWORD: ci-ainult-test`. Millal on see lubatav ja millal mitte? Võrdle Vaultis hoitud parooliga.

??? note "Kontrollnimekiri"
    - [ ] `pytest flask -v` õnnestub sinu masinas ja väljundi lõpus on `3 passed`.
    - [ ] `docker compose up -d --build --wait` ja `curl localhost:5000/db-check` annavad sinu virtuaalmasinas vastuse `DB OK`.
    - [ ] Failis `ci.yml` on kolm tööd järjest: `test`, `konteiner` ja `stack`.
    - [ ] Pull request'is on kõik kolm tööd rohelised.
    - [ ] Faili `.env` ei ole repositooriumis. Käsk `git ls-files | grep .env` ei leia midagi.
    - [ ] Töö `stack` viimane samm on `docker compose down -v` ja see käivitub ka punase käivituse järel.
    - [ ] Parool on GitHubi saladuses. Failis `ci.yml` on ainult viide `${{ secrets.POSTGRES_PASSWORD }}`, mitte parooli väärtus.

## Töö esitamine

Tee pull request harust `n07-kodu` harusse `main`. Lisa kirjeldusse link käivitusele, kus töö `stack` ebaõnnestus (osa 4), ja link käivitusele, kus see õnnestus (osa 6). Kirjuta 2–3 lauset: milline logirida näitas vea põhjust ja mida nägid ajutise sammu `echo $POSTGRES_PASSWORD` väljundis. Eemalda ajutine samm enne esitamist. Kui kõik kontrollid on rohelised, liida pull request.

Tulemuse näed Classroom 50-s.
