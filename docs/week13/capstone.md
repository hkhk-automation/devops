# Capstone — Täielik tarnekonveier

**Kestus:** 4 tundi (grupitöö + esitlus)
**Grupid:** 2–3 inimest
**Eeldused:** Kõik eelnevad nädalad läbitud.

---

## 🎯 Ülesanne

Ehitage töötav automatiseerimislahendus otsast lõpuni ja esitlege seda.

Valige üks stsenaarium:

| Tase | Stsenaarium | Minimaalne kombinatsioon |
|---|---|---|
| Lihtne | Staatiline veebileht | Git + Ansible deploy Proxmox VMile |
| Keskmine | Flask app | Git + Docker + Compose + CI pipeline |
| Keeruline | Täisautomaatne | Git + Docker + CI/CD + GHCR + Ansible deploy |
| Edasijõudnud | Kõik + monitooring | Eelnev + Terraform + Grafana |

---

## Nõuded

Minimaalne kombinatsioon mis peab töötama:

- Versioonihalduse töövoog — branching + PR (nädal 2)
- Serveri konfiguratsioon — Ansible (nädal 3–4) VÕI infrastruktuur koodina (nädal 10–11)
- Üks järgnevatest: CI pipeline / Docker / Compose (nädalad 5–8)

**Nädal 9 võrdlustabel peab esitluses nähtav olema.**

---

## Esitlus — 7 minutit

- **5 min:** live demo + arhitektuuridiagramm
- **2 min:** küsimused kaasõpilastelt ja õpetajalt

Esitluses peate suutma vastata:

- Miks see tööriist siin ja mitte teine?
- Mis läheks katki esimesena kui üks komponent kukub?
- Näita pipeline ebaõnnestumist ja selle parandust

---

## Hindamine

| Kriteerium | Osakaal |
|---|---|
| Lahendus töötab live demo ajal | 50% |
| Arhitektuuridiagramm on selge ja täpne | 20% |
| Tööriistade valik on põhjendatud | 20% |
| Nädal 9 tabel on esitluses | 10% |

---

## 🚀 Lisaülesanne

Lisa Prometheus + Grafana monitooringu stack (nädal 12 materjal). Kaasa üks alert rule. Selgita esitluses: mis tähendaks see alert päriselus?
