# ☸️ Kubernetes Examples - Complete Reference

**⚠️ OLULINE: Ära kopeeri need otse! Kasuta ainult viitena!**

## 📁 Namespace

**k8s/namespace/namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: docker-orchestration-app
  labels:
    name: docker-orchestration-app
```

## 🗄️ Database Components

**k8s/database/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database-deployment
  namespace: docker-orchestration-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "app"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          value: "secret"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```

**k8s/database/pvc.yaml:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: docker-orchestration-app
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

**k8s/database/service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: docker-orchestration-app
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
```

## 🔧 Backend Components

**k8s/backend/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: docker-orchestration-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: flask-app
        image: docker-orchestration-backend:latest
        ports:
        - containerPort: 5000
        env:
        - name: DB_HOST
          value: "database-service"
        - name: DB_NAME
          value: "app"
        - name: DB_USER
          value: "postgres"
        - name: DB_PASSWORD
          value: "secret"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
```

**k8s/backend/service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: docker-orchestration-app
spec:
  selector:
    app: backend
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
```

## 🌐 Frontend Components

**k8s/frontend/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: docker-orchestration-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: frontend-files
          mountPath: /usr/share/nginx/html
      volumes:
      - name: frontend-files
        configMap:
          name: frontend-config
```

**k8s/frontend/configmap.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: docker-orchestration-app
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Docker Orchestration Kubernetes App</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 800px; margin: 0 auto; }
            .status { background-color: #d4edda; padding: 15px; border-radius: 4px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Docker Orchestration Kubernetes Homework</h1>
            <div class="status">
                <h3>📊 Rakenduse staatus</h3>
                <p><strong>Frontend:</strong> ✅ Töötab (Kubernetes)</p>
                <p><strong>Backend:</strong> <span id="backend-status">⏳ Kontrollin...</span></p>
                <p><strong>Database:</strong> <span id="db-status">⏳ Kontrollin...</span></p>
            </div>
            <button onclick="testBackend()">Testi Backend'i</button>
            <div id="results"></div>
        </div>
        <script>
            async function testBackend() {
                try {
                    const response = await fetch('/api/status');
                    const data = await response.json();
                    document.getElementById('backend-status').textContent = '✅ Töötab';
                    document.getElementById('db-status').textContent = data.database === 'Connected' ? '✅ Töötab' : '❌ Ei tööta';
                    document.getElementById('results').innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
                } catch (error) {
                    document.getElementById('backend-status').textContent = '❌ Ei tööta';
                    document.getElementById('results').innerHTML = `<p>Viga: ${error.message}</p>`;
                }
            }
            testBackend();
        </script>
    </body>
    </html>
```

**k8s/frontend/service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: docker-orchestration-app
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

---

**Mäleta:** Need on ainult näited! Õppimine toimub ise tehes! 🎓
