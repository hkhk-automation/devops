# Docker Fundamentals Lab: Esimesed Sammud

Täna õpite Docker'i alused **praktikas**. Keskendume ainult Docker'ile - see on teie esimene kord!

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

---

## Õpiväljundid

Pärast seda lab'i oskate:
- **Mõista, miks Docker on kiire** (kogesite ise)
- **Ehitada lihtsat rakendust** (käed-küljes)
- **Kasutada põhilisi Docker käske** (praktiliselt)
- **Lahendada lihtsaid probleeme** (troubleshooting)

---

## Lab 1: Docker kiiruse kogemine

### 1.1: Esimene Docker käsk

```bash
# Teie esimene Docker käsk!
docker run hello-world

# Mida näete?
# 1. Docker tõmbab image
# 2. Loob container
# 3. Käivitab rakenduse
# 4. Näitab tulemust
```bash

**Mida juhtus?**
- Docker otsis "hello-world" image'i
- Ei leidnud lokaalselt → tõmbas internetist
- Lõi container'i
- Käivitas ja näitas tervitust

### 1.2: Kiiruse test

```bash
# Esimene kord (slow - tõmbab image)
time docker run hello-world

# Teine kord (fast - image on juba olemas)
time docker run hello-world

# Märkige erinevus!
# Esimene: ~_____ sekundit
# Teine: ~_____ sekundit
```text

### 1.3: Põhikäsud

```bash
# Mis image'd teil on?
docker images

# Mis containers on olnud?
docker ps -a

# Palju ruumi Docker kasutab?
docker system df
```bash

**Küsimus:** Miks "hello-world" kestab ainult hetke?  
**Vastus:** Container käivitab programmi ja lõpetab - nagu tavaline programm!

---

## Lab 2: Veebiserver Docker'is

### 2.1: Nginx veebiserver

```bash
# Käivitage nginx web server
docker run -d --name my-web -p 8080:80 nginx

# Mida tähendavad parameetrid?
# -d = detached (taustal)
# --name = anname nimeks "my-web"
# -p 8080:80 = host port 8080 → container port 80
# nginx = image nimi
```text

### 2.2: Testimine

```bash
# Kontrollige, kas töötab
docker ps

# Testid
curl http://localhost:8080
# VÕI avage brauser: http://localhost:8080

## Kontrollige Nginx welcome lehte
```text

### 2.3: Container'i uurimine

```bash
# Vaadake loge
docker logs my-web

# Sisenege container'isse
docker exec -it my-web bash

# Container'i sees:
ls /usr/share/nginx/html/
cat /usr/share/nginx/html/index.html

# Väljuge
exit
```text

### 2.4: Cleanup

```bash
# Peatage ja kustutage
docker stop my-web
docker rm my-web

# Kontrollige
docker ps -a
```text

---

## Lab 3: Oma rakenduse ehitamine

### 3.1: Projekti ettevalmistamine

```bash
mkdir ~/my-first-docker-app && cd ~/my-first-docker-app
```text

### 3.2: HTML rakenduse loomine

**Looge fail `index.html`:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>My Docker App</title>
    <style>
        body { 
            font-family: Arial; 
            text-align: center; 
            margin-top: 100px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container { 
            background: rgba(255,255,255,0.1); 
            padding: 30px; 
            border-radius: 15px; 
            max-width: 500px;
            margin: 0 auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>My First Docker App!</h1>
        <p>Container ID: <span id="hostname">Loading...</span></p>
        <p>Current time: <span id="time"></span></p>
        <p>Created by: <strong>[TEIE NIMI]</strong></p>
        <script>
            document.getElementById('time').innerText = new Date().toLocaleString();
            // Container hostname on container ID esimesed karakterid
            document.getElementById('hostname').innerText = window.location.hostname || 'localhost';
        </script>
    </div>
</body>
</html>
```text

### 3.3: Dockerfile loomine

**Looge fail `Dockerfile` (ilma laiendita!):**
```dockerfile
# Alusta nginx image'ist
FROM nginx:alpine

# Kopeeri meie HTML fail nginx kausta
COPY index.html /usr/share/nginx/html/

# Ava port 80
EXPOSE 80

# Nginx käivitub automaatselt
```text

### 3.4: Image ehitamine

```bash
# Ehitage oma image
docker build -t my-app .

# Kontrollige
docker images | grep my-app

## Kontrollige ehitamise tulemust
```text

### 3.5: Rakenduse käivitamine

```bash
# Käivitage oma rakendus
docker run -d --name my-first-app -p 8080:80 my-app

# Test
curl http://localhost:8080
# VÕI brauser: http://localhost:8080

## Kontrollige rakenduse töötamist
```text

---

## Lab 4: Rakenduse arendamine

### 4.1: Muudatuste tegemine

**Muutke `index.html` faili:**
```html
<!-- Lisa see HTML'i sisse, enne </div> sulgemist -->
<p>Version: 2.0 - UPDATED!</p>
<p>Lab completed on: <span id="date"></span></p>

<script>
// Lisa existing script'i lõppu
document.getElementById('date').innerText = new Date().toLocaleDateString();
</script>
```text

### 4.2: Uue versiooni ehitamine

```bash
# Peatage vana container
docker stop my-first-app
docker rm my-first-app

# Ehitage uus versioon
docker build -t my-app:v2 .

# Käivitage uus versioon
docker run -d --name my-app-v2 -p 8080:80 my-app:v2

# Test muudatusi
curl http://localhost:8080
## Kontrollige versiooni uuendust
```text

### 4.3: Image'ide võrdlus

```bash
# Vaadake mõlemat versiooni
docker images | grep my-app

# Mitu image't teil on? _______
# Miks mõlemad on olemas? _______
```text

---

## Lab 5: Troubleshooting harjutus

### 5.1: "Katki" rakenduse parandamine

**Looge vale `Dockerfile-broken`:**
```dockerfile
FROM nginx:alpine
COPY index.html /wrong/location/
EXPOSE 80
```text

**Proovige seda:**
```bash
# Ehitage "katki" versioon
docker build -f Dockerfile-broken -t broken-app .

# Käivitage
docker run -d --name broken -p 8081:80 broken-app

# Test
curl http://localhost:8081
## Kontrollige töötamist
```text

### 5.2: Probleemi diagnoosimine

```bash
# Vaadake loge
docker logs broken

# Minge container'isse
docker exec -it broken sh

# Container'i sees uurige:
ls /usr/share/nginx/html/
## Kontrollige faili olemasolu

ls /wrong/location/
## Kontrollige faili asukohta

exit
```text

**Küsimus:** Miks ei tööta?  
**Vastus:** _______________________

### 5.3: Parandamine

```bash
# Parandage Dockerfile (kasutage õiget teed)
docker build -t fixed-app .
docker stop broken && docker rm broken
docker run -d --name fixed -p 8081:80 fixed-app

# Test
curl http://localhost:8081
## Kontrollige paranduse tulemust
```text

---

## Lab 6: Container'ite haldamine

### 6.1: Mitme container'i käivitamine

```bash
# Käivitage mitu versiooni korraga
docker run -d --name app-v1 -p 8081:80 my-app
docker run -d --name app-v2 -p 8082:80 my-app:v2

# Kontrollige
docker ps

# Testid
curl http://localhost:8081  # v1
curl http://localhost:8082  # v2
```text

### 6.2: Container'ite jälgimine

```bash
# Reaalajas statistika
docker stats

# Konkreetse container'i stats
docker stats app-v1 --no-stream

# Märkige RAM kasutus: _____ MB
```text

### 6.3: Lõplik cleanup

```bash
# Peatage kõik containers
docker stop app-v1 app-v2 my-app-v2 fixed
docker rm app-v1 app-v2 my-app-v2 fixed

# Kontrollige
docker ps -a

# Kustutage kasutamata image'id (valikuline)
docker image prune
```text

---

## Lab 7: Volume'ide tutvustus

### 7.1: Andmete säilitamine

```bash
# Looge volume
docker volume create my-data

# Käivitage container volume'iga
docker run -d --name data-test \
    -p 8083:80 \
    -v my-data:/usr/share/nginx/html \
    nginx:alpine

# Muutke sisu
docker exec data-test sh -c 'echo "<h1>Persistent Data Test</h1>" > /usr/share/nginx/html/index.html'

# Test
curl http://localhost:8083
## Kontrollige uue sisu kuvamist
```text

### 7.2: Container restart test

```bash
# Hävitage container (aga volume jääb!)
docker stop data-test && docker rm data-test

# Looge uus container sama volume'iga
docker run -d --name data-test-2 \
    -p 8083:80 \
    -v my-data:/usr/share/nginx/html \
    nginx:alpine

# Test
curl http://localhost:8083
## Kontrollige andmete säilimist
```bash

**Küsimus:** Miks andmed jäid alles?  
**Vastus:** _______________________

---

## Lab'i kokkuvõte

### Mida te õppisite:

**Docker käsud:**
- `docker run` - container'i käivitamine
- `docker build` - image'i ehitamine
- `docker ps` - töötavate container'ite vaatamine
- `docker logs` - logide kontroll
- `docker exec` - container'isse sisenemine

**Docker kontseptsioonid:**
- Image vs Container
- Port mapping (-p)
- Volume'id andmete säilitamiseks
- Dockerfile rakenduse kirjeldamiseks

**Troubleshooting oskused:**
- Logide lugemine
- Container'isse sisenemine
- Probleemide diagnoosimine

### Järgmised sammud:

**Kodutöö:** Süsteemi oleku dashboard deployment  
**Järgmine lab:** Docker Compose multi-container rakendused

---

## Boonusülesanne

### Podman kui Docker'i alternatiiv

Podman on Docker'i ühilduv alternatiiv, mis ei vaja daemon'i ja töötab rootless režiimis.

**Installeerimine:**
```bash
sudo apt update && sudo apt install -y podman
```text

**Käskude võrdlus:**
```bash
# Docker vs Podman
docker run hello-world    # vs podman run hello-world
docker ps                 # vs podman ps
docker images             # vs podman images
```bash

**Eelised:**
- Ei vaja daemon'i (daemonless)
- Rootless töörežiim
- Docker Compose ühilduvus
- Kubernetes ühilduvus

**Peamised erinevused:**
- Podman = daemon'ita (rootless)
- Docker = daemon'iga (vajab docker group)
- Käsud on peaaegu identsed

**Hästi tehtud!** Nüüd oskate Docker'i põhitõdesid!
