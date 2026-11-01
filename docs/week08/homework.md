---
tags:
  - CD
  - GHCR
  - Kodutöö
---

# N8 · Kodutöö: väljalase tag'iga

Praktikumis sai iga commit harus `main` oma image'i, mille tag oli räsi. Väljalase (release) on versioon, mille inimene ise märgib, näiteks `v1.0.0`. Git'is tehakse see tag'iga ([Git: tag'id](https://git-scm.com/book/en/v2/Git-Basics-Tagging)) ja pipeline ehitab selle tag'iga image'i. Starteri kaustas `kodutoo/` on kolleegi workflow `release.yml`, mis peaks seda tegema. Selles on kolm viga. Seekord leiad need ilma vihjeteta, samas järjekorras nagu praktikumis: sümptom, hüpotees, tõend, parandus.

Kodutöö on boonus (BOONUS-kontroll Classroom 50-s, 0 punkti). Tee see samas repositooriumis `~/lab08` masinas `proxmox1`.

---

## 1. Workflow kohale

GitHub käivitab ainult neid workflow'sid, mis on kaustas `.github/workflows/`. Kopeeri fail sinna ja loe see läbi:

```bash
cd ~/lab08
cp kodutoo/release.yml .github/workflows/release.yml
cat .github/workflows/release.yml
git add .github/workflows/release.yml
git commit -m "N8 kodutöö: release.yml"
git push
```

**Kontrolli:** push harusse `main` käivitab ainult workflow'i `CI/CD`. Workflow `Release` käivitub tag'i peale.

## 2. Esimene väljalase

Märgi viimane commit versiooniks `v1.0.0` ja saada tag GitHubi:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Tag'i peale käivitatud workflow võtab faili `release.yml` sellest commit'ist, millele tag näitab. Kui parandad workflow'i, tõsta tag uuele commit'ile ja saada see uuesti:

```bash
git tag -f v1.0.0
git push -f origin v1.0.0
```

## 3. Kolm viga

Leia ja paranda vead ükshaaval. Iga vea järel tõsta tag ümber (samm 2) ja vaata uut käivitust. Kirjuta iga vea kohta README kodutöö tabelisse rida: sümptom (rida logist või see, mida vahekaardil **Actions** nägid), põhjus ja parandus.

Kasulikud kohad tõendi leidmiseks:

- vahekaart **Actions**: kas workflow `Release` üldse käivitus, mis sündmus ja mis tag;
- punase sammu logi viimased read;
- muutujate kirjeldused: [GitHubi kontekstid ja muutujad](https://docs.github.com/en/actions/reference/workflows-and-actions/variables). Võrdle, mis väärtus on `github.ref` ja `github.ref_name` tag'i `v1.0.0` korral;
- trigger'i mustrid: [`on.push.tags`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushbranchestagsbranches-ignoretags-ignore).

Kõik vead ei tee käivitust punaseks. Üks neist ei lase sellel üldse alata.

**Kontrolli:** workflow `Release` on roheline ja **Packages** all on tag `v1.0.0`.

## 4. Väljalase serverisse

Skript `server/paigalda.sh` võtab tag'i argumendina. Käivita väljalase ja salvesta väljund:

```bash
bash server/paigalda.sh v1.0.0 2>&1 | tee logid/kodu-server.txt
```

**Kontrolli:** logi viimane rida on `v1.0.0`. Kui seal on midagi muud, ei ole üks viga veel parandatud: vaata, mis väärtuse saab `--build-arg VERSIOON`.

Praktikumi logi `logid/server.txt` ära muuda: põhikontroll loeb seda.

## 5. Esitamine

Täida README jaotises **Kodutöö** tabel K1-K3 ja vasta küsimusele K.4. Saada kõik GitHubi:

```bash
git add .github/workflows/release.yml README.md logid/kodu-server.txt
git commit -m "N8 kodutöö: väljalase v1.0.0"
git push
```

??? note "Automaatkontroll (BOONUS)"
    Kontroll otsib faili `.github/workflows/release.yml`, mille trigger käivitub tag'iga `v1.0.0`, milles on `actions/checkout` ja milles tag'i nimi ei ole `github.ref`. Lisaks peab `logid/kodu-server.txt` viimane rida olema `v1.0.0` ja README kodutöö vastused täidetud.

??? warning "Kui midagi ei tööta"
    - `git push -f origin v1.0.0` annab `rejected`: kontrolli, et kasutasid võtit `-f` nii käsus `git tag` kui ka käsus `git push`.
    - Workflow `Release` ei käivitu ka pärast parandust: tag näitab ikka vanale commit'ile. Kontrolli `git log --oneline -1 v1.0.0` ja tõsta tag ümber.
    - Skript annab `manifest unknown`: registris ei ole veel tag'i `v1.0.0`. Oota rohelist `Release` käivitust.
