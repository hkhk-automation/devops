---
tags:
  - Docker
  - DockerCompose
  - Kodutöö
---

# Kodutöö — neljas teenus stacki

**Eeldused:** Labor tehtud — töötav `docker-compose.yml` kolme teenusega (`web`, `db`, `nginx`).

## Ülesanne

Lisa oma stacki **neljas teenus**. Vali üks:

- **Redis** — vahemälu (cache) Flaskile
- **pgAdmin** — veebiliides PostgreSQL haldamiseks

Vaba valik. Kui pole kindel, vali **pgAdmin** — annab kohe visuaalse tulemuse (avad brauseris, näed tabeleid).

### Nõuded

1. Uus teenus läheb **olemasolevasse** `docker-compose.yml`-i — mitte eraldi projekt.
2. Kasuta labori põhimõtet: lisa teenus, testi eraldi (`docker compose up -d <teenus>`), alles siis edasi.
3. **Redis:** näita et Flask **päriselt kasutab** seda (loeb/kirjutab võtme läbi mõne route'i). Tühi Redis konteiner ilma kasutuseta ei loe.
4. **pgAdmin:** ava brauseris, loo ühendus `db` teenusega (host = service'i nimi, mitte IP — meenuta laborit).
5. Paroolid/võtmed (nt pgAdmin login) käivad läbi `.env`, mitte kõvasti `docker-compose.yml`-is.

### Esitamine

1. Eraldi branch (nt `week06-homework`).
2. Käivita kogu stack, veendu et kõik neli töötavad:

    ```bash
    docker compose up -d
    docker compose ps
    ```

3. **Kopeeri `docker compose ps` väljund** — kõik neli `running`/`Up`. Läheb PR kirjeldusse.
4. Commit muudatused (uuendatud `docker-compose.yml`, konfifailid — **mitte** `.env`).
5. Ava **Pull Request** `main` vastu. PR kirjeldusse:
    - Milline teenus (Redis/pgAdmin) ja miks
    - `docker compose ps` väljund (tekstina, mitte pilt)
    - Kuidas kontrollisid et teenus päriselt töötab (route või pgAdmin ekraanipilt)

!!! warning "Tüüpilised vead"
    - **Redis lisatud, aga rakendus ei kasuta** — kontrollija näeb tühja konteinerit, mitte integratsiooni.
    - **pgAdmin ei saa `db`-ga ühendust** — kasuta hosti `db` (service'i nimi), mitte `localhost` ega IP.
    - **`.env` commit'itud GitHubi** — kontrolli `.gitignore` enne `git add`.
    - **PR-is puudub `docker compose ps` väljund** — ilma selleta ei saa kontrollida.

## Kontrollnimekiri

- [ ] Neljas teenus olemasolevas `docker-compose.yml`-is
- [ ] `docker compose ps` näitab nelja teenust `running`/`Up`
- [ ] Uus teenus on tegelikult kasutuses (mitte lihtsalt käivitatud)
- [ ] Paroolid/võtmed `.env`-is, mitte kõvasti kirjas
- [ ] `.env` on `.gitignore`-is
- [ ] PR tehtud koos `docker compose ps` väljundi ja lühikirjeldusega

## Allikad

| Allikas | URL |
|---|---|
| Redis image | <https://hub.docker.com/_/redis> |
| pgAdmin image | <https://hub.docker.com/r/dpage/pgadmin4> |
| GitHub PR juhend | <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request> |
