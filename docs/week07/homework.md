# Kodutöö — CI oma Flask rakendusele

**Eeldused:** labor on tehtud. Sul on nädala 5 repo Flask rakendusega, mis jookseb Dockeris.

## Ülesanne

Lisa **oma nädala 5 repole** töötav CI pipeline, mis erineb laborist kolme asja poolest:

1. Trigger peab reageerima **kahele** sündmusele: push'ile `main` harusse JA pull request'ile.
2. Pipeline peab sisaldama **vähemalt kahte sammu**: rakenduse testimine + üks lisasamm (nt lint, versioonikontroll või `ls`-tüüpi kontroll, kui sul veel päris testi pole).
3. Kõik peab jooksma **roheliselt** enne esitamist — punase X-iga run ei lähe arvesse.

## Sammud

1. Loo oma Flaski repos fail `.github/workflows/ci.yml`.

2. Kirjuta trigger, mis kuulab mõlemat sündmust:

   ```yaml
   on:
     push:
       branches: [main]
     pull_request:
   ```

   💡 **Erinevus laborist:** laboris kasutasid `on: push` (kõik harud). Siin piirad push'i ainult `main`-le, aga lisad `pull_request`, mis käivitub olenemata harust.

3. Lisa job, mis teeb checkout'i ja käivitab su rakenduse testi (kasuta oma pytest'i, kui see olemas, muidu lihtne shellikontroll nagu laboris Osa 4).

4. Lisa **teine samm samasse jobisse või uus job** — nt:
   - `pip install -r requirements.txt` enne testi (kui see puudub, test ilmselt ebaõnnestub — see loeb "lisasammuks");
   - hadolint Dockerfile'ile (nagu laboris Osa 7);
   - või `python -m py_compile app.py`, mis kontrollib, et fail on süntaktiliselt korrektne Python.

5. Pushi. Kontrolli Actions tab'ist, et run on roheline. Kui punane — loe veateadet (laboris Osa 5-6 harjutasid täpselt seda), paranda, pushi uuesti.

6. Tee endale ka üks pull request (uus haru → PR `main` vastu) ja veendu, et CI käivitub ka seal, mitte ainult push'il.

💭 **Mõtle:** Miks on mõistlik lasta CI-l joosta ka pull request'i peal, mitte ainult siis, kui kood on juba `main`-is? Mis kasu on sellest enne, kui muudatus on üldse ühendatud?

## Esita

Saada õppejõule (Moodle/vastavalt kokkuleppele) **link oma GitHub Actions run'ile**, mis on roheline — mitte lingi töövoo failile ega repole, vaid otse konkreetsele run'ile (Actions tab → vali run → kopeeri URL aadressiribalt).

Link peab olema kujul:
`https://github.com/<sinu-kasutajanimi>/<repo>/actions/runs/<number>`

## Enesekontroll enne esitamist

- [ ] `.github/workflows/ci.yml` on oma Flaski repos, mitte laborist tuttavas harjutusrepos.
- [ ] Trigger sisaldab nii `push` (branches: main) kui `pull_request`.
- [ ] Pipeline'is on vähemalt kaks sammu (test + üks lisasamm).
- [ ] Viimane run on roheline.
- [ ] Oled proovinud ka PR-i peal — CI käivitus ka seal.
- [ ] Link, mille saadad, viitab konkreetsele run'ile, mitte repole.

**Allikad:** [GitHub Actions — Events that trigger workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows), [GitHub Actions — Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
