---
tags:
  - Automatiseerimine
  - DevOps
  - Git
---

# Loeng: versioonihaldus Giti ja GitHubiga

Esimesel nädalal seadistati Git sinu arvutis. Täna õpid, kuidas Git hoiab muudatuste ajalugu ning aitab meeskonnal sama koodi muuta, muudatusi võrrelda ja tööd kokku liita.

??? abstract "Õpiväljundid"
    Tunni lõpuks oskad selgitada:

    1. miks versioonihaldus on meeskonnatöö ja automatiseerimise alus;
    2. millised on Giti kolm ala ja põhitsükkel `add`, `commit`, `log`;
    3. mida panna `.gitignore`-sse ja mida mitte;
    4. mis on haru ja kuidas liita ning lahendada liitmiskonflikt;
    5. mis vahe on kohalikul ja kaugrepositooriumil ning mis on `clone` ja `fork`;
    6. mida tähendavad pull request, merge request ja koodiülevaatus.

## 1. Miks versioonihaldus

Ka kursuse järgmiste teemade (Ansible, Docker, CI/CD) failid on tekstifailid, mida meeskond koos muudab. Kui kaks inimest muudavad sama faili ilma versioonihalduseta, võib ühe inimese töö märkamatult kaduma minna. Git säilitab iga muudatuse ajaloos ja näitab, kus kaks muudatust omavahel konfliktis on.

Kui kaks inimest parandavad sama juurutusskripti ja vahetavad omavahel failikoopiaid, tekivad kausta peagi failid `deploy.sh`, `deploy_v2.sh` ja `deploy_LOPP.sh`. Keegi ei tea, milline neist on uusim. Kui üks salvestab oma paranduse vana faili peale, kaob teise eilne töö. Failinimest ei selgu, mis muutus ega miks.

Puudu on ühine usaldusväärne versioon ja ülevaade sellest, kes mida muutis. Selle annab Git. Git salvestab iga commitiga projekti seisu, näitab kahe seisu vahet (diff: millised read lisandusid ja millised kadusid) ning võimaldab mitmel inimesel korraga töötada. Näiteks Boltis või Wise'is muudavad sajad insenerid sama koodibaasi iga päev ja see on võimalik ainult versioonihalduse abil. Giti põhjalik ja tasuta õpik on [Pro Git](https://git-scm.com/book/en/v2).

??? question "Kontrolli ennast"
    1. Miks ei aita failide ümbernimetamine (`deploy_LOPP.sh`) probleemi lahendada?
    2. Nimeta kaks asja, mida Git meeskonnale annab, mida käsitsi failivahetus ei anna.

## 2. Giti kolm ala ja commit

Git ei salvesta muudatust kohe, kui faili muudad. Muudatus liigub läbi kolme ala. Alguses tekitab see segadust, aga tänu sellele saad ühe töösessiooni jagada mitmeks selgeks commitiks.

<figure markdown="span">
```mermaid
flowchart LR
    A["Tööpuu<br/>failid, mida redigeerid"] -->|git add| B["Ettevalmistusala (staging)<br/>järgmisse commit'i valitud muudatused"]
    B -->|git commit| C["Kohalik repositoorium<br/>ajalugu kaustas .git"]
    C -->|git push| D["GitHub<br/>kaugrepositoorium"]
```
  <figcaption>Joonis 2.1. Muudatus liigub tööpuust staging'u, sealt kausta .git ja lõpuks GitHubi (Talvik, 2026).</figcaption>
</figure>

**Ettevalmistusala** (staging area, index) on järgmise commit'i mustand: sinna lisad täpselt need muudatused, mis lähevad järgmisse commiti. Nii saad ühe töösessiooni jagada loogilisteks commitideks, näiteks veaparanduse ühte ja uue funktsiooni teise.

```bash
git status                                  # mis muutus, mis on staging'us
git add deploy.sh                           # üks fail staging'usse
git commit -m "Lisa paigaldusskripti taaskäivituse kontroll"
git log --oneline --graph                   # ajalugu
```

Iga käsu võtmed on kirjas [Giti dokumentatsioonis](https://git-scm.com/docs).

Commit'i sõnum on kohustuslik: Git keeldub tühja sõnumiga commitist. `git log` on esimene koht, kuhu vea otsimisel vaatad, ja sõnum on selle ainus inimloetav sisu. Sõnum `paranda asjad` ei aita kuu aja pärast kedagi, sõnumist `Lisa taaskäivituse kontroll` on aga kohe näha, mis muutus.

??? question "Kontrolli ennast"
    1. Mis vahe on `git add` ja `git commit` vahel?
    2. Miks keeldub Git tühja commit-sõnumiga commitist?

## 3. Git-failid ja `.gitignore`

Versioonihaldusse kuuluvad failid, mida on vaja projekti taastamiseks ja koos arendamiseks. Saladused, ajutised failid ja tavalised töölogid jäetakse välja. Kursusel nõutud tõendifailid (kaust `logid/`) lisatakse repositooriumi, kui neis pole saladusi.

Repositooriumi juurkaustas on peidetud kaust `.git`. Selles on kogu ajalugu, commitid ja harud. Kui `.git` kustutada, jäävad failid alles, aga ajalugu kaob. Seda kausta käsitsi ei muudeta. Ise kirjutad faili `.gitignore`: loend mustritest, mida Git ignoreerib. Mustrite süntaks on [`gitignore` dokumentatsioonis](https://git-scm.com/docs/gitignore). Tabelis 3.1 on näha, mis sinna kuulub.

??? note "Tabel 3.1. Mis kuulub `.gitignore`-sse"
    | Pane `.gitignore`-sse | Ära pane sinna |
    |-----------------------|----------------|
    | Saladused: `.env`, võtmed, paroolid | Lähtekood ja skriptid |
    | Logid: `*.log` | Jagatud konfiguratsioonifailid (`config.example`) |
    | Genereeritud failid: `build/`, `__pycache__/` | `.gitignore` ise (seda jälgitakse) |
    | Sõltuvused: `node_modules/`, `venv/` | README, Ansible'i, Dockeri ja CI-failid |
    | Operatsioonisüsteemi ja redaktori abifailid: `.DS_Store`, `.idea/` | |

!!! warning "Saladus ajaloos"
    Lisa `.env` `.gitignore`-sse enne esimest commiti. Kui saladus on kord commiti sattunud, saab selle vanast commitist kätte ka pärast faili kustutamist. Saladuste turvalist hoidmist õpid Ansible Vaulti teemas.

## 4. Harud

Kui kõik muudaksid otse `main`-i, segaks igaühe pooleli olev töö teisi. Harude abil saab mitu inimest töötada korraga eri asjade kallal teineteist segamata.

**Haru** (branch) on eraldi tööliin, tehniliselt liikuv viit ühele commitile. Kursusel on `main` ülevaadatud põhiversioon. Töötad oma harus, kuni töö on valmis, ja siis liidad selle tagasi. Meeskond hoiab `main`-i kokkuleppe järgi töökorras.

<figure markdown="span">
```mermaid
gitGraph
   commit id: "avaleht"
   commit id: "logi seadistus"
   branch uus-endpoint
   checkout uus-endpoint
   commit id: "lisa /health"
   commit id: "lisa test"
   checkout main
   merge uus-endpoint id: "liidetud"
```
  <figcaption>Joonis 4.1. Haru areneb main'ist eraldi ja liidetakse valmimisel tagasi (Talvik, 2026).</figcaption>
</figure>

```bash
git switch -c uus-endpoint      # loo haru ja mine sinna
git switch main                 # vaheta haru
git branch                      # loend, tärn = kus oled
```

Harusid on kahte liiki: lokaalne haru (`uus-endpoint` sinu masinas) ja kaugharu jälgimisviit (`origin/main`). See näitab haru `main` olekut GitHubis sellel hetkel, kui viimati käivitasid `git fetch` või `git pull`. `git status` võrdleb neid. Teade "ahead of origin/main by 2 commits" tähendab, et sul on kaks commiti, mida pole veel GitHubi saadetud.

## 5. Liitmine ja konfliktid

Enamasti liidab Git harud ise kokku. Kui aga kaks inimest muutsid sama rida, ei saa Git otsustada, kumb versioon on õige, ja jätab valiku inimesele. Konflikti lahendamine on meeskonnatöös igapäevane oskus.

```bash
git switch main
git merge uus-endpoint
```

Kui `main` pole vahepeal muutunud, teeb Git *fast-forward*'i. Kui on muutunud, tekib *merge-commit*, mis ühendab kaks liini. Konflikt tekib siis, kui kaks inimest muutsid sama rida (või kõrvuti asuvaid ridu). Git märgib failis mõlemad versioonid:

```
<<<<<<< HEAD
port = 8080
=======
port = 3000
>>>>>>> uus-endpoint
```

`HEAD` on praeguse haru versioon, alumine osa on liidetava haru versioon. Vali õige variant, kustuta kõik kolm markeririda (`<<<<<<<`, `=======`, `>>>>>>>`) ja lõpeta liitmine:

```bash
git add config.py
git commit
```

??? question "Kontrolli ennast"
    1. Sina muutsid rida 5, teine inimene rida 40 samas failis. Kas liitmisel tekib konflikt?
    2. Kes otsustab, kumb versioon konflikti korral jääb?

## 6. Lokaalne ja kaugrepo: clone, push, pull, fetch

Kaugrepo on meeskonna ühine kokkulepitud versioon. Lokaalne koopia võib olla vananenud, seepärast alusta tööpäeva käsuga `git pull` ja alles siis tee muudatusi.

- **Lokaalne Git** asub sinu masinas. Kogu repo koos ajalooga on sinu kettal ning commit, haru ja log töötavad ka ilma internetita. Git on hajus versioonihaldus: igal inimesel on täielik koopia.
- **Kaugrepo (remote)** asub GitHubis ja on meeskonna ühine koopia. Põhilise kaugrepo tavapärane nimi on **`origin`**.

<figure markdown="span">
```mermaid
flowchart LR
    LOCAL[".git<br/>lokaalne"] -->|git push| REMOTE["GitHub<br/>origin"]
    REMOTE -->|git fetch / pull| LOCAL
    REMOTE -.->|git clone| OTHER["teise inimese masin"]
```
  <figcaption>Joonis 6.1. clone teeb koopia, push saadab commitid GitHubi, fetch/pull toob teiste commitid (Talvik, 2026).</figcaption>
</figure>

`clone` teeb kaugrepost täieliku koopia sinu masinasse (failid, ajalugu ja seos `origin`-iga). Seda tehakse repoga töö alguses üks kord.

```bash
git clone https://github.com/hkhk-automation/tiimi-repo.git
git push -u origin uus-endpoint   # oma haru GitHubi
git fetch                         # too muudatused, ära liida
git pull                          # fetch + merge
```

`fetch` toob muudatused, kuid ei muuda sinu tööfaile, nii et saad need enne üle vaadata. `pull` toob muudatused ja liidab need kohe. Jagatud repositooriumis tõmbad kõigepealt teiste muudatused (`pull`), siis teed oma töö, salvestad selle (`commit`) ja saadad GitHubi (`push`).

## 7. GitHub: pull request, fork, koodiülevaatus

Kursusel liidame valmis muudatused harusse `main` pull request'i kaudu ja pärast ülevaatust. Nii leitakse vead enne, kui need kõiki mõjutavad. Kui repositooriumis on GitHub Actions (N7), käivituvad iga pull request'i peale ka automaattestid.

Kui haru on valmis, avad **pull request'i** (PR), millega palud muudatused üle vaadata ja liita. Nimetus sõltub platvormist: GitHubis on see pull request, GitLabis ja Bitbucketis merge request (MR). Mõiste on sama. Kogu töövoog on kirjeldatud GitHubi juhendis [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow).

<figure markdown="span">
```mermaid
flowchart LR
    A["push haru"] --> B["ava PR / MR"]
    B --> C["ülevaatus: diff + kommentaarid"]
    C -->|parandust vaja| D["lisa commit harule"]
    D --> C
    C -->|kinnitatud| E["merge main-i"] --> F["kustuta haru"]
```
  <figcaption>Joonis 7.1. Pull request on kontrollpunkt enne main'i: ülevaatus on enne liitmist (Talvik, 2026).</figcaption>
</figure>

PR-is näeb meeskond, millised read muutusid (rohelisega lisatud, punasega eemaldatud), saab kommenteerida ja parandusi paluda. See on **koodiülevaatus** (code review): enne harusse `main` jõudmist vaatab muudatuse üle veel üks inimene. Kui lisad harule uue commiti, uueneb PR automaatselt. **Issue'd** on ülesannete ja vigade jälgimiseks. PR viitab tavaliselt issue'le, mille see lahendab.

**Fork** on repositooriumi koopia sinu GitHubi kontol. Seda kasutatakse siis, kui sul pole algses repositooriumis kirjutusõigust, näiteks avatud lähtekoodiga projektides. Töövoog on järgmine: teed forki, kloonid oma forki, lood haru ja teed muudatused, saadad need push'iga oma forki ning avad pull request'i algsesse repositooriumi ([Fork a repo](https://docs.github.com/en/get-started/quickstart/fork-a-repo)).

Kolm sarnast mõistet erinevad nii: `clone` on koopia sinu masinas, `fork` on eraldi koopia sinu GitHubi kontol ja `branch` on tööliin ühe repositooriumi sees.

??? question "Kontrolli ennast"
    1. GitHub nimetab seda pull request'iks, GitLab merge request'iks. Kas need on eri asjad?
    2. Tahad panustada projekti, kus sul pole kirjutusõigust. Mis on esimene samm: `clone` või `fork`?

## 8. Kokkuvõte

??? abstract "Kokkuvõte"
    - Git salvestab iga commitiga projekti seisu ja kogu ajalugu asub kaustas `.git`.
    - Muudatus liigub tööpuust staging'u (`git add`) ja sealt repositooriumi (`git commit`). Commit'i sõnum on kohustuslik.
    - `.gitignore`: jälgi lähtekoodi ja jagatud konfiguratsioonifaile, ignoreeri saladusi, logisid ja genereeritud faile.
    - Harud on odavad: iga funktsioon on oma harus ja `main` hoitakse kokkuleppe järgi töökorras.
    - Konflikt tekib, kui Git ei saa muudatusi ise kokku liita, näiteks kui mõlemas harus on muudetud sama kohta. Valiku teeb inimene.
    - `origin` on meeskonna ühine kaugrepo. Töö algab käsuga `pull` ja lõpeb käsuga `push`.
    - Pull request (= merge request) on kontrollpunkt enne main'i: koodiülevaatus on enne liitmist.

## Taust ja edasijõudnutele

Ajalugu ümber kirjutavaid käske (`rebase`, `reset`) kasuta ainult oma jagamata harus. Jagatud muudatuse tagasivõtmiseks kasuta `revert`-i, mis teeb uue tühistava commit'i.

??? info "Merge ja rebase"
    Mõlemad liidavad harud kokku, kuid tulemuseks on erinev ajalugu. `merge` säilitab ühenduspunkti, `rebase` tõstab sinu commitid värske main'i otsa ja ajalugu jääb sirgeks.

    ```
    merge:                          rebase:
    main:  A---B---C---M            main:  A---B---C---D'---E'
                      /
    haru:      D---E
    ```

    ```bash
    git switch uus-endpoint
    git rebase main
    ```

    Rebase annab commitidele uued SHA-d, seega kasuta seda ainult isiklikus harus enne PR-i avamist. Jagatud main'is rebase'i ei kasutata.

??? info "Muudatuste tagasivõtmine kolmel tasandil"
    ```bash
    git restore fail.py          # enne commiti: viska muudatus ära
    git reset --soft HEAD~1      # oma harus: võta commit tagasi, jäta muudatus staging'usse
    git revert <sha>             # jagatud harus: uus commit, mis tühistab vana
    ```

    `reset` eemaldab commitid ajaloost, seega sobib see ainult jagamata töö jaoks. `revert` säilitab ajaloo ja lisab tühistava commiti, seega on see ohutu ka main'is. `HEAD` on sinu praegune asukoht, `HEAD~1` on üks samm tagasi.

??? info "Sarnased mõisted: mis vahe on?"
    | Mõiste | Mõiste | Vahe |
    |--------|--------|------|
    | lokaalne | remote | sinu masin või GitHub (`origin`) |
    | clone | fork | koopia sinu masinas või sinu GitHubi kontol |
    | branch | fork | tööliin repositooriumi sees või eraldi repositoorium sinu kontol |
    | pull request | merge request | sama asi GitHubis ja GitLabis/Bitbucketis |
    | fetch | pull | ainult too või too ja liida |
    | merge | rebase | säilita ajalugu või kirjuta see sirgeks |
    | reset | revert | eemalda ajaloost (jagamata töö) või tühista uue commitiga (jagatud töö) |
