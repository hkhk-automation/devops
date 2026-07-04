---
tags:
  - Automatiseerimine
  - Töökeskkond
  - SSH
  - GitHub
---

# Miks automatiseerimine? — Labor

**Kestus:** 4 tundi
**Eeldused:** GitHub konto olemas (vt [avaleht](../index.md) — "Enne esimest tundi"). Muud eelteadmist pole vaja.
**Kontroll-node:** sinu arvuti, kogu töö **VS Code'is**.
**Sihtmärk:** sinu valik (vt [Töökeskkond](../kodulabor.md)); kodus lokaalne, koolis Proxmox (õpetaja annab aadressi). Kodus ja koolis erineb ainult SSH-sihtmärk.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Kaardistad manuaalse deploy-protsessi ja näitad, kus see **vaikselt** katki läheb
    2. Lood SSH võtmepaari ja selgitad, kumb pool tohib maailmas ringi käia
    3. **Loed veateadet** `Permission denied (publickey)` ja tead, mida see päriselt ütleb
    4. Ühendud sihtmärgiga ilma paroolita — terminalist ja VS Code'ist
    5. Loendad kokku, mitu käsitsi sammu sa täna ise tegid — ja tead, mis nendega 13 nädala pärast juhtub

---

Labi loogika: **kaardista → seadista → viga → diagnoos → paranda.** Täna ei ole veel midagi automatiseerida — täna ehitad tööriistad ja õpid selle kursuse kõige tähtsama oskuse: **veateade ei ole karistus, veateade on vastus.** Sa tekitad esimese vea meelega juba täna.

---

## Osa 1 · Märteni reede õhtu — kaardista käsitsi deploy

Tutvu: **Märten**, praktikant. Reede, 16:47. Märten muudab ühte HTML-faili, kopeerib selle FTP-ga serverisse, sulgeb läpaka ja läheb nädalavahetusele. Esmaspäeval avastatakse, et pool lehte on maas — Märten kopeeris faili valesse kausta, ja mitte keegi, kaasa arvatud Märten, ei märganud midagi terve nädalavahetuse jooksul.

See kursus on 13 nädalat vastust küsimusele: **kuidas teha nii, et Märtenil oleks võimatu seda teha.** Mitte "Märten peab hoolsam olema" — hoolsus ei skaleeru. Süsteem peab vea kinni püüdma.

Aga enne kui saad automatiseerida, pead teadma, **mida** sa automatiseerid. Töötate 3-liikmelises rühmas ja kaardistate selle protsessi swimlane-diagrammina:

> Arendaja salvestab faili → kasutaja näeb muudatust brauseris.

Swimlane jagab protsessi osalejate järgi ribadeks — iga osaleja teeb oma samme, aeg liigub vasakult paremale:

```
Arendaja  | [    ] -> [    ] -> [    ]
Server    |             [    ] -> [    ]
Andmebaas |                        [    ]
Kasutaja  |                                 [näeb tulemust]
```

Kasutage trükitud A3-malli (jagab õpetaja) või joonistage paberile.

### Tööetapid

1. **Brainstorm (10 min)** — igaüks kirjutab iseseisvalt post-it'idele kõik sammud, mida teab või oskab ette kujutada. Üks samm = üks post-it. Ära filtreeri — "arendaja unustab salvestada" on ka samm.
2. **Rühmitamine (10 min)** — jagage sammud ribade vahel, otsustage koos järjekord. Vaidlus järjekorra üle on osa tööst — kui te ei tea, kumb enne käib, ei tea seda ilmselt ka Märten.
3. **Vigade märkimine (10 min)** — ringitage punasega sammud, mis **võivad vaikselt ebaõnnestuda**: viga juhtub, aga keegi ei saa kohe teada. Iga punase ringi juurde üks sõna: *kes* selle lõpuks avastab? (Vihje: kui vastus on "klient", on see kõige kallim variant.)
4. **Esitlus (2 min / rühm)** — mitu sammu kokku? Mitu punast? Milline ebaõnnestumine on kõige salakavalam?
5. **Klassi hääletus** — kõige ohtlikum vaikne viga võidab. See juhtum tuleb kursuse jooksul mitu korda tagasi.

??? question "Kui rühmal on raske alustada"
    Tüüpilised kohad, kus käsitsi deploy vaikselt katki läheb:

    - fail kopeeritakse valesse kausta (Märteni klassika)
    - konfiguratsioonimuudatus jääb ühes serveris rakendamata
    - server pole värskendatud, aga arendaja **arvab**, et on
    - vana versioon jääb cache'i — arendaja näeb uut, klient vana
    - andmebaasi migratsioon ununeb
    - kaks inimest muudavad sama faili, teise töö kaob vaikselt

??? question "Mõtle"
    Vaata oma diagrammi punaseid ringe. Mitu neist juhtub sellepärast, et **inimene peab midagi meeles pidama**? Mis on ühine kõigil sammudel, mida masin võiks teha inimese asemel?

---

## Osa 2 · VS Code — sinu kontrollpunkt

Kogu kursuse töö käib VS Code'ist: kood, terminal, hiljem ühendus serveritesse. Kui pole veel installitud: [code.visualstudio.com](https://code.visualstudio.com).

Ava laienduste paneel (`Ctrl+Shift+X` / `Cmd+Shift+X`) ja installi **ainult need kolm** — ülejäänud tulevad siis, kui vastav tööriist tuleb:

| Laiendus | Miks just nüüd |
|---|---|
| Remote - SSH | Täna — ühendus sihtmärgiga otse VS Code'ist |
| YAML (RedHat) | Nädal 3 — Ansible failid on YAML, süntaksiviga näed enne käivitamist |
| Markdown All in One | Kodutööd kirjutad Markdownis |

*Tabel 1.1. Esimese nädala laiendused. Docker, Terraform jt lisandvad omal nädalal.*

Kontroll — ava sisseehitatud terminal (`` Ctrl+` ``):

```bash
echo "töötab"
```

!!! tip
    Windowsil: kui terminal avaneb PowerShellina, on kõik selle labi käsud ikkagi samad — `ssh` ja `ssh-keygen` on Windows 10/11-s olemas. Kui `ssh` puudub, ütle õpetajale enne edasi minemist.

---

## Osa 3 · SSH võti — kaks poolt, üks reegel

Paroolid on nagu Märteni mälu: mõnikord töötab. SSH võtmepaar on kaks faili, mis matemaatiliselt kokku kuuluvad — **privaatvõti** jääb sinu masinasse ja ei liigu mitte kunagi mitte kuhugi, **avalik võti** on nagu visiitkaart, mida jagad serveritele ja GitHubile.

Kontrolli, kas võti on juba olemas:

```bash
ls ~/.ssh/
```

Kui näed `id_ed25519` ja `id_ed25519.pub` — võti on olemas, hüppa vaatamise juurde. Muidu loo:

```bash
ssh-keygen -t ed25519 -C "sinu.nimi@kooliemail"
```

Faili asukoht — Enter (vaikimisi). Passphrase — täna tühi, Enter kaks korda.

Vaata mõlemat poolt ja pane tähele vahet:

```bash
cat ~/.ssh/id_ed25519.pub
```

```bash
head -2 ~/.ssh/id_ed25519
```

Esimene on üks rida, algab `ssh-ed25519` — see läheb varsti GitHubi. Teine ütleb `BEGIN OPENSSH PRIVATE KEY` — kui see fail kunagi kuskile satub (chat, repo, screenshot), on võti surnud ja teed uue.

??? question "Mõtle"
    Server saab endale ainult sinu **avaliku** võtme. Kuidas ta siis üldse suudab kontrollida, et sisse logib just sina, mitte keegi, kes on sama avalikku võtit näinud? (Vastust ei pea täna teadma matemaatiliselt — piisab, kui sõnastad, kumb pool mida tõestab.)

---

## Osa 4 · Permission denied — esimene meelega viga

Nüüd kursuse tähtsaim harjutus. Proovi GitHubiga ühendust **enne**, kui oled võtme sinna lisanud:

```bash
ssh -T git@github.com
```

Esimesel korral küsib host'i kinnitust — `yes`. Ja siis:

```
git@github.com: Permission denied (publickey).
```

**Peatu. Ära paranda veel.** Loe see rida läbi nagu lause, mitte nagu müra:

- `git@github.com` — kellega sa rääkisid (kohale jõudsid, võrk töötab)
- `Permission denied` — ta ei lase sind sisse
- `(publickey)` — põhjus sulgudes: ta ootas avalikku võtit ja ei leidnud sobivat

Veateade ütles sulle täpselt, mis on puudu. Nii teevad seda kõik selle kursuse tööriistad — Ansible, Docker, GitHub Actions — ja 13 nädala jooksul on sinu esimene liigutus alati sama: **loe, mida ta ütles, alles siis liiguta kätt.**

**Paranda** — lisa avalik võti GitHubi:

1. Kopeeri `cat ~/.ssh/id_ed25519.pub` väljund (terve rida)
2. [github.com/settings/keys](https://github.com/settings/keys) → "New SSH key"
3. Title: `kursus-2026`, kleebi, "Add SSH key"

Ja kontrolli uuesti:

```bash
ssh -T git@github.com
```

```
Hi <sinunimi>! You've successfully authenticated...
```

Sama käsk, teine vastus — vahepeal muutus ainult see, et GitHub tunneb nüüd su avalikku võtit.

!!! tip
    Kui ikka `Permission denied` — kolm tavalist põhjust järjekorras: (1) kleepisid **privaat**võtme sisu, mitte `.pub` oma — GitHub keeldub sellest õigusega; (2) võti kleepus poolikult, rida peab algama `ssh-ed25519`; (3) lõid võtme teise nimega — `ssh -T git@github.com -i ~/.ssh/<failinimi>` ütleb, kas asi on selles.

??? question "Mõtle"
    `Permission denied (publickey)` ja "server ei vasta üldse" on täiesti erinevad vead — esimene tähendab, et kohale jõudsid, teine, et ei jõudnudki. Miks on see vahe diagnoosimisel kulla hinnaga? Kummal juhul on mõtet võtit kontrollida?

---

## Osa 5 · Sihtmärk — sinu esimene server

Nüüd päris masin. **Koolis:** õpetaja annab sulle Proxmox VM-i aadressi ja kasutaja. **Kodus:** sinu valitud Ubuntu (vt [Töökeskkond](../kodulabor.md)) — WSL2, lokaalne VM, pilv, ükskõik; ainus nõue on SSH ja sudo. Edaspidi tähistab `<kasutaja>@<sihtmärk>` sinu oma — see ongi see üks rida, mis kooli ja kodu vahel erineb.

Ühenda parooliga:

```bash
ssh <kasutaja>@<sihtmärk>
```

Host'i kinnitus — `yes`, siis parool. Sees? Vaata ringi ja tule tagasi:

```bash
whoami
hostname
uname -a
exit
```

Parool iga kord on Märteni-tase. Kopeeri oma avalik võti sihtmärgile:

```bash
ssh-copy-id <kasutaja>@<sihtmärk>
```

Küsib parooli **viimast** korda. Kontrolli:

```bash
ssh <kasutaja>@<sihtmärk>
```

Sisse ilma paroolita. Sama mehaanika mis GitHubiga — sinu avalik võti on nüüd sihtmärgi `~/.ssh/authorized_keys` failis. Vaata ise järele, kui oled sees:

```bash
cat ~/.ssh/authorized_keys
```

Seal on sinu võti — see sama rida, mille GitHubi kleepisid.

!!! tip
    `ssh-copy-id: command not found` (Windowsi PowerShell) — käsi käsitsi: `type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh <kasutaja>@<sihtmärk> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"`. Teeb täpselt sama asja, lihtsalt ilma mugavuskestata.

!!! tip
    Küsib ikka parooli pärast `ssh-copy-id`-d? Loe, **mida** ta küsib: kui küsimus on `Enter passphrase for key` — see pole serveri parool, vaid sinu võtme oma (panid Osa 3-s passphrase'i). Kui küsib `password:` — võti ei jõudnud kohale, jooksuta `ssh-copy-id` uuesti ja vaata väljundit lõpuni.

??? question "Mõtle"
    Sa said just serverisse ilma paroolita. Loenda: mitu käsitsi sammu kulus **ühe** masina usaldusseoseks (võti, copy-id, kontroll)? Nädal 3 tuleb Ansible, mis vajab täpselt sama SSH-ühendust — aga mis juhtub siis, kui masinaid on 50?

---

## Osa 6 · VS Code Remote-SSH — terminal jääb koju

Terminaliühendus töötab, aga failide muutmine serveris `nano`-ga on kannatus. Remote-SSH avab VS Code'i **otse sihtmärgi sees**:

1. `F1` (või `Ctrl+Shift+P`)
2. `Remote-SSH: Connect to Host` → "Add New SSH Host"
3. Sisesta `ssh <kasutaja>@<sihtmärk>`, salvesta pakutud konfifaili
4. Ühenda — avaneb uus aken, all vasakul roheline `SSH: <sihtmärk>`

Ava seal terminal (`` Ctrl+` ``) ja veendu, et oled õiges masinas:

```bash
hostname
```

See peab näitama **sihtmärgi** nime, mitte sinu arvutit. Kui näitab sinu arvutit — oled kohalikus aknas, mitte remote-aknas.

!!! tip
    Remote-SSH jääb "Setting up SSH host" peale kinni? Sihtmärk vajab esimesel korral internetti (laeb VS Code serveri-osa alla) ja veidi kannatust. Kui minuti pärast ikka midagi — `F1 → Remote-SSH: Kill VS Code Server on Host` ja uuesti.

---

## Osa 7 · Loenda oma sammud

Vaata tagasi tänasele. Sa tegid käsitsi: võtme loomine, GitHubi kleepimine, `ssh-copy-id`, Remote-SSH seadistus, laiendused... Kirjuta paberile või faili number: **mitu käsitsi sammu tänane seadistus kokku võttis?**

Nüüd pane see number oma Osa 1 swimlane'i kõrvale. Tänased sammud olid ühekordsed — aga Märteni deploy-sammud korduvad **iga muudatuse järel**. Selles on vahe: ühekordset seadistust talub, korduvat käsitsitööd mitte.

??? question "Mõtle"
    Nädal 13 lõpus teeb kogu Märteni swimlane'i ära `git push` — üksainus käsk. Vaata oma diagrammi ja ennusta: millised ribad kaovad täielikult, millised jäävad, aga teeb masin? Hoia diagramm alles — kontrollime nädal 13.

---

## Lõppkontroll — oskad ilma juhendita

- [ ] Swimlane valmis, punased ringid märgitud, teie rühma "kõige salakavalam viga" sõnastatud
- [ ] `ssh -T git@github.com` vastab `Hi <sinunimi>!`
- [ ] Selgitad, kumb võtmepool tohib liikuda ja kumb mitte kunagi
- [ ] `Permission denied (publickey)` nägemisel tead, mida see välistab ja mida ütleb
- [ ] `ssh <kasutaja>@<sihtmärk>` läheb sisse **ilma paroolita**
- [ ] VS Code Remote-SSH aknas `hostname` näitab sihtmärki
- [ ] Käsitsi sammude arv kirjas — nädal 13 võrdluseks

!!! warning
    Ära jäta ühtegi linnukest lahtiseks. Nädal 2 eeldab töötavat GitHubi-ühendust ja nädal 3 töötavat sihtmärki — küsi **täna**, mitte siis.

---

## Lisaülesanded (kui jõuad ette)

1. **Postmortem-jaht:** otsi üks päriselu juhtum, kus manuaalne samm põhjustas tootmisrikke. Kirjuta 3 lauset: mis juhtus, mis samm oli käsitsi, kuidas automatiseerimine oleks selle püüdnud. Hea allikas: [github.com/danluu/post-mortems](https://github.com/danluu/post-mortems). Hoia alles — nädal 9 tuled selle juurde tagasi.
2. **SSH config:** uuri `~/.ssh/config` faili — kuidas teha nii, et `ssh minu-server` asendaks tervet `ssh <kasutaja>@<sihtmärk>` rida? Remote-SSH juba kirjutas sinna midagi — loe, mida.
3. **Teine võti:** loo teine võtmepaar teise nimega (`-f ~/.ssh/proov`) ja proovi sellega sihtmärki — miks ta sisse ei saa, kuigi võti on korrektne? Mis käsurea lipp aitaks?

---

## Veaotsing

| Veateade / sümptom | Põhjus | Lahendus |
|---|---|---|
| `Permission denied (publickey)` GitHubis | Võti lisamata / kleebitud privaatvõti / poolik rida | Osa 4 — `.pub` sisu, terve rida |
| `Permission denied` sihtmärgil pärast `ssh-copy-id` | Võti ei jõudnud kohale või vale kasutaja | Jooksuta `ssh-copy-id` uuesti, loe väljund lõpuni |
| Küsib `Enter passphrase for key` | See on võtme, mitte serveri parool | Sisesta Osa 3 passphrase (või loo võti ilma) |
| `ssh: connect ... Connection refused/timed out` | Vale aadress, sihtmärk maas, võrk | Kontrolli aadressi; koolis küsi õpetajalt, kodus vt kodulabor.md |
| `ssh-copy-id: command not found` | Windows PowerShell | Osa 5 käsitsi-variant |
| `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED` | Sihtmärk ehitati uuesti, vana sõrmejälg mälus | `ssh-keygen -R <sihtmärk>` ja ühendu uuesti |
| Remote-SSH ei ühendu, terminal ühendub | VS Code serveri-osa install jäi kinni | `Kill VS Code Server on Host` ja uuesti; sihtmärgil peab olema internet |
| Remote-aknas `hostname` näitab oma arvutit | Oled kohalikus aknas | Vaata all vasakul rohelist `SSH:` märki |

*Tabel 1.2. Iga rida on viga, mida sa täna kohtad või varsti kohtaksid.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| GitHub SSH juhend | <https://docs.github.com/en/authentication/connecting-to-github-with-ssh> | Ametlik võtmete lisamine |
| ssh-keygen manuaal | <https://man.openbsd.org/ssh-keygen> | Võtmete loomine |
| VS Code Remote-SSH | <https://code.visualstudio.com/docs/remote/ssh> | Remote seadistus |
| danluu/post-mortems | <https://github.com/danluu/post-mortems> | Päris rikked, päris õppetunnid |
