---
tags:
  - Docker
  - Flask
  - Kodutöö
---

# Kodutöö — Flask rakenduse konteineriseerimine

**Eeldused:** nädala 5 lab (Dockerfile, build, run, `COPY`).
**Esitamine:** GitHub Pull Request.

---

## Ülesanne

Õpetaja antud `app.py` (lihtne Flask rakendus) tuleb pakkida Docker konteinerisse ja käivitada pordil 5000.

Lae `app.py` õpetaja lingilt/repost oma töökausta, nt `w05-homework/app.py`. Docker jookseb seal, kus sul on (kohalik / WSL / server) — sama koht mis labis.

## Sammud

1. **Loo Dockerfile** samas kaustas kui `app.py`. Vajad: Python baas-image (`FROM python:3.12-slim`), faili kopeerimist (`COPY`), Flaski paigaldust (`RUN pip install flask`), käivituskäsku (`CMD`).

    !!! tip
        Meenuta labist: `COPY` kopeerib build-kontekstist image'isse, `RUN` jookseb ehitamise ajal, `CMD` iga kord konteineri käivitudes.

2. **Ehita image:**

    ```bash
    docker build -t flask-app .
    ```

3. **Käivita konteiner** (masina port 5000 → konteineri port 5000):

    ```bash
    docker run -d -p 5000:5000 --name flask-app-container flask-app
    ```

4. **Kontrolli:**

    ```bash
    curl localhost:5000
    ```

!!! warning
    `curl localhost:5000` ei vasta? Vaata `docker logs flask-app-container`. Sage põhjus: Flask kuulab vaikimisi ainult `127.0.0.1` peal konteineri **sees**, mis pole väljastpoolt ligipääsetav. Rakendus peab kuulama `0.0.0.0` peal (`app.run(host="0.0.0.0", port=5000)`), et port-mapping töötaks. Kui `app.py` seda ei tee, tuleb see muudatus teha.

??? question "Mõtle"
    Miks peab Flask kuulama `0.0.0.0`, mitte `127.0.0.1`, et see konteineris töötaks? Seosta vastus sellega, mida `-p 5000:5000` tegelikult teeb.

## Esitamine

1. Uus haru, nt `w05-flask-docker`.
2. Lisa harusse **ainult** `Dockerfile` (mitte `app.py`, kui õpetaja pole öelnud teisiti).
3. Ekraanipilt, kus on näha töötav rakendus **ja** `docker ps` väljund (konteiner `Up`).
4. Lisa screenshot reposse samas PR-is.
5. Ava **Pull Request** `main` vastu. Kirjelda lühidalt: mis baas-image, kas pidid `app.py`-d muutma (ja miks).

## Enesekontroll

- [ ] `docker build` läbib veata
- [ ] `docker run` — konteiner jääb tööle (`docker ps` näitab `Up`, mitte `Exited`)
- [ ] `curl localhost:5000` tagastab rakenduse vastuse
- [ ] Dockerfile + screenshot samas PR-is
- [ ] PR kirjeldus selgitab valikuid

## Veaotsing

| Probleem | Lahendus |
|---|---|
| Konteiner käivitub ja sureb (`Exited`) | `docker logs <konteiner>` — tavaliselt Pythoni viga või `pip install flask` unustatud |
| `curl` ei vasta, konteiner töötab | Flask vajab `0.0.0.0` (mitte `127.0.0.1`); kontrolli ka `-p 5000:5000` |
| `port is already allocated` | Mõni teine konteiner (nt labist `web1`) kasutab porti. `docker ps -a` + koristus |
