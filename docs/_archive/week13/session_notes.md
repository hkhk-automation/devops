# Nädal 13 - Täielik tarnekonveier: otsast lõpuni (Capstone)

> **Eelmine nädal:** Nähtavus - Prometheus ja Grafana.
> **Täna:** Ehitate täieliku automatiseerimislahenduse ja esitlete seda.

## Nõuded

Grupid 2-3 inimest.

Minimaalne kombinatsioon:
- Versioonihalduse töövoog (branching + PR)
- Serveri konfiguratsioon (Ansible) VÕI infrastruktuur koodina (Terraform)
- Üks: pipeline / konteinerid / Compose

## Stsenaariumid - vali üks

1. Lihtne: Staatiline veebileht - Git + Ansible deploy Proxmox VMile
2. Keskmine: Flask app - Git + Docker + Compose + CI pipeline
3. Keeruline: Git + Docker + CI/CD + GHCR + Ansible deploy
4. Edasijõudnud: Kõik eelnev + Terraform VM provisioning + Grafana monitooring

## Esitlus (7 minutit)

- 5 min: live demo + arhitektuuridiagramm
- 2 min: küsimused kaasõpilastelt ja õpetajalt

Nädal 9 võrdlustabel peab esitluses nähtav olema.

## Hindamiskriteeriumid

- Miks see tööriist siin ja mitte see teine?
- Mis läheks katki esimesena kui üks komponent kukub?
- Näita pipelini ebaõnnestumist ja selle parandust

## Venitusülesanne

Lisa Prometheus + Grafana monitoorimise stack (nädal 12 materjal).
Kaasa üks alert rule. Selgita esitluses: mis tähendaks see alert päriselus?
