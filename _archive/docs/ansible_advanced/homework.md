# Deploy Web Server with Vault & Templates

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Apache serveri juurutamine Ansible Vault salajaste andmete ja Jinja2 mallide abil  

**Te saate valmis starter failid - fookus on Vault'i ja template'ide õppimisel!**

---

## 1. Projekt: Secure Web Server Deployment

### Mida te ehitate:
- 🌐 **Apache web server** dünaamilise sisuga
- 🔐 **Vault-krüptitud salajased andmed** (paroolid, API võtmed)
- 📄 **Jinja2 mallid** dünaamilise HTML genereerimiseks
- 🔧 **Teenuse käsitlejad** automaatsete taaskäivituste jaoks
- 📊 **Süsteemi teabe kuvamine** serveri statistikaga

### Mida te õpite:
- Ansible Vault salajaste andmete haldamine
- Mallipõhine konfiguratsioon
- Teenuse haldamine käsitlejate abil
- Turvaline identimisteabe haldamine

---

## 2. Setup Project

### 2.1 Veebi varade hankimine ja automatiseerimisfailide loomine

```bash
# Kodutöö kataloogi loomine
mkdir ~/ansible-advanced-homework
cd ~/ansible-advanced-homework

# Ainult veebi varade kloonimine (HTML mallid, CSS)
git clone https://github.com/[teacher-repo]/ansible-web-assets.git assets
cp -r assets/templates assets/static .
rm -rf assets/

# Sinu git hoidla initsialiseerimine automatiseerimisfailide jaoks
git init
git remote add origin https://github.com/[your-username]/ansible-advanced-homework.git

# Ansible struktuuri loomine
mkdir group_vars
touch ansible.cfg inventory.yml site.yml README.md
```bash

### 2.2 Automatiseerimise konfiguratsiooni loomine

**Fail: `ansible.cfg`:**
```ini
[defaults]
inventory = inventory.yml
host_key_checking = False
```text

**Fail: `inventory.yml`:**
```yaml
all:
  hosts:
    webserver:
      ansible_host: localhost
      ansible_connection: local
  vars:
    server_name: "my-web-server"
    admin_email: "admin@example.com"
```text

### 2.3 Esimene commit (ainult automatiseerimisfailid)

```bash
# Lisa loodud automatiseerimisfailid
git add ansible.cfg inventory.yml templates/ static/
git commit -m "Loodud Ansible konfiguratsioon + lisatud veebi varad"
```text

---

## 3. Create Vault File

### 3.1 Vault'i loomise õppimine

```bash
# Krüptitud vault faili loomine
ansible-vault create group_vars/vault.yml
# Parooli küsimisel kasuta: vault123
```text

### 3.2 Salajaste andmete lisamine vault'i (KIRJUTA NEED!)

```yaml
# Lisa need salajased andmed oma vault faili:
vault_mysql_password: "mysql_secret_123"
vault_admin_password: "admin_secret_456"
vault_website_title: "Minu Turvaline Veebiserver"
vault_api_key: "api-key-12345-secret"
vault_student_name: "Sinu Nimi Siin"
```text

### 3.3 Vault'i operatsioonide testimine

```bash
# Vaata oma krüptitud vault faili
cat group_vars/vault.yml
# Peaks näitama krüptitud sisu

# Vaata vault'i sisu (dekrüpteeri kontrollimiseks)
ansible-vault view group_vars/vault.yml
# Parool: vault123

# Redigeeri vault faili vajadusel
ansible-vault edit group_vars/vault.yml
```text

### 3.4 Vault'i loomise commit

```bash
git add group_vars/vault.yml
git commit -m "Loodud krüptitud vault salajaste andmetega"
```text

---

## 4. Create Playbook

### 4.1 Peamise playbook'i kirjutamine

**Fail: `site.yml`:**
```yaml
---
- name: "Web server with Vault and Templates"
  hosts: all
  become: yes
  vars:
    web_root: "/var/www/html"
    service_name: "apache2"

  tasks:
    - name: "Install Apache web server"
      package:
        name: "{{ service_name }}"
        state: present
      notify: "start apache"

    - name: "Create web directory"
      file:
        path: "{{ web_root }}"
        state: directory
        mode: '0755'

    - name: "Generate HTML page from template"
      template:
        src: index.html.j2
        dest: "{{ web_root }}/index.html"
        mode: '0644'
      notify: "restart apache"

    - name: "Create server info file"
      copy:
        content: |
          Server: {{ ansible_hostname }}
          Student: {{ vault_student_name }}
          MySQL Password Length: {{ vault_mysql_password | length }}
          Generated: {{ ansible_date_time.iso8601 }}
        dest: "{{ web_root }}/server-info.txt"
        mode: '0644'

    - name: "Ensure Apache is running"
      service:
        name: "{{ service_name }}"
        state: started
        enabled: yes

  handlers:
    - name: "start apache"
      service:
        name: "{{ service_name }}"
        state: started

    - name: "restart apache"
      service:
        name: "{{ service_name }}"
        state: restarted
```text

### 4.2 Playbook'i testimine

```bash
# Kontrolli süntaksit (oluline!)
ansible-playbook --syntax-check site.yml

# Kuiv jooks esmalt
ansible-playbook --check site.yml --ask-vault-pass
# Parool: vault123

# Juurutamine päriselt
ansible-playbook site.yml --ask-vault-pass
```text

### 4.3 Juurutamise kontrollimine

```bash
# Kontrolli, kas Apache töötab
sudo systemctl status apache2

# Testi veebiserverit
curl http://localhost

# Kontrolli genereeritud faile
cat /var/www/html/index.html | head -10
cat /var/www/html/server-info.txt

# Ava brauseris
echo "Ava brauser: http://localhost"
```text

### 4.4 Playbook'i loomise commit

```bash
git add site.yml
git commit -m "Loodud täielik playbook vault'i ja mallidega"
```text

---

## 5. Test Vault and Handler Operations

### 5.1 Vault'i operatsioonide testimine

```bash
# Kontrolli praegust vault'i sisu
ansible-vault view group_vars/vault.yml

# Muuda vault'i salajast andmet
ansible-vault edit group_vars/vault.yml
# Muuda vault_website_title väärtuseks "Minu Uuendatud Sait - [Sinu Nimi]"

# Juuruta uue salajase andmega
ansible-playbook site.yml --ask-vault-pass

# Kontrolli muudatust brauseris
curl http://localhost | grep "Minu Uuendatud Sait"
```text

### 5.2 Käsitleja funktsionaalsuse testimine

```bash
# Tee mallis muudatus (käivitab käsitleja)
echo "<!-- Muudetud $(date) -->" >> templates/index.html.j2

# Juuruta ja jälgi käsitleja käivitamist
ansible-playbook site.yml --ask-vault-pass -v
# Peaks nägema "restart apache" käsitleja käivitamist

# Kontrolli Apache taaskäivitumist
sudo systemctl status apache2 | grep "Active since"
```text

### 5.3 Playbook'i funktsioonide testimine

```bash
# Käivita ainult kindlad ülesanded siltidega (kui saadaval)
ansible-playbook site.yml --ask-vault-pass --list-tasks

# Käivita kontrollirežiimis (kuiv jooks)
ansible-playbook site.yml --ask-vault-pass --check

# Käivita täiendava üksikasjalikkusega
ansible-playbook site.yml --ask-vault-pass -vv
```text

### 5.4 Operatsionaalse testimise commit

```bash
git add .
git commit -m "Testitud vault'i operatsioone ja käsitleja funktsionaalsust"
git push origin main
```text

---

## 6. Final Documentation and Evidence

### 6.1 README.md uuendamine

**Täida `README.md` mall:**
```markdown
# Ansible Kodutöö - Vault ja Mallid

## Mida ma ehitasin
- Apache veebiserver dünaamilise sisuga
- Krüptitud vault salajased andmed turvalise identimisteabe salvestamiseks
- Jinja2 mallid dünaamilise HTML genereerimiseks
- Teenuse käsitlejad automaatsete taaskäivituste jaoks

## Juurutamise käsud
```bash
# Klooni ja juuruta
git clone [repository-url]
cd ansible-advanced-homework
ansible-playbook site.yml --ask-vault-pass
# Vault parool: vault123
```bash

## Töötavad tulemused
- Veebiserver: http://localhost
- Näitab krüptitud vault andmeid turvaliselt
- Mall genereerib dünaamilist sisu
- Käsitlejad taaskäivitavad teenused muudatuste korral

## Mida ma õppisin
- Ansible Vault krüptib tundlikke andmeid
- Jinja2 mallid loovad dünaamilisi konfiguratsioone
- Käsitlejad käivituvad ainult muudatuste korral
- Vault paroolid kaitsevad salajasi andmeid git hoidlates

## Tõendid
- Ekraanipildid `screenshots/` kaustas
- Töötav veebiserver demonstreeritav
- Git ajalugu näitab arengut
```

### 6.2 Tee ekraanipildid

**Vajalikud ekraanipildid:**
1. **Vault'i sisu**: `ansible-vault view group_vars/vault.yml`
2. **Juurutatud veebisait**: Brauser näitab http://localhost
3. **Apache olek**: `sudo systemctl status apache2`
4. **Mall tegevuses**: Näita dünaamilist sisu sinu kohandustega

### 6.3 Lõplik commit ja push

```bash
# Lõplik dokumentatsiooni commit
git add README.md screenshots/
git commit -m "Lõplik dokumentatsioon - Nädal 13 kodutöö valmis"

# Push GitHub'i
git push origin main

# Loo puhas hoidla struktuur
mkdir -p docs/evidence docs/automation
mv ansible.cfg inventory.yml site.yml group_vars/ docs/automation/
mv templates/ static/ docs/automation/
mv screenshots/ docs/evidence/

# Lõplik organiseeritud commit
git add docs/
git commit -m "Kodutöö organiseeritud õigesse struktuuri"
git push origin main
```text

---

## 7. Repository Submission Requirements

### Hoidla struktuur peab sisaldama:

```
ansible-advanced-homework/
├── README.md                          # Täielik dokumentatsioon
├── docs/
│   ├── automation/                    # SINU automatiseerimisfailid
│   │   ├── ansible.cfg
│   │   ├── inventory.yml  
│   │   ├── site.yml
│   │   ├── group_vars/vault.yml
│   │   └── templates/
│   └── evidence/                      # Töö tõendid
│       ├── screenshots/
│       │   ├── vault-contents.png
│       │   ├── website-working.png
│       │   └── apache-status.png
│       └── deployment-log.txt
└── .gitignore
```text

### Esitamise meetod:
1. **GitHub hoidla link** esitatud kursuse süsteemis
2. **Hoidla peab olema avalik** ülevaatamiseks
3. **Selge esitlus** - puhas, organiseeritud, dokumenteeritud
4. **Töötav demonstreerimine** - õpetaja saab kloonida ja juurutada
