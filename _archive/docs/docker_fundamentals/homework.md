# Docker Kodutöö: Süsteemi Oleku Dashboard

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Tähtaeg:** Järgmise nädala alguseks  
**Eesmärk:** Õppida Docker ja Podman container'ite kasutamist praktikas  

**Te saate valmis veebisaidi - keskenduge container tehnoloogiate õppimisele!**

---

## Ülesanne 1: Projekti ülevaade

**Mida see dashboard teeb:**
- Näitab container informatsiooni
- Kuvab serveri olekut
- Võimaldab testida connectivity
- Eristab Docker vs Podman deployment

**Mida te õpite:**
- Docker ja Podman deployment
- Environment variables kasutamine  
- Container networking
- docker-compose orchestration

---

## Ülesanne 2: Starter repository kloneerimine

### 2.1: Kloonige kodutöö starter repository

```bash
# Clone valmis starter repository
git clone https://github.com/teacher/docker-dashboard-starter.git
cd docker-dashboard-starter

# Loo oma branch
git checkout -b homework-TEIE-NIMI
# Näiteks: git checkout -b homework-maria-talvik
```bash

**Mida me saime?**
- Valmis HTML dashboard
- Dockerfile template
- docker-compose.yml
- nginx.conf konfiguratsioon
- README dokumentatsioon

### 2.2: Tutvuge starter failidega

**Kontrollige, mis failid on olemas:**
```bash
ls -la
# Peaksite nägema:
# index.html - Dashboard rakendus
# Dockerfile - Container juhised
# docker-compose.yml - Multi-container setup
# nginx.conf - Web server config
# README.md - Dokumentatsioon
```text

### 2.3: Testage starter rakendust

```bash
# Avage index.html otse brauseris (ilma container'ita)
open index.html
# Või Linux'is: firefox index.html

# Dashboard peaks avanema ja näitama:
# - Süsteemi oleku info
# - Container runtime: "Unknown" 
# - Interactive buttons töötavad
```bash

---

## Ülesanne 3: Docker container loomine

### 3.1: Tutvuge Dockerfile'iga

**Vaadake olemas olevat `Dockerfile` faili:**
```bash
cat Dockerfile
```text

**Dockerfile sisu ja selgitus:**
```dockerfile
FROM nginx:alpine              # Kasutame nginx web server'it
COPY index.html /usr/share/nginx/html/   # Kopeerime HTML faili
COPY nginx.conf /etc/nginx/conf.d/default.conf  # Custom config
EXPOSE 80                      # Container port 80
```bash

### 3.2: Testige Docker build

```bash
# Ehitage container image
docker build -t my-dashboard .

# Kontrollige, et image on loodud
docker images | grep my-dashboard
```text

### 3.3: Esimene commit

```bash
# Commit esialgsed muudatused
git add .
git commit -m "Alustasin kodutööd: kontrollisin starter failid ja Docker build"

# Push oma branch GitHub'i
git push origin homework-TEIE-NIMI
```bash

---

## Ülesanne 4: Container'ite käivitamine

### 4.1: Docker deployment

```bash
# Käivitage container
docker run -d --name my-docker-app -p 8080:80 my-dashboard

# Kontrollige, et container töötab
docker ps

# Testidige brauseris
echo "Avage brauser: http://localhost:8080"
```text

### 4.2: Podman deployment

```bash
# Ehitage image Podman'iga
podman build -t my-dashboard-podman .

# Käivitage Podman container
podman run -d --name my-podman-app -p 8081:80 my-dashboard-podman

# Kontrollige Podman container'eid
podman ps

# Testidige brauseris
echo "Avage brauser: http://localhost:8081"
```bash

### 4.3: Docker-compose kasutamine

**Looge/kontrollige `docker-compose.yml` faili:**
```yaml
version: '3.8'

services:
  dashboard:
    build: .
    ports:
      - "8080:80"
    container_name: compose-dashboard
```bash

**Käivitage docker-compose'iga:**
```bash
# Ehitage ja käivitage
docker-compose up -d

# Kontrollige
docker-compose ps

# Testidige: http://localhost:8080
```text

### 4.4: Commit deployment'i

```bash
git add docker-compose.yml
git commit -m "Docker ja Podman deployment töötab - mõlemad testitud"
```text

---

## Ülesanne 5: Container'ite haldamine

### 5.1: Container'ite info vaatamine

```bash
# Vaadake kõiki töötavaid container'eid
docker ps

# Vaadake container'i logisid
docker logs my-docker-app

# Sisenege container'isse (debugging)
docker exec -it my-docker-app sh

# Container'ist väljumine
exit
```text

### 5.2: Container'ite peatamine ja cleanup

```bash
# Peatage container
docker stop my-docker-app

# Kustutage container
docker rm my-docker-app

# Või mõlemat korraga
docker rm -f my-docker-app
```bash

### 5.3: Docker-compose haldamine

```bash
# Vaadake docker-compose staatust
docker-compose ps

# Vaadake logisid
docker-compose logs

# Peatage kõik teenused
docker-compose down

# Käivitage uuesti
docker-compose up -d
```text

### 5.4: Ressursside puhastamine

```bash
# Vaadake container'ite ressursside kasutust
docker stats

# Puhastage unused resources
docker system prune -f
```text

---

## Ülesanne 6: Dokumentatsiooni täiendamine

### 6.1: Muutke README.md faili

**Täitke README.md oma andmetega:**
```markdown
# System Status Dashboard - [TEIE NIMI]

## Mis see on?
System Status Dashboard on veebirakendus, mis näitab container informatsiooni.

## Kuidas käivitada?

### Docker'iga:
```bash
docker build -t dashboard .
docker run -d -p 8080:80 dashboard
# Avage: http://localhost:8080
```text

### Podman'iga:
```bash
podman build -t dashboard .
podman run -d -p 8081:80 dashboard  
# Avage: http://localhost:8081
```bash

### Docker-compose'iga:
```bash
docker-compose up -d
# Avage: http://localhost:8080
```text

## Mida ma õppisin
- [Teie kogemus 1]
- [Teie kogemus 2] 
- [Teie kogemus 3]

## Probleemid ja lahendused
**Probleem:** [Kirjeldage probleem]  
**Lahendus:** [Kuidas lahendasite]
```

### 6.2: Screenshot'ide tegemine

**Vajalikud screenshot'id:**
1. Dashboard töötab Docker'is: `http://localhost:8080`
2. Dashboard töötab Podman'is: `http://localhost:8081`  
3. Terminal output: `docker ps` ja `podman ps`

**Salvestage `screenshots/` kausta.**

---

## Ülesanne 7: Lõplik esitamine

### 7.1: Lõplik commit

```bash
# Veenduge, et kõik on commit'itud
git add .
git commit -m "Kodutöö valmis: Docker ja Podman deployment testitud"

# Push final version
git push origin homework-TEIE-NIMI
```text

### 7.2: Pull Request loomine

GitHub'is looge Pull Request õpetajale:
1. Minge teacher repository
2. Pull Requests → New Pull Request
3. Valige oma branch `homework-TEIE-NIMI`

---

## Esitamise nõuded

### Repository struktuur:
```
docker-fundamentals-homework/
├── README.md                    # Projekti kirjeldus
├── index.html                   # Veebisaidi fail
├── Dockerfile                   # Container definitsioon
├── docker-compose.yml           # Multi-container setup
└── screenshots/ (valikuline)    # Töötavate container'ite pildid
```bash

### Esitamine:
1. **GitHub Pull Request link** esitage õppetoolis
2. **Oma branch:** `homework-TEIE-NIMI`
3. **Töötav demonstratsioon** - õpetaja saab testida

### Hindamiskriteeriumid:
- Töötav Docker deployment
- Töötav Podman deployment  
- docker-compose setup
- Selge dokumentatsioon
- Git commit history näitab progressi
