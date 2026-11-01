---
tags:
  - CD
  - GHCR
  - Kodutöö
---

# N8 · Kodutöö: väljalase tag'iga

Praktikumis sai iga commit harus `main` oma image'i. Selle tag oli commit'i räsi. **Väljalase** (release) on versioon, mille inimene ise märgib, näiteks `v1.0.0`. Git'is tehakse see tag'iga ([Git'i tag'id](https://git-scm.com/book/en/v2/Git-Basics-Tagging)). Konveier ehitab sama nimega image'i.

Starteri kaustas `kodutoo/` on kolleegi töövoog `release.yml`. See peaks väljalaske ehitama. Selles on kolm viga. Seekord leiad need ilma vihjeteta. Järjekord on sama mis praktikumis: sümptom, hüpotees, tõend, parandus.

Kodutöö on boonus. Classroom 50-s on see BOONUS-kontroll ja annab 0 punkti. Tee kodutöö samas repositooriumis `~/lab08` masinas `proxmox1`.

---

## 1. Töövoog õigesse kausta

GitHub käivitab ainult neid töövooge, mis on kaustas `.github/workflows/`. Kopeeri fail sinna ja loe see läbi:

```bash
cd ~/lab08
cp kodutoo/release.yml .github/workflows/release.yml
cat .github/workflows/release.yml
```

Saada fail GitHubi:

```bash
git add .github/workflows/release.yml
git commit -m "N8 kodutöö: release.yml"
git push
```

**Kontrolli:** see push käivitab ainult töövoo `CI/CD`. Töövoog `Release` käivitub tag'i peale.

## 2. Esimene väljalase

Märgi viimane commit versiooniks `v1.0.0`. Saada tag GitHubi:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Tag näitab ühele kindlale commit'ile. Töövoog võetakse sellest commit'ist. Kui parandad töövoogu, tõsta tag uuele commit'ile ja saada see uuesti:

```bash
git tag -f v1.0.0
git push -f origin v1.0.0
```

## 3. Kolm viga

Leia ja paranda vead ükshaaval. Iga paranduse järel tõsta tag ümber (samm 2) ja vaata uut käivitust.

Kirjuta iga vea kohta README kodutöö tabelisse üks rida. Sümptom on rida logist või see, mida nägid vahekaardil **Actions**. Põhjus ja parandus on kumbki üks lause.

Siit leiad tõendeid:

- vahekaart **Actions**: kas töövoog `Release` üldse käivitus;
- punase sammu logi viimased read;
- [GitHubi muutujad](https://docs.github.com/en/actions/reference/workflows-and-actions/variables): võrdle, mis väärtus on `github.ref` ja `github.ref_name` tag'i `v1.0.0` korral;
- [tag'ide mustrid](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushbranchestagsbranches-ignoretags-ignore) sündmuses `push`.

Kõik vead ei tee käivitust punaseks. Üks viga ei lase käivitusel üldse alata.

**Kontrolli:** töövoog `Release` on roheline. **Packages** all on tag `v1.0.0`.

## 4. Väljalase serverisse

Skript `server/paigalda.sh` võtab tag'i argumendina. Paigalda väljalase ja salvesta väljund:

```bash
bash server/paigalda.sh v1.0.0 2>&1 | tee logid/kodu-server.txt
```

**Kontrolli:** logi viimane rida on `v1.0.0`. Kui seal on midagi muud, on üks viga veel parandamata. Vaata, mis väärtuse saab `--build-arg VERSIOON`.

Praktikumi logi `logid/server.txt` ära muuda. Põhikontroll loeb seda.

## 5. Esitamine

Täida README osas **Kodutöö** tabel K1-K3 ja vasta küsimusele K.4. Saada kõik GitHubi:

```bash
git add .github/workflows/release.yml README.md logid/kodu-server.txt
git commit -m "N8 kodutöö: väljalase v1.0.0"
git push
```

??? note "Automaatkontroll (BOONUS)"
    Kontroll vaatab faili `.github/workflows/release.yml`:

    - tag `v1.0.0` käivitab töövoo;
    - töövoos on `actions/checkout`;
    - image'i tag ei ole `github.ref`.

    Lisaks peab `logid/kodu-server.txt` viimane rida olema `v1.0.0` ja README kodutöö vastused peavad olema täidetud.

??? warning "Kui midagi ei tööta"
    - `git push -f origin v1.0.0` annab `rejected`: kasuta võtit `-f` nii käsus `git tag` kui ka käsus `git push`.
    - Töövoog `Release` ei käivitu ka pärast parandust: tag näitab ikka vanale commit'ile. Vaata `git log --oneline -1 v1.0.0` ja tõsta tag ümber.
    - Skript annab `manifest unknown`: registris pole veel tag'i `v1.0.0`. Oota, kuni `Release` on roheline.
