---
tags:
  - Docker
  - DockerCompose
  - Kodutöö
---

# Kodutöö: neljas teenus stacki

Praktikumis tegid kolme teenusega stacki (`web`, `db`, `nginx`). Selles kodutöös lisad sinna neljanda teenuse samamoodi: ühe teenuse kaupa ja iga sammu testides. Kodutöö on boonus.

## Osa 1 · Teenuse valik

Vali üks kahest:

- Redis: vahemälu (cache) Flaskile ([Redise image](https://hub.docker.com/_/redis));
- pgAdmin: veebiliides PostgreSQL-i haldamiseks ([pgAdmini image](https://hub.docker.com/r/dpage/pgadmin4)).

Kui ei tea, kumba valida, vali pgAdmin. Selle tulemust näed kohe brauseris: ühendud andmebaasiga ja näed tabeleid.

## Osa 2 · Teenuse lisamine

1. Lisa uus teenus olemasolevasse faili `docker-compose.yml`, eraldi projekti ei tehta.
2. Testi uut teenust kõigepealt eraldi (`docker compose up -d <teenus>`) ja mine edasi alles siis, kui see töötab.
3. Redise korral peab Flask seda kasutama, näiteks lugema ja kirjutama ühte võtit mõne route'i kaudu. Konteiner, mida rakendus ei kasuta, ülesannet ei täida.
4. pgAdmini korral ava see brauseris ja loo ühendus teenusega `db`. Hostiks on teenuse nimi `db`, `localhost` ja IP-aadress ei tööta.
5. Paroolid ja võtmed (näiteks pgAdmini sisselogimine) tulevad failist `.env`. Automaatkontroll annab testimisel igale `.env` muutujale oma väärtuse, nii et ka uue teenuse parool võib olla `.env`-is.

Käivita kogu stack ja kontrolli, et kõik neli teenust töötavad:

```bash
docker compose up -d
docker compose ps
```

??? success "Oodatav tulemus"
    `docker compose ps` näitab nelja teenust olekus `Up`.

??? warning "Tüüpilised vead"
    - Redis on lisatud, aga rakendus ei kasuta seda: kontroll näeb tühja konteinerit.
    - pgAdmin ei saa `db`-ga ühendust: kasuta hostina teenuse nime `db`.
    - `.env` jõudis GitHubi: kontrolli `.gitignore` enne `git add` käsku.

??? note "Kontrollnimekiri"

    - [ ] Neljas teenus on olemasolevas `docker-compose.yml`-is
    - [ ] `docker compose ps` näitab nelja teenust olekus `Up`
    - [ ] Uut teenust kasutatakse (Redis: route; pgAdmin: ühendus `db`-ga)
    - [ ] Paroolid ja võtmed on `.env`-is
    - [ ] `.env` on `.gitignore`-is

## Töö esitamine

Töö läheb samasse repositooriumisse nagu praktikum, harusse `n06-lab` või uude harusse `n06-kodutoo`. Tee commit muudetud failidest (`docker-compose.yml`, `app/`, konfiguratsioonifailid) ja saada see GitHubi:

```bash
git switch -c n06-kodutoo
git add -A && git commit -m "N6 kodutöö: neljas teenus" && git push -u origin n06-kodutoo
```

Ava pull request harusse `main` ([GitHubi juhend](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)) ja kirjuta selle kirjeldusse, millise teenuse valisid ja miks, käsu `docker compose ps` väljund tekstina ning kuidas kontrollisid, et teenus töötab (route'i väljund või pgAdmini ekraanipilt). Seejärel liida pull request. Faili `.env` repositooriumi ei panda. Tulemuse näed Classroom 50-s.
