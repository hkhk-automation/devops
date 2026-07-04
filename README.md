# IT automatiseerimise kursus

Serverite ja rakenduste automatiseerimine — Git'ist infrastruktuurini koodina. Kutsekooli 3. aasta esimene automatiseerimiskursus, 13 nädalat.

[Veebileht](https://hkhk-automation.github.io/devops)

## Sisukord

- [Teemad](#teemad)
- [Kohalik seadistamine](#kohalik-seadistamine)
- [Ajakava](#ajakava)
- [Repo struktuur](#repo-struktuur)
- [Publitseerimine](#publitseerimine)
- [Litsents](#litsents)

## Teemad

- Git versioonihaldus ja meeskonnatöö
- Ansible — serverite konfiguratsioon, muutujad, Vault, rollid
- Docker ja Docker Compose
- CI/CD — GitHub Actions, GHCR
- Infrastruktuur koodina — Terraform, Ansible IaC

## Kohalik seadistamine

```bash
git clone https://github.com/hkhk-automation/devops.git
cd devops
pip install -r requirements.txt
mkdocs serve
```

Ava brauser: <http://127.0.0.1:8000>

## Ajakava

| Nädal | Teema | Tööriistad |
|---|---|---|
| N1 | Miks automatiseerimine? | — |
| N2 | Muudatuste jälgimine meeskonnas | Git, GitHub |
| N3 | Serveri konfiguratsiooni automatiseerimine | Ansible |
| N4 | Dünaamiline konfiguratsioon ja saladuste kaitse | Ansible Vault, Jinja2 |
| N5 | Rakenduse pakkimine | Docker |
| N6 | Mitme teenuse käitamine koos | Docker Compose |
| N7 | Automaatne testimine | GitHub Actions CI |
| N8 | Automaatne ehitamine ja levitamine | GitHub Actions CD, GHCR |
| N9 | Infrastruktuur koodina — mõtteviis *(iseseisev)* | — |
| N10 | Infrastruktuuri kirjeldamine koodina | Terraform |
| N11 | Korduvkasutatav infrastruktuur | Terraform moodulid / Ansible rollid |
| N12 | Infrastruktuur koodina — Ansible IaC | Ansible, group_vars |
| N13 | Täielik tarnekonveier — otsast lõpuni | Kõik tööriistad |

## Repo struktuur

```
docs/
├── index.md              # Avaleht
├── kodulabor.md          # Töökeskkonna seadistus
├── litsents.md           # Litsents
├── week01/ ... week13/   # Nädalate materjalid
│   ├── lecture.md        # Loeng (teooria)
│   ├── lab.md            # Praktikum (käed külge)
│   └── homework.md       # Kodutöö (osal nädalatel)
└── _archive/             # Arhiveeritud materjal (ei ehitata)
planning/                 # Koolitaja-juhendid (ajad, riskid)
```

Erandid: N9 on `async_task.md`, N11 on Terraform + Ansible variandid, N13 on `capstone.md`.

## Publitseerimine

Automaatne juurutamine GitHub Actions'iga peale iga `main`-push'i. Käsitsi:

```bash
mkdocs gh-deploy
```

## Litsents

CC BY-SA 4.0 — Maria Talvik. Vt [litsents](docs/litsents.md).
