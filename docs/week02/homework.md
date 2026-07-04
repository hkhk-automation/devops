---
tags:
  - Git
  - Versioonihaldus
  - Meeskonnatöö
  - GitHub
---

# Kodutöö — Review teiselt poolt lauda

**Tähtaeg:** pühapäev 23:59
**Esitamine:** kahe merged PR-i lingid (mitte repo link) Slackis

---

Labis said oma repo püsti, kaitsesid `main`-i ja parandasid Märtenit läbi PR-i. Kodutöö läheb edasi: nüüd töötad **paarilise** repos ja teed päris review-ringi — mõlemalt poolt lauda.

!!! warning
    Kõik läbi PR-i. Kui midagi läheb otse `main`-i, pole kodutöö tehtud — protection peaks selle nagunii tagasi lükkama.

---

## Osa 1 · Panusta paarilise reposse

Paarilise repos oled sa **Write**-collaborator — saad teha branche ja PR-e, aga ei muuda tema reegleid. Klooni tema repo (kui labist pole veel):

```bash
git clone git@github.com:hkhk-automation/marten-monitor-<paarilise-nimi>.git
cd marten-monitor-<paarilise-nimi>
```

Tee oma haru ja üks **sisuline** panus — vali üks:

- lisa `monitor.sh`-ile kommentaar-plokk, mis selgitab mida iga rida teeb
- lisa `README.md`-sse "Kasutamine" sektsioon näidiskäsuga
- paranda mõni asi, mille Märten pooleli jättis

```bash
git switch -c lisa/<sinu-nimi>-panus
# tee muudatus
git add .
git commit -m "lisa: <konkreetne kirjeldus>"
git push -u origin lisa/<sinu-nimi>-panus
```

Ava PR paarilise repos. Description: mida ja miks. Määra reviewer'iks repo omanik (paariline).

## Osa 2 · Review tema PR-i sinu repos

Paariline teeb sama sinu repos. Sinu töö omanikuna:

- ava tema PR → **Files changed**
- kirjuta **vähemalt üks sisuline kommentaar** — "LGTM" ei lähe arvesse; ütle mis on hea, mis võiks teisiti
- kui korras, **Approve** ja merge

??? question "Mõtle"
    Sa oled oma repos admin, paarilise omas Write. Mida sa **ei saa** tema repos teha, mida saad enda omas? Miks on see hea?

## Osa 3 · Konflikt teiselt poolt

Kui te mõlemad puudutasite sama rida, tekib merge'imisel konflikt. Lahenda see (kummas repos see juhtub, seal ka lahendad):

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

## Osa 4 · Solo — üks flow läbi enda protectioni

Oma repos, uus haru, väike lisa — näita et oskad ka üksi reeglite sees liikuda:

- lisa `.github/CODEOWNERS`, mis nõuab `monitor.sh` muudatustele sinu review, **või**
- lisa `.github/ISSUE_TEMPLATE/bug.md` bug-raporti mall

```bash
git switch -c lisa/codeowners
# tee fail
git add .
git commit -m "lisa: CODEOWNERS"
git push -u origin lisa/codeowners
```

Ava PR, approve ise (kui reegel lubab) või selgita description'is miks see erand on, merge.

---

## Mida hinnatakse

- [ ] Panus paarilise repos — PR feature-branchist, mitte otse `main`
- [ ] Sisuline review-kommentaar tema PR-il (mitte "LGTM")
- [ ] Konflikt lahendatud (kui tekkis) — markereid faili ei jäänud
- [ ] Solo-lisa oma repos läbi PR-i
- [ ] Commit-sõnumid on konkreetsed
- [ ] Kaks merged PR-i linki Slackis

!!! tip
    Link peab viima **PR-ile**, mitte repole. PR peab olema staatuses "Merged". Nii näen kohe, et flow käis reeglite kaudu.

---

## Allikad

| Allikas | URL |
|---|---|
| PR-i loomine | <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request> |
| PR review | <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews> |
| CODEOWNERS | <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners> |
