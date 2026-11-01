---
tags:
  - Docker
  - DockerCompose
  - Praktikum
---

# Docker Compose — Labor

**Kestus:** 4 tundi
**Eeldused:** Loeng antud (teenus, võrk, volume, miks mitu konteinerit). Nädal 5 Flask + `Dockerfile` olemas. Kui udu — [tagasi loengusse](lecture.md). Siit edasi **ainult käed külge**.
**Keskkond:** sinu AlmaLinuxi VM, kus Docker on nädal 5 Osa 0 järgi paigaldatud. Kood ja käsud **VS Code'is**. `localhost` = VM, kus Docker jookseb.

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

## Osa 1 · Baas — üks teenus

Tee uus kaust ja kopeeri sinna nädal 5 Flaski rakendus (`app.py`, `requirements.txt`, `Dockerfile`) nimega `app`. Käivita, et see ikka töötab:

```bash
mkdir ~/lab06 && cd ~/lab06
cp -r ~/lab05/flask app
docker build -t week06-app ./app
docker run --rm -p 5000:5000 week06-app
```

Teises terminalis `curl localhost:5000` vastab? Peata (`Ctrl+C`). Nüüd sama Compose'iga. Loo `app/` kõrvale `docker-compose.yml`. **Ainus kord terve fail** — edasi lisad ridu:

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

!!! tip "Kui `build: ./app` ei leia Dockerfile'i"
    Tee on suhteline `docker-compose.yml` asukoha suhtes, mitte terminali kausta suhtes. `docker-compose.yml` peab olema kaustas `~/lab06`, `app/` selle kõrval.

!!! tip "Kui saad vea `port is already allocated`"
    Nädal 5 konteiner `flask1` hoiab veel porti 5000. `docker ps` näitab seda, `docker rm -f flask1` vabastab.

---

## Osa 2 · Andmebaas ilma paroolita

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

## Osa 3 · Vale aadress andmebaasile

Flask peab teadma **kus** db on. Proovime **meelega valesti** — IP-ga. Lisa `web`-le:

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

**Viga:** `DB viga: ... Connection refused`. `127.0.0.1` konteineri sees tähendab **seda sama konteinerit**, mitte db-konteinerit. `web`-i sees pole ühtegi andmebaasi, mis pordil 5432 vastaks.

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

## Osa 4 · Laienda — nginx ja 502

Paneme nginx-i Flaski ette (pöördproksi). Loo `nginx/default.conf` — **meelega vale** pordiga (`8000`, aga Flask kuulab porti `5000`):

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

**502 Bad Gateway.**

??? question "Diagnoosi"
    Vaata `docker compose logs nginx`. Seal on `connect() failed (111: Connection refused) while connecting to upstream`. nginx leidis `web`-i üles, aga keegi ei vastanud pordil 8000. 502 tähendab alati: nginx ise töötab, aga see, kelle juurde ta liikluse saadab, ei vasta. Mis port on Flaski `app.run` reas?

!!! tip "Kui nginx ei käivitu üldse"
    Kui `docker compose ps` ei näita nginx-i ja logis on `host not found in upstream`, siis on `proxy_pass` reas teenuse nimi, mida compose-failis pole (nt `app` või `flask`). nginx kontrollib nimed käivitudes ja keeldub tööle hakkamast. Nimi `proxy_pass`-is = teenuse nimi compose-failis.

**Paranda** — `default.conf`-is port `8000` → `5000`:

```nginx
        proxy_pass http://web:5000;
```

nginx loeb konfiguratsiooni käivitudes, seega taaskäivita see teenus:

```bash
docker compose restart nginx
curl localhost:8080
```

Vastus tuleb — nüüd läbi pordi 8080 ja nginx-i. Kui saad ikka 502, kontrolli `docker compose logs nginx` — kas muudatus jõudis konteinerisse? Kindel viis on `docker compose up -d --force-recreate nginx`.

Eemalda `web`-lt `ports: 5000:5000` (kogu liiklus käib läbi nginx'i, Flask ei pea otse väljas olema):

```bash
docker compose up -d
curl localhost:8080
```

---

## Osa 5 · Andmed kaovad

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

## Osa 6 · Parool failis

`secret123` on `docker-compose.yml`-is kahes kohas, tavatekstis. Läheb GitHubi = lekkis. Vii see faili `.env` ([loeng §7](lecture.md#7-paroolid-valja-env)).

Loo `.env` (sama kaust kui compose):

```
POSTGRES_PASSWORD=secret123
POSTGRES_DB=appdb
```

Asenda `db` all parool kõigepealt **meelega trükiveaga** muutuja nimes (üks `S` puudu):

```yaml
      POSTGRES_PASSWORD: ${POSTGRES_PASWORD}
```

```bash
docker compose config
```

`docker compose config` näitab lõplikku faili, muutujad asendatud. Vaata väljundi algust ja `db` osa.

??? question "Diagnoosi"
    Hoiatus `The "POSTGRES_PASWORD" variable is not set. Defaulting to a blank string.` ja `POSTGRES_PASSWORD: ""`. Compose ei peatu, vaid paneb parooliks tühja teksti. Miks on see ohtlikum kui päris viga? Paranda nimi ja asenda ka teised kohad.

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

!!! warning
    Lisa `.env` **kohe** `.gitignore`-i: `echo ".env" >> .gitignore`. Kui kaust on Giti repo, kontrolli `git status` — `.env` ei tohi olla jälgitavate failide seas.

---

## Osa 7 · Taasta ja koristus

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

`pgdata` on seal. Jäta see alles, sest laboritahvel kontrollib volume'i `pgdata` olemasolu. Käsk `docker compose down -v` kustutaks andmebaasi andmed.

---

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

Hinne tuleb kontrollidest 1–6, kokku 80 punkti, ja 80/80 on täistulemus. Kontroll „BOONUS 7. Kodutöö“ on vabatahtlik ja punkte ei anna.

---

## Lõppkontroll — oskad ilma juhendita

- [ ] Ehitad kolme-teenuse stacki üks teenus korraga
- [ ] `curl localhost:8080` vastab läbi nginx-i (mitte otse Flaski pordilt)
- [ ] Selgitad miks host on `db`, mitte `127.0.0.1` ega IP
- [ ] Eristad: 502 = nginx töötab, aga `web` ei vasta (port); nginx ei käivitu = vale teenuse nimi `proxy_pass`-is
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
| `Connection refused` (`/db-check`) | Host on `127.0.0.1` või IP, mitte teenuse nimi | Host = teenuse nimi (`db`) |
| `could not translate host name` | Teenuse nimes on viga | Nimi `DATABASE_URL`-is = nimi compose'is |
| nginx ei käivitu, `host not found in upstream` | Vale teenuse nimi `proxy_pass`-is | Nimi konfiguratsioonis = nimi compose'is |
| `502 Bad Gateway` | Vale port `proxy_pass`-is või `web` ei tööta | Port = Flaski port (5000), vaata `docker compose ps` |
| Andmed kaovad `down` järel | Volume puudub | Lisa `volumes` |
| `variable is not set. Defaulting to a blank string` | Trükiviga muutuja nimes või `.env` vales kaustas | Nimi `.env`-is = nimi compose'is, `.env` compose-failiga samas kaustas |
| `ModuleNotFoundError: psycopg2` | Image ehitati enne `requirements.txt` muutmist | `docker compose up -d --build` |
| Muudatus ei rakendu | Image/konfiguratsioon vana | Koodi puhul `up -d --build`, nginx-i konfi puhul `restart nginx` |

*Tabel 6.1. Iga rida on viga, mille sa selles labis ise tekitasid ja parandasid.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| Docker Compose | <https://docs.docker.com/compose/> | Kõik võtmesõnad |
| Compose file spec | <https://docs.docker.com/reference/compose-file/> | `depends_on`, `volumes`, `environment` |
| PostgreSQL image | <https://hub.docker.com/_/postgres> | `POSTGRES_PASSWORD` |
| Compose `config` | <https://docs.docker.com/reference/cli/docker/compose/config/> | Muutujate silumiseks |
