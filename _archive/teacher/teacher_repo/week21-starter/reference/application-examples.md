# 🚀 Application Examples - Complete Reference

**⚠️ OLULINE: Ära kopeeri need otse! Kasuta ainult viitena!**

## 🌐 Frontend Example

**app/frontend/index.html:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Week 21 Homework</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background-color: #f5f5f5;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .status { 
            background-color: #d4edda; 
            color: #155724; 
            padding: 15px; 
            border-radius: 4px;
            margin: 10px 0;
        }
        .error { 
            background-color: #f8d7da; 
            color: #721c24; 
        }
        button {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }
        button:hover {
            background-color: #0056b3;
        }
        .api-section {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 4px;
            margin: 10px 0;
        }
        pre {
            background-color: #f1f1f1;
            padding: 10px;
            border-radius: 4px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Week 21 Homework</h1>
        <h2>Docker Compose Multi-Container App</h2>
        
        <div id="status" class="status">
            <h3>📊 Rakenduse staatus</h3>
            <p><strong>Frontend:</strong> <span id="frontend-status">✅ Töötab</span></p>
            <p><strong>Backend:</strong> <span id="backend-status">⏳ Kontrollin...</span></p>
            <p><strong>Database:</strong> <span id="db-status">⏳ Kontrollin...</span></p>
            <p><strong>Aeg:</strong> <span id="timestamp"></span></p>
        </div>

        <div class="api-section">
            <h3>🔧 API Testimine</h3>
            <button onclick="testBackend()">Testi Backend'i</button>
            <button onclick="testDatabase()">Testi Andmebaasi</button>
            <button onclick="testHealth()">Health Check</button>
            <button onclick="refreshStatus()">Värskenda</button>
        </div>

        <div id="results"></div>

        <div class="api-section">
            <h3>📚 API Endpoint'id</h3>
            <p><strong>GET /api/status</strong> - Rakenduse üldine staatus</p>
            <p><strong>GET /api/db-test</strong> - Andmebaasi ühenduse test</p>
            <p><strong>GET /api/health</strong> - Tervise kontroll</p>
        </div>
    </div>

    <script>
        // Värskenda aega
        function updateTime() {
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
        }
        updateTime();
        setInterval(updateTime, 1000);

        // Testi backend'i
        async function testBackend() {
            try {
                const response = await fetch('/api/status');
                const data = await response.json();
                
                document.getElementById('backend-status').textContent = '✅ Töötab';
                document.getElementById('db-status').textContent = data.database === 'Connected' ? '✅ Töötab' : '❌ Ei tööta';
                
                document.getElementById('results').innerHTML = `
                    <div class="status">
                        <h4>Backend vastus:</h4>
                        <pre>${JSON.stringify(data, null, 2)}</pre>
                    </div>
                `;
            } catch (error) {
                document.getElementById('backend-status').textContent = '❌ Ei tööta';
                document.getElementById('results').innerHTML = `
                    <div class="status error">
                        <h4>Viga:</h4>
                        <p>${error.message}</p>
                    </div>
                `;
            }
        }

        // Testi andmebaasi
        async function testDatabase() {
            try {
                const response = await fetch('/api/db-test');
                const data = await response.json();
                
                document.getElementById('results').innerHTML = `
                    <div class="status">
                        <h4>Andmebaasi test:</h4>
                        <pre>${JSON.stringify(data, null, 2)}</pre>
                    </div>
                `;
            } catch (error) {
                document.getElementById('results').innerHTML = `
                    <div class="status error">
                        <h4>Andmebaasi viga:</h4>
                        <p>${error.message}</p>
                    </div>
                `;
            }
        }

        // Testi health check
        async function testHealth() {
            try {
                const response = await fetch('/api/health');
                const data = await response.json();
                
                document.getElementById('results').innerHTML = `
                    <div class="status">
                        <h4>Health Check:</h4>
                        <pre>${JSON.stringify(data, null, 2)}</pre>
                    </div>
                `;
            } catch (error) {
                document.getElementById('results').innerHTML = `
                    <div class="status error">
                        <h4>Health Check viga:</h4>
                        <p>${error.message}</p>
                    </div>
                `;
            }
        }

        // Värskenda staatust
        function refreshStatus() {
            testBackend();
        }

        // Kontrolli staatust lehe laadimisel
        window.onload = function() {
            testBackend();
        };
    </script>
</body>
</html>
```

## 🔧 Backend Example

**app/backend/app.py:**
```python
from flask import Flask, jsonify
import os
import psycopg2
from datetime import datetime

app = Flask(__name__)

def get_db_connection():
    """Ühenda andmebaasiga"""
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'db'),
            database=os.getenv('DB_NAME', 'app'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD', 'secret')
        )
        return conn
    except Exception as e:
        print(f"Andmebaasi ühenduse viga: {e}")
        return None

@app.route('/')
def home():
    """Koduleht"""
    return jsonify({
        'message': 'Week 21 Homework Backend API',
        'endpoints': {
            '/api/status': 'Rakenduse staatus',
            '/api/db-test': 'Andmebaasi test',
            '/api/health': 'Tervise kontroll'
        }
    })

@app.route('/api/status')
def status():
    """Tagasta rakenduse staatus"""
    db_status = "Connected" if get_db_connection() else "Disconnected"
    
    return jsonify({
        'status': 'OK',
        'environment': os.getenv('NODE_ENV', 'development'),
        'database': db_status,
        'timestamp': datetime.now().isoformat(),
        'message': 'Week 21 Homework Backend töötab!',
        'version': '1.0.0'
    })

@app.route('/api/db-test')
def db_test():
    """Testi andmebaasi ühendust"""
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT version();")
            version = cursor.fetchone()
            cursor.close()
            conn.close()
            
            return jsonify({
                'status': 'success',
                'message': 'Andmebaasi ühendus töötab!',
                'database_version': version[0] if version else 'Unknown',
                'connection_info': {
                    'host': os.getenv('DB_HOST', 'db'),
                    'database': os.getenv('DB_NAME', 'app'),
                    'user': os.getenv('DB_USER', 'postgres')
                }
            })
        except Exception as e:
            return jsonify({
                'status': 'error',
                'message': f'Andmebaasi päringu viga: {str(e)}'
            }), 500
    else:
        return jsonify({
            'status': 'error',
            'message': 'Ei saa ühenduda andmebaasiga',
            'connection_info': {
                'host': os.getenv('DB_HOST', 'db'),
                'database': os.getenv('DB_NAME', 'app'),
                'user': os.getenv('DB_USER', 'postgres')
            }
        }), 500

@app.route('/api/health')
def health():
    """Tervise kontroll"""
    db_healthy = get_db_connection() is not None
    
    return jsonify({
        'status': 'healthy' if db_healthy else 'unhealthy',
        'database': 'connected' if db_healthy else 'disconnected',
        'timestamp': datetime.now().isoformat(),
        'uptime': 'running'
    })

@app.route('/api/info')
def info():
    """Süsteemi info"""
    return jsonify({
        'application': 'Week 21 Homework Backend',
        'framework': 'Flask',
        'python_version': os.sys.version,
        'environment_variables': {
            'DB_HOST': os.getenv('DB_HOST', 'not_set'),
            'DB_NAME': os.getenv('DB_NAME', 'not_set'),
            'DB_USER': os.getenv('DB_USER', 'not_set'),
            'NODE_ENV': os.getenv('NODE_ENV', 'development')
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

**app/backend/requirements.txt:**
```txt
Flask==2.3.3
psycopg2-binary==2.9.7
```

**app/backend/Dockerfile:**
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

## 🐳 Docker Compose Example

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  # Frontend - lihtne HTML rakendus
  frontend:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./app/frontend:/usr/share/nginx/html:ro
    depends_on:
      - backend
    restart: unless-stopped

  # Backend - Flask API
  backend:
    build: ./app/backend
    ports:
      - "5000:5000"
    environment:
      - DB_HOST=db
      - DB_NAME=app
      - DB_USER=postgres
      - DB_PASSWORD=secret
      - NODE_ENV=development
    depends_on:
      - db
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Database - PostgreSQL
  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=secret
    volumes:
      - db_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  db_data:
```

---

**Mäleta:** Need on ainult näited! Õppimine toimub ise tehes! 🎓
