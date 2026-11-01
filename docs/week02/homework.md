---
tags:
  - Git
  - Versioonihaldus
  - Meeskonnatöö
  - GitHub
  - Kodutöö
---

# Kodutöö: koodiülevaatus autori ja ülevaataja rollis

Kodutöös teed paarilisega läbi kogu ülevaatustsükli nii autori kui ka ülevaataja rollis, kasutades praktikumis loodud repositooriumeid `marten-monitor-<nimi>`. Kõik muudatused liidetakse harusse `main` pull request'i kaudu. Kodutöö on boonusülesanne.

## Osa 1 · Panus paarilise repositooriumisse

Paarilise repositooriumis on sul Write-õigus: saad luua harusid ja PR-e, kuid ei saa muuta tema reegleid. Klooni tema repositoorium (kui sa ei teinud seda praktikumis):

```bash
git clone git@github.com:hkhk-automation/marten-monitor-<paarilise-nimi>.git
cd marten-monitor-<paarilise-nimi>
```

Loo oma haru ja tee üks sisuline muudatus, näiteks üks järgmistest:

- lisa failile `monitor.sh` kommentaariplokk, mis selgitab, mida iga rida teeb;
- lisa faili `README.md` jaotis "Kasutamine" koos näidiskäsuga;
- paranda midagi, mis skriptis on veel pooleli.

```bash
git switch -c lisa/<sinu-nimi>-panus
# tee muudatus
git add .
git commit -m "lisa: <konkreetne kirjeldus>"
git push -u origin lisa/<sinu-nimi>-panus
```

Ava paarilise repositooriumis PR ([pull request'i loomine](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)). Kirjelda pull request'i kirjelduses (description), mida ja miks muutsid. Määra ülevaatajaks (reviewer) repositooriumi omanik ehk paariline.

## Osa 2 · Paarilise pull request'i ülevaatamine oma repositooriumis

Paariline teeb sama sinu repositooriumis. Vaata oma repositooriumis paarilise muudatused üle:

- ava tema PR ja vahekaart **Files changed** ([kuidas ülevaatus GitHubis käib](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews));
- kirjuta vähemalt üks sisuline kommentaar: mis on hästi tehtud ja mida võiks teha teisiti ("LGTM" üksi ei ole sisuline kommentaar);
- kui muudatus on korras, vajuta **Approve** ja liida PR.

??? question "Mõtle"
    Oma repositooriumis oled administraator, paarilise repositooriumis on sul Write-õigus. Mida ei saa sa tema repositooriumis teha, mida saad oma repositooriumis? Miks on see hea?

## Osa 3 · Konflikt teisest vaatenurgast

Kui muutsite mõlemad sama rida, tekib liitmisel konflikt. Lahenda see selles repositooriumis, kus konflikt tekkis:

```bash
git switch main
git pull origin main
git switch <sinu-haru>
git merge main
# lahenda konflikt ja eemalda konfliktimarkerid, kontrolli git diff
git add .
git commit -m "fix: lahenda liitmiskonflikt"
git push
```

## Osa 4 · Iseseisev muudatus kaitstud haruga repositooriumis

Ka üksi töötades kehtib haru kaitse. Loo oma repositooriumis uus haru ja tee väike lisandus:

- lisa fail `.github/CODEOWNERS`, mis nõuab `monitor.sh` muudatustele sinu ülevaatust ([faili süntaks](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)), või
- lisa veakirje mall `.github/ISSUE_TEMPLATE/bug.md`.

```bash
git switch -c lisa/codeowners
# tee fail
git add .
git commit -m "lisa: CODEOWNERS"
git push -u origin lisa/codeowners
```

Ava PR ja määra ülevaatajaks paariline. GitHub ei luba oma pull request'i ise kinnitada ja haru kaitse nõuab ühte kinnitust, seega liida PR pärast paarilise kinnitust.

## Töö esitamine

Lisa GitHub Projecti lingid kahele liidetud (Merged) pull request'ile: sinu panus paarilise repositooriumisse ja sinu enda lisandus. Link peab viima pull request'ile, repositooriumi link ei sobi.

Tulemuse näed Classroom 50-s.
