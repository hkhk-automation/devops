# Ansible Roles Homework: Ehita sama infrastruktuur nii Ansible kui Puppet'iga

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Deploy sama infrastruktuuri mõlema tööriistaga ja võrdle praktikas  

**Te saate valmis starter kood - fookus on deployment'il ja praktilisel võrdlusel!**

---

## 1. Projekt: Veebserveri + Andmebaasi seadistamine

**Mida te ehitate:**
- **Nginx veebiserver** kohandatud konfiguratsiooniga
- **PostgreSQL andmebaas** algse skeemiga  
- **SSL sertifikaadid** (ise-allkirjastatud testimiseks)
- **Süsteemi monitooring** põhiliste tervise kontrollidega
- **Logide pööramise** konfiguratsioon

**Mida te õpite:**
- Ansible vs Puppet praktilised erinevused
- Konfiguratsioonihalduse töövood
- Infrastruktuuri deployment strateegiad
- Tööriistaspetsiifilised debug ja probleemilahendus

---

## 2. Ansible vs Puppet - Miks võrdleme?

**Miks on oluline mõista erinevaid tööriistu?**

### 2.1 Ansible - Push-based lähenemine
- **Kuidas töötab:** Kontrollserver saadab käsud sihtmasinatele
- **Eelised:** Lihtne alustada, YAML süntaks, agentless
- **Puudused:** Vajab SSH ühendust, vähem keerukaid funktsioone
- **Kus kasutada:** Väiksemad meeskonnad, lihtsad automatiseerimised

### 2.2 Puppet - Pull-based lähenemine
- **Kuidas töötab:** Sihtmasinad ise küsivad konfiguratsiooni serverilt
- **Eelised:** Võimas, keerukad funktsioonid, agent-based
- **Puudused:** Keerulisem seadistada, Ruby süntaks
- **Kus kasutada:** Suured ettevõtted, keerukad infrastruktuurid

**Miks praktiline võrdlus on oluline?**
- Näete erinevusi käitumises
- Mõistate, millal mida kasutada
- Õpite debug'ima mõlemat tööriista
- Saate praktilise kogemuse

---

## 3. Repository seadistamine

### 3.1 Klooni starter repository

```bash
# Klooni kodutöö starter valmis failidega
git clone https://github.com/[teacher-repo]/ansible-puppet-comparison.git
cd ansible-puppet-comparison

# Loo oma töö branch
git checkout -b homework-[your-name]

# Kontrolli starter struktuuri
ls -la
# Peaksite nägema: ansible/, puppet/, docs/, README.md
```bash

### 3.2 Kontrolli starter faile

**Repository sisaldab:**
- `ansible/` - Ansible playbook'i baas (vajab SSL ja virtual hosts lisamist)
- `puppet/` - Puppet manifest'i baas (vajab SSL ja monitoring lisamist)
- `vagrant/` - Test VM'ide konfiguratsioon (valmis kasutamiseks)
- `requirements.md` - Mis te peate lisama

### 3.3 Tutvu starter koodiga

**Ansible struktuur:**
```bash
cd ansible/
ls -la
# Peaksite nägema:
# - inventory/ (sihtmachinad)
# - roles/ (nginx, postgresql)
# - site.yml (peamine playbook)
# - requirements.md (mis vaja lisada)
```text

**Puppet struktuur:**
```bash
cd ../puppet/
ls -la
# Peaksite nägema:
# - manifests/ (Puppet kood)
# - modules/ (nginx, postgresql)
# - hiera/ (andmed)
# - requirements.md (mis vaja lisada)
```bash

**Miks see struktuur on oluline?**
- **Ansible:** Playbook → Roles → Tasks
- **Puppet:** Manifests → Classes → Resources
- Mõlemad järgivad modulaarset lähenemist
- Kood on organiseeritud ja taaskasutatav

---

## 4. Ehita Ansible deployment

### 4.1 Käivita test keskkond

```bash
# Käivita VM testimiseks
cd ../vagrant/
vagrant up ansible-vm

# Ühenda VM'iga
vagrant ssh ansible-vm
```text

**Miks kasutame Vagrant'i?**
- **Isolatsioon:** Ei mõjuta teie põhisüsteemi
- **Korratavus:** Igaüks saab sama keskkonna
- **Kiire:** Võimaldab kiiresti testida ja kustutada
- **Turvaline:** Võite eksperimenteerida vabalt

### 4.2 Lisa SSL konfiguratsioon

**Starters on ainult basic nginx + postgresql. Peate lisama:**

```bash
cd ../ansible/

# Lisa SSL task'id (roles/nginx/tasks/ssl.yml)
# Kohandada nginx template'i SSL jaoks  
# Lisada virtual hosts konfiguratsioon

# Vaata requirements.md faili, mis täpselt vaja
cat requirements.md
```text

**Mida peate lisama SSL jaoks:**

#### 4.2.1 SSL sertifikaatide genereerimine
```yaml
# roles/nginx/tasks/ssl.yml
- name: "Create SSL directory"
  file:
    path: /etc/nginx/ssl
    state: directory
    mode: '0755'

- name: "Generate self-signed SSL certificate"
  command: openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/C=EE/ST=Tallinn/L=Tallinn/O=Test/CN=localhost"
  args:
    creates: /etc/nginx/ssl/nginx.crt
```text

#### 4.2.2 Nginx SSL konfiguratsioon
```nginx
# roles/nginx/templates/nginx.conf.j2
server {
    listen 80;
    server_name localhost;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name localhost;
    
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    
    location / {
        root /var/www/html;
        index index.html;
    }
}
```text

**Miks SSL on oluline?**
- **Turvalisus:** Krüptitud ühendused
- **Praktika:** Enamik päris rakendusi kasutab HTTPS
- **Õppimine:** SSL konfiguratsioon on oluline oskus
- **Testimine:** Näete, kuidas töötab turvaline ühendus

### 4.3 Lisa virtual hosts

**Virtual hosts võimaldavad ühel serveril mitut veebisaiti:**

```yaml
# roles/nginx/tasks/vhosts.yml
- name: "Create virtual host directories"
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - /var/www/site1
    - /var/www/site2

- name: "Create virtual host content"
  copy:
    content: |
      <h1>Site 1</h1>
      <p>This is site 1 content</p>
    dest: /var/www/site1/index.html
    mode: '0644'
```text

**Miks virtual hosts on olulised?**
- **Ressursi säästmine:** Üks server, mitut rakendust
- **Organiseerimine:** Eraldi kontekstid erinevatele projektidele
- **Praktika:** Paljud ettevõtted kasutavad virtual hoste
- **Skaleerimine:** Võimaldab kasvada ilma uute serverite lisamata

### 4.4 Käivita ja testi

```bash
# Proovi oma laiendatud versiooni
ansible-playbook -i inventory/local site.yml --ask-become-pass

# Kontrolli teenuseid
sudo systemctl status nginx postgresql
curl -k https://localhost  # SSL peaks töötama!

# Testi virtual hoste
curl -k https://localhost/site1
curl -k https://localhost/site2
```text

**Miks testimine on oluline?**
- **Veakontroll:** Veenduge, et kõik töötab
- **Dokumentatsioon:** Näete, mis töötab ja mis mitte
- **Õppimine:** Testimine on oluline oskus
- **Usaldus:** Saate usaldada oma automatiseerimist

### 4.5 Commit oma töö

```bash
# Kui kõik töötab
git add .
git commit -m "Lisasin SSL ja virtual hosts Ansible'ile - töötab"
```text

---

## 5. Ehita Puppet deployment

### 5.1 Lülitu Puppet VM'ile

```bash
# Hävita eelmine VM ja käivita puppet VM
vagrant destroy ansible-vm
vagrant up puppet-vm
vagrant ssh puppet-vm
```text

**Miks eraldi VM?**
- **Puhas keskkond:** Ei mõjuta eelmist tööd
- **Võrdlus:** Saate võrrelda mõlemat lähenemist
- **Praktika:** Reaalses elus kasutate erinevaid masinaid
- **Debug:** Lihtsam lahendada probleeme

### 5.2 Lisa samad asjad Puppet'iga

**Puppet kood on veel poolik - pead lisama:**

```bash
cd ../puppet/

# SSL sertifikaatide genereerimine
# Nginx SSL konfiguratsioon
# Virtual hosts setup
# PostgreSQL initial schema

# Vaata requirements.md - mis pead täpselt tegema
cat ../requirements.md
```text

**Puppet SSL konfiguratsioon:**

#### 5.2.1 SSL sertifikaatide genereerimine
```puppet
# modules/nginx/manifests/ssl.pp
class nginx::ssl {
  file { '/etc/nginx/ssl':
    ensure => 'directory',
    mode   => '0755',
  }
  
  exec { 'generate-ssl-cert':
    command => 'openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/C=EE/ST=Tallinn/L=Tallinn/O=Test/CN=localhost"',
    creates => '/etc/nginx/ssl/nginx.crt',
    path    => '/usr/bin',
    require => File['/etc/nginx/ssl'],
  }
}
```text

#### 5.2.2 Nginx SSL konfiguratsioon
```puppet
# modules/nginx/templates/nginx.conf.erb
server {
    listen 80;
    server_name localhost;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name localhost;
    
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    
    location / {
        root /var/www/html;
        index index.html;
    }
}
```bash

**Miks Puppet süntaks on erinev?**
- **Ruby põhine:** Puppet kasutab Ruby süntaksit
- **Deklaratiivne:** Kirjeldate, mis peab olema, mitte kuidas
- **Idempotent:** Puppet kontrollib olekut ja teeb ainult vajalikud muudatused
- **Võimas:** Rohkem keerukaid funktsioone kui Ansible

### 5.3 Lisa monitoring

**Monitoring võimaldab kontrollida teenuste tööd:**

```puppet
# modules/monitoring/manifests/health.pp
class monitoring::health {
  file { '/usr/local/bin/health-check.sh':
    content => '#!/bin/bash
      if systemctl is-active --quiet nginx; then
        echo "Nginx is running"
        exit 0
      else
        echo "Nginx is not running"
        exit 1
      fi',
    mode    => '0755',
  }
  
  cron { 'health-check':
    command => '/usr/local/bin/health-check.sh >> /var/log/health.log 2>&1',
    minute  => '*/5',
  }
}
```text

**Miks monitoring on oluline?**
- **Probleemide avastamine:** Varane hoiatamine
- **Töökindlus:** Veenduge, et teenused töötavad
- **Praktika:** Kõik päris süsteemid vajavad monitooringut
- **Debug:** Aitab leida probleeme

### 5.4 Rakenda oma Puppet kood

```bash
# Proovi oma versiooni
sudo puppet apply --modulepath=modules manifests/site.pp

# Kontrolli, et sama tulemus mis Ansible'iga
sudo systemctl status nginx postgresql
curl -k https://localhost  # SSL peaks töötama!

# Testi monitoring
sudo /usr/local/bin/health-check.sh
```text

### 5.5 Commit Puppet töö

```bash
# Kui sama tulemus mis Ansible'iga
git add .
git commit -m "Lisasin samad asjad Puppet'iga - sama tulemus"
```text

---

## 6. Võrdle ja analüüsi

### 6.1 Mõtle läbi, mis oli erinev

Pärast mõlema tööriista kasutamist:

```bash
# Lihtsalt testi mõlemad veel kord
curl -k https://localhost  # Kas mõlemad töötavad?

# Commit kogu oma töö
git add .
git commit -m "Mõlemad deploymentid töötavad - Ansible ja Puppet"
git push origin homework-[your-name]
```bash

### 6.2 Lühike võrdlus

**Kirjuta 2-3 lauset oma kogemusest:**

- Mida märkasid Ansible ja Puppet vahel?
- Mis oli lihtsam/keerulisem?
- Mida eelistaksid ja miks?

---

## 7. Lõpeta ja esita

### 7.1 Kirjuta põhjalik README.md

```markdown
# Kodutöö - Ehitasin sama asja Ansible ja Puppet'iga

## Mida ehitasin
- Laiensid basic nginx + postgresql starter koodi
- Lisasin SSL sertifikaadid ja HTTPS konfiguratsioon
- Lisasin virtual hosts funktsionaalsuse
- Lisasin põhilise monitooringu
- Tegin seda nii Ansible kui Puppet'iga

## Praktiline võrdlus

### Ansible kogemus
- **Seadistamine:** Lihtne ja kiire
- **Süntaks:** YAML oli selge ja loetav
- **Debug:** Hea veateadete kvaliteet
- **Dokumentatsioon:** Palju näiteid ja õpetusi

### Puppet kogemus
- **Seadistamine:** Keerulisem, aga võimas
- **Süntaks:** Ruby vajab harjumist
- **Debug:** Rohkem keeruline, aga detailne
- **Dokumentatsioon:** Hea, aga vähem algajasõbralik

## Eelistus ja põhjendus
Ma eelistaks **[Ansible/Puppet]** sest [2-3 lauset põhjendust].

## Õpitud oskused
- SSL sertifikaatide konfigureerimine
- Virtual hosts seadistamine
- Monitooringu lisamine
- Tööriistade võrdlemine praktikas
- Debug ja probleemilahendus

---
Tehtud [kuupäev] - mõlemad deploymentid töötavad!
```text

### 7.2 Lõplik push ja esitamine

```bash
# Lõplik commit
git add .
git commit -m "Lõpetasin kodutöö - mõlemad deploymentid töötavad"

# Push GitHub'i
git push origin homework-[your-name]

# Kontrolli, et kõik on GitHub'is
echo "Kontrolli: https://github.com/[your-username]/ansible-puppet-comparison"
```yaml

---

## KKK

**Q: Kas pean mõlemad deploymentid tegema?**  
A: Jah, see on kodutöö eesmärk - võrrelda mõlemat lähenemist.

**Q: Mis teha, kui üks ei tööta?**  
A: Proovi debug'ida ja küsi abi. Kui üks töötab, saad selle esitada.

**Q: Kas pean kirjutama pika võrdluse?**  
A: Ei, piisab lühikest, aga põhjalikust analüüsist.

**Q: Millal on tähtaeg?**  
A: Järgmise nädala alguseks. Hilinemine = punktide kaotus.

**Head konfiguratsioonihaldust!**
