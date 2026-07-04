---
tags:
  - Docker
  - DockerCompose
  - Konteinerid
---

# Loeng — Mitme teenuse käitamine koos

**Kestus:** ~35 minutit
**Tase:** Algaste — eeldame et tead Docker build/run käske

---

!!! abstract "Õpiväljundid"
    Pärast loengut oskad:

    - selgitada miks reaalne rakendus vajab mitut konteinerit
    - kirjeldada `docker-compose.yml` struktuuri
    - käivitada ja peatada multi-container stack ühe käsuga
    - eristada mis on teenus, võrk ja maht Compose'is
    - põhjendada miks andmebaasi andmed lähevad volume'i, mitte konteinerisse

---

## 1. Miks mitu konteinerit?

Eelmisel nädalal pakkisime Flask rakenduse ühte image'isse ja käivitasime üksiku konteinerina. Väikeseks demoks sobib, aga päris rakendusel on rohkem osi: Flask vajab andmebaasi (PostgreSQL), ja tihti ka nginx'i ees, mis käsitleb HTTPS-i ja jagab liiklust.

Miks mitte panna kõik — Flask, PostgreSQL, nginx — ühte konteinerisse? Tehniliselt saab, praktikas halb mõte. Kui kõik on ühes: ei saa andmebaasi uuendada rakendust puudutamata, ei saa nginx'i restart'ida Flaski protsessi mõjutamata, ei saa üht komponenti eraldi skaleerida. Iga komponent oma konteineris = vastutus eraldatud.

<figure markdown="span">
```mermaid
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#ede7f6','primaryBorderColor':'#5e35b1','primaryTextColor':'#212121','lineColor':'#7e57c2'}}}%%
graph LR
    U[Klient] -->|port 80| N[nginx]
    N -->|web:5000| W[Flask web]
    W -->|db:5432| D[(PostgreSQL)]
    D -.->|püsib| V[volume pgdata]
```
  <figcaption>Joonis 6.1. Kolm teenust ühes stackis; väljapoole on avatud ainult nginx (Talvik, 2025).</figcaption>
</figure>

---

## 2. docker-compose.yml — struktuur

Mitme konteineri käivitamine ükshaaval `docker run`-iga on tüütu ja veaohtlik — pordid, võrgud, järjekord tuleb iga kord meeles pidada. Compose kogub kogu kirjelduse ühte faili.

```yaml
services:
  flask:
    build: .
    ports:
      - "5000:5000"
    depends_on:
      - postgres
    networks:
      - appnet

  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - appnet

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    depends_on:
      - flask
    networks:
      - appnet

volumes:
  pgdata:

networks:
  appnet:
```

`services` kirjeldab kolme teenust. Flask ehitatakse kohapeal (`build: .`), postgres ja nginx tulevad valmis image'itena. `ports` seob konteineri pordi väljapoole — ainult flask ja nginx vajavad seda, postgres räägib ainult sisevõrgus. `depends_on` määrab käivitusjärjekorra — aga tähelepanu: see ootab ainult et konteiner **käivituks**, mitte et postgres oleks päriselt päringuteks valmis. Selle nüansi lahendab reaalne rakendus retry-loogikaga.

!!! warning
    Compose on YAML. "Lihtne, nad ütlesid." Kaks tundi hiljem otsid, miks `depends_on` ei tööta — ja põhjus on üks tühik vale koha peal. Taane on Compose'is tähendus, mitte iluvõte. Kasuta redaktorit, mis taande näitab.

`volumes` defineerib `pgdata` mahu andmete säilitamiseks. `networks` loob `appnet` sisevõrgu, kus kõik kolm suhtlevad.

---

## 3. Põhikäsklused

```bash
docker compose up -d      # käivita kõik teenused taustal, ehita puuduvad image'id
docker compose ps         # mis teenused töötavad
docker compose logs flask # ühe teenuse logi
docker compose down       # peata ja eemalda kõik konteinerid + võrk
```

`down` on üks käsk kolme asemel (mitte kolm `docker stop` + `docker rm`).

---

## 4. Võrgud

Compose loob teenuste vahele sisevõrgu, kus iga teenus on kättesaadav **oma nime järgi**. Flask koodis pole andmebaasi aadressiks IP, vaid nimi `postgres`:

```
postgresql://user:secret@postgres:5432/mydb
```

`postgres` on DNS-nimi, mille Compose ise sisevõrku lahendab — töötab, sest mõlemad teenused on samas `appnet` võrgus.

Väljastpoolt on nähtav ainult see, mis on `ports` all. Meie näites flaski 5000 ja nginx'i 80. Postgres'il pole `ports` sektsiooni — andmebaas ei ole väljastpoolt üldse ligipääsetav, ainult sama stacki teenused näevad seda. See pole piirang, see on kaitse.

---

## 5. Volumes

Konteiner on ajutine. Kustutad postgres konteineri ja käivitad uue — sisemine failisüsteem on taas puhas, nagu image algselt oli. Kui andmebaasi andmed oleksid konteineri sees, kaoksid nad iga kord.

Volume hoiab andmed konteinerist **väljaspool**, host-masina kettal. Konteiner näeb volume't tavalise kataloogina, aga andmed elavad konteinerist sõltumatult. Kustutad konteineri, käivitad uue sama volume'iga — andmed on alles.

Seepärast on meie failis `pgdata:/var/lib/postgresql/data` — postgres kirjutab sinna, ja volume tagab et see püsib üle konteineri elutsükli.

---

## 6. Miks tööl oluline

Suur makse- või veebiteenus koosneb kümnetest komponentidest — backend, andmebaas, cache, sõnumijärjekord — igaüks eraldi konteinerina. Ükski ei tööta üksi, kõik sõltuvad üksteisest, ja kogu kooslus peab käivituma samamoodi arendaja masinal ja tootmises.

Compose teeb selle korratavaks. Uus meeskonnaliige ei paigalda käsitsi PostgreSQL'i, Redis'it ja kõike muud — üks fail, üks käsk (`docker compose up -d`), ja tal on sama keskkond mis kõigil teistel. Erinevused keskkondade vahel (paroolid, domeenid) tulevad keskkonnamuutujatest, mitte failistruktuuri muutmisest.

---

## Kokkuvõte

- **Iga komponent oma konteineris** — rakendus, andmebaas, proxy eraldi, mitte üks suur konteiner
- **docker-compose.yml kirjeldab kogu stacki ühes failis** — teenused, pordid, sõltuvused, võrgud, volume'id
- **Põhikäsklused:** `up -d`, `down`, `logs`, `ps`
- **Teenused leiavad üksteist nime järgi** — Compose sisevõrgus `postgres` on DNS-nimi, mitte IP
- **Väljapoole on nähtav ainult `ports` all kirjas olev** — andmebaas ilma `ports`-ita jääb sisevõrku
- **Andmebaasi andmed lähevad volume'i, mitte konteinerisse** — konteiner ajutine, volume püsiv

---

## Allikad

| Allikas | URL |
|---|---|
| Docker Compose | <https://docs.docker.com/compose/> |
| Compose file referents | <https://docs.docker.com/reference/compose-file/> |
| Compose Getting Started | <https://docs.docker.com/compose/gettingstarted/> |

**Versioonid (testitud, juuli 2026):** Docker Compose `v2.x`, PostgreSQL `postgres:16`.

---

*Järgmine: Praktikumis paned kokku Flask + PostgreSQL + nginx stacki.*
