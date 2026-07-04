---
tags:
  - CD
  - GHCR
  - Praktikum
---

# CD ja GHCR — käed külge — Labor

**Kestus:** 4 tundi
**Eeldused:** Loeng antud (CI vs CD, register, tagid). Nädal 5 repo (Flask + Dockerfile) + nädal 7 pipeline (`.github/workflows/ci.yml` roheline). Kui udu — [tagasi loengusse](lecture.md).
**Keskkond:** kood **VS Code'is**, pipeline GitHubi runneris. Serveri-samm (Osa 6): sinu sihtmärk (kodus valitud, koolis Proxmox).

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Laiendad nädal 7 pipeline'i `build-and-push` job'iga
    2. **Diagnoosid** `403 permission_denied` ja parandad `permissions`-iga
    3. Leiad ehitatud image'i GHCR-ist (Packages) kahe tagiga
    4. Tõmbad image'i serverisse ja käivitad — ring sulgub
    5. Selgitad miks build jookseb ainult `main`-il, mitte PR-idel

---

Labi loogika: **baas (CI) → laienda → viga (403) → paranda → laienda (server) → taasta.** Ehitad CD osa nädal 7 pipeline'i otsa, tekitad õigustevea ise, sulged ringi serverini. Fragmendid, mitte terve fail (kontrolliks terve fail on Osa 3 lõpus kollapsi taga).

---

## Osa 1 · Eeltöö — CI roheline, image ehitub

Ava repo VS Code'is (`code .`). Kontrolli et nädal 7 CI on roheline (Actions tab) ja Dockerfile ehitub lokaalselt:

```bash
docker build -t test-build .
docker run --rm -p 5000:5000 test-build
```

`http://localhost:5000` vastab? Koristus:

```bash
docker stop $(docker ps -q)
docker rmi test-build
```

Kui Dockerfile on alamkaustas (nt `app/`), pane kirja — läheb hiljem `context:` väärtuseks.

!!! tip
    Kui image lokaalselt ei ehitu, lahenda **enne**. CD ei saa ehitada seda, mis su masinaski katki. (Meenuta: "works on my machine" — kui isegi su masinas ei tööta, on lugu hull.)

---

## Osa 2 · Trigger + build job ilma õigusteta

Ava `.github/workflows/ci.yml`. Lisa `main`-push trigger (fragment, `on:` alla):

```yaml
on:
  push:
    branches: [main]
  pull_request:
```

Lisa `build-and-push` job **olemasoleva `test` job'i järele**, `jobs:` all samal tasemel — **teadlikult ilma `permissions` blokita** (tekitame vea):

```yaml
  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:latest
            ghcr.io/${{ github.repository }}:${{ github.sha }}
```

`ghcr.io/${{ github.repository }}` — automaatne, kujul `kasutaja/repo`. Sa ei kirjuta oma nime kuhugi. `needs: test` = build ainult pärast roheliseid teste. `if: main` = ainult `main`-il.

Commit ja push **otse main-i** (täna erand, et CD käivituks):

```bash
git add .github/workflows/ci.yml
git commit -m "ci: lisa build-and-push job"
git push origin main
```

---

## Osa 3 · Viga — 403 permission_denied

Actions tab — `test` roheline, `build-and-push` **punane**. Ava `build-and-push` → build-push samm. Veateade: `denied: permission_denied` või `403`.

??? question "Diagnoosi enne kui parandad"
    Workflow saab vaikimisi koodi ainult **lugeda**. GHCR on pakett — sinna kirjutamiseks on vaja luba, mida sa ei andnud. Mis blokk annab workflow'ile kirjutusõiguse pakettidesse?

**Paranda** — lisa `permissions` blokk **workflow tasandil** (pärast `on:`, enne `jobs:`):

```yaml
permissions:
  contents: read
  packages: write
```

Kontrolli ka repo seadeid: `Settings → Actions → General → Workflow permissions` → **Read and write permissions**.

Push uuesti:

```bash
git add .github/workflows/ci.yml
git commit -m "ci: lisa packages write luba"
git push origin main
```

Nüüd `build-and-push` roheline.

??? note "Terve fail kontrolliks (ava kui tahad võrrelda)"
    ```yaml
    name: CI/CD

    on:
      push:
        branches: [main]
      pull_request:

    permissions:
      contents: read
      packages: write

    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - uses: actions/setup-python@v5
            with:
              python-version: '3.12'
          - run: pip install -r requirements.txt
          - run: pytest

      build-and-push:
        needs: test
        runs-on: ubuntu-latest
        if: github.ref == 'refs/heads/main'
        steps:
          - uses: actions/checkout@v4
          - uses: docker/login-action@v3
            with:
              registry: ghcr.io
              username: ${{ github.actor }}
              password: ${{ secrets.GITHUB_TOKEN }}
          - uses: docker/build-push-action@v5
            with:
              context: .
              push: true
              tags: |
                ghcr.io/${{ github.repository }}:latest
                ghcr.io/${{ github.repository }}:${{ github.sha }}
    ```
    Kohanda `test` job oma rakendusele (Python versioon, test-käsk).

---

## Osa 4 · Kontrolli GHCR-i

Repo pealehel paremal → **Packages**. Näed oma image'it (repo nimega). Kliki → näed tage: `latest` ja commit hash.

??? question "Mõtle"
    Miks on kasulik, et sama image on korraga tagitud nii `latest` kui commit hash'iga? Kumba kasutaks server tootmises ja miks?

---

## Osa 5 · Viga — PR ei tohi buildida

Kontrolli et `if: main` päriselt kaitseb. Loo haru, muuda midagi, ava PR:

```bash
git switch -c test-pr
echo "# test" >> README.md
git add README.md && git commit -m "test: pr ei tohi buildida"
git push -u origin test-pr
```

Ava PR GitHubis. Actions tab — PR-il jookseb **ainult `test`**, `build-and-push` on **skipped** (hall).

??? question "Diagnoosi"
    Miks `build-and-push` PR-il ei jooksnud? Mis rida job'is selle otsustas? Mis juhtuks, kui selle rea eemaldaksid — ja miks annaks see PR-il vea?

Sulge PR (või merge, kui tahad). Naase `main`-ile:

```bash
git switch main
```

---

## Osa 6 · Ring sulgub — server pull + run

Image on GHCR-is. Nüüd server tõmbab selle. **Serveriks on sinu sihtmärk** — kodus valitud (vt [Töökeskkond](../kodulabor.md)), koolis Proxmox. Ühenda:

```bash
ssh <kasutaja>@<server>
```

GHCR-ist tõmbamiseks logi serveril sisse (vajab GitHub Personal Access Tokenit `read:packages` õigusega — `GitHub → Settings → Developer Settings → Personal access tokens → Tokens (classic)`):

```bash
echo "<sinu_token>" | docker login ghcr.io -u <sinu-github-nimi> --password-stdin
```

Tõmba ja käivita:

```bash
docker pull ghcr.io/<sinu-github-nimi>/<repo>:latest
docker run -d -p 5000:5000 ghcr.io/<sinu-github-nimi>/<repo>:latest
curl http://localhost:5000
```

Rakenduse vastus tuleb — kood GitHubis → CI testis → CD ehitas ja pushis → server käivitas. Sina ei puutunud serverit koodiga, ainult käivitasid valmis paki.

??? question "Mõtle"
    Nädal 13 automatiseerime **ka** selle viimase sammu (server tõmbab ise). Praegu tegid `pull` + `run` käsitsi. Mis on risk, kui see samm jääb igaveseks käsitsi — kes selle reedel õhtul unustab?

---

## Osa 7 · Taasta

Serveril koristus:

```bash
docker stop $(docker ps -q)
docker system prune -f
```

Lokaalselt: kustuta `test-pr` haru kui tegid.

---

## Lõppkontroll — oskad ilma juhendita

- [ ] `.github/workflows/ci.yml` sisaldab `test` + `build-and-push` job'i
- [ ] `permissions: packages: write` on olemas
- [ ] `403` nägemisel tead kohe kust luba tuleb
- [ ] Image GHCR-is kahe tagiga (`latest` + hash)
- [ ] `build-and-push` jookseb `main`-il, on **skipped** PR-il
- [ ] Image käivitub serveril, `curl` annab vastuse
- [ ] Selgitad `needs: test` ja `if: main` rolli

---

## Lisaülesanded (kui jõuad ette)

**Trivy — haavatavuse skanner.** Lisa build'i järele:

```yaml
      - uses: aquasecurity/trivy-action@master
        with:
          image-ref: ghcr.io/${{ github.repository }}:${{ github.sha }}
          format: table
          exit-code: 1
          severity: CRITICAL
```

`exit-code: 1` = CRITICAL haavatavus katab pipeline'i. Testimiseks pane ajutiselt `FROM python:3.6-slim` (vana, haavatav) — pipeline peaks katkema. Siis taasta.

---

## Veaotsing

| Veateade | Põhjus | Lahendus |
|---|---|---|
| `denied: permission_denied` / 403 | `packages: write` puudub | Lisa `permissions` blokk + repo seaded |
| `failed to read dockerfile` | Dockerfile vales kohas | Kontrolli `context:` |
| `unauthorized` | Login samm kukkus | `registry: ghcr.io` täpselt, `username: ${{ github.actor }}` |
| Image ehitatakse enne teste | `needs:` puudub | `needs: test` build job'ile |
| `build-and-push` jookseb PR-il | `if:` puudub | `if: github.ref == 'refs/heads/main'` |
| Server `pull` → `unauthorized` | Serveril pole GHCR login'i | `docker login ghcr.io` tokeniga |

*Tabel 8.1. Iga rida on viga, mille sa selles labis ise tekitasid või kohtad.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| GHCR | <https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry> | Register |
| build-push-action | <https://github.com/docker/build-push-action> | Build + push |
| login-action | <https://github.com/docker/login-action> | GHCR login |
| GITHUB_TOKEN | <https://docs.github.com/en/actions/security-guides/automatic-token-authentication> | Automaatne token |
| Trivy action | <https://github.com/aquasecurity/trivy-action> | Haavatavuse skann |
