# 📋 Templates - Näidised ja Mallid

**⚠️ OLULINE: Ära kopeeri need failid otse! Kasuta neid ainult viitena!**

## 🎯 Mida siin on?

See kaust sisaldab **näiteid** ja **malle**, mida saad kasutada oma failide loomisel. Need ei ole täielikud lahendused, vaid ainult viited.

## 📁 Failide selgitus

### Docker Compose
- **`docker-compose.yml.example`** - Näide, kuidas kirjutada Docker Compose faili
- **Mida õppida:** Teenuste definitsioonid, pordid, volumes, keskkonnamuutujad

### Frontend
- **`app/frontend/`** - Näide lihtsast HTML rakendusest
- **Mida õppida:** Lihtne web rakendus, mis suhtleb backend'iga

### Backend
- **`app/backend/`** - Näide Python Flask API'st
- **Mida õppida:** API endpoint'id, andmebaasi ühendus, keskkonnamuutujad

### Kubernetes
- **`k8s/`** - Näited Kubernetes manifestidest
- **Mida õppida:** Deployments, Services, ConfigMaps, PVC

## 🚀 Kuidas kasutada?

### 1. Ära tee copy-paste!
```bash
# ❌ Ära tee seda:
cp templates/docker-compose.yml.example docker-compose.yml

# ✅ Tee seda:
# 1. Vaata näidet
# 2. Mõista, mida iga rida teeb
# 3. Kirjuta oma fail ise
```

### 2. Vaata ja mõista
```bash
# Vaata näidet
cat templates/docker-compose.yml.example

# Mõista iga rida:
# - version: Compose faili versioon
# - services: Teenuste definitsioonid
# - image: Millist Docker image'i kasutada
# - ports: Millised pordid avada
```

### 3. Kirjuta ise
```bash
# Loo oma fail
touch docker-compose.yml

# Kirjuta oma konfiguratsioon
# Kasuta näidet viitena, aga kirjuta ise
```

## 📚 Mida õppida igast failist?

### Docker Compose
- **Teenuste definitsioonid** - kuidas kirjeldada container'eid
- **Võrgu konfiguratsioon** - kuidas teenused omavahel suhtlevad
- **Volume seaded** - kuidas andmeid säilitada
- **Keskkonnamuutujad** - kuidas konfiguratsiooni hallata

### Frontend
- **Lihtne HTML** - kuidas luua kasutajaliides
- **JavaScript** - kuidas suhelda backend'iga
- **CSS** - kuidas stiilida rakendust

### Backend
- **Flask API** - kuidas luua API endpoint'eid
- **Andmebaasi ühendus** - kuidas ühenduda PostgreSQL'iga
- **Keskkonnamuutujad** - kuidas konfiguratsiooni hallata

### Kubernetes
- **Deployments** - kuidas juurutada rakendusi
- **Services** - kuidas teenuseid avalikustada
- **ConfigMaps** - kuidas konfiguratsiooni hallata
- **PVC** - kuidas püsivaid andmeid hallata

## ⚠️ Olulised märkused

1. **Ära kopeeri otse** - õppimise eesmärk on failid ise luua
2. **Mõista iga rida** - miks see vajalik on ja mida see teeb
3. **Kohanda oma vajadustele** - muuda nimesid, porde, seadeid
4. **Testi oma lahendust** - ära usalda ainult näiteid

## 🔍 Kui oled kinni

1. **Vaata näidet** - võib-olla annab see vihje
2. **Kontrolli dokumentatsiooni** - Docker Compose, Kubernetes
3. **Küsi abi** - õppejõult või kolleegidelt
4. **Proovi ise** - õppimine toimub katsetamise kaudu

---

**Mäleta:** Näited on ainult viited! Õppimine toimub ise tehes! 🎓
