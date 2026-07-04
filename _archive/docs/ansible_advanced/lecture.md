# Ansible Advanced: Edasijõudnud Funktsioonid

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Teemad:** Variables, Templates, Handlers, Vault

## Õpiväljundid

Pärast seda nädalat oskate:
- Hallata keerukamaid muutujaid ja nende hierarhiat
- Luua dünaamilisi konfiguratsioone Jinja2 template'itega
- Kasutada handler'eid efektiivseks teenuste haldamiseks
- Rakendada Ansible Vault'i tundlike andmete kaitsmiseks
- Järgida Ansible best practice'sid

---

## 1. Variables ja Variable Precedence

### 1.1 Muutujate hierarhia

Ansible'is on muutujatel kindel prioriteedi järjekord:

```mermaid
graph TD
    A[1. Command line<br/>-e, --extra-vars] --> B[2. Task variables<br/>task sees]
    B --> C[3. Block variables<br/>block sees]
    C --> D[4. Role variables<br/>role/vars/main.yml]
    D --> E[5. Play variables<br/>playbook sees]
    E --> F[6. Host variables<br/>host_vars/]
    F --> G[7. Group variables<br/>group_vars/]
    G --> H[8. Role defaults<br/>role/defaults/main.yml]
    
    style A fill:#ff9999
    style B fill:#ffcc99
    style C fill:#ffff99
    style D fill:#99ff99
    style E fill:#99ccff
    style F fill:#cc99ff
    style G fill:#ff99cc
    style H fill:#99ffcc
```text

**Prioriteedi järjekord (kõrgeim esimesena):**
1. **Command line** (`-e`, `--extra-vars`)
2. **Task variables** (task sees)
3. **Block variables** (block sees)
4. **Role variables** (role/vars/main.yml)
5. **Play variables** (playbook sees)
6. **Host variables** (host_vars/)
7. **Group variables** (group_vars/)
8. **Role defaults** (role/defaults/main.yml)

**Näide muutujate konfliktist:**

```yaml
# group_vars/all.yml
server_port: 80

# host_vars/webserver1.yml  
server_port: 8080

# playbook.yml
- name: "Server setup"
  vars:
    server_port: 3000
  tasks:
    - debug:
        msg: "Port will be: {{ server_port }}"  # Tulemus: 3000
```bash

🤔 **Realiteedikontroll:** Kui teil on 100 serverit ja igal on erinev konfiguratsioon, kuidas te seda ilma muutujate hierarhiata hallaksite?

### 1.2 Faktide kasutamine

Ansible kogub automaatselt süsteemi infot:

```yaml
- name: "Näita süsteemi faktid"
  debug:
    msg:
      - "OS: {{ ansible_os_family }}"
      - "Memory: {{ ansible_memtotal_mb }}MB"
      - "CPU cores: {{ ansible_processor_vcpus }}"
      - "IP: {{ ansible_default_ipv4.address }}"
```text

### 1.3 Registered variables

Salvestage käsu tulemusi:

```yaml
- name: "Kontrolli Apache staatust"
  shell: "systemctl is-active apache2"
  register: apache_status
  failed_when: false

- name: "Tegevus Apache staatuse põhjal"
  debug:
    msg: "Apache on {{ apache_status.stdout }}"
  when: apache_status.rc == 0
```text

---

## 2. Jinja2 Templates

### 2.1 Template'ite põhitõed

Jinja2 võimaldab luua dünaamilisi faile:

```yaml
# Playbook task
- name: "Genereeri konfiguratsioon"
  template:
    src: app.conf.j2
    dest: /etc/app/config.conf
```text

**Template fail (`templates/app.conf.j2`):**
```ini
# {{ ansible_managed }}
server_name = {{ inventory_hostname }}
port = {{ server_port | default(80) }}
debug = {{ debug_mode | default(false) | lower }}

# Environment specific
{% if environment == 'production' %}
log_level = ERROR
cache_enabled = true
{% else %}
log_level = DEBUG
cache_enabled = false
{% endif %}
```text

**Küsimus:** Miks on kasulik kasutada `{{ ansible_managed }}` kommentaari template'i alguses?

### 2.2 Conditionals template'ites

```jinja2
{% if ansible_os_family == "Debian" %}
package_manager = apt
{% elif ansible_os_family == "RedHat" %}
package_manager = yum
{% else %}
package_manager = unknown
{% endif %}

# Inline conditionals
service_port = {{ 443 if ssl_enabled else 80 }}
```text

🤔 **Mõelge:** Kuidas aitavad conditionals hallata erinevaid operatsioonisüsteeme ühes template'is?

### 2.3 Loops template'ites

```jinja2
# Virtual hosts
{% for host in virtual_hosts %}
<VirtualHost *:{{ host.port }}>
    ServerName {{ host.name }}
    DocumentRoot {{ host.document_root }}
    {% if host.ssl_enabled | default(false) %}
    SSLEngine on
    SSLCertificateFile {{ host.ssl_cert }}
    {% endif %}
</VirtualHost>
{% endfor %}

# Database users
{% for user in database_users %}
CREATE USER '{{ user.name }}'@'{{ user.host }}' IDENTIFIED BY '{{ user.password }}';
GRANT {{ user.privileges | join(', ') }} ON {{ user.database }}.* TO '{{ user.name }}'@'{{ user.host }}';
{% endfor %}
```text

📊 **Võrdlus:** Võrrelge template'i kasutamist staatilise konfiguratsiooniga. Millised on eelised ja puudused?

### 2.4 Filters

```jinja2
# String manipulation
server_name = {{ inventory_hostname | upper }}
config_file = {{ app_name | lower }}.conf

# Number operations
memory_limit = {{ (ansible_memtotal_mb * 0.8) | int }}M
worker_processes = {{ ansible_processor_vcpus | default(1) }}

# List operations
packages = {{ required_packages | join(' ') }}
first_server = {{ groups['webservers'] | first }}

# JSON/YAML
config = {{ app_config | to_nice_json }}
```text

**Praktiline nipp:** Kasutage `| default()` filter'it vaikeväärtuste määramiseks template'ites.

---

## 3. Handlers ja Notifications

### 3.1 Handler'ite põhitõed

Handler'id käivituvad ainult siis, kui task teeb muudatusi:

```yaml
tasks:
  - name: "Uuenda Apache konfiguratsioon"
    template:
      src: apache.conf.j2
      dest: /etc/apache2/apache2.conf
    notify: "restart apache"
    
  - name: "Lisa virtual host"
    template:
      src: vhost.conf.j2
      dest: "/etc/apache2/sites-available/{{ site_name }}.conf"
    notify:
      - "enable site"
      - "reload apache"

handlers:
  - name: "restart apache"
    service:
      name: apache2
      state: restarted
  
  - name: "reload apache"
    service:
      name: apache2
      state: reloaded

  - name: "enable site"
    command: "a2ensite {{ site_name }}"
```text

🤔 **Mõelge:** Miks kasutada `reload` mitte `restart`? Millal on vahe oluline?

### 3.2 Handler'ite täiustatud kasutamine

**Listen groups:**
```yaml
tasks:
  - name: "Uuenda PHP konfiguratsioon"
    template:
      src: php.ini.j2
      dest: /etc/php/7.4/fpm/php.ini
    notify: "restart web services"
  
  - name: "Uuenda Apache konfiguratsioon"
    template:
      src: apache.conf.j2
      dest: /etc/apache2/apache2.conf
    notify: "restart web services"

handlers:
  - name: "restart php-fpm"
    service:
      name: php7.4-fpm
      state: restarted
    listen: "restart web services"

  - name: "restart apache"
    service:
      name: apache2
      state: restarted
    listen: "restart web services"
```bash

**Küsimus:** Mis järjekorras käivituvad handler'id ja miks see on oluline?

🎯 **Praktikasoovitus:** Kasutage `meta: flush_handlers` kriitiliste kontrollidel, kui peate veenduma, et teenus on taaskäivitatud enne järgmisi task'e.

---

## 4. Ansible Vault Secrets

### 4.1 Vault'i põhitõed

Ansible Vault krüpteerib tundlikud andmed:

```bash
# Loo krüpteeritud fail
ansible-vault create secrets.yml

# Muuda krüpteeritud faili
ansible-vault edit secrets.yml

# Vaata krüpteeritud faili
ansible-vault view secrets.yml

# Krüpteeri olemasolev fail
ansible-vault encrypt plaintext.yml

# Dekrüpteeri fail
ansible-vault decrypt secrets.yml
```text

**Näide vault failis:**
```yaml
# secrets.yml (krüpteeritud)
vault_db_password: "supersecretpassword123"
vault_api_key: "abc123def456ghi789"
vault_ssl_private_key: |
  -----BEGIN PRIVATE KEY-----
  [private key content]
  -----END PRIVATE KEY-----
```text

🔐 **Turvanipp:** Vault'i parool peaks olema vähemalt 12 tähemärki ja sisaldama erinevaid sümboleid.

### 4.2 Vault'i kasutamine playbook'ides

```yaml
# group_vars/production/vault.yml (krüpteeritud)
vault_mysql_root_password: "production_mysql_secret"
vault_app_secret_key: "prod_app_key_123456"

# group_vars/production/vars.yml (avatud)
mysql_root_password: "{{ vault_mysql_root_password }}"
app_secret_key: "{{ vault_app_secret_key }}"
environment: "production"
```text

**Playbook käivitamine:**
```bash
# Küsi parooli
ansible-playbook site.yml --ask-vault-pass

# Kasuta parool faili
echo "mypassword" > .vault_pass
ansible-playbook site.yml --vault-password-file .vault_pass
```text

🤔 **Mõelge:** Kuidas saaksite organisatsioonis turvaliselt jagada vault paroole?

### 4.3 Multiple vault passwords

```bash
# Erinev vault erinevale keskkonnale
ansible-vault create --vault-id prod@prompt production-secrets.yml
ansible-vault create --vault-id dev@prompt development-secrets.yml

# Käivitamine
ansible-playbook site.yml --vault-id prod@prompt --vault-id dev@prompt
```text

### 4.4 Vault parooli haldamine

**Environment variable:**
```bash
export ANSIBLE_VAULT_PASSWORD=mypassword
ansible-playbook site.yml
```text

**Script'iga:**
```bash
#!/bin/bash
# vault_pass.sh
echo "my_secret_password"

chmod +x vault_pass.sh
ansible-playbook site.yml --vault-password-file vault_pass.sh
```text

💭 **Küsimus:** Mis probleeme võib tekkida vault paroolide haldamisel meeskonnatöös?

### 4.5 Vault'i rekey

```bash
# Muuda vault parooli
ansible-vault rekey secrets.yml

# Muuda spetsiifilise vault'i parooli
ansible-vault rekey --vault-id old@prompt --new-vault-id new@prompt secrets.yml
```text

**Praktiline nipp:** Regulaarselt muutke vault paroole ja dokumenteerige rotatsiooni protseduuri.

### 4.6 Best practices

#### 4.6.1 Vault failide organisatsioon
```
group_vars/
├── all/
│   ├── vars.yml          # Avalikud muutujad
│   └── vault.yml         # Krüpteeritud saladused
├── production/
│   ├── vars.yml
│   └── vault.yml
└── development/
    ├── vars.yml
    └── vault.yml
```text

🤔 **Mõelge:** Kuidas organiseerida vault faile nii, et oleks selge, millised andmed on krüpteeritud ja millised mitte?

#### 4.6.2 Vault rotatsiooni strateegi

```bash
# Regulaarne parooli vahetamine (näiteks kvartaalselt)
# 1. Loo uus vault parool
ansible-vault rekey --new-vault-password-file new_password production-secrets.yml

# 2. Uuenda CI/CD süsteemid uue parooliga
# 3. Teavita meeskonda muudatusest
# 4. Eemalda vana parool kõigist süsteemidest
```bash

---

## 5. Lab: Template-based Configuration

Käed-küljes praktikum Ansible'i täpsemate funktsioonidega tutvumiseks.

**📁 Vaata:** [lab.md](lab.md)

**Sisaldab:**
- Advanced variables setup
- Jinja2 template'ite loomine
- Handlers ja advanced playbook'id  
- Ansible Vault rakendamine
