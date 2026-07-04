# Docker Orkestratsioon

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

## Sissejuhatus

Kaasaegses IT-maailmas koosneb enamik rakendusi mitmest komponendist. Ettevõtte veebileht vajab tavaliselt veebiserver staatiliste failide jaoks, rakendusserver äriloogika täitmiseks, andmebaas andmete säilitamiseks ja võib-olla veel cache kiiruse parandamiseks. Traditsionaalselt paigaldati need kõik samale serverile või hallati eraldi serverites keeruliste skriptidega.

Docker on muutnud olukorda - iga komponent saab oma container'isse. See toob kaasa märkimisväärseid eeliseid: komponente saab sõltumatult skaleerida, arendada ja testimiseks kiiresti üles seadistada. Kuid mitme container'i käsitsi haldamine muutub kiiresti keeruliseks - tuleb meeles pidada õiget käivitamise järjekorda, konfigureerida võrke ja hallata andmete säilitamist.

Docker Compose lahendab need väljakutsed, võimaldades defineerida kogu süsteemi ühe YAML failiga. See on orkestreerimise tööriist, mis automatiseerib mitme container'i koordineerimise ja annab arendajatele võimaluse keskenduda äriloogikale, mitte infrastruktuuri detailidele.

## Mitme-konteineriga süsteemide vajadus

### Monoliitiline lähenemine ja selle piirangud

Kui me paigaldame kõik komponendid ühte container'isse, tekivad kiiresti probleemid. Kujutage ette container'it, mis sisaldab Nginx veebiserverit, Python rakendusserverit ja PostgreSQL andmebaasi. Selline lahendus tundub alguses lihtne, kuid praktikas osutub see mitmel viisil ebaefektiivseks.

Esiteks, skaleerimise probleem. Kui teie rakendus vajab rohkem arvutusvõimsust API päringute töötlemiseks, ei saa te käivitada ainult rohkem rakendusserveri instantse - teil tuleb käivitada terve container koos andmebaasiga. See raiskab ressursse ja muudab süsteemi kulukamaks.

Teiseks, vigade isolatsiooni puudumine. Kui Nginx server mingil põhjusel kukub, kaob kättesaadavus kogu rakendusele, kuigi andmebaas ja API server võiksid edasi töötada. Ühe komponendi viga paralüseerib kogu süsteemi.

Kolmandaks, arendamise keerukus. Iga koodimuudatus nõuab terve container'i uuesti ehitamist ja käivitamist, mis võtab aega ja aeglustab arendusprotsessi. Samuti muutub keeruliseks erinevate komponentide iseseisvad testimine ja juurutamine.

### Mikroteenuste arhitektuur

Alternatiiviks on jagada rakendus loogilisteks komponentideks, kus igaüks täidab konkreetset ülesannet. Veebisirvija pöördub esialgu Nginx serveri poole, mis serveerib staatilised failid ja suunab API päringud edasi Python rakendusserverile. Rakendusserver tegeleb äriloogikaga ja suhtleb andmebaasiga ning cache serveriga.

Selline arhitektuur toob kaasa märkimisväärseid eeliseid. Iga komponent saab optimeerida konkreetseks ülesandeks - andmebaasile saab anda rohkem mälu, API serverile rohkem CPU ressursse. Komponente saab sõltumatult arendada ja juurutada, mis võimaldab meeskondadel paralleelselt töötada.

Siiski tekivad uued väljakutsed. Kuidas tagada, et API server leiab alati andmebaasi? Kuidas hallata seda, et andmebaas käivitatakse enne API serverit? Kuidas konfigureerida turvalist võrgusuhtlust komponentide vahel?

## Docker Compose kontseptsioonid

### Deklaratiivne konfiguratsioon

Docker Compose lahendab orkestreerimise väljakutsed deklaratiivse lähenemisega. Selle asemel, et kirjutada skripte, mis kirjeldavad sammhaaval, kuidas süsteemi üles seadistada, kirjeldame YAML failis, milline on soovitud lõpptulemus. Docker Compose võtab vastutuse selle eest, kuidas see tulemus saavutada.

YAML (YAML Ain't Markup Language) on inimloetav andmete serialiseerimise standard, mis sobib hästi konfiguratsioonifailide jaoks. Selle süntaks põhineb taanetel ja hierarhial, muutes keerulised konfiguratsioonid visuaalselt mõistetavaks.

Compose fail defineerib teenused (services), mis on abstraktsioon container'ite üle. Iga teenus kirjeldab, millist Docker image'it kasutada või kuidas seda ehitada, millised pordid avada, kuidas konfigureerida keskkonnamuutujaid ja kuidas ühendada teiste teenustega.

### Automaatne võrgundus ja service discovery

Üks Docker Compose võtmeomadusi on automaatne võrgu seadistamine. Iga projekt saab oma isoleeritud virtuaalse võrgu, kus kõik teenused saavad omavahel suhelda. Veel olulisem on see, et Docker Compose seadistab DNS süsteemi, mis võimaldab teenustel üksteist leidmast nimede järgi.

See tähendab, et kui te määrate docker-compose.yml failis teenuse nimeks "database", siis teised teenused saavad sellega ühenduda kasutades täpselt seda nime. Pole vaja muretseda IP aadresside pärast, mis muutuvad iga container'i taaskäivitamisel.

Service discovery automatiseerimine lihtsustab märkimisväärselt rakenduse konfiguratsiooni. Python kood võib ühenduda andmebaasiga kasutades connection string'i nagu "postgresql://user:password@database:5432/myapp", kus "database" on teenuse nimi compose failis.

### Sõltuvuste haldamine

Reaalsetes rakendustes on teenuste vahel selged sõltuvused. API server ei saa töötada ilma andmebaasita, veebisirvija ei saa API'd kasutada, kui see pole käivitatud. Docker Compose pakub depends_on direktiivi, mis määrab käivitamise järjekorra.

Siiski on oluline mõista, et depends_on tagab ainult container'ite käivitamise järjekorra, mitte teenuste valmiduse ootamist. PostgreSQL container võib käivitada, kuid andmebaas ise võib veel initsialiseerumise protsessis olla. Täiustatud stsenaariumides kasutatakse health check'e, mis kontrollivad teenuse tegelikku valmidust.

## YAML süntaks ja compose faili struktuur

### Põhisüntaks ja reeglid

YAML süntaks nõuab täpsust, kuid selle omandamine on lihtne. Kõige olulisem reegel on kasutada ainult tühikuid taandamiseks - TAB märgid ei ole lubatud. Standardne on kasutada kahe tühiku sammu iga hierarhia taseme jaoks.

Võti-väärtus paarid kirjutatakse kujul "key: value", kus koolon järel peab olema tühik. Nimekirjad märgitakse sidekriipsuga, millele järgneb tühik ja element. Hierarhia luuakse taandamisega - lapse elemendid peavad olema rohkem taandatud kui vanem element.

```yaml
# Õige YAML süntaks
version: '3.8'                    # Koolon + tühik
services:                         # Koolon lõpus
  web:                           # 2 tühikut taane
    image: nginx:alpine          # 4 tühikut taane
    ports:                       # 4 tühikut taane
      - "80:80"                  # 6 tühikut + kriips + tühik

# Vale süntaks - ära tee nii
version:'3.8'                     # Tühik puudub
services:
web:                              # Taane puudub
    image:nginx                   # Tühik puudub kooloni järel
	ports:                        # TAB märk (keelatud!)
```bash

Compose faili põhistruktuur algab versiooni deklaratsiooniga. Versioon 3.8 on laialt toetatud ja sisaldab kõiki kaasaegseid funktsioone. Seejärel järgneb services sektsioon, kus defineeritakse kõik rakenduse komponendid.

### Teenuste defineerimine

Iga teenus compose failis vastab ühele või mitmele container'ile. Teenuse definitsioon võib kasutada valmis Docker image'it Docker Hub'ist või ehitada image'i kohalikust Dockerfile'ist. Valik sõltub sellest, kas tegu on standardse tarkvaraga nagu andmebaas või oma rakenduse koodiga.

```yaml
version: '3.8'

services:
  # Valmis image - standardsed teenused
  database:
    image: postgres:13           # Konkreetne versioon on alati parem
    environment:
      - POSTGRES_PASSWORD=secret
      - POSTGRES_DB=myapp

  # Ehitame ise - oma rakenduse kood
  api:
    build: ./backend            # Lihtne variant
    # VÕI detailsem konfiguratsioon:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
      args:
        - PYTHON_VERSION=3.11

  # Web server valmis image'iga
  web:
    image: nginx:alpine
    ports:
      - "8080:80"              # HOST:CONTAINER
```bash

Standardsed teenused nagu PostgreSQL, Redis või Nginx kasutavad tavaliselt valmis image'eid. Need on hoolikalt testitud, optimeeritud ja regulaarselt uuendatud. Oma rakenduse komponendid nõuavad tavaliselt kohalikku ehitamist Dockerfile'i põhjal.

Port mapping võimaldab container'i sees töötavaid teenuseid kättesaadavaks teha host süsteemist. Mapping "8080:80" tähendab, et host'i port 8080 suunatakse container'i port 80'le. Turvalisuse seisukohast tuleks avalikuks teha ainult need pordid, mis on tõesti vajalikud väliseks ligipääsuks.

### Keskkonnamuutujate haldamine

Rakendused vajavad konfigureerimist erinevates keskkondades. Andmebaasi parool, API võtmed ja debug seadistused erinevad development'i ja production'i keskkondades. Docker Compose toetab keskkonnamuutujate määramist mitmel viisil.

```yaml
services:
  api:
    environment:
      # Otse määratud väärtus
      - NODE_ENV=production
      - DEBUG=false
      
      # Võta host'i keskkonnas
      - PATH                     # Kasutab host'i PATH'i
      
      # .env failist vaikeväärtusega
      - PORT=${API_PORT:-3000}   # Kui API_PORT puudub, kasuta 3000
      
      # Keerukas arvutatud väärtus
      - DATABASE_URL=postgres://user:${DB_PASSWORD}@database:5432/${DB_NAME}
```text

Lihtsaim viis on määrata muutujad otse compose failis, kuid see pole soovitatav tundlike andmete jaoks. Turvalisem on kasutada .env faile, kus tundlikud seadistused hoitakse eraldi failides, mis ei lähe versioonikontrolli.

```env
# .env fail - ei lähe Git'i
DB_PASSWORD=supersecret123
API_PORT=5000
DEBUG=true
NODE_ENV=development

# Database seadistused
POSTGRES_DB=myapp_dev
POSTGRES_USER=developer
```text

```yaml
# docker-compose.yml - kasutab .env faili
services:
  api:
    environment:
      - PORT=${API_PORT}
      - DB_PASSWORD=${DB_PASSWORD}
      - NODE_ENV=${NODE_ENV}
      
  database:
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
```bash

Environment variables võimaldavad sama compose faili kasutada erinevates keskkondades, muutes ainult .env faili sisu. See järgib "konfigureeri environment'i kaudu" põhimõtet, mis on DevOps maailmas laialdaselt tunnustatud.

### Sõltuvuste defineerimine

Reaalsetes rakendustes on teenuste vahel selged sõltuvused. API server ei saa töötada ilma andmebaasita, veebisirvija ei saa API'd kasutada, kui see pole käivitatud. Docker Compose pakub depends_on direktiivi, mis määrab käivitamise järjekorra.

```yaml
services:
  frontend:
    image: nginx:alpine
    depends_on:
      - backend                 # Ootab backend'i käivitumist

  backend:
    build: ./api
    environment:
      - DATABASE_URL=postgres://postgres:secret@database:5432/app
    depends_on:
      - database               # Ootab database'i käivitumist
      - cache                  # JA cache'i käivitumist

  database:
    image: postgres:13         # Käivitub esimesena
    environment:
      - POSTGRES_PASSWORD=secret

  cache:
    image: redis:alpine        # Käivitub paralleelselt database'iga
```text

Siiski on oluline mõista, et depends_on tagab ainult container'ite käivitamise järjekorra, mitte teenuste valmiduse ootamist. PostgreSQL container võib käivitada, kuid andmebaas ise võib veel initsialiseerumise protsessis olla. Täiustatud stsenaariumides kasutatakse health check'e, mis kontrollivad teenuse tegelikku valmidust.

```yaml
services:
  backend:
    build: ./api
    depends_on:
      database:
        condition: service_healthy  # Ootab health check'i

  database:
    image: postgres:13
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s              # Kontrolli iga 10 sekundi tagant
      timeout: 5s                # 5 sekundi timeout
      retries: 5                 # Max 5 katset
      start_period: 30s          # Anna 30s käivitumiseks
```text

## Andmete säilitamine ja volume'id

### Persistent storage vajadus

Container'id on oma olemuselt ajutised - kui container kustutada ja uuesti luua, kaovad kõik selle sees tehtud muudatused. Andmebaasi puhul tähendaks see katastroofi, sest kõik kasutajate andmed kaoksid. Volume'id lahendavad selle probleemi, võimaldades määrata, millised kaustad tuleb säilitada container'ite elutsükli väliselt.

```yaml
services:
  database:
    image: postgres:13
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - postgres_data:/var/lib/postgresql/data  # Named volume

  cache:
    image: redis:alpine
    volumes:
      - redis_data:/data         # Redis andmed

volumes:
  postgres_data:                 # Docker haldab automaatselt
  redis_data:
```bash

Docker pakub mitut tüüpi volume'e, igaüks oma kasutusjuhtudega. Named volume'id on Docker'i hallatavad ja optimeeritud, bind mount'id ühendavad otse host süsteemi kaustadega. Valik sõltub sellest, kas tegu on production andmetega või development töövoogudega.

### Named volume'id

Named volume'id on eelistatud viis production andmete säilitamiseks. Docker haldab nende asukohta ja optimeerib jõudlust operatsioonisüsteemi võimaluste kohaselt. Need on portaablid erinevate süsteemide vahel ja toetavad backup ning restore operatsioone Docker CLI kaudu.

Compose failis defineeritakse named volume'id kaks korda - esmalt teenuse juures, määrates mount point'i, ja seejärel globaalselt volumes sektsioonis. See võimaldab volume'e jagada mitme teenuse vahel kui vaja.

### Bind mount'id development'is

Development keskkonnas on sageli kasulik, kui koodi muudatused kajastuvad kohe container'is ilma uuesti ehitamata. Bind mount'id võimaldavad host süsteemi kausta ühendada otse container'isse, luues "live reload" efekti.

```yaml
services:
  web:
    image: nginx:alpine
    volumes:
      # Konfiguratsioonifailid (read-only)
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      
      # Staatilised failid development'is
      - ./frontend/dist:/usr/share/nginx/html:ro
      
      # Logid välja host süsteemi
      - ./logs/nginx:/var/log/nginx

  api:
    build: ./backend
    volumes:
      # Live reload - kood muutub, container näeb kohe
      - ./backend/src:/app/src:ro
      - ./backend/app.py:/app/app.py:ro
```bash

Bind mount'ide kasutamisel tuleb olla ettevaatlik lubadega ja turvalisusega. Read-only mount'id (:ro) on turvalisemad, kui container ei vaja sinna kirjutamist. Production keskkonnas tuleks bind mount'e vältida, sest need loovad sõltuvuse host süsteemi struktuurist.

## Praktiline näide: Täielik 4-teenusega süsteem

Demonstreerimaks kõiki õpitud kontseptsioone, ehitame kasutajate haldamise süsteemi, mis koosneb neljast teenusest: Nginx frontend, Python Flask API, PostgreSQL andmebaas ja Redis cache.

### Projekti struktuur

```
user-management/
├── docker-compose.yml
├── .env
├── .env.example
├── frontend/
│   ├── index.html
│   └── nginx.conf
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
└── database/
    └── init.sql
```bash

### Backend implementatsioon

Python Flask rakendus demonstreerib service discovery ja cache kasutamist:

```python
# backend/app.py
from flask import Flask, jsonify, request
import psycopg2
import redis
import os
import json

app = Flask(__name__)

# Andmebaasi ühendus - kasutab teenuse nime!
def get_db():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'database'),    # 'database' on teenuse nimi
        database=os.getenv('DB_NAME', 'userdb'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD')
    )

# Redis ühendus - samuti teenuse nimi
cache = redis.Redis(
    host=os.getenv('REDIS_HOST', 'cache'),        # 'cache' on teenuse nimi
    port=6379,
    decode_responses=True
)

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy", "service": "user-api"})

@app.route('/api/users')
def get_users():
    # Proovi cache'ist
    cached = cache.get('users')
    if cached:
        return jsonify({"users": json.loads(cached), "source": "cache"})
    
    # Laadi andmebaasist
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id, name, email FROM users")
    users = [{"id": r[0], "name": r[1], "email": r[2]} for r in cur.fetchall()]
    conn.close()
    
    # Salvesta cache'isse 60 sekundiks
    cache.setex('users', 60, json.dumps(users))
    return jsonify({"users": users, "source": "database"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```bash

### Docker Compose konfiguratsioon

```yaml
version: '3.8'

services:
  # Frontend - Nginx + HTML
  frontend:
    image: nginx:alpine
    ports:
      - "${WEB_PORT:-8080}:80"
    volumes:
      - ./frontend/index.html:/usr/share/nginx/html/index.html:ro
      - ./frontend/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - backend
    restart: unless-stopped

  # Backend - Python Flask API
  backend:
    build: ./backend
    environment:
      - DB_HOST=database
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=cache
    depends_on:
      database:
        condition: service_healthy
      cache:
        condition: service_started
    restart: unless-stopped

  # Database - PostgreSQL
  database:
    image: postgres:13
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Cache - Redis
  cache:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```text

### Environment konfiguratsioon

```env
# .env - development seadistused
DB_NAME=userdb
DB_USER=postgres
DB_PASSWORD=secret123
WEB_PORT=8080
```text

```env
# .env.example - template Git'i jaoks
DB_NAME=userdb
DB_USER=postgres
DB_PASSWORD=change_this_password
WEB_PORT=8080
```text

### Käivitamine ja testimine

```bash
# Kopeeri environment variables
cp .env.example .env

# Kontrolli konfiguratsiooni
docker-compose config

# Ehita ja käivita
docker-compose up --build -d

# Kontrolli teenuste staatust
docker-compose ps

# Vaata logisid
docker-compose logs backend

# Testi rakendust
curl http://localhost:8080/api/health
curl http://localhost:8080/api/users
```bash

## Andmete säilitamine ja volume'id

### Persistent storage vajadus

Container'id on oma olemuselt ajutised - kui container kustutada ja uuesti luua, kaovad kõik selle sees tehtud muudatused. Andmebaasi puhul tähendaks see katastroofi, sest kõik kasutajate andmed kaoksid. Volume'id lahendavad selle probleemi, võimaldades määrata, millised kaustad tuleb säilitada container'ite elutsükli väliselt.

Docker pakub mitut tüüpi volume'e, igaüks oma kasutusjuhtudega. Named volume'id on Docker'i hallatavad ja optimeeritud, bind mount'id ühendavad otse host süsteemi kaustadega. Valik sõltub sellest, kas tegu on production andmetega või development töövoogudega.

### Named volume'id

Named volume'id on eelistatud viis production andmete säilitamiseks. Docker haldab nende asukohta ja optimeerib jõudlust operatsioonisüsteemi võimaluste kohaselt. Need on portaablid erinevate süsteemide vahel ja toetavad backup ning restore operatsioone Docker CLI kaudu.

Compose failis defineeritakse named volume'id kaks korda - esmalt teenuse juures, määrates mount point'i, ja seejärel globaalselt volumes sektsioonis. See võimaldab volume'e jagada mitme teenuse vahel kui vaja.

### Bind mount'id development'is

Development keskkonnas on sageli kasulik, kui koodi muudatused kajastuvad kohe container'is ilma uuesti ehitamata. Bind mount'id võimaldavad host süsteemi kausta ühendada otse container'isse, luues "live reload" efekti.

Bind mount'ide kasutamisel tuleb olla ettevaatlik lubadega ja turvalisusega. Read-only mount'id (:ro) on turvalisemad, kui container ei vaja sinna kirjutamist. Production keskkonnas tuleks bind mount'e vältida, sest need loovad sõltuvuse host süsteemi struktuurist.

## Võrguarhitektuur ja turvalisus

### Automaatne network'i loomine

Docker Compose loob automaatselt isoleeritud võrgu iga projekti jaoks. See tähendab, et erinevate projektide container'id ei näe üksteist, pakkudes loomulikku isolatsiooni. Võrgu nimi tuletakse tavaliselt projekti kausta nimest ja "default" liitega.

Automaatne võrk kasutab bridge driver'it, mis sobib enamiku rakenduste jaoks. Kõik sama projekti teenused saavad omavahel suhelda, kuid välismaailma ligipääs on kontrollitud port mapping'ute kaudu.

### Custom network'ide kasutamine

Keerukamates stsenaariumides võib olla vaja luua mitu võrku, et eraldada teenused turvalisuse kaalutlustel. Näiteks võib luua frontend võrgu web serveri ja API vahel ning backend võrgu API ja andmebaasi vahel. See võimaldab andmebaasil olla täiesti isoleeritud välismaailmast.

Network'ide defineerimine toimub sarnaselt volume'idega - esmalt kasutatakse neid teenuste juures ja seejärel defineeritakse globaalselt networks sektsioonis. Internal network'id ei saa ligipääsu välismaailma, pakkudes maksimaalset isolatsiooni.

## Development workflow'de optimeerimine

### Live reload ja kiire iteratsioon

Development keskkonnas on produktiivsuse jaoks kriitiline, et koodimuudatused kajastuksid kiiresti töötavas rakenduses. Docker Compose toetab seda bind mount'ide ja development-spetsiifiliste image'ite kaudu.

Multi-stage Dockerfile'id võimaldavad luua eraldi development ja production build'e samast lähtefailist. Development stage võib sisaldada lisainstrumente nagu debugger'id ja file watcher'id, samas kui production stage on optimeeritud suuruse ja jõudluse jaoks.

### Environment-spetsiifilised konfiguratsioonid

Üks Docker Compose võtmeeeliseid on võimalus kasutada mitut compose faili korraga. Base fail sisaldab ühiseid seadistusi, samas kui environment-spetsiifilised failid sisaldavad ainult erinevusi.

Development'i jaoks võib docker-compose.override.yml fail lisada debug porte ja bind mount'e, samas kui production fail lisab resource limit'id ja health check'e. See võimaldab hoida DRY (Don't Repeat Yourself) põhimõtet konfiguratsioonis.

### Monitoring ja debugging

Production-ready süsteemid vajavad monitooringut ja logimist. Docker Compose toetab erinevaid logging driver'eid ja resource monitoring'ut. Health check'id võimaldavad automaatselt tuvastada ja taaskäivitada mittetöötavaid teenuseid.

Debugging tools'id nagu container'isse sisenemine, logide vaatamine ja resource kasutuse monitooring on olulised nii development kui production keskkonnas. Docker Compose pakub mugavaid käske nende operatsioonide jaoks.

## Turvalisus ja production seadistused

### Secrets management

Tundlike andmete nagu paroolide ja API võtmete käitlemine nõuab erilist tähelepanu. Need ei tohi kunagi sattuda versioonikontrolli ega olla hard-coded compose failides. Docker Compose toetab secrets süsteemi, mis võimaldab tundlikke andmeid turvaliselt container'itesse edastada.

Development keskkonnas võib kasutada .env faile, kuid production'is tuleks kaaluda väliseid secrets management süsteeme nagu HashiCorp Vault või cloud provider'ite native lahendusi.

### Network turvalisus

Default network isolatsioon pakub head algtaset turvalisust, kuid täiendavad meetmed võivad olla vajalikud. Internal network'id, port'ide minimaalne avamine ja non-root user'id container'ites parandavad turvalisust märkimisväärselt.

Reverse proxy nagu Nginx võib pakkuda lisaturvalisust, TLS terminatsiooni ja rate limiting'ut. API teenused ei peaks olema otse internetist kättesaadavad.

### Resource management

Production keskkonnas on oluline piirata container'ite resource kasutust, et vältida ühe teenuse poolt kogu süsteemi monopoliseerimist. Memory ja CPU limit'id kaitsevad süsteemi stabilsuse eest.

Restart poliitikad tagavad, et teenused taaskäivitatakse automaatselt vigade korral. "unless-stopped" poliitika on tavaliselt hea valik, kuna see ei taaskäivita teenuseid, mis on tahtlikult peatatud.

## Järgmised sammud orkestreerimises

Docker Compose on suurepärane õppimise platvorm ja sobib väikeste kuni keskmiste production deployment'ide jaoks. Suurema skaala ja keerukama orkestreerimise jaoks tuleks kaaluda Kubernetes'e, mis pakub automaatset skaleerimist, advanced networking'ut ja enterprise-level funktsioone.

Container orkestreerimise omandamine Docker Compose'iga annab tugeva aluse edasiseks arengus. Siin õpitud kontseptsioonid - service discovery, volume management, networking - kehtivad ka keerukamates orkestreerimise platvormides.

Jätkuks tasub uurida CI/CD integreerimist, infrastructure as code työriistade nagu Terraform kasutamist ja monitoring stack'ide nagu Prometheus ja Grafana seadistamist Docker Compose keskkondades.
