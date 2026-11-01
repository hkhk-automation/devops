# IT-automatiseerimine

13 nädala jooksul õpid automatiseerima serverihalduse ja tarkvaraarenduse töid, mida muidu tehakse käsitsi.

[Alusta esimesest nädalast](week01/lecture.md) · [Teemad nädalate kaupa](#teemad-nadalate-kaupa)

## Mida sa õpid

Kursuse lõpuks oskad:

1. jälgida ja üle vaadata meeskonna koodimuudatusi Gitis;
2. seadistada servereid Ansible'iga, ilma et teeksid igas serveris samu samme käsitsi;
3. pakkida rakenduse koos sõltuvustega image'isse ja käivitada selle konteinerina;
4. koostada konveieri, mis testib iga muudatuse ja paneb image'i registrisse;
5. kirjeldada masinaid koodina ja lugeda enne muutmist plaani;
6. hallata mitme serveri seadistusi ühes playbook'is ja versioonihalduses.

## Teemad nädalate kaupa

| # | Teema | Tööriistad |
|---|---|---|
| N1 | Miks automatiseerimine? Töökeskkond ja SSH | SSH, VS Code |
| N2 | Muudatuste jälgimine meeskonnas | Git, GitHub |
| N3 | Serveri konfiguratsiooni automatiseerimine | Ansible |
| N4 | Dünaamiline konfiguratsioon ja saladuste kaitse | Ansible Vault, Jinja2 |
| N5 | Rakenduse pakkimine ja teisaldamine | Docker |
| N6 | Mitme teenuse käitamine koos | Docker Compose |
| N7 | Automaatne testimine ja tarnekonveier | GitHub Actions CI |
| N8 | Automaatne ehitamine ja levitamine | GitHub Actions CD, GHCR |
| N9 | Infrastruktuur koodina: mõtteviis *(iseseisev)* | - |
| N10 | Infrastruktuuri kirjeldamine koodina | OpenTofu, Proxmox |
| N11 | Korduvkasutatav infrastruktuur | OpenTofu moodulid või Ansible'i rollid |
| N12 | Terve serveripark koodina | Ansible, group_vars |
| N13 | Lõpuprojekt | stsenaariumi järgi |

## Enne esimest tundi

**1. GitHubi konto.** Loo konto kooli e-posti aadressiga: [github.com](https://github.com). Vali kasutajanimi, millest õpetaja sind ära tunneb, näiteks eesnimi ja perekonnanimi kokku. Repositooriumid tekivad Classroom 50-s ise.

**2. GitHub Education Pack.** Õppijale on see tasuta. Kinnitamine võib võtta mitu päeva ja vahel küsitakse lisatõendit, seega taotle kohe:
[education.github.com/pack](https://education.github.com/pack)

**3. VS Code:** [code.visualstudio.com](https://code.visualstudio.com)

Laiendused paigaldame kursuse käigus, praegu ära paigalda midagi ette.

**4. Töökeskkond.** Koolis saad Proxmoxi virtuaalmasinad. Kodus pääsed nendeni VPN-iga. Mida kodus ilma VPN-ita teha saab, on lehel [Töökeskkond](kodulabor.md).

## Hindamine

| Komponent | Osakaal |
|---|---|
| Nädalased kodutööd (N2–N12) | 60% |
| N13 lõpuprojekti esitlus | 30% |
| Aktiivsus ja osalemine | 10% |

Tööd esitatakse GitHubis. Kuidas, on kirjas iga ülesande juures. Tähtaja näed Classroom 50-s.

