---
tags:
  - Docker
  - DockerCompose
  - Praktikum
---

# Docker Compose — käed külge — Labor

**Kestus:** 4 tundi
**Eeldused:** Loeng antud (teenus, võrk, volume, miks mitu konteinerit). Nädal 5 Flask + `Dockerfile` olemas. Kui udu — [tagasi loengusse](lecture.md). Siit edasi **ainult käed külge**.
**Keskkond:** Docker seal kus töötad — kohalik / WSL / server. Kood ja käsud **VS Code'is**. `localhost` = masin kus Docker jookseb.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Ehitad kolme-teenuse stacki üks teenus korraga, testides igal sammul
    2. **Diagnoosid** viis tüüpilist Compose-viga veateate järgi (kadunud parool, vale host-nimi, 502, kadunud andmed, `.env`)
    3. Selgitad miks teenused suhtlevad **nime**, mitte IP järgi
    4. Selgitad miks andmed lähevad volume'i, mitte konteinerisse — ja tõestad seda
    5. Taastad puhta seisu ise tehtud sasi järel

---

Labi loogika: **baas → laienda → viga → paranda → laienda → viga → taasta.** Sa ei kopeeri valmis `docker-compose.yml`-i. Sa ehitad selle teenus haaval, lõhud igal võtmekohal meelega, ja saad aru **miks**. Tervet faili näed **üks kord** — edasi ainult "lisa see teenus" / "lisa need read".

---

## Osa 1 · Baas — üks teenus (25 min)

Mine nädal 5 kausta, kus on `app/` (Flask + `Dockerfile`) ja käivita et ikka töötab:

```bash
docker build -t week06-app ./app
docker run -p 5000:5000 week06-app
```

`localhost:5000` vastab? Peata (`Ctrl+C`). Nüüd sama Compose'iga. Loo `app/` kõrvale `docker-compose.yml`. **Ainus kord terve fail** — edasi lisad ridu:

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

Sama vastus, aga nüüd üks käsk. **Ära edasi mine enne kui vastab.**

!!! tip
    `build: ./app` ei leia Dockerfile'i — tee on suhteline `docker-compose.yml` suhtes, mitte terminali kausta suhtes.

---

## Osa 2 · Andmebaas ilma paroolita (35 min)

Lisa **teine teenus**. Näita ainult uut tükki — lisa `web` alla, sama taande tasandile:

```yaml
  db:
    image: postgres:16
```

Käivita ainult db ja vaata logi:

```bash
docker compose up -d db
docker compose logs db
```

**Vaata mis juhtub.** `db` sureb kohe, logis midagi stiilis `Database is uninitialized and superuser password is not specified`.

??? question "Diagnoosi enne kui parandad"
    PostgreSQL image keeldub käivitumast ilma parooli. Miks arvad, et image on **teadlikult** tehtud niimoodi keelduma, mitte vaikeparooliga käivituma?

**Paranda** — lisa `db`-le keskkonnamuutujad:

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

---

## Osa 3 · Vale aadress andmebaasile (35 min)

Flask peab teadma **kus** db on. Proovime **meelega valesti** — IP-ga. Lisa `web`-le:

```yaml
    environment:
      DATABASE_URL: postgresql://postgres:secret123@127.0.0.1:5432/appdb
    depends_on:
      - db
```

`app.py`-s loe muutuja ja tee test-route (kasuta oma nädal 5 rakendust; kui vaja, lihtne kontroll):

```
@app.route("/db-check")
```
(ühendus `os.environ["DATABASE_URL"]` kaudu — täpne kood on su enda rakenduse asi)

```bash
docker compose up -d
curl localhost:5000/db-check
```

**Viga.** `127.0.0.1` konteineri sees tähendab **seda sama konteinerit**, mitte db-konteinerit.

??? question "Diagnoosi"
    Iga konteiner on oma `localhost`. `web` konteineri `127.0.0.1` ei ole `db` konteiner. Compose annab teenustele **nime**-põhise aadressi. Mis on siis õige host `web`-i jaoks?

**Paranda** — IP asemel teenuse nimi `db`:

```yaml
      DATABASE_URL: postgresql://postgres:secret123@db:5432/appdb
```

```bash
docker compose up -d
curl localhost:5000/db-check
```

Ühendus OK. `db` on DNS-nimi Compose sisevõrgus — mitte miski, mille sa määrasid, vaid mille Compose ise teenuse nimest tegi.

---

## Osa 4 · Laienda — nginx ja 502 (40 min)

Paneme nginx'i Flaski ette (pöördproksi). Loo `nginx/default.conf` — **meelega vale** teenuse nimega (`app`, mitte `web`):

```nginx
server {
    listen 80;
    location / {
        proxy_pass http://app:5000;
    }
}
```

Lisa `nginx` teenus:

```yaml
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - web
```

```bash
docker compose up -d
curl localhost
```

**502 Bad Gateway.**

??? question "Diagnoosi"
    Vaata `docker compose logs nginx`. nginx otsib teenust `app`, aga `docker-compose.yml`-is on ta nimega `web`. nginx ei leia `app`-i sisevõrgust. Kus on kirjaviga — konfiguratsioonis või compose-failis?

**Paranda** — `default.conf`-is `app` → `web`:

```nginx
        proxy_pass http://web:5000;
```

nginx loeb konfiguratsiooni käivitudes, seega taaskäivita see teenus:

```bash
docker compose restart nginx
curl localhost
```

Vastus tuleb — nüüd läbi pordi 80 ja nginx'i. Eemalda `web`-lt `ports: 5000:5000` (kogu liiklus käib läbi nginx'i, Flask ei pea otse väljas olema):

```bash
docker compose up -d
curl localhost
```

---

## Osa 5 · Andmed kaovad (35 min)

Kirjuta andmebaasi midagi (oma rakenduse route kaudu, või käsitsi):

```bash
docker compose exec db psql -U postgres -d appdb -c "CREATE TABLE test (id int); INSERT INTO test VALUES (1);"
docker compose exec db psql -U postgres -d appdb -c "SELECT * FROM test;"
```

Rida on olemas. Nüüd tee see, mida sa iga päev teed — kustuta stack ja käivita uuesti:

```bash
docker compose down
docker compose up -d
docker compose exec db psql -U postgres -d appdb -c "SELECT * FROM test;"
```

**Tabelit pole.** Andmed kadusid.

??? question "Diagnoosi"
    `down` kustutas konteinerid. PostgreSQL kirjutas andmed konteineri **sisemisse** failisüsteemi, mis kadus koos konteineriga. Kus peaksid andmed elama, et konteineri kustutamine neid ei puudutaks?

**Paranda** — lisa `db`-le volume ja faili lõppu `volumes:` sektsioon:

```yaml
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret123
      POSTGRES_DB: appdb
    volumes:
      - pgdata:/var/lib/postgresql/data
```

Faili **lõppu** (teenustega samal tasandil):

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

Rida on **alles**. Volume elab konteinerist eraldi.

??? question "Mõtle"
    `docker compose down -v` (tähega `v`) kustutab **ka** volume'i. Millal sa seda tahaksid, ja miks Docker ei tee seda vaikimisi?

---

## Osa 6 · Parool failis (30 min)

`secret123` on `docker-compose.yml`-is kahes kohas, tavatekstis. Läheb GitHubi = lekkis. (Märteni `.env`, teine fail.) Vii `.env`-i.

Loo `.env` (sama kaust kui compose):

```
POSTGRES_PASSWORD=secret123
POSTGRES_DB=appdb
```

Asenda compose-failis väärtused **meelega vale süntaksiga** kõigepealt (`$NIMI`, ilma sulgudeta):

```yaml
      POSTGRES_PASSWORD: $POSTGRES_PASSWORD
```

```bash
docker compose config
```

`docker compose config` näitab lõplikku faili muutujatega asendatuna. Vaata — asendus ei toimi ootuspäraselt.

??? question "Diagnoosi"
    Compose ootab `${NIMI}` (lokkis sulgudega), mitte `$NIMI`. Paranda kõik kolm kohta.

**Paranda:**

```yaml
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
```
ja `web` `DATABASE_URL`-is samamoodi `${POSTGRES_PASSWORD}` / `${POSTGRES_DB}`.

```bash
docker compose config
docker compose up -d
curl localhost/db-check
```

!!! warning
    Lisa `.env` **kohe** `.gitignore`-i. `echo ".env" >> .gitignore` ja kontrolli `git status` — `.env` ei tohi olla jälgitavate failide seas.

---

## Osa 7 · Taasta ja koristus (15 min)

```bash
docker compose ps
docker compose down
docker compose ps
```

??? question "Mõtle"
    `docker compose stop` vs `down` vs `down -v` — kolm eri taset. Millal kumbagi? (Peatab / kustutab konteinerid / kustutab ka andmed.)

Volume püsib `down` järel — kontrolli:

```bash
docker volume ls
```

`pgdata` on seal. Täielikuks puhastuseks: `docker compose down -v`.

---

## Lõppkontroll — oskad ilma juhendita

- [ ] Ehitad kolme-teenuse stacki üks teenus korraga
- [ ] `curl localhost` vastab läbi nginx'i (mitte otse Flaski pordilt)
- [ ] Selgitad miks host on `db`, mitte `127.0.0.1` ega IP
- [ ] 502 nägemisel tead kohe: teenuse nimi konfiguratsioonis vs compose'is
- [ ] Tõestad et volume säilitab andmed üle `down`/`up`
- [ ] Parool on `.env`-is (`${NIMI}` süntaks), `.env` on `.gitignore`-is
- [ ] `docker compose ps` on tühi kui pead selle tühjaks tegema

---

## Lisaülesanded (kui jõuad ette)

1. **Healthcheck:** lisa `db`-le `healthcheck`, muuda `web depends_on` → `condition: service_healthy`. Millal `depends_on` üksi ei piisa?
2. **Neljas teenus:** Redis või pgAdmin stacki (vt kodutöö) — teenus haaval, testi eraldi.
3. **Skaleerimine:** `docker compose up -d --scale web=3`. Mis läheb katki port-mapping'uga, ja miks vajaks see nginx load-balancer'it?

---

## Veaotsing

| Veateade | Põhjus | Lahendus |
|---|---|---|
| `db` sureb (`Exit 1`) | `POSTGRES_PASSWORD` puudub | Lisa `environment` |
| `could not translate host name` | Kasutad IP/`127.0.0.1`, mitte teenuse nime | Host = teenuse nimi (`db`) |
| `502 Bad Gateway` | Vale teenuse nimi `proxy_pass`-is | Nimi konfiguratsioonis = nimi compose'is |
| Andmed kaovad `down` järel | Volume puudub | Lisa `volumes` |
| `${NIMI}` ei asendu | `.env` puudub, või `$NIMI` ilma sulgudeta | `${NIMI}` + `.env` samas kaustas |
| Muudatus ei rakendu | Image/konfiguratsioon vana | `docker compose up -d --build`, konfi puhul `restart` |

*Tabel 6.1. Iga rida on viga, mille sa selles labis ise tekitasid ja parandasid.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| Docker Compose | <https://docs.docker.com/compose/> | Kõik võtmesõnad |
| Compose file spec | <https://docs.docker.com/reference/compose-file/> | `depends_on`, `volumes`, `environment` |
| PostgreSQL image | <https://hub.docker.com/_/postgres> | `POSTGRES_PASSWORD` |
| Compose `config` | <https://docs.docker.com/reference/cli/docker/compose/config/> | Muutujate silumiseks |
