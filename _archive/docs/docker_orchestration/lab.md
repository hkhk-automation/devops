# Docker Compose Lab

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

## Mida õpid

Selle labi lõpuks oskad:
- Luua Dockerfile Python rakenduse jaoks
- Kirjutada docker-compose.yml faili mitme teenusega
- Käivitada ja hallata multi-container rakendusi
- Debugida tavalisemaid container'ite probleeme

## Eeldused

- Docker ja Docker Compose on installitud
- Põhimõisted container'itest on teada

---

## Samm 1: Projekti struktuuri loomine

Loo järgmine kataloogide struktuur:

```bash
mkdir docker-compose-lab
cd docker-compose-lab
mkdir backend
mkdir frontend
```text

Sinu projekt peaks välja nägema nii:
```
docker-compose-lab/
├── backend/
├── frontend/
└── docker-compose.yml (loome hiljem)
```bash

Igal teenus (backend, frontend) on oma failid ja seadistused. See hoiab projekti korrastatuna.

---

## Samm 2: Backend rakenduse loomine

### 2.1 Python rakenduse loomine

Loo fail `backend/app.py`:

```python
from flask import Flask, jsonify
import os

# Flask rakenduse loomine
app = Flask(__name__)

# Tervisekontrolli endpoint - kontrollib, kas teenus töötab
@app.route('/api/health')
def health():
    return jsonify({
        'status': 'healthy',
        'service': 'backend'
    })

# Info endpoint - tagastab põhiinfot
@app.route('/api/info')
def info():
    return jsonify({
        'message': 'Tere Docker Compose\'ist!',
        'environment': os.getenv('APP_ENV', 'development')  # Loeb keskkonnamuutujat
    })

# Käivitab serveri kõigil IP-del (vajalik Docker'is)
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```text

Container'is peab rakendus kuulama kõiki võrguliidesesid (`host='0.0.0.0'`), et välispoolt oleks ligipääsetav.

### 2.2 Sõltuvuste faili loomine

Loo fail `backend/requirements.txt`:

```
Flask==2.3.3
```bash

Docker peab teadma, milliseid Python pakette installida. See fail loetleb kõik vajalikud sõltuvused.

### 2.3 Dockerfile loomine

Loo fail `backend/Dockerfile`:

```dockerfile
# Alustame Python base image'iga - sisaldab Python'i ja Linux'i
FROM python:3.9-slim

# Määrame töökausts container'is - kõik käsud toimuvad siin
WORKDIR /app

# Kopeerime sõltuvuste faili esimesena (optimiseerimise jaoks)
COPY requirements.txt .

# Installime Python pakette
RUN pip install -r requirements.txt

# Kopeerime kogu rakenduse koodi
COPY . .

# Dokumenteerime, et rakendus kasutab porti 5000
EXPOSE 5000

# Määrame, mis käsk käivitub container'i käivitamisel
CMD ["python", "app.py"]
```bash

Docker'i layer caching toimib nii, et kui kopeerime `requirements.txt` eraldi, siis koodi muutmisel ei pea sõltuvusi uuesti installima.

---

## Samm 3: Frontend failide loomine

### 3.1 Lihtsa HTML loomine

Loo fail `frontend/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Docker Compose Demo</title>
    <style>
        body { 
            font-family: Arial; 
            padding: 50px; 
            background-color: #f5f5f5; 
        }
        button { 
            padding: 10px 20px; 
            margin: 10px; 
            background-color: #007bff;
            color: white;
            border: none;
            cursor: pointer;
        }
        .result { 
            margin: 20px 0; 
            padding: 20px; 
            background: #fff; 
            border: 1px solid #ddd;
        }
    </style>
</head>
<body>
    <h1>Docker Compose Lab</h1>
    <p>See leht töötab Nginx container'is</p>
    
    <button onclick="testAPI()">Testi Backend API</button>
    <div id="result" class="result">Klõpsa nuppu API testimiseks</div>

    <script>
        // Funktsioon backend API testimiseks
        function testAPI() {
            fetch('/api/info')  // Päring backend'ile
                .then(response => response.json())
                .then(data => {
                    // Näita vastust lehel
                    document.getElementById('result').innerHTML = 
                        'API vastus: ' + JSON.stringify(data, null, 2);
                })
                .catch(error => {
                    // Näita viga
                    document.getElementById('result').innerHTML = 'Viga: ' + error;
                });
        }
    </script>
</body>
</html>
```bash

Fetch() on moodne viis API-ga suhtlemiseks ilma lehe uuesti laadimata.

---

## Samm 4: Docker Compose faili loomine

Loo fail `docker-compose.yml` projekti juurkaustas:

```yaml
version: '3.8'  # Compose faili formaat

services:  # Määrame kõik teenused
  frontend:
    image: nginx:alpine          # Kasutame valmis Nginx image'i
    ports:
      - "8080:80"               # Host port 8080 -> Container port 80
    volumes:
      - ./frontend:/usr/share/nginx/html  # Meie HTML failid Nginx'i
    depends_on:
      - backend                 # Frontend vajab backend'i

  backend:
    build: ./backend            # Ehitame oma image Dockerfile'ist
    ports:
      - "5000:5000"            # API kättesaadav port 5000 kaudu
```bash

See fail kirjeldab kogu rakenduse arhitektuuri - millised teenused, kuidas nad omavahel suhtlevad, millised pordid.

`depends_on` ütleb Docker'ile, et frontend vajab backend'i töötamist, seega backend käivitatakse esimesena.

---

## Samm 5: Rakenduse käivitamine

### 5.1 Kõikide teenuste käivitamine

```bash
docker-compose up --build
```text

`--build` ehitab image'd uuesti enne käivitamist. Vajalik, kui Dockerfile või kood on muutunud.

Sa näed logisid mõlemast teenusest. Oota, kuni näed:
```
backend_1   |  * Running on all addresses (0.0.0.0)
frontend_1  | ... nginx started
```bash

### 5.2 Rakenduse testimine

Ava brauser ja mine: `http://localhost:8080`

Klõpsa nuppu "Testi Backend API" - peaksid nägema JSON vastust backend'ilt.

Nginx forwording päringud `/api/*` backend container'ile, tänu Docker'i sisemisele võrgule.

### 5.3 Rakenduse peatamine

Vajuta `Ctrl+C` terminalis või käivita:

```bash
docker-compose down
```text

---

## Samm 6: Andmebaasi lisamine

### 6.1 Backend'i uuendamine andmebaasi kasutamiseks

Päris rakendused vajavad andmete salvestamist. PostgreSQL on populaarne ja töökindel andmebaas.

Uuenda `backend/app.py`:

```python
from flask import Flask, jsonify
import psycopg2
import os
from datetime import datetime

app = Flask(__name__)

# Funktsioon andmebaasi ühenduse loomiseks
def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),     # Andmebaasi host
            database=os.getenv('DB_NAME', 'app'),       # Andmebaasi nimi
            user=os.getenv('DB_USER', 'postgres'),      # Kasutajanimi
            password=os.getenv('DB_PASSWORD', 'password')  # Salasõna
        )
        return conn
    except:
        return None  # Ühendus ebaõnnestus

@app.route('/api/health')
def health():
    return jsonify({'status': 'healthy'})

@app.route('/api/info')
def info():
    return jsonify({
        'message': 'Tere Docker Compose\'ist!',
        'timestamp': datetime.now().isoformat()
    })

# Uus endpoint andmebaasi staatuse kontrolliks
@app.route('/api/db-status')
def db_status():
    conn = get_db_connection()
    status = 'connected' if conn else 'disconnected'
    if conn:
        conn.close()  # Sulge ühendus
    
    return jsonify({
        'database': status,
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```text

### 6.2 Sõltuvuste uuendamine

Uuenda `backend/requirements.txt`:

```
Flask==2.3.3
psycopg2-binary==2.9.7   # PostgreSQL driver Python'i jaoks
```bash

`psycopg2-binary` on PostgreSQL adapter Python'i jaoks, mis võimaldab andmebaasiga suhelda.

### 6.3 Environment faili loomine

Esmalt loome `.env` faili turvaliste seadistuste jaoks.

Loo `.env` fail projekti juurkaustas:

```env
# Andmebaasi seadistused
POSTGRES_DB=app
POSTGRES_USER=postgres
POSTGRES_PASSWORD=supersecretpassword123

# Rakenduse seadistused
APP_ENV=development
```bash

`.env` fail hoiab tundlikud andmed eraldi koodist. See on standardne viis konfiguratsioonide haldamiseks.

### 6.4 Docker Compose uuendamine

Peame lisama andmebaasi teenuse ja ühendama kõik teenused omavahel.

Uuenda `docker-compose.yml`:

```yaml
version: '3.8'

services:
  frontend:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./frontend:/usr/share/nginx/html
    depends_on:
      - backend

  backend:
    build: ./backend
    environment:
      - APP_ENV=${APP_ENV}      # Loeb .env failist
      - DB_HOST=db              # Andmebaasi host nimi
      - DB_NAME=${POSTGRES_DB}  # Loeb .env failist
      - DB_USER=${POSTGRES_USER}        # Loeb .env failist
      - DB_PASSWORD=${POSTGRES_PASSWORD} # Loeb .env failist
    ports:
      - "5000:5000"
    depends_on:
      - db                      # Backend vajab andmebaasi

  db:                           # UUS: Andmebaasi teenus
    image: postgres:13          # PostgreSQL 13 image
    environment:
      - POSTGRES_DB=${POSTGRES_DB}       # Loeb .env failist
      - POSTGRES_USER=${POSTGRES_USER}   # Loeb .env failist
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}  # Loeb .env failist
    volumes:
      - postgres_data:/var/lib/postgresql/data  # Andmete püsivus

volumes:
  postgres_data:                # Named volume andmete jaoks
```bash

Docker Compose loeb automaatselt `.env` faili ja asendab `${MUUTUJA}` väärtused.

---

## Samm 7: Täieliku rakenduse testimine

### 7.1 Uuesti ehitamine ja käivitamine

```bash
docker-compose up --build
```text

Nüüd käivitub kolm teenust: frontend, backend ja andmebaas.

### 7.2 Andmebaasi ühenduse testimine

Ava `http://localhost:5000/api/db-status` otse brauseris - peaksid nägema:

```json
{
  "database": "connected",
  "timestamp": "2025-01-15T10:30:00"
}
```text

### 7.3 Frontend'i uuendamine andmebaasi testimiseks

Uuenda `frontend/index.html`, lisa uus nupp:

```html
<!-- Lisa see teiste nuppude kõrvale -->
<button onclick="testDatabase()">Testi andmebaasi</button>

<script>
// Lisa see teiste funktsioonide kõrvale
function testDatabase() {
    fetch('/api/db-status')
        .then(response => response.json())
        .then(data => {
            document.getElementById('result').innerHTML = 
                'Andmebaasi staatus: ' + JSON.stringify(data, null, 2);
        });
}
</script>
```bash

---

## Samm 8: Kasulikud käsud ja debugimine

### 8.1 Docker Compose käsud

```bash
# Vaata töötavaid container'eid
docker-compose ps

# Vaata logisid kõigist teenustest
docker-compose logs

# Vaata konkreetse teenuse logisid
docker-compose logs backend

# Jälgi logisid reaalajas
docker-compose logs -f

# Käivita käsk container'is
docker-compose exec backend bash

# Peata kõik teenused
docker-compose down

# Eemalda ka volume'id
docker-compose down -v
```text

### 8.2 Container'ite probleemide lahendamine

**Kontrolli, kas container'id töötavad:**
```bash
docker-compose ps
```text

Peaksid nägema:
```
Name               State           Ports
backend_1          Up              0.0.0.0:5000->5000/tcp
db_1              Up              5432/tcp
frontend_1        Up              0.0.0.0:8080->80/tcp
```text

**Kontrolli container'i logisid:**
```bash
docker-compose logs backend
```text

**Ligipääs container'i shell'ile:**
```bash
docker-compose exec backend bash
```text

**Testi võrguühendust:**
```bash
docker-compose exec backend ping db
```bash

### 8.3 Levinud probleemid

**Port on juba kasutusel:**
- Muuda host porti docker-compose.yml failis (nt "8081:80")

**Container ei käivitu:**
- Kontrolli logisid: `docker-compose logs [teenus]`
- Kontrolli Dockerfile süntaksit
- Veendu, et kõik vajalikud failid eksisteerivad

**Ei saa andmebaasiga ühendust:**
- Kontrolli keskkonnamuutujaid
- Veendu, et andmebaasi container töötab
- Kontrolli, et teenused on samas võrgus

---

## Samm 9: Production kaalutlused

### 9.1 .env faili turvalisus

`.env` fail sisaldab tundlikke andmeid, seega:

```bash
# Lisa .gitignore faili
echo ".env" >> .gitignore
```text

Loo eraldi `.env.example` fail:

```env
# Andmebaasi seadistused
POSTGRES_DB=app
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here

# Rakenduse seadistused
APP_ENV=production
```bash

Production keskkonnas kasuta tugevaid salasõnu ja eraldi `.env` faili.

### 9.2 Health check'id

Health check'id ütlevad Docker'ile, kas teenus on tõesti valmis töötama, mitte ainult käivitatud.

Lisa health check'id teenustele:

```yaml
  db:
    image: postgres:13
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 30s     # Kontrollib iga 30 sekundi järel
      timeout: 10s      # Aeg välja, kui 10s pärast pole vastust
      retries: 5        # Proovib 5 korda enne "unhealthy" märkimist
    # ... ülejäänud konfiguratsioon

  backend:
    build: ./backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    # ... ülejäänud konfiguratsioon
```bash
---

## Lisaressursid ja abi

### **Õppimiseks:**
- [Docker Compose Quickstart](https://docs.docker.com/compose/gettingstarted/) - kiire algus
- [Docker Compose Examples](https://github.com/docker/awesome-compose) - palju näiteid
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/) - kõik võimalikud seaded

### 🆘 **Abi saamiseks:**
- [Docker Community](https://forums.docker.com/) - foorumid
- [Stack Overflow](https://stackoverflow.com/questions/tagged/docker-compose) - küsimused ja vastused
- [Docker Documentation](https://docs.docker.com/) - ametlik dokumentatsioon

### **Praktikaks:**
- [Docker Compose Best Practices](https://docs.docker.com/compose/production/) - tootmiskeskkonna nõuded
- [Docker Compose Networking](https://docs.docker.com/compose/networking/) - võrgu konfiguratsioon
- [Docker Compose Environment Variables](https://docs.docker.com/compose/environment-variables/) - keskkonnamuutujad
