# Ansible Roles Lab: Nginx Role

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Luua töötav Ansible role

---

## Lab ülesanded

### Ülesanne 1: Role struktuuri loomine

```bash
# Looge töökataloog
mkdir ~/ansible-roles-lab && cd ~/ansible-roles-lab
mkdir roles && cd roles

# Genereerige role struktuur
ansible-galaxy init nginx-custom

# Liikuge role kausta
cd nginx-custom
```

**Checkpoint:** `ls -la` peaks näitama 8 kausta/faili

---

### Ülesanne 2: Defaults seadistamine

**Fail:** `defaults/main.yml`

**Nõuded:**
- Defineerige vähemalt 5 muutujat nginx jaoks
- Üks muutuja peab kasutama Jinja2 (näiteks: `{{ ansible_processor_vcpus }}`)
- Dokumenteerige kommentaaridega

**Vihje:** Mõelge portidele, kasutajatele, SSL-ile

**Test:**
```bash
ansible -m debug -a "var=nginx_port" localhost -e "@defaults/main.yml"
```

---

### Ülesanne 3: Installation tasks

**Fail:** `tasks/install.yml`

**Nõuded:**
1. Update package cache (ainult Debian/Ubuntu)
2. Install nginx
3. Create nginx user
4. Create directories: `/var/www/html`, `/etc/nginx/sites-available`, `/etc/nginx/sites-enabled`

**Looge ka:** `tasks/main.yml`
```yaml
---
- include_tasks: install.yml
```

**Test:**
```bash
ansible-playbook --syntax-check tasks/main.yml
```

---

### Ülesanne 4: Nginx template

**Fail:** `templates/nginx.conf.j2`

**Nõuded:**
- Kasutage vähemalt 3 muutujat defaults'ist
- Lisage conditional block ({% if %})
- Worker processes peab sõltuma CPU tuumadest

**Näide algus:**
```nginx
user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};

events {
    worker_connections {{ nginx_worker_connections }};
}

http {
    # Teie kood siia
}
```

**Fail:** `tasks/configure.yml`
```yaml
---
- name: Deploy nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    backup: yes
  notify: restart nginx
```

**Test:** Template peab genereeruma ilma vigadeta

---

### Ülesanne 5: Handlers

**Fail:** `handlers/main.yml`

**Nõuded:**
1. Handler "restart nginx"
2. Handler "reload nginx"

**Test:** Handler peab olema `service` mooduliga

---

### Ülesanne 6: Virtual hosts

**Fail:** `templates/vhost.conf.j2`

```nginx
server {
    listen {{ item.port | default(80) }};
    server_name {{ item.name }};
    root {{ item.root | default('/var/www/html') }};
    
    # Lisa SSL kui item.ssl == true
}
```

**Fail:** `tasks/vhosts.yml`

**Nõuded:**
1. Loop läbi `nginx_vhosts` listi
2. Create vhost config igale saidile
3. Create document root kataloogid
4. Enable sites (symlink)

**defaults/main.yml lisa:**
```yaml
nginx_vhosts: []
# nginx_vhosts:
#   - name: example.com
#     port: 80
#     root: /var/www/example
```

---

### Ülesanne 7: SSL sertifikaadid

**Fail:** `tasks/ssl.yml`

**Nõuded:**
1. Genereeri self-signed cert kui `nginx_ssl_enabled: true`
2. Kasuta OpenSSL käsku
3. Cert kehtib 365 päeva

**Käsk vihjeks:**
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx.key \
  -out /etc/ssl/certs/nginx.crt \
  -subj "/C=EE/ST=Harjumaa/L=Tallinn/O=School/CN=localhost"
```

---

### Ülesanne 8: Idempotency test

**Fail:** `tasks/main.yml`

Ühendage kõik taskid:
```yaml
---
- include_tasks: install.yml
- include_tasks: configure.yml
- include_tasks: ssl.yml
  when: nginx_ssl_enabled | default(false)
- include_tasks: vhosts.yml
  when: nginx_vhosts | length > 0
```

**Test:** Käivitage 2x järjest, teine kord ei tohi midagi muuta
```bash
ansible-playbook test.yml
ansible-playbook test.yml  # Kõik peab olema "ok", mitte "changed"
```

---

### Ülesanne 9: Test playbook

**Fail:** `~/ansible-roles-lab/test.yml`

```yaml
---
- name: Test nginx role
  hosts: localhost
  connection: local
  become: yes
  
  vars:
    nginx_ssl_enabled: true
    nginx_vhosts:
      - name: test.local
        port: 8080
        ssl: true
  
  roles:
    - nginx-custom
  
  post_tasks:
    - name: Check nginx
      uri:
        url: "http://localhost:8080"
      ignore_errors: yes
```

**Lõpptest:**
```bash
ansible-playbook test.yml --ask-become-pass
sudo systemctl status nginx
curl http://localhost:8080
```

---

## Hindamiskriteeriumid

### Kohustuslik (5p)
- [ ] Role struktuur õige
- [ ] Nginx installeerub
- [ ] Template töötab
- [ ] Handler töötab
- [ ] Idempotent

### Lisapunktid
- [ ] SSL töötab (+1p)
- [ ] Virtual hosts töötab (+1p)
- [ ] Validation tasks (+1p)
- [ ] README.md (+1p)
- [ ] Meta informatsioon (+1p)

---

## Vihjed probleemide korral

**Nginx ei käivitu:**
```bash
sudo nginx -t  # Kontrolli konfiguratsiooni
sudo journalctl -u nginx  # Vaata logisid
```

**Template ei genereeru:**
```bash
ansible -m template -a "src=nginx.conf.j2 dest=/tmp/test.conf" localhost
```

**Handler ei käivitu:**
- Kontrollige, kas task muutis midagi (changed: true)
- Notify nimi peab täpselt klappima

---

## Esitamine

1. Push GitHub'i: `ansible-roles-lab/` kaust
2. README.md peab sisaldama kasutamise näidet
3. Role peab töötama Ubuntu 20.04/22.04
