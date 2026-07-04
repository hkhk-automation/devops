# Kodutöö - Projekti Lõpetamine

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

## Ülesanne 1: Kodutöö Eesmärk

Lõpeta oma automatiseerimise projekt ja dokumenteeri see professionaalselt. See on sinu võimalus näidata kõiki oskusi, mida oled kursuse jooksul õppinud.

---

## Ülesanne 2: Projekti Dokumenteerimine

### README.md Loomine

**Loo põhjalik README.md fail oma projekti jaoks:**

```markdown
# Minu Automatiseerimise Projekt

## Projekti Kirjeldus
[Kirjelda oma projekti üksikasjalikult:
- Millist probleemi see lahendab?
- Miks see on oluline?
- Mis oli su eesmärk?]

## Kasutatud Tehnoloogiad

Märgi ära kõik tehnoloogiad, mida kasutasid:

- [ ] **Git** - Versioonihaldus ja koostöö
- [ ] **Docker** - Konteinerimine ja pakendamine
- [ ] **Ansible** - Konfiguratsioonihaldus
- [ ] **Terraform** - Infrastruktuur kui kood
- [ ] **CI/CD** - Pidev integratsioon ja tarneahel
- [ ] **Muud:** [Nimeta täiendavad tööriistad]

## Projekti Struktuur
```bash
projekt/
├── README.md
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── ansible/
│   ├── playbook.yml
│   └── inventory/
├── terraform/
│   ├── main.tf
│   └── variables.tf
├── .github/
│   └── workflows/
└── docs/
```

## Kuidas Kasutada

### Eeltingimused
- Docker ja Docker Compose
- [Muud vajalikud tööriistad]

### Samm-sammulised Juhised
1. **Klooni repository:**
   ```bash
   git clone https://github.com/sinu-kasutajanimi/projekti-nimi.git
   cd projekti-nimi
   ```

2. **Käivita projekt:**
   ```bash
   # Lisa konkreetsed käsud
   ```

3. **Kontrolli tulemust:**
   ```bash
   # Kuidas kontrollida, et kõik töötab
   ```

## Projekti Tulemused

### Mida Õppisin
- [Konkreetsed oskused, mida omandatud]
- [Väljakutsed, millega silmitsi seisid]
- [Kuidas probleeme lahendasid]

### Järgmised Sammud
- [Kuidas saaks projekti edasi arendada]
- [Millised uued tehnoloogiad huvitavad]

## Autorid
- **Nimi:** [Sinu nimi]
- **Kursus:** Automatiseerimine
- **Aasta:** 2025
```text

---

## Ülesanne 3: GitHub Repository Seadistamine

### Repository Loomine

**Loo GitHub repository ja seadista see õigesti:**

```bash
# 1. Loo uus repository GitHubis (läbi veebiliidese)
# 2. Klooni see kohalikku arvutisse
git clone https://github.com/sinu-kasutajanimi/projekti-nimi.git
cd projekti-nimi

# 3. Kopeeri oma projektifailid kausta
# 4. Lisa failid Git'i
git add .
git commit -m "Algne projekti import"

# 5. Push'i GitHubi
git push origin main
```text

### Vajalikud Failid

**Veendu, et sul on järgmised failid:**

1. **README.md** - Projekti dokumentatsioon
2. **.gitignore** - Eiratavad failid
3. **LICENSE** - Litsentsi info (valikuline)

**.gitignore näide:**
```gitignore
# Docker
*.log
.env

# Terraform
*.tfstate
*.tfstate.backup
.terraform/

# Ansible
*.retry

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
```bash

---

## Ülesanne 4: Projekti Esitlus

### Esitluse Ettevalmistus

**Valmista ette 3-5 minutiline esitlus, mis sisaldab:**

#### Slaid 1: Projekti Tutvustus
- Projekti nimi ja eesmärk
- Põhiline funktsioon

#### Slaid 2: Tehnilised Lahendused
- Kasutatud tehnoloogiad
- Arhitektuuri ülevaade
- Huvitavamad lahendused

#### Slaid 3: Väljakutsed ja Õppimine
- Suurimad raskused
- Kuidas neid lahendasid
- Peamised õppetunnid

#### Slaid 4: Demo
- Lühike näidis projekti tööst
- Ekraanipildid või reaalajas demo

#### Slaid 5: Järgmised Sammud
- Kuidas projekti edasi arendada
- Uued tehnoloogiad, mida tahaksid õppida

### Esitluse Nõuanded
- **Näita koodi** - ära ainult räägi sellest
- **Valmista demo ette** - testi enne esitlust
- **Ole uhke** - sa oled palju õppinud!
- **Jaga kogemusi** - mis oli raske, mis lihtne?

---

## Ülesanne 5: Projekti Hindamine

### Kontroll-loend

**Kontrolli enne esitamist:**

#### Tehniline Pool
- [ ] Kõik kood on GitHubis
- [ ] README.md on täielik ja selge
- [ ] Projekt käivitub juhiste järgi
- [ ] Kõik kasutatud tehnoloogiad on dokumenteeritud

#### Dokumentatsioon
- [ ] Projekti eesmärk on selgelt kirjeldatud
- [ ] Paigaldamise juhised on olemas
- [ ] Kasutamise näited on lisatud
- [ ] Õppetunnid on dokumenteeritud

#### Esitlus
- [ ] Slaidid on valmis
- [ ] Demo on testitud
- [ ] Aeg on planeeritud (3-5 minutit)

### Hinne Kujuneb
- **60%** - Projekti funktsioon ja tehniline kvaliteet
- **25%** - Dokumentatsiooni kvaliteet
- **15%** - Esitluse selgus ja ettevalmistus

---

## Ülesanne 6: Järgmised Sammud

### Õppimise Jätkamine

**Soovitatavad järgmised sammud:**

#### Tehnoloogiate Süvendamine
1. **Kubernetes** - konteinerite orkestratsioon
2. **Monitoring** - Prometheus, Grafana
3. **Security** - turvaliste praktikate õppimine
4. **Cloud Platforms** - AWS, Azure, GCP

#### Praktilised Projektid
1. **Microservices arhitektuur** - mitme teenuse haldamine
2. **Infrastructure as Code** - täielik automatiseerimine
3. **GitOps** - Git-põhine töövoog
4. **Chaos Engineering** - süsteemi vastupidavuse testimine

#### Kogukond ja Võrgustik
1. **GitHub** - panusta avatud lähtekoodiga projektidesse
2. **DevOps Estonia** - kohalik kogukond
3. **Konverentsid** - DevOpsDays, KubeCon
4. **Sertifikaadid** - AWS, Azure, Kubernetes

### Karjääri Areng

**DevOps rollidega tutvumine:**
- **DevOps Engineer** - automatiseerimine ja infrastruktuur
- **Site Reliability Engineer** - süsteemi usaldusväärsus
- **Platform Engineer** - arendajate platformide loomine
- **Cloud Architect** - pilvelahenduste disain

---

## Kokkuvõte

**Palju õnne! Oled edukalt lõpetanud automatiseerimise kursuse!**

### Mida Sa Nüüd Oskad
- **Git** - versioonihaldus ja koostöö
- **Docker** - rakenduste pakendamine
- **Ansible** - serverite konfigureerimine  
- **Terraform** - infrastruktuuri kood
- **CI/CD** - automaatne testimine ja rakendamine

### Su Järgmised Võimalused
- **Jätka õppimist** - tehnoloogiad arenevad kiiresti
- **Ehita projekte** - praktika on parim õpetaja
- **Võta osa kogukonnast** - jaga kogemusi ja õpi teistelt
- **Otsi praktikat** - rakenda oskusi päriselu projektides

**Edu edasistel DevOps teekondadel!** 🚀

---

## Lisaressursid

### Dokumentatsioon
- [Git dokumentatsioon](https://git-scm.com/docs)
- [Docker dokumentatsioon](https://docs.docker.com/)
- [Ansible dokumentatsioon](https://docs.ansible.com/)
- [Terraform dokumentatsioon](https://www.terraform.io/docs)

### Kogukond
- [DevOps Estonia](https://devops.ee/)
- [GitHub Estonia](https://github.com/estonia)
- [Slack kogukond](https://devopsestonia.slack.com/)

### Kursuse Materjalid
- [Kursuse veebileht](https://mtalvik.github.io/automation)
- [GitHub repository](https://github.com/mtalvik/automation)
