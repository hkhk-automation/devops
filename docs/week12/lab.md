# Praktikum — Nähtavus: mis toimub tegelikult?

> **Eelmine nädal:** Terraform moodulid / Ansible rollid.
> **Täna:** Deploy monitoorimise stack ja loe mõõdikuid.
> **Järgmine nädal:** Capstone — täielik tarnekonveier otsast lõpuni.

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

---

## Ülevaade

Täna ehitame kolmest teenusest koosneva monitoorimise stack'i:

```
flask-app (port 5000)  ←── Prometheus kogub mõõdikuid (port 9090)
                                        ↓
                             Grafana kuvab graafikuid (port 3000)
```

Kõik kolm teenust käivituvad koos Docker Compose'iga. Sina ei kirjuta rakenduse koodi — Flask app on juba instrumenteeritud.

---

## Eeldused

- Docker ja Docker Compose on installitud (nädal 5–6)
- Proxmox VM töötab ja SSH ühendus toimib
- Nädal 8 GHCR-i image on olemas (või kasutad õpetaja antud image'it)

---

## Osa 1 — Failide ettevalmistamine

### 1.1 Loo projekti kaust

Ühenda Proxmox VM-iga ja loo kaust:

```bash
ssh student@192.168.1.XX
mkdir -p ~/monitoring
cd ~/monitoring
```

### 1.2 Loo docker-compose.yml

```bash
nano docker-compose.yml
```

Kleebi sisu:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - monitoring

  flask-app:
    image: ghcr.io/sinugithubnimi/automation:latest
    container_name: flask-app
    ports:
      - "5000:5000"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  grafana-data:
```

!!! warning "Muuda image nimi"
    Asenda `ghcr.io/sinugithubnimi/automation:latest` oma tegeliku image nimega (nädal 8 GHCR). Kui pole, küsi õpetajalt — ta annab testimise image'i.

### 1.3 Loo Prometheus konfiguratsioon

```bash
nano prometheus.yml
```

Kleebi sisu:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'flask-app'
    static_configs:
      - targets: ['flask-app:5000']
    metrics_path: '/metrics'
```

`flask-app` on Docker Compose teenuse nimi — Compose võrk lahendab selle automaatselt IP-ks.

---

## Osa 2 — Stack käivitamine

### 2.1 Käivita kõik teenused

```bash
docker compose up -d
```

`-d` tähendab "detached" — käivitub taustal, terminal jääb vabaks.

### 2.2 Kontrolli, et kõik teenused käivitusid

```bash
docker compose ps
```

Peaksid nägema kolm teenust, kõigi olek `Up`:

```
NAME          IMAGE                    STATUS
flask-app     ghcr.io/...              Up
grafana       grafana/grafana          Up
prometheus    prom/prometheus          Up
```

Kui mõni teenus on `Exiting` või `Restarting` — vaata logisid:

```bash
docker compose logs flask-app
docker compose logs prometheus
```

### 2.3 Kontrolli ligipääsu

```bash
# Rakendus
curl http://localhost:5000

# Prometheuse mõõdikute endpoint
curl http://localhost:9090/-/healthy

# Flask app mõõdikud
curl http://localhost:5000/metrics
```

Viimane käsk peaks tagastama pikka tekstifaili koos mõõdikutega. Kui näed `# HELP` ridu — töötab.

---

## Osa 3 — Prometheuse seadistamine

### 3.1 Ava Prometheuse UI

Ava brauseris: `http://192.168.1.XX:9090`

(Asenda IP oma VM-i IP-ga)

### 3.2 Kontrolli, et Flask app on scrape sihtmärkide nimekirjas

Mine: `Status → Targets`

Peaksid nägema `flask-app` rea, olek `UP`. Kui olek on `DOWN`:
- Kontrolli, et Flask app töötab (`docker compose ps`)
- Kontrolli, et prometheus.yml on õige (`cat prometheus.yml`)
- Taaskäivita Prometheus: `docker compose restart prometheus`

### 3.3 Proovi lihtsat päringut

Prometheuse UI-s on otsinguriba. Sisesta:

```
http_requests_total
```

Klõpsa "Execute". Näed tabelit kõigi kogutud väärtustega.

Proovi ka:

```
rate(http_requests_total[1m])
```

See näitab päringute arvu minutis (muutumiskiirus, mitte koguarv).

---

## Osa 4 — Koormuse genereerimine

Tühja rakendust pole huvitav monitoorida. Genereerime koormust, et graafikud midagi näitaks.

### 4.1 Käivita koormustest

```bash
for i in {1..200}; do curl -s http://localhost:5000 > /dev/null; done
```

See saadab 200 päringut järjest.

Paralleelne koormus (aeglasema vastuse nägemiseks):

```bash
for i in {1..50}; do curl -s http://localhost:5000 & done
wait
```

### 4.2 Genereeri ka mõned vead (kui Flask app toetab)

```bash
# Proovi olematut URLi
for i in {1..20}; do curl -s http://localhost:5000/nonexistent > /dev/null; done
```

---

## Osa 5 — Grafana seadistamine

### 5.1 Ava Grafana

Ava brauseris: `http://192.168.1.XX:3000`

Sisselogimine:
- Kasutajanimi: `admin`
- Parool: `admin`

Grafana küsib parooli muutmist — võid vahele jätta (klõpsa "Skip").

### 5.2 Lisa Prometheus andmeallikas

1. Vasakul menüüs: `Connections → Data Sources`
2. Klõpsa "Add data source"
3. Vali "Prometheus"
4. URL väljale: `http://prometheus:9090`
5. Klõpsa "Save & test"

Peaksid nägema rohelist "Successfully queried the Prometheus API" teadet.

### 5.3 Impordi dashboard

Õpetaja jagab `dashboard.json` faili. Kui faili pole, kasuta Grafana avalikku dashboardi ID `1860` (Node Exporter Full) — või loo ise lihtne (järgmine samm).

**Dashboardi importimine:**
1. Vasakul menüüs: `Dashboards → Import`
2. Lae üles JSON fail või sisesta dashboard ID
3. Vali andmeallikaks äsja loodud Prometheus
4. Klõpsa "Import"

### 5.4 Loo lihtne paneel (kui JSON-i pole)

1. `Dashboards → New → New Dashboard → Add visualization`
2. Andmeallikas: Prometheus
3. Metrics browser'is sisesta:
   ```
   rate(http_requests_total[1m])
   ```
4. Paremal: paneeli pealkiri: "Päringud minutis"
5. Klõpsa "Apply"
6. Salvesta dashboard: `Cmd+S` / `Ctrl+S`

---

## Osa 6 — Graafikute analüüs

Pärast koormuse genereerimist vaata Grafana dashboardit.

### Kirjalik ülesanne — vasta kolmele küsimusele

Kirjuta vastused `docs/week12/` kausta loodavasse faili `vaatlused.md`:

**Küsimus 1:** Mida "Päringud minutis" graafik sulle ütleb? Kirjuta üks lõik (3–5 lauset) — mis number on hea, mis halb, mida see tähendab kasutajate kogemusele.

**Küsimus 2:** Kujutle, et graafik näitab järsku tõusu — näiteks 10 päringult minutis 500-le. Mis võib seda põhjustada? Loetle vähemalt 3 erinevat põhjust (mõtle: kas see on hea või halb?).

**Küsimus 3:** Milliseid lisagraafikuid tahaksid näha lisaks päringute arvule? Miks need olulised oleksid? Nimeta vähemalt 2.

```bash
# Loo fail
mkdir -p docs/week12
nano docs/week12/vaatlused.md
```

---

## Osa 7 — Koristus (lõpus)

```bash
docker compose down
```

`-v` lipuga kustutab ka Grafana andmete helitugevuse (kõik seaded lähevad kaotsi):

```bash
docker compose down -v
```

---

## Venitusülesanne

!!! tip "Venitusülesanne — neile, kes lõpetasid varem"

**Alertmanager — teavituse seadistamine**

Lisa docker-compose.yml-ile Alertmanager teenus:

```yaml
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    networks:
      - monitoring
```

Loo `alertmanager.yml`:

```yaml
global:
  resolve_timeout: 5m

route:
  receiver: 'webhook'

receivers:
  - name: 'webhook'
    webhook_configs:
      - url: 'http://localhost:5001/alert'
```

Lisa Prometheusele alert rule — loo fail `alerts.yml`:

```yaml
groups:
  - name: basic
    rules:
      - alert: HighRequestRate
        expr: rate(http_requests_total[1m]) > 10
        for: 30s
        annotations:
          summary: "Palju päringuid - {{ $value | printf \"%.0f\" }}/min"
```

Uuenda `prometheus.yml`:
```yaml
rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

Kopeeri `alerts.yml` VM-ile, taaskäivita stack ja genereeri koormust. Kontrolli `http://192.168.1.XX:9093` — kas alert käivitus?

---

## Kontrollnimekiri

- [ ] `docker compose up -d` käivitas kõik 3 teenust
- [ ] `docker compose ps` näitab kõik `Up`
- [ ] `curl http://localhost:5000/metrics` vastab mõõdikutega
- [ ] Prometheuse UI: `flask-app` target on `UP`
- [ ] Koormustest käivitati (200 päringut)
- [ ] Grafana on seadistatud Prometheus andmeallikaga
- [ ] Dashboard kuvab graafikuid
- [ ] `docs/week12/vaatlused.md` on täidetud kolme küsimusega
- [ ] `docker compose down` koristab teenused
