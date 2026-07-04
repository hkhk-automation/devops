# Kubernetes Labor - Põhialused

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Mõista Kubernetes'i põhikontseptsioone ja teha esimesed sammud

---

## 1. Keskkonna Seadistamine

### 1.1 Minikube Installeerimine

Minikube on tööriist, mis loob kohaliku Kubernetes klastri teie arvutis. See emuleerib päris Kubernetes keskkonda, kuid töötab ühes masinas.

**Miks Minikube?** Päris Kubernetes klaster vajab mitut serverit ja keerukat seadistust. Minikube teeb selle lihtsaks õppimiseks.

```bash
# macOS
brew install minikube

# Linux  
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Kontrollige installatsiooni
minikube version
```text

### 1.2 Klastri Käivitamine

```bash
# Käivitage Minikube
minikube start

# Kontrollige, et kõik töötab
kubectl cluster-info
kubectl get nodes
```bash

Peaksite nägema ühte node'i "Ready" staatuses. See on teie kohalik Kubernetes klaster.

**Kontrollpunkt:** `kubectl get nodes` näitab "Ready" staatust.

---

## 2. Esimene Pod

### 2.1 Pod'i Mõiste

Pod on Kubernetes'i väikseim üksus. Mõelge sellele nagu "wrapper'ile" ühe või mitme konteineri ümber. Tavaliselt on pod'is üks kontainer.

**Miks mitte lihtsalt kontainer?** Pod annab konteinerile IP aadressi, DNS nime ja võimaluse jagada failisüsteemi teiste pod'i konteineritega.

```bash
# Looge esimene pod
kubectl run nginx-pod --image=nginx:1.20 --port=80

# Vaadake pod'i staatust
kubectl get pods

# Vaadake detailset infot
kubectl describe pod nginx-pod
```text

### 2.2 Pod'iga Suhtlemine

```bash
# Vaadake pod'i logisid
kubectl logs nginx-pod

# Minge pod'i sisse
kubectl exec -it nginx-pod -- /bin/bash

# Pod'i sees saate testida:
curl localhost
exit

# Testiga kohalikult (avahe uus terminal)
kubectl port-forward nginx-pod 8080:80
# Avage brauseris: http://localhost:8080
```text

**Selgitus:** Port forwarding suunab teie arvuti pordi 8080 pod'i porti 80. Nii saate pod'i testida nagu see oleks teie arvutis.

```bash
# Kustutage pod
kubectl delete pod nginx-pod
```text

**Kontrollpunkt:** Saite luua pod'i, testida seda ja kustutada.

---

## 3. Deployment - Rakenduse Haldamine

### 3.1 Miks Deployment?

Üksik pod on nagu üksik töötaja. Kui töötaja haigestub (pod kukub), ei ole kedagi, kes tööd jätkaks. Deployment on nagu manager - ta jälgib, et töötajaid oleks alati õige arv.

Looge fail `nginx-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3  # Tahame 3 pod'i
  selector:
    matchLabels:
      app: nginx
  template:    # Kuidas pod välja näeb
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
```text

```bash
# Looge deployment
kubectl apply -f nginx-deployment.yaml

# Vaadake deployment'i
kubectl get deployments

# Vaadake pod'e
kubectl get pods

# Vaadake, mis juhtub kui pod'i kustutada
kubectl delete pod <nginx-pod-name>
kubectl get pods
```text

**Märkate:** Uus pod tekib automaatselt! Deployment taastas soovitud oleku.

### 3.2 Skaleerimise Test

```bash
# Skaleerige 5 pod'ini
kubectl scale deployment nginx-deployment --replicas=5

# Vaadage tulemust
kubectl get pods

# Skaleerige tagasi 2 pod'ini  
kubectl scale deployment nginx-deployment --replicas=2

# Vaadake, kuidas pod'id kustutatakse
kubectl get pods
```text

**Kontrollpunkt:** Mõistate, kuidas Deployment hoiab soovitud arvu pod'e töös.

---

## 4. Service - Stabiilne Ligipääs

### 4.1 Service'i Probleem

Pod'ide IP aadressid muutuvad! Kui pod taaskäivitatakse, saab ta uue IP. Kuidas teised pod'id teda leiavad?

Service lahendab selle - ta annab stabiilse IP aadressi ja DNS nime.

Looge fail `nginx-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx  # Leiab kõik pod'id label'iga app=nginx
  ports:
  - port: 80
    targetPort: 80
  type: NodePort  # Võimaldab välisest ligipääsu
```text

```bash
# Looge service
kubectl apply -f nginx-service.yaml

# Vaadake service'e
kubectl get services

# Testige service'i DNS'd
kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh

# Test pod'is:
nslookup nginx-service
wget -qO- nginx-service
exit
```text

### 4.2 Väline Ligipääs

```bash
# Avage service väljastpoolt
minikube service nginx-service
```text

See peaks avama brauseri nginx'i lehega.

**Kontrollpunkt:** Service suunab liikluse pod'idele ja on ligipääsetav väljastpoolt.

---

## 5. ConfigMap - Konfiguratsioon

### 5.1 Miks ConfigMap?

Rakendused vajavad konfiguratsiooni (andmebaasi URL, API võtmed). Neid ei tohiks kõvakoodida image'i sisse. ConfigMap hoiab neid eraldi.

```bash
# Looge ConfigMap käsurealt
kubectl create configmap app-config \
  --from-literal=database.host=postgres-service \
  --from-literal=api.timeout=30 \
  --from-literal=environment=development

# Vaadake ConfigMap'i
kubectl get configmap app-config -o yaml
```text

### 5.2 ConfigMap'i Kasutamine

Looge fail `config-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-test-pod
spec:
  containers:
  - name: test
    image: busybox
    command: ["sh", "-c", "echo Database: $DB_HOST; echo Timeout: $API_TIMEOUT; sleep 3600"]
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.host
    - name: API_TIMEOUT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: api.timeout
```text

```bash
# Deploy'ige pod
kubectl apply -f config-pod.yaml

# Vaadake tulemust
kubectl logs config-test-pod
```text

**Kontrollpunkt:** Pod kasutab ConfigMap'i väärtuseid keskkonnamuutujatena.

---

## 6. Cleanup

```bash
# Kustutage kõik ressursid
kubectl delete deployment nginx-deployment
kubectl delete service nginx-service
kubectl delete configmap app-config
kubectl delete pod config-test-pod

# Peatage Minikube
minikube stop
```bash

---

## Kokkuvõte

**Mida õppisite:**
- **Pod** - väikseim üksus, sisaldab konteinereid
- **Deployment** - haldab pod'ide arvu ja uuendusi
- **Service** - stabiilne võrguligipääs pod'idele
- **ConfigMap** - konfiguratsioon rakenduste jaoks

**Järgmises osas (Intermediate):**
- Secret'id ja turvalisus
- Health check'id ja monitoring
- Rolling update'id
- Keerukamad rakendused

---

## Viited

- [Kubernetes Official Documentation](https://kubernetes.io/docs/) - ametlik dokumentatsioon
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/) - Minikube seadistamine
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) - kasulikud käsud
