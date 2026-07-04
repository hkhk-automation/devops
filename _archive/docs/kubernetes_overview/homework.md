# Kubernetes Kodutöö: BookStore E-commerce Rakendus

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️
 
**Eesmärk:** Deploy'ida kolmeosaline web rakendus Kubernetes'i kasutades

---

## Ülesande Kirjeldus

Teie ülesanne on luua Kubernetes deployment lihtsa e-commerce rakenduse jaoks nimega "BookStore". Fork'ige antud repositoorium, parandage vigased failid ja lisage puuduvad komponendid.

### Arhitektuur
```text
Internet → Frontend (nginx) → Backend API → PostgreSQL Database
```

### Repository Link
**Starter Repository:** `https://github.com/your-instructor/bookstore-k8s-starter`

**Fork'ige see repo ja töötage oma koopias!**

---

## Praegused Failid Repo's (Vigased/Mittetäielikud!)

### 📁 `/database/postgres-secret.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
data:
  username: YWRtaW4=
  password: ""           #  PUUDU: lisa base64 encoded "mypassword123"
  database: ""           #  PUUDU: lisa base64 encoded "bookstore"
```text

### 📁 `/database/postgres-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db
  labels:
    app: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres      #  VIGA: ei vasta metadata labels'iga
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        ports:
        - containerPort: 5432
        #  PUUDUVAD: environment variables Secret'ist
        #  PUUDUVAD: resource limits
```text

### 📁 `/backend/backend-config.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  NODE_ENV: "development"     #  VALE: peaks olema "production"
  PORT: "8080"               #  VALE: peaks olema "3000"
  DATABASE_HOST: "localhost" #  VALE: peaks olema Kubernetes service nimi
  API_ENDPOINT: "/health"    #  ÕKE
```text

### 📁 `/backend/backend-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
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
      - name: api
        image: hashicorp/http-echo:0.2.3
        args:
        - -text=Hello from BookStore API
        - -listen=:3000
        ports:
        - containerPort: 3000
        #  PUUDUVAD: ConfigMap environment variables
        #  PUUDUVAD: health checks (liveness/readiness probes)
        #  PUUDUVAD: resource requests/limits
```text

### 📁 `/frontend/frontend-service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: ClusterIP          #  VIGA: peaks olema NodePort või LoadBalancer
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 8080       #  VIGA: nginx kuulab port 80
```text

### 📁 `/frontend/nginx-config.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  default.conf: |
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        location /api/ {
            proxy_pass http://backend-service:8080/;  #  VIGA: vale port
        }
    }
  #  PUUDU: index.html sisu
```text

### 📁 `/README.md` (Mittetäielik)
```markdown
# BookStore Kubernetes App

## What this does
Simple e-commerce app on Kubernetes

## How to run
```bash
kubectl apply -f .
```bash

#  PUUDUVAD:
# - Detailed setup instructions
# - Prerequisites
# - Troubleshooting
# - Architecture diagram
```

---

## Teie Ülesanded

### 1. Fork Repository
```bash
# Fork GitHub'is, seejärel:
git clone https://github.com/YOUR-USERNAME/bookstore-k8s-starter
cd bookstore-k8s-starter
```bash

### 2. Parandage Vigased Failid

**postgres-secret.yaml:**
- [ ] Lisa puuduv `password` base64 väärtus
- [ ] Lisa puuduv `database` base64 väärtus

**postgres-deployment.yaml:**
- [ ] Paranda labels selector match
- [ ] Lisa environment variables Secret'ist
- [ ] Lisa resource limits (memory: 256Mi, cpu: 200m)

**backend-config.yaml:**
- [ ] Muuda NODE_ENV → "production"
- [ ] Muuda PORT → "3000"
- [ ] Muuda DATABASE_HOST õigeks service nimeks

**backend-deployment.yaml:**
- [ ] Lisa ConfigMap environment variables
- [ ] Lisa liveness probe (HTTP GET :3000/)
- [ ] Lisa readiness probe (HTTP GET :3000/)
- [ ] Lisa resource limits

**frontend-service.yaml:**
- [ ] Muuda type NodePort või LoadBalancer'iks
- [ ] Paranda targetPort → 80

**nginx-config.yaml:**
- [ ] Paranda proxy_pass port number
- [ ] Lisa index.html sisu (lihtne HTML leht)

### 3. Looge Puuduvad Failid

**Puuduvad failid, mida te peate looma:**

- [ ] `/database/postgres-service.yaml`
- [ ] `/backend/backend-service.yaml`  
- [ ] `/frontend/frontend-deployment.yaml`

### 4. Täiendage README.md

Lisa järgmised sektsioonid:
- [ ] Prerequisites (Minikube, kubectl)
- [ ] Detailed deployment steps
- [ ] Testing instructions
- [ ] Troubleshooting common issues
- [ ] Architecture explanation

### 5. Testimine

```bash
# Deploy kõik
kubectl apply -f database/
kubectl apply -f backend/
kubectl apply -f frontend/

# Kontrolli
kubectl get all
minikube service frontend-service
```text

---

## Näited Õigetest Väärtustest

### Base64 Encoding Examples
```bash
echo -n "mypassword123" | base64
# Väljund: bXlwYXNzd29yZDEyMw==

echo -n "bookstore" | base64  
# Väljund: Ym9va3N0b3Jl
```text

### Environment Variables Example
```yaml
env:
- name: POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: username
```text

### Health Probe Example
```yaml
livenessProbe:
  httpGet:
    path: /
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
```text

### Resource Limits Example
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```bash

---

## Esitamine

### Git Workflow
```bash
# Tehke muudatused
git add .
git commit -m "Fix Kubernetes deployments and add missing files"
git push origin main

# Saatke mulle repo link
```bash

**Esitamisviis:** Saatke email'iga oma GitHub repo link koos lühikese kirjeldusega, mida muutsite.

### Nõutud Commit'id
Teie git history peaks näitama:
- [ ] Initial fork
- [ ] Fix secret values  
- [ ] Fix deployment configurations
- [ ] Add missing service files
- [ ] Complete frontend setup
- [ ] Update documentation

---

## Hindamiskriteeriumid

### Git ja Kood (40 punkti)
- [ ] Repository korrektselt fork'itud (5p)
- [ ] Kõik vead parandatud (20p)  
- [ ] Puuduvad failid lisatud (15p)

### Funktsionaalsus (40 punkti)
- [ ] Kõik pod'id käivituvad (15p)
- [ ] Service'id töötavad (10p)
- [ ] Väline ligipääs toimib (15p)

### Dokumentatsioon (20 punkti)
- [ ] README.md täielik (10p)
- [ ] Git commit message'id kirjeldavad muudatusi (10p)

---

## Abi ja Ressursid

### Kubernetes Dokumentatsioon
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

### Debug Käsud
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get services
```text

**Edu tööga!** Push'ige oma töö GitHub'i ja saatke link 📧
