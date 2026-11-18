---
tags:
  - Lõpuprojekt
---

# Lõpuprojekt: automatiseerimislahendus otsast lõpuni

Lõpuprojektis paned kursusel õpitud tööriistad kokku üheks töötavaks lahenduseks ja näitad seda esitlusel. Projekti tegemiseks on üks tund klassis ja ülejäänu teed kodus, seepärast vali tase, mille jõuad lõpuni teha. Teed töö üksi.

## Osa 1 · Taseme valik

Vali tabelist üks tase. Viimases veerus on see, mis peab esitlusel töötama. Iga tase kasutab ainult seda, mida oled praktikumides juba teinud, ja veerus „Alus“ on praktikum, millest alustada.

??? note "Tabel 13.1. Tasemed"
    | Tase | Lahendus | Alus | Peab töötama |
    |---|---|---|---|
    | Lihtne | Staatiline veebileht | N3, N11 | Git ja Ansible'i roll, mis paigaldab lehe serverisse |
    | Keskmine | Flaski rakendus konteineris | N5, N6, N7 | Git, Docker Compose ja CI-konveier, mis testib rakendust |
    | Keeruline | Automaatne tarne | N7, N8 | Git, Docker, CI/CD ja GHCR: konveier ehitab image'i ja paigaldab selle serverisse |
    | Edasijõudnud | Infrastruktuur ja seadistus koodina | N10, N11, N12 | OpenTofu loob masinad, Ansible'i roll seadistab need |

Kõrgem tase ei ole kohustuslik. Lihtne tase, mis töötab ja mida oskad selgitada, on parem kui pooleli jäänud edasijõudnu tase.

## Osa 2 · Nõuded

Igal tasemel peab olema:

- GitHubi repositoorium, kus on kõik lahenduse failid;
- README, kus on kirjas, mida lahendus teeb, ja käsud, millega seda käivitada ja kontrollida;
- paroolid ja tokenid ei ole repositooriumis;
- vähemalt üks muudatus, mis on tehtud harus ja liidetud pull request'iga.

## Osa 3 · Tund klassis

Tunnis alustad oma lahendust ja küsid abi kohe, kui midagi ei tööta. Tunni lõpuks on sul:

1. tase valitud ja repositoorium loodud;
2. esimene osa töötab: Ansible'i playbook käivitub, konteiner käivitub, konveier on roheline või OpenTofu plaan õnnestub;
3. README-s on kirjas, mis on veel tegemata.

Ülejäänu teed kodus. Kui praktikumis jäi mõni osa tegemata, kasuta selle praktikumi juhendit ja starterit.

## Osa 4 · Esitlus

Esitlus kestab 5 minutit ja selles näitad lahendust töötamas:

1. Ütle, mis taseme valisid ja mida lahendus teeb.
2. Käivita lahendus: playbook, konveier või `tofu apply` ja playbook.
3. Näita tulemust: leht või rakendus vastab.
4. Näita, et korduv käivitus ei muuda midagi: Ansible'i `changed=0`, OpenTofu `No changes` või roheline konveier.

Ole valmis vastama ühele küsimusele: mida teeb mõni rida sinu failis või mis juhtub, kui üks samm ebaõnnestub.

Kui demo ajal võrk või server ei tööta, näita logifaile, mis on repositooriumis enne esitlust olemas.

??? note "Tabel 13.2. Hindamine"
    | Kriteerium | Osakaal |
    |---|---|
    | Lahendus töötab esitlusel või logid näitavad, et töötas | 50% |
    | Oskad selgitada, mida failid ja käsud teevad | 30% |
    | README järgi saab lahenduse käivitada, saladusi repositooriumis ei ole | 20% |

## Töö esitamine

Repositooriumis on lahenduse failid, README ja kaust `logid/`, kus on vähemalt ühe eduka käivituse väljund. Repositooriumi lingi ja tähtaja näed Classroom 50-s.

## Lisaülesanded

??? example "1 · Triiv"
    Muuda serveris midagi käsitsi, näiteks lehe sisu, nii et server erineb koodis kirjeldatust. Näita esitlusel, kuidas Ansible'i korduv käivitus selle parandab ja mida tähendab siis kokkuvõttes `changed=1`.

??? example "2 · Kaks taset koos"
    Ühenda kaks taset: näiteks OpenTofu loob masina ja Ansible paigaldab sinna konteineri, mille konveier ehitas.
