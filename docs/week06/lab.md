---
tags:
  - Docker
  - DockerCompose
  - Praktikum
---

# Praktikum: Docker Compose

**Eeldused:** Loeng antud (teenus, võrk, volume, miks mitu konteinerit). Nädal 5 Flask + `Dockerfile` olemas. Kui midagi on segane, mine [tagasi loengusse](lecture.md). Siit edasi on ainult praktiline töö.

**Keskkond:** sinu AlmaLinuxi VM, kus Docker on nädal 5 Osa 0 järgi paigaldatud. Kood ja käsud VS Code'is. `localhost` = VM, kus Docker töötab.

??? abstract "Õpiväljundid"

    Praktikumi lõpuks sa:

    1. Ehitad kolme-teenuse stacki üks teenus korraga, testides igal sammul
    2. Leiad veateate järgi viie tüüpilise Compose-vea põhjuse (kadunud parool, vale host-nimi, 502, kadunud andmed, `.env`)
    3. Selgitad miks teenused suhtlevad nime, mitte IP järgi
    4. Selgitad miks andmed lähevad volume'i, mitte konteinerisse: ja tõestad seda
    5. Taastad puhta seisu ise tehtud sasi järel

## Osa 1 · Baas: üks teenus

Tee uus kaust ja kopeeri sinna nädal 5 Flaski rakendus (`app.py`, `requirements.txt`, `Dockerfile`) nimega `app`. Käivita, et see ikka töötab:

```bash
mkdir ~/lab06 && cd ~/lab06
cp -r ~/lab05/flask app
docker build -t week06-app ./app
docker run --rm -p 5000:5000 week06-app
```

Teises terminalis `curl localhost:5000` vastab? Peata (`Ctrl+C`). Nüüd sama [Docker Compose'iga](https://docs.docker.com/compose/). Loo `app/` kõrvale `docker-compose.yml`. Ainus kord terve fail: edasi lisad ridu:

```yaml
services:
  web:
    build: ./app
    ports:
      - "5000:5000"
```

```bash
docker compose up -d
docker compose ps
curl localhost:5000
```

Sama vastus, aga nüüd üks käsk. Ära edasi mine enne kui vastab.

??? warning "Kui `build: ./app` ei leia Dockerfile'i"
    Tee on suhteline `docker-compose.yml` asukoha suhtes, mitte terminali kausta suhtes. `docker-compose.yml` peab olema kaustas `~/lab06`, `app/` selle kõrval.

??? warning "Kui saad vea `port is already allocated`"
    Nädal 5 konteiner `flask1` hoiab veel porti 5000. `docker ps` näitab seda, `docker rm -f flask1` vabastab.

## Osa 2 · Andmebaas ilma paroolita

Lisa teine teenus. Näita ainult uut tükki, lisa `web` alla, sama taande tasandile:

```yaml
  db:
    image: postgres:16
```

Käivita ainult db ja vaata logi:

```bash
docker compose up -d db
docker compose logs db
```

Vaata mis juhtub. `db` sureb kohe, logis midagi stiilis `Database is uninitialized and superuser password is not specified`.

??? question "Leia põhjus enne parandamist"
    PostgreSQL image keeldub käivitumast ilma parooli. Miks arvad, et image on teadlikult tehtud niimoodi keelduma, mitte vaikeparooliga käivituma?

**Paranda**: lisa `db`-le keskkonnamuutujad. Image'i muutujad on kirjeldatud [PostgreSQL-i image'i lehel](https://hub.docker.com/_/postgres).

```yaml
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret123
      POSTGRES_DB: appdb
```

```bash
docker compose up -d db
docker compose logs db
```

Otsi logist `database system is ready to accept connections`. Tuleb paari sekundiga.

## Osa 3 · Vale aadress andmebaasile

Flask peab teadma kus db on. Proovime meelega valesti: IP-ga. Lisa `web`-le:

```yaml
    environment:
      DATABASE_URL: postgresql://postgres:secret123@127.0.0.1:5432/appdb
    depends_on:
      - db
```

Flask vajab PostgreSQL-i draiverit. Lisa `app/requirements.txt` lõppu rida:

```
psycopg2-binary
```

Lisa `app/app.py`-sse (importid faili algusesse, route teiste route'ide juurde, `app.run` rea kohale):

??? example "Lisa faili `app/app.py`"

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

Kood muutus, seega image tuleb uuesti ehitada (`--build`):

```bash
docker compose up -d --build
curl localhost:5000/db-check
```

??? warning "Kui logis on `ModuleNotFoundError: psycopg2`"
    Image ehitati enne, kui `requirements.txt` muutus. Ehita uuesti käsuga `docker compose up -d --build`.

**Viga:** `DB viga: ... Connection refused`. `127.0.0.1` konteineri sees tähendab seda sama konteinerit, mitte db-konteinerit. `web`-i sees pole ühtegi andmebaasi, mis pordil 5432 vastaks.

??? question "Leia põhjus"
    Iga konteiner on oma `localhost`. `web` konteineri `127.0.0.1` ei ole `db` konteiner. Compose annab teenustele nime-põhise aadressi. Mis on siis õige host `web`-i jaoks?

**Paranda**: IP asemel teenuse nimi `db`:

```yaml
      DATABASE_URL: postgresql://postgres:secret123@db:5432/appdb
```

```bash
docker compose up -d
curl localhost:5000/db-check
```

Ühendus OK. `db` on DNS-nimi Compose sisevõrgus, mitte miski, mille sa määrasid, vaid mille Compose ise teenuse nimest tegi.

??? warning "Kui `/db-check` annab vea `could not translate host name`"
    Hostinimes `DATABASE_URL`-is on trükiviga. Nimi peab olema täpselt sama mis teenuse nimi `docker-compose.yml`-is (`db`).

## Osa 4 · Laienda: nginx ja 502

Paneme nginx-i Flaski ette (pöördproksi). Loo `nginx/default.conf`: meelega vale pordiga (`8000`, aga Flask kuulab porti `5000`):

```nginx
server {
    listen 80;
    location / {
        proxy_pass http://web:8000;
    }
}
```

Lisa `nginx` teenus:

```yaml
  nginx:
    image: nginx:1.27
    ports:
      - "8080:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - web
```

VM-i port 80 on nädal 3 nginx-i käes, seepärast avame konteineri nginx-i VM-i pordil 8080.

```bash
docker compose up -d
curl localhost:8080
```

502 Bad Gateway.

??? question "Leia põhjus"
    Vaata `docker compose logs nginx`. Seal on `connect() failed (111: Connection refused) while connecting to upstream`. nginx leidis `web`-i üles, aga keegi ei vastanud pordil 8000. 502 tähendab alati: nginx ise töötab, aga see, kelle juurde ta liikluse saadab, ei vasta. Mis port on Flaski `app.run` reas?

??? warning "Kui nginx ei käivitu üldse"
    Kui `docker compose ps` ei näita nginx-i ja logis on `host not found in upstream`, siis on `proxy_pass` reas teenuse nimi, mida compose-failis pole (nt `app` või `flask`). nginx kontrollib nimed käivitudes ja keeldub tööle hakkamast. Nimi `proxy_pass`-is = teenuse nimi compose-failis.

**Paranda**: `default.conf`-is port `8000` → `5000`:

```nginx
        proxy_pass http://web:5000;
```

nginx loeb konfiguratsiooni käivitudes, seega taaskäivita see teenus:

```bash
docker compose restart nginx
curl localhost:8080
```

Vastus tuleb, nüüd läbi pordi 8080 ja nginx-i. Kui saad ikka 502, kontrolli `docker compose logs nginx`: kas muudatus jõudis konteinerisse? Kindel viis on `docker compose up -d --force-recreate nginx`.

Eemalda `web`-lt `ports: 5000:5000` (kogu liiklus käib läbi nginx'i, Flask ei pea otse väljas olema):

```bash
docker compose up -d
curl localhost:8080
```

## Osa 5 · Andmed kaovad

Kirjuta andmebaasi midagi (oma rakenduse route kaudu, või käsitsi):

```bash
docker compose exec db psql -U postgres -d appdb -c "CREATE TABLE test (id int); INSERT INTO test VALUES (1);"
docker compose exec db psql -U postgres -d appdb -c "SELECT * FROM test;"
```

Rida on olemas. Nüüd tee see, mida sa iga päev teed, kustuta stack ja käivita uuesti:

```bash
docker compose down
docker compose up -d
docker compose exec db psql -U postgres -d appdb -c "SELECT * FROM test;"
```

Tabelit pole. Andmed kadusid.

??? question "Leia põhjus"
    `down` kustutas konteinerid. PostgreSQL kirjutas andmed konteineri sisemisse failisüsteemi, mis kadus koos konteineriga. Kus peaksid andmed elama, et konteineri kustutamine neid ei puudutaks?

**Paranda**: lisa `db`-le volume ja faili lõppu `volumes:` sektsioon:

```yaml
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret123
      POSTGRES_DB: appdb
    volumes:
      - pgdata:/var/lib/postgresql/data
```

Faili lõppu (teenustega samal tasandil):

```yaml
volumes:
  pgdata:
```

```bash
docker compose up -d
docker compose exec db psql -U postgres -d appdb -c "CREATE TABLE test (id int); INSERT INTO test VALUES (1);"
docker compose down
docker compose up -d
docker compose exec db psql -U postgres -d appdb -c "SELECT * FROM test;"
```

Rida on alles. Volume elab konteinerist eraldi.

??? question "Mõtle"
    `docker compose down -v` (tähega `v`) kustutab ka volume'i. Millal sa seda tahaksid, ja miks Docker ei tee seda vaikimisi?

## Osa 6 · Parool failis

`secret123` on `docker-compose.yml`-is kahes kohas, tavatekstis. Läheb GitHubi = lekkis. Vii see faili `.env` ([loeng §7](lecture.md#7-paroolid-valja-env)).

Loo `.env` (sama kaust kui compose):

```
POSTGRES_PASSWORD=secret123
POSTGRES_DB=appdb
```

Asenda `db` all parool kõigepealt meelega trükiveaga muutuja nimes (üks `S` puudu):

```yaml
      POSTGRES_PASSWORD: ${POSTGRES_PASWORD}
```

```bash
docker compose config
```

[`docker compose config`](https://docs.docker.com/reference/cli/docker/compose/config/) näitab lõplikku faili, muutujad asendatud. Vaata väljundi algust ja `db` osa.

??? question "Leia põhjus"
    Hoiatus `The "POSTGRES_PASWORD" variable is not set. Defaulting to a blank string.` ja `POSTGRES_PASSWORD: ""`. Compose ei peatu, vaid paneb parooliks tühja teksti. Miks on see ohtlikum kui viga, mis peatab käivituse? Paranda nimi ja asenda ka teised kohad.

**Paranda:**

```yaml
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
```
ja `web` `DATABASE_URL`-is samamoodi `${POSTGRES_PASSWORD}` / `${POSTGRES_DB}`.

```bash
docker compose config
docker compose up -d
curl localhost:8080/db-check
```

??? warning "Kui hoiatus `variable is not set` jääb alles"
    Kontrolli, et muutuja nimi on `.env`-is ja `docker-compose.yml`-is sama ning et `.env` on `docker-compose.yml`-iga samas kaustas.

!!! warning
    Lisa `.env` kohe `.gitignore`-i: `echo ".env" >> .gitignore`. Kui kaust on Giti repo, kontrolli `git status`: `.env` ei tohi olla jälgitavate failide seas.

## Osa 7 · Taasta ja koristus

```bash
docker compose ps
docker compose down
docker compose ps
```

??? question "Mõtle"
    `docker compose stop` vs `down` vs `down -v`: kolm eri taset. Millal kumbagi? (Peatab / kustutab konteinerid / kustutab ka andmed.)

Volume püsib `down` järel, kontrolli:

```bash
docker volume ls
```

`pgdata` on seal. Jäta see alles, sest laboritahvel kontrollib volume'i `pgdata` olemasolu. Käsk `docker compose down -v` kustutaks andmebaasi andmed.

## Esitamine

Automaatkontroll käivitab sinu stacki GitHubis ise. Selleks peavad repos olema need failid:

```text
docker-compose.yml
app/Dockerfile
app/app.py
app/requirements.txt
nginx/default.conf
.gitignore
```

Faili `.env` reposse ei panda. Automaatkontroll loob testimiseks oma `.env`-i ja annab väärtuse igale muutujale, mida `docker-compose.yml` kasutab.

1. Tee töö harus `n06-lab`: `git switch -c n06-lab`.
2. Lisa failid, tee commit ja `git push -u origin n06-lab`.
3. Ava GitHubis pull request `main` vastu ja liida see (**Merge**). Automaatkontroll hindab haru `main`.
4. Vaata tulemust repo vahekaardil **Actions**. Punase testi korral loe selle väljundit, paranda ja push'i uuesti.

Tulemuse näed Classroom 50-s.

??? note "Kontrollnimekiri: kas oskad ilma juhendita?"

    - [ ] Ehitad kolme-teenuse stacki üks teenus korraga
    - [ ] `curl localhost:8080` vastab läbi nginx-i (mitte otse Flaski pordilt)
    - [ ] Selgitad miks host on `db`, mitte `127.0.0.1` ega IP
    - [ ] Eristad: 502 = nginx töötab, aga `web` ei vasta (port); nginx ei käivitu = vale teenuse nimi `proxy_pass`-is
    - [ ] Tõestad et volume säilitab andmed üle `down`/`up`
    - [ ] Parool on `.env`-is (`${NIMI}` süntaks), `.env` on `.gitignore`-is
    - [ ] `docker compose ps` on tühi kui pead selle tühjaks tegema

## Lisaülesanded

??? example "A · Healthcheck"
    Lisa `db`-le `healthcheck` ja muuda `web` teenuse `depends_on` kujule `condition: service_healthy`. Näide on Dockeri juhendis [Control startup order](https://docs.docker.com/compose/how-tos/startup-order/), kõik võtmed [Compose'i failivormingu juhendis](https://docs.docker.com/reference/compose-file/). Millal `depends_on` üksi ei piisa?

??? example "B · Neljas teenus"
    Lisa stacki Redis või pgAdmin (vt [kodutöö](homework.md)): teenus haaval, iga teenust testi eraldi.

??? example "C · Skaleerimine"
    Käivita `docker compose up -d --scale web=3`. Mis läheb katki pordivastendusega (`ports`) ja miks vajaks see nginx-i koormusejaoturit?
