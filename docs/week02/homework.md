---
tags:
  - Git
  - Versioonihaldus
  - Meeskonnatöö
  - GitHub
---

# Kodutöö: ülevaatus mõlemalt poolt

**Tähtaeg:** pühapäev 23:59
**Esitamine:** kahe liidetud (merged) PR-i lingid GitHub Projectis. Haru: `n02-lab`.

---

Praktikumis seadistasid oma repositooriumi, kaitsesid `main`-haru ja parandasid Märteni skripti pull request'i kaudu. Kodutöös töötad **paarilise** repositooriumis ja teete läbi kogu ülevaatuse ringi nii autori kui ka ülevaataja rollis.

!!! warning
    Kõik muudatused tehakse pull request'i kaudu. Kui midagi jõuab otse `main`-i, ei ole kodutöö tehtud. Haru kaitse peaks sellise push'i niikuinii tagasi lükkama.

---

## Osa 1 · Panus paarilise repositooriumisse

Paarilise repositooriumis on sul **Write**-õigus: saad luua harusid ja PR-e, kuid ei saa muuta tema reegleid. Klooni tema repositoorium (kui sa ei teinud seda praktikumis):

```bash
git clone git@github.com:hkhk-automation/marten-monitor-<paarilise-nimi>.git
cd marten-monitor-<paarilise-nimi>
```

Loo oma haru ja tee üks **sisuline** muudatus. Vali üks järgmistest:

- lisa failile `monitor.sh` kommentaariplokk, mis selgitab, mida iga rida teeb;
- lisa faili `README.md` jaotis "Kasutamine" koos näidiskäsuga;
- paranda midagi, mille Märten pooleli jättis.

```bash
git switch -c lisa/<sinu-nimi>-panus
# tee muudatus
git add .
git commit -m "lisa: <konkreetne kirjeldus>"
git push -u origin lisa/<sinu-nimi>-panus
```

Ava paarilise repositooriumis PR. Kirjelda description'is, mida ja miks muutsid. Määra ülevaatajaks (reviewer) repositooriumi omanik ehk paariline.

## Osa 2 · Paarilise pull request'i ülevaatamine oma repositooriumis

Paariline teeb sama sinu repositooriumis. Omanikuna on sinu ülesanded järgmised:

- ava tema PR ja vahekaart **Files changed**;
- kirjuta **vähemalt üks sisuline kommentaar**. "LGTM" ei lähe arvesse. Kirjuta, mis on hästi tehtud ja mida võiks teha teisiti;
- kui muudatus on korras, vajuta **Approve** ja liida PR.

??? question "Mõtle"
    Oma repositooriumis oled admin, paarilise repositooriumis on sul Write-õigus. Mida **ei saa** sa tema repositooriumis teha, mida saad oma repositooriumis? Miks on see hea?

## Osa 3 · Konflikt teisest vaatenurgast

Kui muutsite mõlemad sama rida, tekib liitmisel konflikt. Lahenda see selles repositooriumis, kus konflikt tekkis:

```bash
git switch main
git pull origin main
git switch <sinu-haru>
git merge main
# lahenda markerid, kontrolli git diff
git add .
git commit -m "resolve: merge konflikt"
git push
```

## Osa 4 · Iseseisev töövoog oma haru kaitse all

Loo oma repositooriumis uus haru ja tee väike lisandus. Nii näitad, et oskad reeglite piires ka üksi töötada:

- lisa fail `.github/CODEOWNERS`, mis nõuab `monitor.sh` muudatustele sinu ülevaatust, **või**
- lisa veateate mall `.github/ISSUE_TEMPLATE/bug.md`.

```bash
git switch -c lisa/codeowners
# tee fail
git add .
git commit -m "lisa: CODEOWNERS"
git push -u origin lisa/codeowners
```

Ava PR. GitHub ei luba oma pull request'i ise kinnitada, seega selgita description'is, miks see on erand, ja liida PR.

---

## Mida hinnatakse

- [ ] Panus paarilise repositooriumisse on tehtud PR-iga funktsiooniharust, otse `main`-i ei ole midagi saadetud
- [ ] Paarilise PR-il on sisuline ülevaatuse kommentaar ("LGTM" ei lähe arvesse)
- [ ] Konflikt on lahendatud (kui see tekkis) ja faili ei jäänud markereid
- [ ] Iseseisev lisandus oma repositooriumis on tehtud PR-i kaudu
- [ ] Commit-sõnumid on konkreetsed
- [ ] GitHub Projectis on kahe liidetud PR-i lingid

!!! tip
    Link peab viima **PR-ile**, repositooriumi link ei sobi. PR peab olema olekus "Merged".

---

## Allikad

| Allikas | URL |
|---|---|
| PR-i loomine | <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request> |
| PR-i ülevaatus | <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews> |
| CODEOWNERS | <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners> |
