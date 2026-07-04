<div class="hero-section" markdown>
<div class="hero-content" markdown>
# IT Automatiseerimine

13 nädalaga õpid automatiseerima kõike, mida täna teed käsitsi. Kutsekooli 3. aasta esimene automatiseerimiskursus.

[Alusta kursusega](week01/lecture.md){ .btn-primary }
[13 nädala ülevaade](#programm){ .btn-secondary }
</div>
</div>

## Mida sa õpid

1. Jälgida koodimuudatusi meeskonnas ja mitte kunagi kaotada tööd
2. Seadistada servereid automaatselt — ühe käsuga, mitte käsitsi klikkides
3. Pakkida rakendus konteinerisse ja käivitada see kõikjal
4. Ehitada pipeline, mis testib ja levitab koodi automaatselt iga muudatuse järel
5. Kirjeldada infrastruktuuri koodina — server on alati täpselt selline nagu peab
6. Näha ja hallata infrastruktuuri koodina — üks playbook, mitu serverit, kõik versioonis

---

## Programm

| # | Teema | Tööriistad |
|---|---|---|
| N1 | Miks automatiseerimine? | — |
| N2 | Muudatuste jälgimine meeskonnas | Git, GitHub |
| N3 | Serveri konfiguratsiooni automatiseerimine | Ansible |
| N4 | Dünaamiline konfiguratsioon ja saladuste kaitse | Ansible Vault, Jinja2 |
| N5 | Rakenduse pakkimine ja ümberpaigutamine | Docker |
| N6 | Mitme teenuse käitamine koos | Docker Compose |
| N7 | Automaatne testimine ja tarnekonveier | GitHub Actions CI |
| N8 | Automaatne ehitamine ja levitamine | GitHub Actions CD, GHCR |
| N9 | Infrastruktuur koodina — mõtteviis *(iseseisev)* | — |
| N10 | Infrastruktuuri kirjeldamine koodina | Terraform |
| N11 | Korduvkasutatav infrastruktuur | Terraform moodulid / Ansible rollid |
| N12 | Infrastruktuur koodina — Ansible IaC | Ansible, group_vars |
| N13 | Täielik tarnekonveier — otsast lõpuni | Kõik tööriistad |

---

## Enne esimest tundi

**1. GitHub konto** — kasuta kooli e-maili: [github.com](https://github.com). Konto kasutajanimi ja repod käivad kujul **eesnimiperekonnanimi** (nt `mariatalvik`) — nii leiab õpetaja need organisatsioonis üles.

**2. GitHub Education Pack** — kooli e-mailiga tasuta, taotlemine võtab 1–2 päeva, tee kohe:
[education.github.com/pack](https://education.github.com/pack)

**3. VS Code** — [code.visualstudio.com](https://code.visualstudio.com)

Laiendused installime kursuse käigus — ära paigalda praegu midagi ette.

**4. Töökeskkond** — koolis saad Proxmox VM-i, kodus vajad oma Ubuntu sihtmärki (WSL2, VM või pilv — sinu valik). Ainus nõue: SSH ja sudo. Vt [Töökeskkond](kodulabor.md).

---

## Hindamine

| Komponent | Osakaal |
|---|---|
| Nädalased kodutööd (N2–N12) | 60% |
| N13 capstone esitlus | 30% |
| Aktiivsus ja osalemine | 10% |

Kõik kodutööd esitatakse GitHubis pull request'ina. Tähtajad on nädalavahetuse lõpp (pühapäev 23:59).
