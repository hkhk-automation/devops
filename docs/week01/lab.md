---
tags:
  - Automatiseerimine
  - Töökeskkond
  - SSH
  - GitHub
---

# Praktikum — Miks automatiseerimine?

**Kestus:** 4 tundi
**Tase:** Sissejuhatav
**Täna:** kaardistame manuaalse protsessi, leiame valupunktid, seadistame töökeskkonna.

---

## Osa 1 · Manuaalse protsessi kaardistamine (rühmatöö)

Töötate 3-liikmelises rühmas. Kaardistage see protsess **swimlane-diagrammina**:

> Arendaja salvestab faili → kasutaja näeb muudatust brauseris.

Mõelge kõigile sammudele selle teekonna vahel. Ärge hüpake lahenduse juurde — esmalt kaardistage, mis manuaalses töövoos *tegelikult* juhtub.

Swimlane jagab protsessi osalejate järgi "ribadeks" — iga osaleja teeb oma samme, aeg liigub vasakult paremale. Teie diagrammis on neli riba. Kasutage trükitud A3-malli (jagab õpetaja) või joonistage paberile:

```
Arendaja  | [    ] -> [    ] -> [    ]
Server    |             [    ] -> [    ]
Andmebaas |                        [    ]
Kasutaja  |                                 [näeb tulemust]
```

### Tööetapid

1. **Brainstorm (5 min)** — igaüks kirjutab iseseisvalt post-it'idele kõik sammud mida teab. Üks samm = üks post-it.
2. **Rühmitamine (5 min)** — jagage sammud ribade vahel, otsustage koos järjekord.
3. **Vigade märkimine (5 min)** — ringige punasega sammud, mis **võivad vaikselt ebaõnnestuda** — kus viga juhtub, aga keegi ei märka kohe.
4. **Esitlus (2 min / rühm)** — mitu sammu kokku? Millised tundusid kõige ohtlikumad?
5. **Klassi hääletus** — milline ebaõnnestumine on kõige ohtlikum?

??? question "Kui rühmal on raske alustada"
    Tüüpilised sammud manuaalses deploy'is, kus asi vaikselt katki läheb:

    - arendaja kopeerib faili käsitsi serverisse
    - konfiguratsioonimuudatus jääb rakendamata
    - server pole värskendatud, aga arendaja arvab et on
    - vana versioon jääb cache'i
    - andmebaasi migratsioon ununeb

---

## Osa 2 · Töökeskkonna seadistamine

Seadistame tööriistad, mida kogu kursuse vältel kasutame. Tee sammud ükshaaval — kui midagi ei tööta, küsi kohe.

### 2.1 GitHub Education Pack

GitHub Student Developer Pack annab tasuta ligipääsu tööriistadele mida ettevõtted kasutavad (GitHub Pro, Copilot, domeenid jne).

1. Mine [education.github.com/pack](https://education.github.com/pack)
2. "Sign up for Student Developer Pack"
3. Logi sisse GitHubi kontoga (loo konto kui pole)
4. Vali "Student", sisesta oma **kooliemail**
5. Laadi üles õpilastõend (õpilaspilet vms)
6. Oota heakskiitu — tavaliselt 1–3 tööpäeva

!!! warning
    Kasuta **kooliemaili**, mitte isiklikku — tavalise emailiga heakskiit tõenäoliselt ei tule. Pärast heakskiitu näed profiilil "Pro" märget.

### 2.2 VS Code

1. Mine [code.visualstudio.com](https://code.visualstudio.com), laadi alla, installi
2. Ava laienduste paneel: `Ctrl+Shift+X` (Win/Linux) või `Cmd+Shift+X` (Mac)
3. Otsi ja installi:

| Laiendus | Miks |
|---|---|
| YAML (RedHat) | GitHub Actions ja Ansible failid on YAML |
| HashiCorp Terraform | Terraform konfiguratsioonid |
| Docker | Dockerfile'ide tugi |
| Remote - SSH | Proxmox VM-iga ühendus otse VS Code'ist |
| GitLens | Git ajalugu redaktoris |
| Markdown All in One | Kursusematerjalide lugemine/kirjutamine |

*Tabel 1.1. Kursuse VS Code laiendused.*

Kontroll: ava terminal (`` Ctrl+` ``) — peaksid nägema terminaliakent.

### 2.3 SSH võti

SSH võti on turvalisem kui parool. Loome ühe korra, kasutame kogu kursuse.

Kontrolli kas võti juba olemas:

```bash
ls ~/.ssh/
```

Kui näed `id_ed25519` ja `id_ed25519.pub` — võti on olemas, mine 2.4 juurde. Muidu loo:

```bash
ssh-keygen -t ed25519 -C "sinu.nimi@kooliemail"
```

Faili nimi — Enter (vaikimisi `~/.ssh/id_ed25519`). Passphrase — võib tühjaks jätta, Enter kaks korda.

Vaata avalikku võtit:

```bash
cat ~/.ssh/id_ed25519.pub
```

### 2.4 SSH võti GitHubi

1. [github.com/settings/keys](https://github.com/settings/keys) → "New SSH key"
2. Nimi: `kursus-2026`
3. Kleebi `id_ed25519.pub` sisu → "Add SSH key"

Kontroll:

```bash
ssh -T git@github.com
```

Peaks vastama: `Hi <sinunimi>! You've successfully authenticated...`

### 2.5 Ühendus Proxmox VM-ile

Proxmox on virtuaalserverite keskkond serveritöö harjutamiseks. Õpetaja on VM-i juba loonud ja annab sulle IP ja kasutajanime.

```bash
ssh student@192.168.1.XX
```

Esimesel korral küsib kinnitust — `yes`. Kopeeri võti VM-ile, et parooli enam ei küsitaks:

```bash
ssh-copy-id student@192.168.1.XX
```

Küsib parooli ühe korra. Kontrolli et pääsed nüüd ilma paroolita:

```bash
ssh student@192.168.1.XX
whoami
hostname
uname -a
```

### 2.6 VS Code Remote-SSH

Nüüd saad ühenduda VM-ile otse VS Code'ist:

1. `F1` või `Ctrl+Shift+P`
2. `Remote-SSH: Connect to Host` → "Add New SSH Host"
3. Sisesta `ssh student@192.168.1.XX`, salvesta konfiguratsioon
4. Ühenda

VS Code avaneb uuesti, all paremal näed `SSH: 192.168.1.XX` — oled VM-is.

---

## Lõppkontroll

- [ ] Swimlane-diagramm valmis ja esitletud
- [ ] GitHub konto olemas
- [ ] Education Pack taotlus esitatud
- [ ] VS Code + laiendused installitud
- [ ] SSH võti loodud ja GitHubi lisatud
- [ ] SSH ühendus Proxmox VM-iga töötab ilma paroolita
- [ ] VS Code Remote-SSH ühendus töötab

!!! warning
    Ära jäta lahendamata. Küsi õpetajalt kohe — järgmisel nädalal on kõik need tööriistad vaja.

---

## Lisaülesanne (ette jõudnutele)

Otsi üks päriselu juhtum, kus manuaalne samm põhjustas tootmisrikke. Kirjuta 3 lauset: mis juhtus, mis samm oli manuaalne, kuidas automatiseerimine oleks selle ära hoidnud.

Otsingud: `deployment failure human error postmortem`, `site reliability incident manual step`. Hea allikas: [github.com/danluu/post-mortems](https://github.com/danluu/post-mortems).

Hoia see alles — nädal 9 (IaC-mõtteviis) tuled selle juurde tagasi.
