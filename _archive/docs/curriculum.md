# IT Automatiseerimise Kursuse Õppekava

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**8 Moodulit**

---

## Kursuse Ülevaade

Kaasaegse DevOps automatiseerimise praktikad ja tööriistad. Kursus katab versioonihaldusest kuni orkestratsioonini - kõik vajalik infrastruktuuri automatiseerimiseks.

**Kursuse eesmärgid:**
- Praktiline kogemus olulisemate automatiseerimise tööriistadega
- Projektipõhine õppimine reaalse infrastruktuuri näidetel
- Tööstuse standardid ja parimad praktikad
- Iseseisev probleemilahendamine ja dokumenteerimine

---

## Kursuse Struktuur

| Moodul | Teema | Kontakt | Kodutöö 1 | Kodutöö 2 |
|--------|-------|---------|------------|-----------|
| **1** | **Git Versioonihaldus** | 4h | Git projekti portfoolio | Git sisemused ja edasijõudnud kontseptsioonid |
| **2** | **Ansible Alused** | 4h | LAMP stack playbook (Vagrant) | - |
| **3** | **Docker Alused** | 4h | Süsteemi monitoring dashboard | - |
| **4** | **Docker Orkestratsioon** | 4h | Full-stack rakendus (4 teenust) | 12-factor app analüüs |
| **5** | **Ansible Edasijõudnud** | *Iseseisvad laborid* | Apache + Vault + Jinja2 | - |
| **6** | **Ansible Rollid** | *Iseseisvad laborid* | Multi-tier infrastruktuur | Ansible vs Puppet võrdlus |
| **7** | **Terraform Alused** | 2h | Kohalik infrastruktuur | Moodulid ja korduvkasutus |
| **8** | **CI/CD + Kubernetes** | 2h | Projekti lõpetamine | - |

---

## Moodulite Detailsed Kirjeldused

### 1️⃣ **Git Versioonihaldus** (4h)

**Õpieesmärgid:**
- Versioonihalduse kontseptsioonid ja töövoog
- Meeskonnatöö Git'iga (harude strateegia, merge conflicts)
- GitHub töövoog (Pull Requests, Issues, projektihaldus)
- Edasijõudnud Git funktsioonid

**Praktilised teemad:**
- Git seadistamine ja SSH võtmed
- Repositooriumide loomine ja kloneerimine
- Harude loomine, ühendamine, konfliktide lahendamine
- GitHub collaboration workflow
- Git hooks ja submodules (boonus)

**Kodutööd:**
- **HW1:** Täielik Git projekti portfoolio harude töövooga
- **HW2:** Git ajalugu, sisemused ja edasijõudnud kontseptsioonide lugemine

---

### 2️⃣ **Ansible Alused** (4h)

**Õpieesmärgid:**
- Ansible arhitektuur ja SSH põhised automatiseerimise kontseptsioonid
- Kohalik testimiskeskkond Vagrant'iga
- Inventory haldamine ja ad-hoc käsud
- Esimeste playbook'ide loomine

**Praktilised teemad:**
- Ansible installatsioon ja SSH konfiguratsioon
- Vagrant/VirtualBox testimiskeskkond
- YAML süntaks ja playbook struktuur
- Moodulid: package, service, file, template
- Veakäsitlus ja debug

**Kodutööd:**
- **HW1:** LAMP Stack Playbook Vagrant keskkonnas (Apache, MySQL, PHP)

---

### 3️⃣ **Docker Alused** (4h)

**Õpieesmärgid:**
- Konteineritehnoloogia mõistmine vs VM'id
- Docker lifecycle ja CLI oskused
- Dockerfile loomine ja optimeerimine
- Volume'id, networking ja turvalisus

**Praktilised teemad:**
- **Loeng 1 (2h):** Docker installatsioon, põhikäsud, lihtne Dockerfile
- **Loeng 2 (2h):** Dockerfile optimeerimine, networking, Podman alternatiiv

**Detailsed teemad:**
- Container lifecycle (create, start, stop, remove)
- Dockerfile best practices ja mitmeetapiline ehitus
- Docker networking (bridge, host, none)
- Volume'ide kasutamine andmete säilitamiseks
- Podman vs Docker võrdlus

**Kodutööd:**
- **HW1:** Süsteemi oleku monitoring dashboard (Docker + Podman)

---

### 4️⃣ **Docker Orkestratsioon** (4h)

**Õpieesmärgid:**
- Mitme-konteineriga rakenduste orkestratsioon
- Docker Compose süntaks ja parimad praktikad
- Keskkonnaspetsiifilised konfiguratsioonid
- Service discovery ja networking

**Praktilised teemad:**
- Docker Compose YAML struktuur
- Service'ide defineerimine ja sõltuvused
- Environment variables ja secrets
- Volume'ide jagamine service'ide vahel
- Load balancing ja health checks

**Kodutööd:**
- **HW1:** Full-stack rakendus (frontend, backend, andmebaas, cache)
- **HW2:** 12-factor app analüüs - võrdle oma projekti printsiipidega

---

### 5️⃣ **Ansible Edasijõudnud** (Iseseisvad Laborid)

**Õpieesmärgid:**
- Edasijõudnud playbook struktuurid
- Muutujad, Jinja2 mallid ja conditional logic
- Ansible Vault saladuste turvaliseks haldamiseks
- Error handling ja rollback strateegiad

**Iseseisvad laborid:**
- **Labor 1:** Muutujad ja Jinja2 mallide labor
- **Labor 2:** Handlers ja error handling labor  
- **Labor 3:** Ansible Vault turvalisuse labor
- **Labor 4:** Multi-environment deployment patterns

**Kodutööd:**
- **HW1:** Apache veebiserver Vault'iga ja Jinja2 mallidega

---

### 6️⃣ **Ansible Rollid** (Iseseisvad Laborid)

**Õpieesmärgid:**
- Ansible rollide struktuur ja parimad praktikad
- Ansible Galaxy kogukonna rollide kasutamine
- Multi-OS tugi ja input validation
- Puppet vs Ansible konfiguratsiooni haldamise võrdlus

**Iseseisvad laborid:**
- **Labor 1:** Vagrant testing environment setup
- **Labor 2:** Role creation samm-sammuline juhend
- **Labor 3:** Ansible Galaxy integration
- **Labor 4:** Puppet fundamentals ja võrdlusharjutus

**Kodutööd:**
- **HW1:** Multi-tier infrastruktuur (veebiserver + andmebaas)
- **HW2:** Ansible vs Puppet võrdlev analüüs - sama infrastruktuur mõlema tööriistaga

---

### 7️⃣ **Terraform Alused** (2h)

**Õpieesmärgid:**
- Infrastructure as Code põhimõtted
- HCL (HashiCorp Configuration Language) süntaks
- State'i haldamine ja lifecycle
- Moodulid ja korduvkasutatavus

**Praktilised teemad:**
- Terraform installatsioon ja seadistamine
- Kohalik provider (failisüsteemi haldamine)
- Muutujad, outputs ja funktsioonid
- Count ja for_each tsüklid
- Moodulite loomine ja kasutamine

**Kodutööd:**
- **HW1:** Terraform põhitõed - kohalik infrastruktuur muutujatega
- **HW2:** Terraform moodulid ja korduvkasutus - projekti generaator

---

### 8️⃣ **CI/CD + Kubernetes** (2h)

**Õpieesmärgid:**
- Ettevõtte-tasemel DevOps pipeline'id
- Kubernetes põhikontseptsioonid ja deployment'id
- Turvalisus ja monitooring pipeline'ides
- Projekti integratsioon ja dokumenteerimine

**Praktilised teemad:**
- **CI/CD (1h):** GitLab CI/CD, pipeline arhitektuur, turvaskaneerimine
- **Kubernetes (1h):** Minikube, pod'id, deployment'id, service'id

**Detailsed teemad:**
- Multi-stage pipeline konfiguratsioon
- Docker image optimeerimine ja turvaskaneerimine
- Kubernetes objektid: ConfigMap, Secret, Health checks
- Rolling updates ja service discovery

**Kodutööd:**
- **HW1:** Projekti lõpetamine ja professionaalne dokumenteerimine

---

## Tehnilised Eeldused

### Tarkvara Nõuded:
- **Git** (versioonihaldus)
- **Docker Desktop** (konteinerid)
- **VirtualBox/VMware** (virtualisatsioon)
- **Vagrant** (VM haldamine)
- **Ansible** (konfiguratsiooni haldamine)
- **Terraform** (infrastruktuuri kood)
- **kubectl + Minikube** (Kubernetes)

### Opsüsteemi Tugi:
- **Windows:** WSL2 + Docker Desktop
- **macOS:** Homebrew + Docker Desktop
- **Linux:** Native tools

### Seadistamise Juhendid:
- [Windows Setup Guide](docker_orchestration/kodu_masina_ehitus_juhend.md#windows-setup)
- [Linux/macOS Setup Guide](docker_orchestration/kodu_masina_ehitus_juhend.md)

---

## Failide Organisatsioon

### Standardne Mooduli Struktuur:
```text
moodul_nimi/
├── lecture.md              # Põhiline loengumaterjal
├── lab.md                  # Praktilised harjutused ja laborid
├── homework.md             # Praktiline ülesanne (HW1)
└── reading_materials.md    # Lugemismaterjalid (HW2)
```

### Erisused:

**Docker (kaheks jaotatud):**
```bash
docker_fundamentals/
├── lecture1.md             # Docker alused - osa 1
├── lecture2.md             # Docker alused - osa 2
├── lab.md                  # Praktilised harjutused
└── homework.md             # Praktiline ülesanne
```

**Terraform (kaks kodutööd):**
```bash
terraform_basics/
├── lecture.md              # Terraform loeng
├── lab.md                  # Praktilised harjutused  
├── homework1.md            # Terraform põhitõed
├── homework2.md            # Terraform moodulid
└── homework_aws_backup.md  # AWS backup (boonus)
```

**Kubernetes + CI/CD (kaks laborit):**
```text
kubernetes_overview/
├── lecture.md              # Kubernetes + CI/CD ülevaade
├── lab1.md                 # Kubernetes labor - põhialused
├── lab2.md                 # Kubernetes labor - intermediate
└── homework.md             # Lõpuprojekt
```

---

## Hindamise Süsteem

### Hindamise Kriteeriumid:

| Komponent | Osakaal | Kirjeldus |
|-----------|---------|-----------|
| **Praktilised Ülesanded** | 70% | Kodutööd ja laborid (tehniline korrektsus) |
| **Lugemismaterjalid** | 15% | Analüüsid ja reflektsioonid (mõistmine) |
| **Lõpuprojekt** | 10% | Kõigi tööriistade integratsioon |
| **Osalus** | 5% | Aktiivsus ja küsimused |

### Hindeskaalad:
- **A (90-100%):** Erakordne töö, innovatiivsed lahendused
- **B (80-89%):** Hea töö, kõik nõuded täidetud
- **C (70-79%):** Rahuldav töö, põhinõuded täidetud
- **D (60-69%):** Nõrk töö, osalised puudused
- **F (<60%):** Mittearvestatud

### Portfoolio Nõuded:
- **GitHub repositoorium** kõigi ülesannetega
- **README.md** kursuse kokkuvõttega
- **Dokumenteeritud kood** ja konfiguratsioonid
- **Troubleshooting logi** leitud probleemidest

---

## Kursuse Tulemusnäitajad

### Tehnilised Oskused:
- **Git workflow** meeskonnatöös
- **Ansible automation** server konfiguratsioonideks
- **Docker containerization** rakenduste jaoks
- **Infrastructure as Code** Terraform'iga
- **CI/CD pipeline'id** automaatseks deployment'iks
- **Kubernetes basics** orkestratsiooniks

### Praktiline Kogemus:
- **Multi-tier rakenduste** deployment
- **Turvalisuse parimad praktikad** 
- **Monitoring ja logging** seadistamine
- **Troubleshooting** ja veakäsitlus
- **Dokumenteerimine** ja knowledge sharing

### Karjääri Ettevalmistus:
- **DevOps Engineer** positsioonideks
- **Cloud Infrastructure** rollideks  
- **Site Reliability Engineer** (SRE) oskusteks
- **Automation Specialist** töödeks
