# Docker Orchestration Kodutöö

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Moodul:** Docker Orkestratsioon  
**Tähtaeg:** Järgmise nädala algus  
**Hindamine:** 120 punkti

---

## Ülesanne 1: Full-stack rakenduse ehitamine (100 punkti)

### Ülesande kirjeldus

Looge töötav full-stack veebirakendus Docker Compose'iga, mis demonstreerib multi-container orchestration põhimõtteid.

### Nõuded

#### Arhitektuur (40 punkti)

Rakendus peab koosnema **neljast teenusest:**

1. **Frontend** - veebiserver (Nginx + HTML/JS)
2. **Backend** - API server (Python/Node.js)  
3. **Andmebaas** - PostgreSQL
4. **Cache** - Redis

#### Funktsionaalsus (30 punkti)

- Frontend näitab andmeid andmebaasist
- Backend pakub REST API endpoint'e
- Redis cache'ib andmebaasi päringuid
- Kõik teenused suhtlevad omavahel

#### Konfiguratsioon (20 punkti)

- Environment variables `.env` failis
- Named volumes andmete säilitamiseks
- Correct service dependencies (`depends_on`)
- Proper port mappings

#### Dokumentatsioon (10 punkti)

- README.md käivitamisjuhistega
- Arhitektuuri kirjeldus
- API endpoint'ide dokumentatsioon

### Näidis arhitektuur

```bash
Kasutaja → Nginx (Frontend) → Python/Node (Backend) → PostgreSQL
                                     ↓
                                  Redis Cache
```

### Minimaalsed endpoint'id

Backend peab pakkuma:
- `GET /api/health` - API tervise kontroll
- `GET /api/users` - kasutajate loetelu
- `POST /api/users` - uue kasutaja lisamine

### Näited ja template'id

#### docker-compose.yml näide
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
      - DB_HOST=database
      - DB_PASSWORD=${DB_PASSWORD}
    depends_on:
      - database

  database:
    image: postgres:13
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```text

#### .env faili näide
```env
DB_PASSWORD=mySecurePassword123
WEB_PORT=8080
API_PORT=5000
```bash

#### Python backend näide (backend/app.py)
```python
from flask import Flask, jsonify
import psycopg2
import os

app = Flask(__name__)

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/api/users')
def get_users():
    # Ühendus andmebaasiga
    conn = psycopg2.connect(
        host="database",
        database="myapp",
        user="postgres",
        password=os.getenv('DB_PASSWORD')
    )
    
    cur = conn.cursor()
    cur.execute("SELECT name, email FROM users")
    users = cur.fetchall()
    conn.close()
    
    return jsonify({"users": [{"name": u[0], "email": u[1]} for u in users]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```text

#### Dockerfile näide (backend/Dockerfile)
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .

CMD ["python", "app.py"]
```text

#### requirements.txt näide
```
Flask==2.3.3
psycopg2-binary==2.9.7
```text

#### HTML frontend näide (frontend/index.html)
```html
<!DOCTYPE html>
<html>
<head>
    <title>My App</title>
</head>
<body>
    <h1>User Management</h1>
    <button onclick="loadUsers()">Load Users</button>
    <div id="result"></div>

    <script>
        async function loadUsers() {
            const response = await fetch('/api/users');
            const data = await response.json();
            document.getElementById('result').innerHTML = 
                data.users.map(u => `<p>${u.name} - ${u.email}</p>`).join('');
        }
    </script>
</body>
</html>
```text

#### SQL init script näide (database/init.sql)
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(200)
);

INSERT INTO users (name, email) VALUES 
('John Doe', 'john@example.com'),
('Jane Smith', 'jane@example.com');
```bash

### Esitamine

**Git repository sisaldab:**
- `docker-compose.yml`
- Kõik vajalikud source failid
- `.env.example` (ilma paroolideta)
- `README.md`

**Testimine:**
Projekt peab käivituma käskudega:
```bash
git clone [your-repo]
cd [repo-name]
cp .env.example .env
docker-compose up -d
```bash

### Näited ja vihje'd

#### docker-compose.yml starter
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./frontend:/usr/share/nginx/html
    depends_on:
      - api

  api:
    build: ./backend
    environment:
      - DB_PASSWORD=${DB_PASSWORD}
    depends_on:
      - database
    # TODO: lisa Redis dependency

  database:
    image: postgres:13
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql

  # TODO: lisa Redis teenus

volumes:
  postgres_data:
```text

#### Backend starter (app.py)
```python
from flask import Flask, jsonify
import psycopg2
import os

app = Flask(__name__)

@app.route('/api/health')
def health():
    return jsonify({"status": "OK"})

@app.route('/api/users')
def get_users():
    # TODO: implementeeri andmebaasi ühendus
    # Vihje: kasutage psycopg2.connect() 
    # host="database", user="postgres", password=os.getenv('DB_PASSWORD')
    pass

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```text

#### Frontend starter (index.html)
```html
<!DOCTYPE html>
<html>
<head>
    <title>Docker App</title>
</head>
<body>
    <h1>My Application</h1>
    <button onclick="testAPI()">Test API</button>
    <button onclick="loadUsers()">Load Users</button>
    <div id="result"></div>

    <script>
        async function testAPI() {
            // TODO: tee fetch päring /api/health endpoint'ile
        }

        async function loadUsers() {
            // TODO: tee fetch päring /api/users endpoint'ile
            // Vihje: kasutage fetch() ja response.json()
        }
    </script>
</body>
</html>
```text

#### Database setup (init.sql)
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(200)
);

INSERT INTO users (name, email) VALUES 
('Test User', 'test@example.com');

-- TODO: lisa rohkem test andmeid
```bash

#### Vihje'd:
- Alustage PostgreSQL ja lihtsa API'ga
- Redis lisage hiljem cache'iks
- Kasutage teenuste nimesid docker-compose.yml'is ühenduste jaoks
- Environment variables võtke .env failist

---

## Ülesanne 2: Orkestreerimise mustrite lugemine (20 punkti)

### Lugemine
Lugege läbi: https://www.12factor.net/

### Ülesanne
Vastake järgmistele küsimustele (500-800 sõna):

1. Millised 12-factor printsiibid on teie Docker Compose projektis hästi rakendatud?

2. Millised printsiibid puuduvad või on halvasti implementeeritud teie projektis?

3. Kuidas muudaksite oma projekti, et see järgiks paremini 12-factor metodoloogiat?

### Esitamine
Lisage vastused README.md faili lõppu.

---

## Üldine esitamine

**Repository link:** [jagage minuga GitHub link]

---

**Edu kodutööga! 🐳**
