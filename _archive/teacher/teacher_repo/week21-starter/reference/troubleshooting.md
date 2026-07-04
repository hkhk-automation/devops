# 🔧 Troubleshooting Guide

**Kas oled kinni? Proovi need sammud järjekorras:**

## 🐳 Docker Compose Probleemid

### 1. Teenused ei käivitu

**Sümptomid:** `docker-compose up` ei tööta, teenused ei käivitu

**Lahendus:**
```bash
# 1. Kontrolli logisid - näed, mis viga on
docker-compose logs

# 2. Kontrolli üksikute teenuste logisid
docker-compose logs web
docker-compose logs backend
docker-compose logs db

# 3. Taaskäivita kõik teenused
docker-compose down
docker-compose up -d

# 4. Kontrolli teenuste staatust
docker-compose ps
```

**Mida vaadata:**
- Kas failid eksisteerivad? (`ls -la`)
- Kas pordid on vabad? (`lsof -i :8080`)
- Kas Docker töötab? (`docker --version`)

### 2. Port on juba kasutusel

**Sümptomid:** `port is already allocated` või `address already in use`

**Lahendus:**
```bash
# 1. Kontrolli mis kasutab porti
lsof -i :8080
lsof -i :5000

# 2. Peata teenus, mis kasutab porti
sudo kill -9 <PID>

# VÕI muuda porti docker-compose.yml failis:
ports:
  - "8081:80"  # 8080 asemel 8081
  - "5001:5000"  # 5000 asemel 5001
```

### 3. Andmebaasi ühendus ei tööta

**Sümptomid:** Backend ei saa ühenduda andmebaasiga

**Lahendus:**
```bash
# 1. Kontrolli kas PostgreSQL käivitus
docker-compose logs db

# 2. Kontrolli andmebaasi teenuse staatust
docker-compose ps db

# 3. Testi ühendust käsitsi
docker-compose exec db psql -U postgres -d app

# 4. Kontrolli keskkonnamuutujad
docker-compose exec backend env | grep DB
```

### 4. Fail ei leia

**Sümptomid:** `no such file or directory` või `file not found`

**Lahendus:**
```bash
# 1. Kontrolli kas fail eksisteerib
ls -la app/frontend/index.html
ls -la app/backend/app.py

# 2. Kontrolli faili õigused
chmod 644 app/frontend/index.html
chmod 644 app/backend/app.py

# 3. Kontrolli volume seaded docker-compose.yml failis
volumes:
  - ./app/frontend:/usr/share/nginx/html:ro
```

## ☸️ Kubernetes Probleemid

### 1. Podid ei käivitu

**Sümptomid:** Podid on `Pending` või `Error` staatuses

**Lahendus:**
```bash
# 1. Kontrolli podide staatust
kubectl get pods -n docker-orchestration-app

# 2. Vaata üksikute podide üksikasju
kubectl describe pod <pod-name> -n docker-orchestration-app

# 3. Vaata podide logisid
kubectl logs <pod-name> -n docker-orchestration-app

# 4. Kontrolli namespace
kubectl get namespace docker-orchestration-app
```

**Levinud põhjused:**
- Image ei leia (`ImagePullBackOff`)
- Liiga vähe ressursse (`Pending`)
- Konfiguratsiooni viga (`CrashLoopBackOff`)

### 2. Image ei leia

**Sümptomid:** `ImagePullBackOff` või `ErrImagePull`

**Lahendus:**
```bash
# 1. Kontrolli kas image on olemas
docker images | grep docker-orchestration

# 2. Build image uuesti
cd app/backend
docker build -t docker-orchestration-backend:latest .

# 3. Load image Minikube'i
minikube image load docker-orchestration-backend:latest

# 4. Kontrolli image Minikube'is
minikube ssh "docker images | grep docker-orchestration"
```

### 3. Service ei ühendu

**Sümptomid:** Ei saa ühenduda teenusega, `connection refused`

**Lahendus:**
```bash
# 1. Kontrolli service'i
kubectl get services -n docker-orchestration-app

# 2. Kontrolli service'i üksikasju
kubectl describe service <service-name> -n docker-orchestration-app

# 3. Testi port-forward
kubectl port-forward service/frontend-service 8081:80 -n docker-orchestration-app

# 4. Kontrolli podide valikud
kubectl get pods -l app=frontend -n docker-orchestration-app
```

## 🔍 Levinud Vead ja Lahendused

### 1. "Connection refused"
**Põhjus:** Teenus ei tööta või port on suletud
**Lahendus:**
- Kontrolli kas teenus käivitus
- Kontrolli porti konfiguratsiooni
- Kontrolli firewall'i seadeid

### 2. "Image not found"
**Põhjus:** Docker image ei eksisteeri
**Lahendus:**
- Build image uuesti
- Load image Minikube'i (kui kasutad K8s)
- Kontrolli image nime õigsust

### 3. "Permission denied"
**Põhjus:** Faili õigused on valed
**Lahendus:**
- Kasuta `sudo` vajadusel
- Kontrolli faili õigused: `ls -la`
- Muuda õigusi: `chmod 644 <fail>`

### 4. "No such file or directory"
**Põhjus:** Fail ei eksisteeri või tee on vale
**Lahendus:**
- Kontrolli faili olemasolu: `ls -la`
- Kontrolli tee õigsust
- Kontrolli volume seaded

## 🛠️ Debugimise Käsud

### Docker Compose
```bash
# Vaata kõiki container'eid
docker ps

# Vaata container'i sisu
docker exec -it <container-name> sh

# Vaata faili sisu container'is
docker exec <container-name> cat /path/to/file

# Kontrolli võrku
docker network ls
docker network inspect <network-name>
```

### Kubernetes
```bash
# Vaata kõiki ressurssideid
kubectl get all -n docker-orchestration-app

# Vaata konkreetse ressurssi üksikasju
kubectl describe <resource-type> <name> -n docker-orchestration-app

# Vaata logisid reaalajas
kubectl logs -f <pod-name> -n docker-orchestration-app

# Kontrolli konfiguratsiooni
kubectl get configmap -n docker-orchestration-app
kubectl get secret -n docker-orchestration-app
```

## 📞 Kui midagi ei aita

**Järjekord:**
1. **Kontrolli juhendid** `week_21/` kaustast
2. **Vaata näiteid** `templates/` kaustast
3. **Kontrolli dokumentatsiooni** linkide kaudu
4. **Pöördu õppejõu poole**

**Kui pöördud õppejõu poole, siis:**
- Kirjelda probleemi täpselt
- Lisa veateated
- Lisa käsud, mida proovisid
- Lisa logid

---

**Ära anna alla! Kõik probleemid on lahendatavad! 💪**

**Mäleta:** Iga viga on õppimise võimalus! 🎓
