# IT-automatiseerimine

13 nädala jooksul õpid automatiseerima serverihalduse ja tarkvaraarenduse töid, mida muidu tehakse käsitsi.

[Alusta esimesest nädalast](week01/lecture.md) · [Programm](#programm)

## Mida sa õpid

1. Jälgida meeskonna koodimuudatusi nii, et tehtud töö ei lähe kaduma
2. Seadistada servereid automaatselt ühe käsuga, ilma et peaksid igas serveris samu samme käsitsi tegema
3. Pakkida rakendus konteinerisse ja käivitada see igas masinas, kus on Docker
4. Ehitada pipeline, mis testib ja levitab koodi automaatselt iga muudatuse järel
5. Kirjeldada infrastruktuuri koodina, et sama keskkonda saaks luua korduvalt ja ühtmoodi
6. Hallata infrastruktuuri koodina: üks playbook, mitu serverit, kõik muudatused versioonihalduses

---

## Programm

| # | Teema | Tööriistad |
|---|---|---|
| N1 | Miks automatiseerimine? | - |
| N2 | Muudatuste jälgimine meeskonnas | Git, GitHub |
| N3 | Serveri konfiguratsiooni automatiseerimine | Ansible |
| N4 | Dünaamiline konfiguratsioon ja saladuste kaitse | Ansible Vault, Jinja2 |
| N5 | Rakenduse pakkimine ja ümberpaigutamine | Docker |
| N6 | Mitme teenuse käitamine koos | Docker Compose |
| N7 | Automaatne testimine ja tarnekonveier | GitHub Actions CI |
| N8 | Automaatne ehitamine ja levitamine | GitHub Actions CD, GHCR |
| N9 | Infrastruktuur koodina: mõtteviis *(iseseisev)* | - |
| N10 | Infrastruktuuri kirjeldamine koodina | Terraform |
| N11 | Korduvkasutatav infrastruktuur | Terraform moodulid / Ansible rollid |
| N12 | Terve serveripark koodina | Ansible, group_vars |
| N13 | Täielik tarnekonveier otsast lõpuni | Kõik tööriistad |

---

## Enne esimest tundi

**1. GitHubi konto.** Loo konto kooli e-posti aadressiga: [github.com](https://github.com). Kasutajanimi ja repode nimed on kujul **eesnimiperekonnanimi** (nt `mariatalvik`), siis leiab õpetaja need organisatsioonist üles.

**2. GitHub Education Pack.** Kooli e-posti aadressiga on see tasuta. Taotluse kinnitamine võtab 1–2 päeva, seega taotle kohe:
[education.github.com/pack](https://education.github.com/pack)

**3. VS Code:** [code.visualstudio.com](https://code.visualstudio.com)

Laiendused paigaldame kursuse käigus, praegu ära paigalda midagi ette.

**4. Töökeskkond.** Koolis saad Proxmoxi virtuaalmasina (VM). Kodus vajad oma Ubuntu masinat (WSL2, VM või pilveserver, vali ise). Masinas peab olema SSH-ligipääs ja sudo-õigus. Vt [Töökeskkond](kodulabor.md).

---

## Hindamine

| Komponent | Osakaal |
|---|---|
| Nädalased kodutööd (N2–N12) | 60% |
| N13 lõpuprojekti esitlus | 30% |
| Aktiivsus ja osalemine | 10% |

Kõik kodutööd esitatakse GitHubis pull request'ina. Tähtaeg on nädalavahetuse lõpus (pühapäeval kell 23:59).

