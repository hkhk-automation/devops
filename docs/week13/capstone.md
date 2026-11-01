---
tags:
  - Lõpuprojekt
---

# Lõpuprojekt: automatiseerimislahendus otsast lõpuni

Lõpuprojektis ehitate 2–3-liikmelise rühmana töötava automatiseerimislahenduse ja esitlete seda. Lahendus kasutab kursusel õpitud tööriistu. Milliseid, sõltub valitud stsenaariumist.

## Osa 1 · Stsenaarium

Valige üks stsenaarium. Tabeli viimane veerg on see, mis peab esitlusel töötama.

??? note "Tabel 13.1. Stsenaariumid"
    | Tase | Stsenaarium | Peab töötama |
    |---|---|---|
    | Lihtne | Staatiline veebileht | Git ja Ansible, mis paigaldab lehe serverisse |
    | Keskmine | Flaski rakendus | Git, Docker Compose ja CI-konveier, mis testib rakendust |
    | Keeruline | Automaatne tarne | Git, Docker, CI/CD, GHCR ja Ansible, mis paigaldab rakenduse serverisse |
    | Edasijõudnud | Tarne ja infrastruktuur koodina | Eelmine rida, lisaks OpenTofu, mis loob masinad, ja Ansible mitme sõlme seadistamiseks |

## Osa 2 · Nõuded kõigile

Iga stsenaariumi puhul peab olema:

- repositoorium, kus muudatused on tehtud harudes ja liidetud pull request'iga;
- README, mille järgi saab lahenduse käivitada ja kontrollida;
- saladused (paroolid, tokenid) ei ole repositooriumis ega logides;
- tööriistade võrdlustabel: iga kasutatud tööriista kohta, kas fail kirjeldab samme või tulemust, millist olekut tööriist haldab ja kas korduv käivitamine on ohutu. Näide on [N9 praktikumi](../week09/lab.md) lisaülesannetes.

## Osa 3 · Mida demo näitab

Iga stsenaariumi juures näitate demos kaks või kolm kontrolli. Valige need, mis teie lahendusele sobivad:

- veebileht või rakendus vastab aadressil, mis on README-s;
- Ansible'i teine käivitus annab `changed=0`;
- töötava image'i versioon (tag) on näha;
- punane CI-käivitus peatab järgmise sammu (liitmise või paigalduse);
- keskkonna saab README järgi uuesti üles seada.

Lisaks näitate ühe vea ja selle paranduse. CI-konveieriga lahenduses on see punane ja siis roheline käivitus. Lihtsas stsenaariumis on see playbook'i väljund enne ja pärast parandust.

## Osa 4 · Esitlus

Esitlus kestab 7 minutit: 5 minutit demot ja 2 minutit küsimusi. Demos näidake arhitektuurijoonist, üht töövoogu algusest lõpuni ning vea parandust. Võrdlustabel ja paigaldusjuhis on repositooriumis, esitluses tooge välja kõige olulisem järeldus.

Esitluses peate oskama vastata:

- Miks valisite selle tööriista, mitte alternatiivi?
- Mis läheb esimesena katki, kui üks komponent ei tööta?

Kui demo ajal võrk või server ei tööta, näidake enne salvestatud tõendeid (logid, ekraanipildid). Need peavad olema repositooriumis enne esitlust.

??? note "Tabel 13.2. Hindamiskriteeriumid"
    | Kriteerium | Osakaal |
    |---|---|
    | Lahendus töötab demo ajal (või tõendid näitavad, et töötas) | 50% |
    | Arhitektuurijoonis on selge ja täpne | 20% |
    | Tööriistade valik on põhjendatud | 20% |
    | Võrdlustabel on repositooriumis | 10% |

## Töö esitamine

Repositooriumis on:

- README: rühma liikmed ja kes mida tegi, käivitusjuhis ja demo kontrollid;
- arhitektuurijoonis;
- võrdlustabel;
- vea ja paranduse tõendid (logid või käivituste lingid).

Repositooriumi lingi ja tähtaja näete Classroom 50-s.

## Lisaülesanded

??? example "1 · Kaks keskkonda ja triiv"
    Hallake Ansible'iga kahte keskkonda (`production` ja `staging`) `group_vars`-failidega. Muutke ühes hostis midagi käsitsi, nii et server erineb koodis kirjeldatust (triiv), ja näidake esitluses, kuidas playbook selle parandab. Selgitage, mida ütleb tootmise serveripargis `changed=0` ja mida `changed=5`.
