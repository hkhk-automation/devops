# 🚀 Week 21 Starter Template

**⚠️ OLULINE: See on ainult starter template! Õpilased peavad failid ise looma!**

## 📋 Eesmärk

See kaust sisaldab ainult **starter templates** ja **reference examples** Week 21 kodutöö jaoks. Õpilased peavad:

1. **Lugema juhendid** `week_21/` kaustast
2. **Loomad failid ise** juhendite järgi
3. **Kasutada seda kausta** ainult viitena või abina

## 📁 Struktuur

```
docker-orchestration-starter/
├── templates/           # Näidised ja mallid
│   ├── docker-compose.yml.example
│   ├── app/
│   │   ├── frontend/
│   │   └── backend/
│   └── k8s/
├── reference/           # Viited ja dokumentatsioon
│   ├── kubernetes-examples/
│   ├── troubleshooting.md
│   └── deploy.sh
└── README.md           # See fail
```

## 🎯 Kuidas kasutada

### Õpilastele:
1. **Ära kopeeri failid otse!**
2. **Loe juhendeid** `week_21/` kaustast
3. **Loo failid ise** juhendite järgi
4. **Kasuta seda kausta** ainult kui oled kinni

### Õppejõudele:
- Seda kausta saab jagada õpilastega kui nad on kinni
- Või kasutada kontrollimiseks, kas õpilaste lahendused on õiged

## 📚 Mida õpilased peavad tegema

### 1. Loo projekti struktuur
```bash
mkdir docker-orchestration-homework
cd docker-orchestration-homework
mkdir -p app/{frontend,backend}
mkdir -p k8s/{namespace,database,backend,frontend}
```

### 2. Loo rakenduse komponendid
- **Frontend:** Lihtne HTML/CSS/JS rakendus
- **Backend:** Python Flask API
- **Database:** PostgreSQL konfiguratsioon

### 3. Loo Docker Compose fail
- Teenuste definitsioonid
- Võrgu konfiguratsioon
- Volume seaded

### 4. Loo Kubernetes manifests
- Namespace
- Deployments
- Services
- ConfigMaps

## 🔧 Levinud probleemid ja lahendused

### Docker Compose
- **Port on juba kasutusel:** Muuda porti `docker-compose.yml` failis
- **Teenused ei käivitu:** Kontrolli logisid `docker-compose logs`
- **Andmebaasi ühendus:** Kontrolli keskkonnamuutujad

### Kubernetes
- **Podid ei käivitu:** Kontrolli `kubectl get pods -n docker-orchestration-app`
- **Image ei leia:** Build image ja load Minikube'i
- **Service ei ühendu:** Kontrolli port-forward

## 📖 Lisaressursid

### Dokumentatsioon
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Flask Documentation](https://flask.palletsprojects.com/)

### Näited
- Vaata `templates/` kausta näiteid
- Kontrolli `reference/` kausta viiteid

## ⚠️ Oluline!

**Ära tee copy-paste!** See on ainult viide. Õppimise eesmärk on failid ise luua ja mõista, mida iga rida teeb.

**Õppimise järjekord:**
1. Loe juhendid `week_21/` kaustast
2. Proovi ise luua failid
3. Kasuta seda kausta ainult kui oled kinni
4. Küsi abi õppejõult

---

**Edu kodutöö tegemisel! 🎉**
