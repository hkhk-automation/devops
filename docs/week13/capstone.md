---
tags:
  - Lõpuprojekt
---

# Lõpuprojekt: täielik tarnekonveier

Lõpuprojektis ehitate 2–3-liikmelise grupiga töötava automatiseerimislahenduse otsast lõpuni ja esitlete seda. Lahendus kasutab kursusel õpitud tööriistu: Git, Ansible, Docker, Docker Compose, GitHub Actions ja vajaduse korral OpenTofu.

## Osa 1 · Stsenaarium

Valige üks stsenaarium. Minimaalne kombinatsioon on see, mis peab esitlusel töötama.

??? note "Tabel 13.1. Stsenaariumid"
    | Tase | Stsenaarium | Minimaalne kombinatsioon |
    |---|---|---|
    | Lihtne | Staatiline veebileht | Git ja Ansible, mis paigaldab lehe serverisse |
    | Keskmine | Flaski rakendus | Git, Docker, Docker Compose ja CI konveier |
    | Keeruline | Täisautomaatne tarne | Git, Docker, CI/CD, GHCR ja Ansible, mis paigaldab rakenduse |
    | Edasijõudnud | Kõik ja infrastruktuur koodina | Eelmine rida, lisaks OpenTofu (masinate loomine) ja Ansible mitmele hostile |

## Osa 2 · Nõuded

Lahenduses peab töötama:

- versioonihaldus harude ja pull request'idega;
- serveri konfiguratsioon Ansible'iga või infrastruktuur koodina (OpenTofu ja Ansible);
- vähemalt üks järgmistest: CI konveier, Docker või Docker Compose.

Esitluses peab olema tööriistade võrdlustabel: iga kasutatud tööriista kohta, kas fail kirjeldab samme või tulemust, millist olekut tööriist haldab ja kas korduv käivitamine on ohutu. Sama tabeli näide on [N9 praktikumi](../week09/lab.md) lisaülesannetes.

## Osa 3 · Esitlus

Esitlus kestab 7 minutit: 5 minutit töötavat demot koos arhitektuuri joonisega ja 2 minutit küsimusi kaasõppijatelt ja õpetajalt.

Esitluses peate oskama vastata järgmistele küsimustele:

- Miks valisite selle tööriista ja ei valinud teist?
- Mis läheb esimesena katki, kui üks komponent ei tööta?
- Näidake konveieri ebaõnnestunud käivitust ja selle parandust.

??? note "Tabel 13.2. Hindamiskriteeriumid"
    | Kriteerium | Osakaal |
    |---|---|
    | Lahendus töötab demo ajal | 50% |
    | Arhitektuuri joonis on selge ja täpne | 20% |
    | Tööriistade valik on põhjendatud | 20% |
    | Võrdlustabel on esitluses | 10% |

## Lisaülesanded

??? example "1 · Kaks keskkonda ja triiv"
    Hallake Ansible'iga kahte keskkonda (`production` ja `staging`) `group_vars` failidega. Muutke ühes hostis midagi käsitsi, nii et server erineb koodis kirjeldatust (triiv), ja näidake esitluses, kuidas playbook selle parandab. Selgitage, mida tähendab tootmise serveripargis `changed=0` ja mida `changed=5`.
