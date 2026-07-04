# Docker konteinerite teooria ja praktika

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

Eelmisel nädalal õppisime Ansible role'e, kuidas automatiseerida serverite konfiguratsiooni. Täna astume järgmisesse dimensiooni - konteinerite maailma. Kui Ansible aitab hallata olemasolevaid servereid, siis Docker muudab selle, kuidas me rakendusi üldse ehitame ja jooksutame.

Mõtle konteineritele kui LEGO klotside süsteemile - iga konteiner on üks klots, mis saab kiiresti kokku panna suuremateks rakendusteks. Aga erinevalt LEGO-st, need "klotsid" sisaldavad terveid rakendusi ja jooksevad igal arvutil täpselt ühesuguselt.

## Mis on Docker ja miks seda vaja

Docker on tööriist konteinerite loomiseks ja haldamiseks. Aga mis need konteinerid siis on ja miks nad paremad on kui traditsioonilised lahendused?

Põhiline probleem, mida Docker lahendab, on kuulus "töötab mu masinas" sündroom. Sa ehitad rakenduse oma laptopil, see töötab suurepäraselt. Liigutad serverisse - ei tööta. Kolleeg üritab käivitada oma masinas - ei tööta. Probleem pole sinus ega sinu koodis, vaid selles, et erinevates keskkondades on erinevad versioonid, sõltuvused ja konfiguratsioonid.

Docker võimaldab sul pakkida rakenduse koos kõigi sõltuvustega ühte "kasti" ehk konteinerisse, mis töötab igal arvutil täpselt ühesuguselt. See konteiner sisaldab kõike vajalikku: operatsioonisüsteemi osi, runtime'i, teeke, sõltuvusi ja sinu rakendust ennast.

### Põhilised mõisted

Enne kui edasi liikume, pead mõistma nelja põhilist mõistet:

**Image** on mall konteineri jaoks, nagu CD-ROM või programmi installer. See sisaldab kõike vajalikku: operatsioonisüsteemi osi, rakendust ja kõiki sõltuvusi. Image on muutumatu - kui sa teed sinna muudatusi, loodi tegelikult uus image.

**Container** on käivitatud image, nagu programm, mis jookseb su arvutis. Container elab ja töötab, teda saab peatada, taaskäivitada või kustutada. Iga kord kui käivitad sama image'i, saad uue konteineri.

**Dockerfile** on tekstifail, mis sisaldab retsepti image'i loomiseks. See kirjeldab samm-sammult, kuidas image ehitada: millist base image'i kasutada, millised failid kopeerida, millised käsud käivitada.

**Registry** on pood image'ite jaoks, nagu App Store nutitelefonile. Kõige populaarsem on Docker Hub, kus leidub tuhandeid valmis image'e kõikvõimalike rakenduste jaoks.

## Konteinerid versus virtuaalmasinad

Et mõista, miks konteinerid on revolutsiooniline, vaatame, kuidas server infrastruktuur on aastate jooksul arenenud.

### Tehnoloogia evolutsioon

Füüsiliste serverite ajastul (kuni 2000. aastate algus) tähendas üks rakendus üht serverit. See oli kallis ja ebaefektiivne - enamik servereid kasutasid ainult 5-15% oma võimsusest, aga maksma pidid täishinnaga.

Virtuaalmasinad (2000-2010) lahendasid osa probleemist. Üks võimas server sai majutada mitu virtuaalmasinat, igaüks oma operatsioonisüsteemiga. Aga iga virtuaalmasin vajab täispikka operatsioonisüsteemi, mis tähendab 1-2GB mälukasutust ja 20GB kettaruumi isegi lihtsa rakenduse jaoks.

Konteinerid (alates 2013) viisid efektiivsuse järgmisele tasemele. Erinevalt virtuaalmasinadest jagavad kõik konteinerid sama operatsioonisüsteemi kerneli. See tähendab, et üks konteiner kasutab ainult 10-100MB mälu ja käivitub sekundite jooksul.

### Praktiline erinevus

Virtuaalmasin on nagu terve eraldi korter - seal on oma köök, vannituba, elekter, kõik. Iga korter on täiesti eraldatud, aga ka ressursimahukas.

Konteiner on nagu tuba jagatud korteris - sa jagad kööki ja vannituba (operatsioonisüsteemi kerneli), aga sinu tuba (rakendus) on täiesti privaatne. See on palju efektiivsem.

Numbrites väljendub see drastilises erinevuses:

| Kriteerium | Virtuaalmasinad | Konteinerid |
|------------|------------------|------------|
| Käivitusaeg | 1-2 minutit | 1-5 sekundit |
| Mälukasutus | 1-8GB | 10-100MB |
| Mahtuvus serveris | 10-50 | 100-1000 |
| Kettaruumi vajadus | 10-50GB | 100MB-1GB |

### Millal kasutada mida

Virtuaalmasinad on endiselt õiged valik, kui vajad erinevaid operatsioonisüsteeme samal serveril, maksimaalset turvalist eraldatust või töötad legacy süsteemidega, mis pole konteineri jaoks sobivad.

Konteinerid on ideaalsed kaasaegsete veebirakenduste, mikroteenuste arhitektuuri, arendus- ja testimiskeskkondade ning kiire deployment'i jaoks.

## Docker'i installimine ja seadistamine

Docker'i installimine Ubuntu või Debian süsteemis käib mitmeastmeliselt, sest tahame kasutada ametlikku Docker'i repositooriumit, mitte distributsiooniga kaasas olevat aegunud versiooni.

Kõigepealt uuenda pakettide nimistut ja installi vajalikud eeldused:

```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
```bash

Lisa Docker'i ametlik GPG võti ja repositoorium:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```bash

Nüüd saad installida Docker'i:

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```bash

Käivita Docker'i teenus ja seadista see automaatselt käivituma:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```bash

Viimane samm on lisada oma kasutaja docker gruppi, et sa ei peaks pidevalt sudo kasutama:

```bash
sudo usermod -aG docker $USER
```bash

Pärast seda pead välja logima ja tagasi sisse logima, või käivitama `newgrp docker` käsu.

Testi installatsiooni:

```bash
docker --version
docker run hello-world
```bash

Viimane käsk laadib väikese testi image'i ja käivitab selle. Kui näed tervitussõnumit, on Docker edukalt installitud.

## Docker'i käsurea põhialused

Docker'i käsurea süntaks järgib lihtsat mustrit: `docker [VALIKUD] KÄSK [ARGUMENDID]`. Kõik Docker'i funktsioonid on kättesaadavad alamkäskude kaudu.

### Image'ide haldamine

Image'ide allalaadimine käib `pull` käsuga:

```bash
docker pull nginx             # Viimane versioon
docker pull nginx:1.21        # Konkreetne versioon
docker pull ubuntu:20.04      # Erinevad operatsioonisüsteemid
```text

Lokaalse image'ide vaatamiseks kasuta:

```bash
docker images                 # Kõik lokaalsed image'id
docker search mysql           # Otsi Docker Hub'ist
```text

Kasutamata image'ide kustutamiseks:

```bash
docker rmi nginx              # Kustuta konkreetne image
docker image prune            # Kustuta kõik kasutamata image'id
```text

### Konteinerite käivitamine

Lihtsaim viis konteineri käivitamiseks:

```bash
docker run nginx
```text

See käsk laadib nginx image'i (kui see veel masinas pole), loob sellest konteineri ja käivitab selle. Probleem on see, et käsk blokeerib terminali.

Praktilisemad variandid:

```bash
docker run -d nginx                 # Käivita taustaal (detached)
docker run --name my-web nginx     # Anna konteinerile nimi
docker run -p 8080:80 nginx        # Ühenda port 8080 konteineri port 80-ga
```text

Interaktiivse konteineri jaoks, näiteks kui tahad Ubuntu'ga katsetada:

```bash
docker run -it ubuntu bash         # Interaktiivne terminal
```text

Käivitatud konteineris käsu jooksutamiseks:

```bash
docker exec -it container_name bash # Ühenda käivitatud konteinerisse
```text

### Konteinerite jälgimine ja haldamine

Vaata, millised konteinerid töötavad:

```bash
docker ps                     # Töötavad konteinerid
docker ps -a                  # Kõik konteinerid (ka peatatud)
```text

Konteineri logide vaatamiseks:

```bash
docker logs container_name    # Näita loge
docker logs -f container_name # Jälgi loge reaalajas
```text

Konteineri elutsükli haldamine:

```bash
docker start container_name   # Käivita peatatud konteiner
docker stop container_name    # Peata konteiner
docker restart container_name # Taaskäivita
docker rm container_name      # Kustuta konteiner
```text

### Praktiline näide

Vaatame, kuidas käivitada lihtne veebiserver:

```bash
# Käivita Nginx konteiner
docker run -d --name my-web -p 8080:80 nginx

# Testi brauseris või curl'iga
curl http://localhost:8080

# Vaata konteineri loge
docker logs my-web

# Peata ja kustuta
docker stop my-web
docker rm my-web
```bash

## Dockerfile - rakenda konteineri retsept

Dockerfile on tekstifail, mis sisaldab juhiseid Docker'ile, kuidas ehitada image sinu rakenduse jaoks. See on nagu retsept, mis kirjeldab kõik vajalikud sammud.

### Põhilised juhised

**FROM** määrab base image'i, millelt hakata ehitama:

```dockerfile
FROM nginx:alpine           # Väike ja kiire
FROM python:3.9             # Python runtime
FROM node:16                # Node.js runtime
```text

Tootmises kasuta alati konkreetseid versioone:

```dockerfile
FROM node:16.14.2-alpine    # Täpne versioon, mitte "latest"
```text

**WORKDIR** määrab töökatalogi konteineris:

```dockerfile
WORKDIR /app                # Kõik järgnevad käsud tehakse siin
```text

**COPY** kopeerib faile host süsteemist konteinerisse:

```dockerfile
COPY app.py /app/           # Üks fail
COPY src/ /app/src/         # Terve kaust
COPY . /app/                # Kõik praegusest kaustast
```text

**RUN** käivitab käsu image'i ehitamise ajal:

```dockerfile
RUN apt-get update && apt-get install -y curl
RUN pip install -r requirements.txt
```text

**CMD** määrab vaikimisi käsu, mis käivitatakse konteineri käivitamisel:

```dockerfile
CMD ["python", "app.py"]
CMD ["nginx", "-g", "daemon off;"]
```bash

### Praktiline näide: Python rakendus

Loome lihtsa Flask rakenduse ja pakime selle konteinerisse.

Loo fail `app.py`:

```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return '<h1>Tere Docker'i maailmast!</h1>'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```text

Loo fail `requirements.txt`:

```
Flask==2.3.2
```text

Loo `Dockerfile`:

```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Kopeeri sõltuvuste fail esimesena (cache optimeerimiseks)
COPY requirements.txt .
RUN pip install -r requirements.txt

# Kopeeri rakenduse kood viimasena
COPY app.py .

EXPOSE 5000
CMD ["python", "app.py"]
```text

Ehita ja käivita:

```bash
# Ehita image
docker build -t my-python-app .

# Käivita konteiner
docker run -d --name flask-app -p 5000:5000 my-python-app

# Testi
curl http://localhost:5000
```text

### .dockerignore fail

Nagu `.gitignore`, aitab `.dockerignore` hoida image'ist välja faile, mida pole vaja:

```
__pycache__
*.pyc
.git
README.md
.env
node_modules
```bash

## Andmete säilitamine volume'idega

Vaikimisi kaotad kõik andmed, kui konteineri kustutad. See on hea isolatsiooni jaoks, aga halb andmebaasidele või failide säilitamiseks.

### Named volume'id

Volume'id on Docker'i viis andmete säilitamiseks väljaspool konteinerit:

```bash
# Loo volume
docker volume create mydata

# Kasuta volume'i
docker run -d \
  --name database \
  -v mydata:/var/lib/mysql \
  mysql:8.0

# Volume info
docker volume ls
docker volume inspect mydata
```text

### Bind mount'id

Vahel tahad otse host süsteemi kausta konteinerisse ühendada:

```bash
# Ühenda host'i kaust konteinerisse
docker run -d \
  --name web \
  -v /home/kasutaja/veebisait:/usr/share/nginx/html \
  nginx

# Muudatused host'is on kohe nähtavad konteineris
echo "<h1>Tere!</h1>" > /home/kasutaja/veebisait/index.html
curl http://localhost  # Uus sisu on kohe nähtav
```bash

## Dockerfile'i optimeerimine

Dockeri üks võimsaimaid omadusi on ka selle suurim lõks algajatele. Docker ehitab image'i kihtide kaupa ja cache'ib neid. Kui muudad ühte rida Dockerfile'is, siis kõik järgnevad kihid ehitatakse uuesti.

### Kihtide cache'imise probleem

Vaatame tüüpilist viga Node.js rakenduse puhul:

```dockerfile
FROM node:16
COPY . /app/          # Kogu kood kopeeritakse kohe
WORKDIR /app
RUN npm install      # Sõltuvused installib uuesti iga koodimuudatuse puhul
CMD ["npm", "start"]
```text

Optimeeritud versioon:

```dockerfile
FROM node:16
WORKDIR /app

# Kopeeri ainult sõltuvuste failid
COPY package*.json ./
RUN npm install

# Kopeeri lähtekood alles pärast sõltuvuste installimist
COPY . .
CMD ["npm", "start"]
```bash

### RUN käskude optimeerimine

Docker loob iga RUN käsu jaoks eraldi kihi. Vale lähenemine:

```dockerfile
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean
```text

Õige lähenemine:

```dockerfile
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```text

### CMD ja ENTRYPOINT erinevus

CMD määrab vaikimisi käsu, mida saab käivitamisel üle kirjutada:

```dockerfile
CMD ["python", "app.py"]
```text

ENTRYPOINT määrab käsu, mis käivitatakse alati:

```dockerfile
ENTRYPOINT ["python", "app.py"]
```text

Parim praktika on kasutada neid koos:

```dockerfile
ENTRYPOINT ["python", "app.py"]
CMD ["--help"]
```text

## Mitmestaadilised ehitused

### Probleem: ehitustööriistad tootmises

Tüüpiline Node.js rakendus vajab ehitamiseks palju tööriistu, aga tootmises pole neid vaja.

Traditsioonilise lähenemisega:

```dockerfile
FROM node:16
WORKDIR /app
COPY package*.json ./
RUN npm install        # Kaasa arvatud arendussõltuvused!
COPY . .
RUN npm run build
CMD ["npm", "start"]
```text

Mitmestaadilise ehitusega:

```dockerfile
# Esimene staadium: ehitamine
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Teine staadium: tootmine
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY --from=builder /app/dist ./dist
CMD ["npm", "start"]
```text

Tulemus on 80% väiksem image.

### Äärmuslik optimeerimine

Go keele puhul:

```dockerfile
# Ehitusstaadium
FROM golang:1.19-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o app

# Käitamisstaadium
FROM scratch  # Täiesti tühi image!
COPY --from=builder /app/app /app
EXPOSE 8080
CMD ["/app"]
```bash

Lõpptulemus: ainult 5MB suurune image!

## Turvalisuse põhitõed

### Mitte-root kasutaja

Vaikimisi käivituvad Docker konteinerid root kasutajana:

```dockerfile
# Kasuta konkreetseid versioone
FROM node:16.14.2-alpine

# Loo spetsiaalne kasutaja
RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -u 1001

# Lülitu sellele kasutajale
USER appuser

# Kopeeri failid õige omanikuga
COPY --chown=appuser:appuser . .
```text

### Minimalistlik lähenemine

Alpine Linux on populaarne valik:

```dockerfile
FROM python:3.9-alpine  # ~50MB vs python:3.9 ~900MB
```text

### Tervisecontrollid

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -f http://localhost:5000/health || exit 1
```bash

## Docker'i võrgustik

### Vaikimisi võrgu probleem

Docker'i vaikimisi käitumine töötab ainult IP aadresside kaudu:

```bash
docker run -d --name web1 nginx
docker run -d --name web2 nginx

# Töötab
docker exec web1 ping 172.17.0.3

# Ei tööta
docker exec web1 ping web2
```text

### Kohandatud võrgud

Lahendus on luua kohandatud võrk:

```bash
# Loo rakendusespetsiifiline võrk
docker network create myapp-network

# Käivita konteinerid selles võrgus
docker run -d --name web --network myapp-network nginx
docker run -d --name api --network myapp-network python:3.9

# Nüüd töötab nimede lahendamine
docker exec web ping api          # Töötab!
```text

### Kolmekihiline rakendus

```bash
# Loo kaks võrku
docker network create frontend   # Veeb ↔ API
docker network create backend    # API ↔ Andmebaas

# Andmebaas (ainult backend võrgus)
docker run -d --name db \
  --network backend \
  -e POSTGRES_PASSWORD=secret \
  postgres:13

# API (mõlemas võrgus)
docker run -d --name api \
  --network backend \
  python:3.9
docker network connect frontend api

# Veebiserver (ainult frontend võrgus)
docker run -d --name web \
  --network frontend \
  -p 80:80 \
  nginx
```bash

## Podman kui Docker'i alternatiiv

Podman on Red Hat'i poolt arendatud Docker'i alternatiiv, mis lahendab mitu turvaprobleemi.

### Arhitektuuri erinevus

Docker töötab klient-server mudelis:

```
Sa → Docker klient → Docker daemon → Konteiner
                           ↑
                    Alati töötab kui root
```text

Podman'is pole daemon'it:

```
Sa → Podman → Konteiner
       ↑
   Otsene käivitamine
```bash

### Peamised erinevused

| Aspekt | Docker | Podman |
|---------|---------|---------|
| Daemon | Vajab dockerd | Ei vaja daemon'it |
| Root õigused | Vajab root õigusi | Töötab tavalise kasutajana |
| Käivitamine | Daemon peab töötama | Kohe kasutamisvalmis |
| Turvalisus | docker grupp = root | Tavaline kasutaja |

### Käsud on peaaegu identset

```bash
# Docker                 →    Podman
docker pull nginx       →    podman pull nginx
docker run -d nginx     →    podman run -d nginx
docker ps               →    podman ps
docker logs name        →    podman logs name
```text

Saad isegi teha alias'e:

```bash
alias docker=podman
```text

## Levinumad vead

### Aegunud pakettide cache

```dockerfile
# Vale
RUN apt-get update
RUN apt-get install -y curl

# Õige
RUN apt-get update && apt-get install -y curl
```text

### Root kasutaja probleem

```dockerfile
# Vale
FROM ubuntu
COPY app /app
CMD ["/app"]  # Käivitub root kasutajana

# Õige
FROM ubuntu
RUN useradd -m appuser
USER appuser
COPY app /app
CMD ["/app"]
```text

### Liiga suured image'id

```dockerfile
# Vale
FROM ubuntu:latest  # ~72MB + kõik tööriistad

# Õige
FROM python:3.9-alpine  # ~45MB + Python juba sees
```text

## Praktiline näide: optimeeritud Flask rakendus

Vaatame, kuidas kõik põhimõtted töötavad koos:

**requirements.txt:**
```
Flask==2.3.2
gunicorn==21.2.0
```text

**app.py:**
```python
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    env = os.getenv("NODE_ENV", "unknown")
    return f'<h1>Tere, {env} keskkonnas!</h1>'

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```text

**Optimeeritud Dockerfile:**
```dockerfile
# Mitmestaadline ehitus
FROM python:3.9-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Tootmisstaadium
FROM python:3.9-slim
WORKDIR /app

# Mitte-root kasutaja
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Kopeeri sõltuvused
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Kopeeri lähtekood
COPY --chown=appuser:appuser . .

# Lülitu mitte-root kasutajale
USER appuser

# Tervisecontroll
HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -f http://localhost:5000/health || exit 1

EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```text

**Ehitamine ja käivitamine:**
```bash
# Ehita optimeeritud image
docker build -t flask-app:optimized .

# Loo kohandatud võrk
docker network create app-network

# Käivita kohandatud võrgus
docker run -d \
  --name flask-app \
  --network app-network \
  -e NODE_ENV=production \
  -p 5000:5000 \
  --restart=unless-stopped \
  flask-app:optimized

# Testi
curl http://localhost:5000
curl http://localhost:5000/health
```bash

## Tootmiskeskkonna põhimõtted

Eduka Docker'i kasutamise tootmiskeskkonnas saab kokku võtta mõne olulise põhimõttega:

Kasuta alati ametlikke base image'e, mille turvalisust jälgitakse ja mida uuendatakse regulaarselt. Kopeeri sõltuvuste failid enne rakenduse koodi, et ära kasutada kihtide cache'imise eeliseid. Kasuta mitmestaadilisi ehitusi tootmises, et hoida image väike ja turvaline.

Loo alati mitte-root kasutaja ja määra paketiversioonid kindlalt. Kombineeri RUN käsud üheks ja kasuta .dockerignore faili. Lisa tervisecontrollid, et orkestreerimissüsteemid saaksid konteineri seisundit jälgida.

Kasuta kohandatud võrke mitme konteineri rakenduste jaoks ja nimega volume'e andmete säilitamiseks tootmises.

## Kokkuvõte

Selles teooriaülevaates õppisid Docker'i põhitõdesid: mis on konteinerid, kuidas nad erinevad virtuaalmasinadest ja miks nad on kaasaegse tarkvara arendamise põhialus. Samuti õppisid edasijõudnute tehnikaid, mis muudavad image'id kiiremaks, turvalisemaks ja väiksemaks.

Docker'i võrgustiku mõistmine on kriitilise tähtsusega mitme konteineri rakenduste ehitamiseks. Podman pakub huvitavat alternatiivi, eriti kui turvalisus on prioriteet.

Järgmistes praktikumides ja kodutöödes rakendad neid teadmisi ning õpid Docker Compose'i, mis aitab hallata keerukaid mitme konteineri rakendusi.
