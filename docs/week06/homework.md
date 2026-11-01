---
tags:
  - Docker
  - DockerCompose
  - Kodutöö
---

# Kodutöö: neljanda teenuse lisamine stacki

Praktikumis lõid kolme teenusega stacki (`web`, `db`, `nginx`). Selles kodutöös lisad sellele neljanda teenuse ja kontrollid iga sammu tulemust. Kodutöö on boonusülesanne.

Kodutöö teed praktikumi repositooriumis eraldi harus. Tee see haru enne muudatusi:

```bash
git switch n06-lab
git switch -c n06-kodutoo
```

## Osa 1 · Teenuse valik

Vali üks kahest:

- Redis: vahemälu (cache) Flaskile ([Redise image](https://hub.docker.com/_/redis));
- pgAdmin: veebiliides PostgreSQL-i haldamiseks ([pgAdmini image](https://hub.docker.com/r/dpage/pgadmin4)).

Kui sa ei tea, kumba valida, vali pgAdmin. Selle tulemust näed kohe brauseris: ühendud andmebaasiga ja näed tabeleid.

## Osa 2 · Teenuse lisamine

1. Lisa uus teenus olemasolevasse faili `docker-compose.yml`. Eraldi projekti ära loo.
2. Testi uut teenust kõigepealt eraldi (`docker compose up -d <teenus>`) ja mine edasi alles siis, kui see töötab.
3. Redise korral peab Flask seda kasutama, näiteks salvestama ja lugema ühe võtme väärtust mõne route'i kaudu. Ainult Redise konteineri lisamisest ei piisa: rakendus peab seda ka kasutama.
4. pgAdmini korral ava see brauseris ja loo ühendus teenusega `db`. Hostiks on teenuse nimi `db`, `localhost` ja IP-aadress ei tööta.
5. Paroolid ja muud tundlikud väärtused (näiteks pgAdmini sisselogimisparool) kirjuta faili `.env` ja viita neile Compose'i failis muutujatega. Automaatkontroll annab testimise ajal nendele muutujatele oma väärtused.

Käivita kogu stack ja kontrolli, et kõik neli teenust töötavad:

```bash
docker compose up -d
docker compose ps
```

??? success "Oodatav tulemus"
    `docker compose ps` näitab nelja teenust olekus `Up`.

??? warning "Tüüpilised vead"
    - Redis on lisatud, aga rakendus ei kasuta seda: töötav Redise konteiner ei tõenda, et rakendus seda kasutab.
    - pgAdmin ei saa `db`-ga ühendust: kasuta hostina teenuse nime `db`.
    - `.env` jõudis GitHubi: kontrolli enne käsku `git add`, et `.env` on failis `.gitignore`.

??? note "Kontrollnimekiri"

    - [ ] Neljas teenus on olemasolevas `docker-compose.yml`-is
    - [ ] `docker compose ps` näitab nelja teenust olekus `Up`
    - [ ] Uut teenust kasutatakse (Redis: route; pgAdmin: ühendus `db`-ga)
    - [ ] Paroolid ja võtmed on `.env`-is
    - [ ] `.env` on `.gitignore`-is

## Töö esitamine

Salvesta muudetud failid (`docker-compose.yml`, `app/`, konfiguratsioonifailid) commit'ina ja saada need GitHubi:

```bash
git add -A && git commit -m "N6 kodutöö: neljas teenus" && git push -u origin n06-kodutoo
```

Ava pull request harusse `main` ([GitHubi juhend](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)) ja lisa kirjeldusse:

- millise teenuse valisid ja miks;
- käsu `docker compose ps` väljund tekstina;
- kuidas kontrollisid uue teenuse toimimist (Redist kasutava route'i väljund või pgAdmini ekraanipilt).

Seejärel liida pull request. Tulemuse näed Classroom 50-s.
