# Kubernetes Labor - Intermediate

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Õppida Kubernetes'i edasijõudnud funktsioone ja tööriistade kompleksset kasutamist

---

## 1. Secret'id ja Turvalisus

### 1.1 Tundlike Andmete Haldamine

Erinevalt ConfigMap'ist, mis hoiab avalikku konfiguratsiooni, hoiavad Secret'id tundlikke andmeid nagu paroolid ja API võtmed. Secret'id on base64 kodeeritud (mitte krüpteeritud!) ja Kubernetes piirab nende ligipääsu.

```bash
# Looge secret käsurealt
kubectl create secret generic database-secret \
  --from-literal=username=postgres \
  --from-literal=password=SuperSecret123 \
  --from-literal=connection-string="postgresql://postgres:SuperSecret123@db:5432/myapp"

# Vaadake secret'i struktuuri
kubectl get secret database-secret -o yaml

# Dekodeerige base64 väärtus
echo "cG9zdGdyZXM=" | base64 -d
```text

### 1.2 Security Context ja Pod Turvalisus

Production keskkonnas tuleb pod'e käivitada minimaalse õigustega. Security context määrab, milliste õigustega pod töötab.

Looge fail `secure-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app-pod
spec:
  securityContext:
    runAsNonRoot: true    # Ei tohi käivituda root kasutajana
    runAsUser: 1000       # Kasuta UID 1000
    runAsGroup: 3000      # Kasuta GID 3000
    fsGroup: 2000         # Failisüsteemi õigused
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c"]
    args:
    - |
      echo "Käivitan turvaliselt!"
      echo "Kasutaja ID: $(id)"
      echo "Database kasutaja: $DB_USER"
      echo "Ühendusstring pikkus: ${#DB_CONNECTION}"
      sleep 3600
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: database-secret
          key: username
    - name: DB_CONNECTION
      valueFrom:
        secretKeyRef:
          name: database-secret
          key: connection-string
    securityContext:
      allowPrivilegeEscalation: false  # Ei saa õigusi tõsta
      readOnlyRootFilesystem: true     # Root failisüsteem read-only
      capabilities:
        drop:
        - ALL  # Eemalda kõik Linux capabilities
    volumeMounts:
    - name: tmp-volume
      mountPath: /tmp
    - name: secret-files
      mountPath: /etc/database
      readOnly: true
  volumes:
  - name: tmp-volume
    emptyDir: {}
  - name: secret-files
    secret:
      secretName: database-secret
      defaultMode: 0400  # Read-only owner'ile
```text

```bash
# Deploy'ige turvaline pod
kubectl apply -f secure-pod.yaml

# Kontrollige turvalisust
kubectl logs secure-app-pod
kubectl describe pod secure-app-pod

# Testige security piiranguid
kubectl exec -it secure-app-pod -- sh

# Pod'is proovige (peaks ebaõnnestuma):
echo "test" > /test.txt      # Read-only filesystem
whoami                      # Peaks näitama user 1000
ps aux                      # Vaadake protsessi omanik

exit
```text

**Kontrollpunkt:** Pod töötab mitteroot kasutajana ja read-only failisüsteemiga.

---

## 2. Health Check'id ja Monitoring

### 2.1 Probe'ide Tüübid

Kubernetes kasutab kolme tüüpi probe'e pod'ide tervise jälgimiseks:

- **Liveness Probe** - kas kontainer töötab? Kui mitte, restart
- **Readiness Probe** - kas kontainer on valmis liiklust vastu võtma?
- **Startup Probe** - kas kontainer on käivitunud? (aeglastele app'idele)

Looge fail `webapp-with-probes.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-with-health
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: hashicorp/http-echo:0.2.3
        args:
        - -text={"status":"ok","pod":"$(HOSTNAME)","version":"1.0"}
        - -listen=:8080
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        # Startup probe - annab aeglasele app'ile aega käivituda
        startupProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 6  # 30 sekundit aega käivituda
        # Readiness probe - kas ready liiklust vastu võtma?
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
        # Liveness probe - kas app töötab?
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        resources:
          requests:
            memory: "32Mi"
            cpu: "50m"
          limits:
            memory: "64Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 8080
  type: NodePort
```text

```bash
# Deploy'ige rakendus
kubectl apply -f webapp-with-probes.yaml

# Jälgige pod'ide käivitumist
kubectl get pods -l app=webapp -w

# Vaadake probe'ide tulemusi
kubectl describe pod -l app=webapp
```text

### 2.2 Health Check'ide Testimine

```bash
# Testige rakendust
minikube service webapp-service

# Simuleerige app'i "katkestamist"
kubectl exec -it deployment/webapp-with-health -- pkill http-echo

# Jälgige, kuidas Kubernetes reageerib
kubectl get pods -l app=webapp -w

# Vaadake event'e
kubectl get events --sort-by=.metadata.creationTimestamp
```text

**Kontrollpunkt:** Liveness probe tuvastab "katkise" konteiner'i ja restardib selle.

---

## 3. Rolling Update'id ja Deployment Strategies

### 3.1 Rolling Update Konfigureerimine

Rolling update võimaldab rakendust uuendada null downtime'iga. Kubernetes asendab vanu pod'e uutega järk-järgult.

Uuendage webapp deployment'i:

```yaml
# Lisage spec sektsiooni strategy osa
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1      # Max 1 pod võib olla kättesaamatu
      maxSurge: 1           # Max 1 lisa pod saab olla ajutiselt
```text

```bash
# Uuendage deployment'i
kubectl patch deployment webapp-with-health -p '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxUnavailable":1,"maxSurge":1}}}}'

# Simuleerige update'i
kubectl set image deployment/webapp-with-health webapp=hashicorp/http-echo:0.2.1

# Jälgige update'i progressi detailselt
kubectl rollout status deployment/webapp-with-health -w

# Vaadake update'i ajalugu
kubectl rollout history deployment/webapp-with-health

# Testige rollback'i
kubectl rollout undo deployment/webapp-with-health

# Kontrollige rollback'i tulemust
kubectl rollout status deployment/webapp-with-health
```text

### 3.2 Update Strategy Testimine

```bash
# Looge load test script
kubectl run load-tester --image=busybox --rm -it --restart=Never -- sh

# Load tester'is:
while true; do
  wget -qO- webapp-service && echo " - $(date)"
  sleep 1
done

# Teises terminalis tehke update
kubectl set image deployment/webapp-with-health webapp=hashicorp/http-echo:0.2.3
```text

Peaksite märkama, et teenus jääb kättesaadavaks update'i ajal.

**Kontrollpunkt:** Rolling update toimub ilma teenuse katkestusteta.

---

## 4. Persistent Storage

### 4.1 Volume'ide Vajadus

Vaikimisi pod'ide andmed kaovad pod'i restarti korral. Persistent volume'id lahendasid selle probleemi.

Looge fail `database-with-storage.yaml`:

```yaml
# PersistentVolume - füüsiline storage
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /tmp/postgres-data
---
# PersistentVolumeClaim - taotlus storage'i jaoks
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: manual
---
# PostgreSQL pod'iga PVC
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U $POSTGRES_USER -d $POSTGRES_DB
          initialDelaySeconds: 15
          periodSeconds: 5
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U $POSTGRES_USER -d $POSTGRES_DB
          initialDelaySeconds: 30
          periodSeconds: 10
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```text

```bash
# Deploy'ige PostgreSQL koos persistent storage'iga
kubectl apply -f database-with-storage.yaml

# Kontrollige PV ja PVC staatust
kubectl get pv
kubectl get pvc

# Kontrollige pod'i
kubectl get pods -l app=postgres

# Testige andmebaasi
kubectl exec -it deployment/postgres-db -- psql -U postgres -d myapp -c "CREATE TABLE test (id INT, name TEXT);"
kubectl exec -it deployment/postgres-db -- psql -U postgres -d myapp -c "INSERT INTO test VALUES (1, 'persistent data');"

# Kustutage pod ja vaadake, kas andmed säilivad
kubectl delete pod -l app=postgres
kubectl get pods -l app=postgres

# Kontrollige andmeid pärast pod'i taaskäivitumist
kubectl exec -it deployment/postgres-db -- psql -U postgres -d myapp -c "SELECT * FROM test;"
```text

**Kontrollpunkt:** Andmed säilivad pod'i taaskäivitamise järel.

---

## 5. Multi-Tier Rakenduse Deploy

### 5.1 Full-Stack Rakendus

Nüüd ühendame kõik osad: frontend, backend API ja andmebaas.

Looge fail `backend-api.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
    spec:
      containers:
      - name: api
        image: hashicorp/http-echo:0.2.3
        args:
        - -text
        - |
          {
            "service": "backend-api",
            "version": "2.0",
            "pod": "$(POD_NAME)",
            "database": "connected",
            "timestamp": "$(date -Iseconds)"
          }
        - -listen=:3000
        ports:
        - containerPort: 3000
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: connection-string
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 15
          periodSeconds: 10
        resources:
          requests:
            memory: "32Mi"
            cpu: "50m"
          limits:
            memory: "64Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-api-service
spec:
  selector:
    app: backend-api
  ports:
  - port: 3000
    targetPort: 3000
```text

### 5.2 Frontend koos Custom Configuration

Looge `frontend-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
data:
  nginx.conf: |
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
        
        location /api/ {
            proxy_pass http://backend-api-service:3000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Kubernetes Multi-Tier App</title>
        <style>
            body { font-family: Arial; margin: 40px; background: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
            button { padding: 10px 20px; margin: 10px; background: #007cba; color: white; border: none; border-radius: 5px; }
            .result { margin-top: 20px; padding: 15px; background: #f0f0f0; border-radius: 5px; }
            .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
            .success { background: #d4edda; color: #155724; }
            .error { background: #f8d7da; color: #721c24; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Kubernetes Multi-Tier Application</h1>
            <p>Frontend → Backend API → PostgreSQL Database</p>
            
            <div class="status success">
                <strong>Frontend Status:</strong>  Running
            </div>
            
            <button onclick="testBackend()">Test Backend API</button>
            <button onclick="testDatabase()">Test Database Connection</button>
            <button onclick="loadTest()">Load Test (10 requests)</button>
            
            <div id="result" class="result" style="display: none;"></div>
        </div>

        <script>
            function showResult(content, isError = false) {
                const result = document.getElementById('result');
                result.style.display = 'block';
                result.className = 'result ' + (isError ? 'error' : 'success');
                result.innerHTML = content;
            }

            async function testBackend() {
                try {
                    const response = await fetch('/api/');
                    const data = await response.text();
                    const json = JSON.parse(data);
                    showResult(`
                        <h3> Backend API Response</h3>
                        <pre>${JSON.stringify(json, null, 2)}</pre>
                    `);
                } catch (error) {
                    showResult(`<h3> Backend Error</h3><p>${error.message}</p>`, true);
                }
            }

            async function testDatabase() {
                // Simuleerime database testi
                showResult(`
                    <h3>🗄️ Database Status</h3>
                    <p>PostgreSQL:  Connected</p>
                    <p>Database: myapp</p>
                    <p>Tables: test (1 record)</p>
                `);
            }

            async function loadTest() {
                showResult('<h3>🔄 Running Load Test...</h3><p>Sending 10 requests to backend...</p>');
                
                const results = [];
                for (let i = 1; i <= 10; i++) {
                    try {
                        const start = Date.now();
                        const response = await fetch('/api/');
                        const data = await response.text();
                        const json = JSON.parse(data);
                        const duration = Date.now() - start;
                        results.push(`Request ${i}:  ${duration}ms (Pod: ${json.pod})`);
                    } catch (error) {
                        results.push(`Request ${i}:  ${error.message}`);
                    }
                }
                
                showResult(`
                    <h3>📊 Load Test Results</h3>
                    <pre>${results.join('\n')}</pre>
                `);
            }
        </script>
    </body>
    </html>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-nginx
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
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf
        - name: html-content
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 10
      volumes:
      - name: nginx-config
        configMap:
          name: frontend-config
      - name: html-content
        configMap:
          name: frontend-config
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
```text

### 5.3 Rakenduse Deploy ja Testimine

```bash
# Deploy'ige backend
kubectl apply -f backend-api.yaml

# Deploy'ige frontend
kubectl apply -f frontend-config.yaml

# Kontrollige kõiki komponente
kubectl get all

# Kontrollige service'ite connectivity't
kubectl get endpoints

# Avage rakendus
minikube service frontend-service
```text

Peaksite nägema täisfunktsionaalset web rakendust, mis suhtleb backend API'ga.

**Kontrollpunkt:** Teil on töötav multi-tier rakendus koos frontend'i, backend'i ja andmebaasiga.

---

## 6. Monitoring ja Troubleshooting

### 6.1 Klastri Monitooring

```bash
# Vaadake resource kasutamist
kubectl top nodes
kubectl top pods --all-namespaces

# Analüüsige event'e
kubectl get events --sort-by=.metadata.creationTimestamp

# Vaadake detailset pod'i infot
kubectl describe pod -l app=frontend

# Kontrollige service'ite endpoint'e
kubectl get endpoints --all-namespaces
```text

### 6.2 Network Troubleshooting

```bash
# Looge network debug pod
kubectl run netshoot --image=nicolaka/netshoot --rm -it -- bash

# Debug pod'is testige:
# DNS resolution
nslookup backend-api-service.default.svc.cluster.local
nslookup postgres-service.default.svc.cluster.local

# Connectivity test
curl backend-api-service:3000
nc -zv postgres-service 5432

# Trace network path
traceroute backend-api-service

exit
```text

---

## 7. Cleanup ja Kokkuvõte

```bash
# Kustutage kõik ressursid
kubectl delete -f frontend-config.yaml
kubectl delete -f backend-api.yaml
kubectl delete -f database-with-storage.yaml
kubectl delete -f webapp-with-probes.yaml
kubectl delete secret database-secret
kubectl delete pod secure-app-pod

# Kontrollige puhastust
kubectl get all

# Peatage Minikube
minikube stop
```text

---

## Kokkuvõte

**Mida õppisite:**

1. **Security** - Secret'ide kasutamine ja pod'ide turvalisus
2. **Health Monitoring** - Liveness, readiness ja startup probe'id
3. **Rolling Updates** - Null downtime deployment'id
4. **Persistent Storage** - Andmete püsiv salvestamine
5. **Multi-tier Architecture** - Keerukamate rakenduste deploy
6. **Troubleshooting** - Network debugging ja monitoring

**Production-ready oskused:**
- Turvaliselt konfigureeritud pod'id
- Automaatne health monitoring
- Zero-downtime update'id
- Andmete persistence
- Service mesh põhialused

**Järgmised sammud:**
- Helm package manager
- Ingress controller'id
- Horizontal Pod Autoscaler
- Custom Resource Definitions (CRD)
- Production klastri seadistamine cloud provider'is

---

## Viited

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/) - turvalisuse juhised
- [Kubernetes Probes Documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) - health check'ide seadistamine
- [Persistent Volumes Guide](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) - storage'i haldamine
- [Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) - deployment'ide strateegiad
