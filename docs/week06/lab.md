---
tags:
  - Docker
  - DockerCompose
  - Praktikum
---

# Praktikum: Docker Compose

Täna paned kokku kolme teenusega stacki (Flask, PostgreSQL ja nginx) ühe teenuse kaupa. Töö käib sinu AlmaLinuxi VM-is, kuhu paigaldasid Dockeri [N5 praktikumi osas 0](../week05/lab.md#osa-0-dockeri-paigaldamine-virtuaalmasinasse); `localhost` tähendab seda VM-i.

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

??? abstract "Õpiväljundid"

    Praktikumi lõpuks sa:

    1. Ehitad kolme teenusega stacki ühe teenuse kaupa ja testid igal sammul
    2. Leiad veateate järgi viie tüüpilise Compose'i vea põhjuse (puuduv parool, vale hostinimi, 502, kadunud andmed, `.env`)
    3. Selgitad, miks teenused suhtlevad nime järgi ja IP-aadressi ei kasutata
    4. Selgitad, miks andmed lähevad volume'i, ja näitad seda katsega
    5. Taastad pärast vigu puhta oleku

Rida **Ennusta** tähendab, et enne käsku mõtled läbi, mis juhtub. Vastus on kokkuvolditud plokis.

## Osa 1 · Üks teenus

Tee uus kaust ja kopeeri sinna N5 Flaski rakendus (`app.py`, `requirements.txt`, `Dockerfile`) nimega `app`. Kui sul N5 kausta pole, on failid [N5 praktikumi osas 10](../week05/lab.md#osa-10-tegelik-rakendus-flask-konteinerisse). Kontrolli, et rakendus töötab:

```bash
mkdir ~/lab06 && cd ~/lab06
cp -r ~/lab05/flask app
docker build -t week06-app ./app
docker run --rm -p 5000:5000 week06-app
```

Teises terminalis peab `curl localhost:5000` vastama. Seejärel peata konteiner (`Ctrl+C`) ja käivita sama [Docker Compose'iga](https://docs.docker.com/compose/). Loo `app/` kõrvale fail `docker-compose.yml`, millele edaspidi lisad ridu:

```yaml
services:
  web:
    build: ./app
    ports:
      - "5000:5000"
```

Käivita teenus:

```bash
docker compose up -d
docker compose ps
curl localhost:5000
```

Vastus on sama, aga nüüd piisab ühest käsust. Kui `curl` ei vasta, paranda see enne edasiminekut.

??? warning "Kui `build: ./app` ei leia Dockerfile'i"
    Tee arvestatakse `docker-compose.yml` asukohast. `docker-compose.yml` peab olema kaustas `~/lab06` ja `app/` selle kõrval.

??? warning "Kui saad vea `port is already allocated`"
    N5 konteiner `flask1` kasutab veel porti 5000. `docker ps` näitab seda ja `docker rm -f flask1` vabastab pordi.

## Osa 2 · Andmebaas ilma paroolita

Lisa teine teenus `web` alla, samale taandele:

```yaml
  db:
    image: postgres:16
```

**Ennusta:** kas `db` käivitub?

Käivita ainult `db` ja vaata logi:

```bash
docker compose up -d db
docker compose logs db
```

??? success "Oodatav tulemus"
    `db` lõpetab kohe töö ja logis on teade `Database is uninitialized and superuser password is not specified`.

??? question "Leia põhjus enne parandamist"
    PostgreSQL-i image ei käivitu ilma paroolita. Miks on image tehtud nii, et vaikeparooliga see ei käivitu?

Paranda: lisa `db`-le keskkonnamuutujad. Image'i muutujad on kirjeldatud [PostgreSQL-i image'i lehel](https://hub.docker.com/_/postgres).

```yaml
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret123
      POSTGRES_DB: appdb
```

Käivita uuesti:

```bash
docker compose up -d db
docker compose logs db
```

Paari sekundi pärast on logis rida `database system is ready to accept connections`.

## Osa 3 · Vale aadress andmebaasile

Flask peab teadma, kus andmebaas on. Proovi meelega valesti, aadressiga `127.0.0.1`. Lisa `web`-le:

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

Lisa `app/app.py`-sse andmebaasi kontroll (importid faili algusesse, route teiste route'ide juurde enne rida `app.run`):

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

`curl` näitab viga `DB viga: ... Connection refused`.

??? question "Leia põhjus"
    Igal konteineril on oma `localhost`. `127.0.0.1` tähendab `web`-i sees sama konteinerit ja seal pole andmebaasi, mis pordil 5432 vastaks. Compose annab teenustele nimepõhise aadressi. Mis on siis õige host `web`-i jaoks?

Paranda: kasuta aadressi asemel teenuse nime `db`:

```yaml
      DATABASE_URL: postgresql://postgres:secret123@db:5432/appdb
```

Rakenda muudatus ja kontrolli:

```bash
docker compose up -d
curl localhost:5000/db-check
```

`curl` näitab `DB OK`. `db` on DNS-nimi, mille Compose tegi sisevõrgus teenuse nimest.

??? warning "Kui `/db-check` annab vea `could not translate host name`"
    Hostinimes `DATABASE_URL`-is on trükiviga. Nimi peab olema täpselt sama mis teenuse nimi `docker-compose.yml`-is (`db`).

## Osa 4 · nginx ja viga 502

Pane nginx Flaski ette pöördproksiks. Loo fail `nginx/default.conf`, meelega vale pordiga (`8000`, aga Flask kuulab porti `5000`):

```nginx
server {
    listen 80;
    location / {
        proxy_pass http://web:8000;
    }
}
```

Lisa teenus `nginx`:

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

Konteineri nginx on VM-i pordil 8080, sest VM-i port 80 võib olla juba kasutusel.

**Ennusta:** mida `curl` näitab?

```bash
docker compose up -d
curl localhost:8080
```

??? success "Oodatav tulemus"
    `502 Bad Gateway`.

??? question "Leia põhjus"
    Vaata `docker compose logs nginx`. Seal on `connect() failed (111: Connection refused) while connecting to upstream`. nginx leidis `web`-i üles, aga pordil 8000 ei vastanud keegi. Viga 502 tähendab, et nginx ise töötab, aga teenus, kuhu see liikluse saadab, ei vasta. Mis port on Flaski `app.run` reas?

??? warning "Kui nginx ei käivitu üldse"
    Kui `docker compose ps` ei näita nginx-i ja logis on `host not found in upstream`, on `proxy_pass` reas teenuse nimi, mida Compose'i failis pole (näiteks `app` või `flask`). nginx kontrollib nimed käivitumisel ja vale nime korral ei käivitu. Nimi `proxy_pass` reas peab olema sama mis teenuse nimi Compose'i failis.

Paranda: muuda `default.conf`-is port `8000` pordiks `5000`:

```nginx
        proxy_pass http://web:5000;
```

nginx loeb konfiguratsiooni käivitumisel, seega taaskäivita see teenus:

```bash
docker compose restart nginx
curl localhost:8080
```

Nüüd tuleb vastus pordilt 8080 nginx-i kaudu. Kui saad ikka vea 502, vaata `docker compose logs nginx`, kas muudatus jõudis konteinerisse. Kindel viis on `docker compose up -d --force-recreate nginx`.

Eemalda `web`-lt `ports: 5000:5000`, sest kogu liiklus käib nginx-i kaudu ja Flaski pole vaja otse väljapoole avada:

```bash
docker compose up -d
curl localhost:8080
```

## Osa 5 · Andmed kaovad

Kirjuta andmebaasi tabel ja üks rida:

```bash
docker compose exec db psql -U postgres -d appdb -c "CREATE TABLE test (id int); INSERT INTO test VALUES (1);"
docker compose exec db psql -U postgres -d appdb -c "SELECT * FROM test;"
```

Rida on olemas. Nüüd kustuta stack ja käivita see uuesti, nagu tööl tihti tehakse.

**Ennusta:** kas rida on pärast seda alles?

```bash
docker compose down
docker compose up -d
docker compose exec db psql -U postgres -d appdb -c "SELECT * FROM test;"
```

??? success "Oodatav tulemus"
    Tabelit pole, andmed kadusid.

??? question "Leia põhjus"
    `down` kustutas konteinerid. PostgreSQL kirjutas andmed konteineri sisemisse failisüsteemi, mis kadus koos konteineriga. Kus peaksid andmed olema, et konteineri kustutamine neid ei kustutaks?

Paranda: lisa `db`-le volume ja faili lõppu `volumes:` sektsioon:

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

Korda katset:

```bash
docker compose up -d
docker compose exec db psql -U postgres -d appdb -c "CREATE TABLE test (id int); INSERT INTO test VALUES (1);"
docker compose down
docker compose up -d
docker compose exec db psql -U postgres -d appdb -c "SELECT * FROM test;"
```

Rida on alles, sest volume on konteinerist eraldi.

??? question "Mõtle"
    `docker compose down -v` (tähega `v`) kustutab ka volume'i. Millal seda vaja on ja miks Docker seda vaikimisi ei tee?

## Osa 6 · Parool failis

`secret123` on `docker-compose.yml`-is kahes kohas selge tekstina. Kui fail jõuab GitHubi, on parool lekkinud. Vii see faili `.env` ([loengu osa 7](lecture.md#7-paroolid-valja-env)).

Loo fail `.env` samasse kausta, kus on `docker-compose.yml`:

```
POSTGRES_PASSWORD=secret123
POSTGRES_DB=appdb
```

Asenda `db` all parool kõigepealt meelega trükiveaga muutuja nimes (üks `S` puudu):

```yaml
      POSTGRES_PASSWORD: ${POSTGRES_PASWORD}
```

[`docker compose config`](https://docs.docker.com/reference/cli/docker/compose/config/) näitab lõplikku faili, kus muutujad on asendatud. Vaata väljundi algust ja `db` osa:

```bash
docker compose config
```

??? question "Leia põhjus"
    Väljundis on hoiatus `The "POSTGRES_PASWORD" variable is not set. Defaulting to a blank string.` ja rida `POSTGRES_PASSWORD: ""`. Compose ei peatu ja paneb parooliks tühja teksti. Miks on see ohtlikum kui viga, mis peatab käivituse? Paranda nimi ja asenda ka teised kohad.

Paranda muutujate nimed `db` all:

```yaml
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
```

Kasuta `web` teenuse `DATABASE_URL`-is samamoodi muutujaid `${POSTGRES_PASSWORD}` ja `${POSTGRES_DB}`. Kontrolli ja käivita:

```bash
docker compose config
docker compose up -d
curl localhost:8080/db-check
```

??? warning "Kui hoiatus `variable is not set` jääb alles"
    Kontrolli, et muutuja nimi on `.env`-is ja `docker-compose.yml`-is sama ning et `.env` on `docker-compose.yml`-iga samas kaustas.

!!! warning
    Lisa `.env` kohe `.gitignore`-i: `echo ".env" >> .gitignore`. Kui kaust on Giti repositoorium, kontrolli `git status` väljundit: `.env` ei tohi olla jälgitavate failide seas.

## Osa 7 · Koristamine

Peata ja eemalda stack:

```bash
docker compose ps
docker compose down
docker compose ps
```

??? question "Mõtle"
    `docker compose stop` peatab konteinerid, `down` kustutab konteinerid ja `down -v` kustutab ka andmed. Millal kasutad igaüht neist?

Volume jääb pärast `down` käsku alles. Kontrolli:

```bash
docker volume ls
```

`pgdata` on seal. Jäta see alles, sest laboritahvel kontrollib volume'i `pgdata` olemasolu. Käsk `docker compose down -v` kustutaks andmebaasi andmed.

??? note "Kontrollnimekiri"

    - [ ] Ehitad kolme teenusega stacki ühe teenuse kaupa
    - [ ] `curl localhost:8080` vastab nginx-i kaudu
    - [ ] Selgitad, miks host on `db` ja miks `127.0.0.1` või IP-aadress ei sobi
    - [ ] Eristad vigu: 502 tähendab, et nginx töötab, aga `web` ei vasta (port); kui nginx ei käivitu, on `proxy_pass` reas vale teenuse nimi
    - [ ] Näitad katsega, et volume hoiab andmed alles pärast `down` ja `up` käsku
    - [ ] Parool on `.env`-is (`${NIMI}` süntaks), `.env` on `.gitignore`-is
    - [ ] Oskad teha `docker compose ps` väljundi tühjaks

## Töö esitamine

Töö on harus `n06-lab`: tee haru, saada see GitHubi ja liida pull request harusse `main`.

```bash
git switch -c n06-lab
git add docker-compose.yml app nginx .gitignore && git commit -m "N6 Compose stack" && git push -u origin n06-lab
```

Faili `.env` repositooriumi ei panda. Tulemuse näed Classroom 50-s.

## Lisaülesanded

??? example "A · Healthcheck"
    Lisa `db`-le `healthcheck` ja muuda `web` teenuse `depends_on` kujule `condition: service_healthy`. Näide on Dockeri juhendis [Control startup order](https://docs.docker.com/compose/how-tos/startup-order/), kõik võtmed [Compose'i failivormingu juhendis](https://docs.docker.com/reference/compose-file/). Millal `depends_on` üksi ei piisa?

??? example "B · Neljas teenus"
    Lisa stacki Redis või pgAdmin (vt [kodutöö](homework.md)): teenus haaval, iga teenust testi eraldi.

??? example "C · Skaleerimine"
    Käivita `docker compose up -d --scale web=3`. Mis läheb katki pordivastendusega (`ports`) ja miks vajaks see nginx-i koormusejaoturit?
