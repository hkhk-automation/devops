---
tags:
  - Docker
  - DockerCompose
  - Kodutöö
---

# Kodutöö: neljas teenus stacki

**Eeldused:** praktikum on tehtud ja sul on töötav `docker-compose.yml` kolme teenusega (`web`, `db`, `nginx`).

## Ülesanne

Lisa oma stacki neljas teenus. Vali üks kahest:

- **Redis:** vahemälu (cache) Flaskile ([Redise image](https://hub.docker.com/_/redis));
- **pgAdmin:** veebiliides PostgreSQL-i haldamiseks ([pgAdmini image](https://hub.docker.com/r/dpage/pgadmin4)).

Kui sa ei tea, kumba valida, vali pgAdmin. Selle tulemust näed kohe brauseris: ühendud andmebaasiga ja näed tabeleid.

### Nõuded

1. Uus teenus läheb olemasolevasse faili `docker-compose.yml`, eraldi projekti ei tehta.
2. Lisa teenus samamoodi nagu praktikumis: kõigepealt testi seda eraldi (`docker compose up -d <teenus>`), alles siis mine edasi.
3. **Redis:** Flask peab Redist kasutama, näiteks loeb ja kirjutab ühe võtme mõne route'i kaudu. Konteiner, mida rakendus ei kasuta, ei ole tehtud töö.
4. **pgAdmin:** ava see brauseris ja loo ühendus teenusega `db`. Hostiks on teenuse nimi, mitte IP-aadress (nagu praktikumis).
5. Paroolid ja võtmed (näiteks pgAdmini sisselogimine) käivad faili `.env` kaudu, mitte otse `docker-compose.yml`-i. Automaatkontroll annab testimisel igale `.env` muutujale oma väärtuse, nii et ka uue teenuse parool võib olla `.env`-is.

### Esitamine

Kodutöö läheb samasse repositooriumisse nagu praktikum.

1. Jätka harus `n06-lab` või tee uus haru: `git switch -c n06-kodutoo`.
2. Käivita kogu stack ja kontrolli, et kõik neli teenust töötavad:

    ```bash
    docker compose up -d
    docker compose ps
    ```

3. Tee commit muudetud failidest (`docker-compose.yml`, `app/`, konfiguratsioonifailid). Faili `.env` ei lisata.
4. Ava pull request `main` vastu ([GitHubi juhend](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)). Kirjelda selles:
    - millise teenuse valisid ja miks;
    - käsu `docker compose ps` väljund tekstina (mitte ekraanipildina);
    - kuidas kontrollisid, et teenus töötab (route'i väljund või pgAdmini ekraanipilt).
5. Liida pull request (**Merge**). Automaatkontroll hindab haru `main`, kodutöö kontroll on BOONUS.

??? warning "Tüüpilised vead"
    - Redis on lisatud, aga rakendus ei kasuta seda: kontrollija näeb tühja konteinerit.
    - pgAdmin ei saa `db`-ga ühendust: kasuta hostina teenuse nime `db`, mitte `localhost` ega IP-d.
    - `.env` jõudis GitHubi: kontrolli `.gitignore` enne `git add`.
    - Pull request jäi liitmata: automaatkontroll hindab ainult haru `main`.

??? note "Kontrollnimekiri"

    - [ ] Neljas teenus on olemasolevas `docker-compose.yml`-is
    - [ ] `docker compose ps` näitab nelja teenust olekus `Up`
    - [ ] Uut teenust kasutatakse (Redis: route; pgAdmin: ühendus `db`-ga)
    - [ ] Paroolid ja võtmed on `.env`-is, mitte `docker-compose.yml`-is
    - [ ] `.env` on `.gitignore`-is
    - [ ] Pull request on tehtud koos `docker compose ps` väljundi ja lühikirjeldusega ning liidetud `main`-i
