---
tags:
  - Ansible
  - Rollid
  - Praktikum
---

# Praktikum: Ansible'i rollid

Täna teed N3–N4 nginx'i playbook'ist rolli. Roll on sama töö, aga kindlates kaustades: ülesanded, vaikeväärtused, mallid ja handler'id on eraldi failides. Rolli struktuur on seletatud [loengus](lecture_ansible_roles.md).

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

??? abstract "Õpiväljundid"
    Praktikumi lõpuks oskad:

    1. luua rolli käsuga `ansible-galaxy init` ja selgitada, milleks on kaustad `tasks/`, `defaults/`, `templates/` ja `handlers/`;
    2. kirjutada nginx'i rolli osade kaupa ja käivitada seda failist `site.yml`;
    3. muuta rolli muutujat playbook'is, ilma rolli sisu muutmata;
    4. selgitada, miks muutuja `nginx_port` lehel ei muuda porti, mida nginx kuulab;
    5. kasutada Galaxy rolli ja kirjutada see faili `requirements.yml`.

Rida **Ennusta** tähendab, et enne käsku mõtled läbi, mis juhtub. Vastus on kokkuvolditud plokis.

## Osa 1 · Töökaust ja rolli algstruktuur

Töötad oma arvutis (juhtsõlm), nagu N3–N4-s. Sihtmasin on `proxmox1`. Klooni oma Lab 11 repositoorium (link on Classroom 50-s) ja tee tööharu:

```bash
git clone <sinu-repo-URL> ~/lab11 && cd ~/lab11
git switch -c n11-rollid
mkdir -p logid roles
```

Kõik failiteed selles juhendis on kausta `~/lab11` suhtes. Kopeeri N3–N4 repositooriumist fail `inventory.ini` (rühm `web`, sõlm `proxmox1`) või kirjuta see uuesti:

```ini
[web]
proxmox1
```

Loo roll `nginx`:

```bash
ansible-galaxy init --init-path roles nginx
find roles/nginx -maxdepth 1
```

??? success "Oodatav tulemus"
    Kaustas `roles/nginx/` on alamkaustad `tasks`, `defaults`, `handlers`, `templates`, `files`, `vars`, `meta` ja `tests` ning fail `README.md`.

??? warning "Kui `ansible-galaxy init` annab vea „already exists“"
    Kaust on juba olemas. Vaata, mis seal on (`find roles/nginx`). Kui seal on sinu varasem töö, jätka sellega. Ära kustuta kausta ega kasuta võtit `--force`, siis kaob sinu töö.

Täna kasutad kaustu `tasks`, `defaults`, `templates` ja `handlers`. Ülejäänud kaustad võivad tühjaks jääda. Roll töötab ka ilma nendeta.

??? question "Küsimus"
    `defaults/main.yml` ja `vars/main.yml` hoiavad mõlemad muutujaid. Vaata tabelit [Variable precedence](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable). Kumba paned väärtuse, mida rolli kasutaja peaks saama muuta?

## Osa 2 · nginx'i roll

### 2.1 Paigaldus ja teenus

Kirjuta faili `roles/nginx/tasks/main.yml`:

```yaml
- name: nginx on paigaldatud
  ansible.builtin.package:
    name: nginx
    state: present

- name: nginx töötab ja käivitub ka pärast taaskäivitust
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: true
```

Rolli käivitab playbook. Loo fail `site.yml`:

```yaml
- hosts: web
  become: true
  roles:
    - nginx
```

**Ennusta:** nginx on `proxmox1`-s N3-st juba olemas. Kas ülesanded on `changed` või `ok`?

```bash
ansible-playbook -i inventory.ini site.yml
```

??? success "Oodatav tulemus"
    Mõlemad ülesanded on `ok`, sest nginx on juba paigaldatud ja töötab. Roll kirjeldab soovitud olekut. Kui olek on juba õige, ei muuda roll midagi.

??? warning "Kui tuleb viga `the role 'nginx' was not found`"
    `ansible-playbook` otsib rolle kaustast `roles/` faili `site.yml` kõrval. Kontrolli, et oled kaustas `~/lab11`.

??? warning "Kui tuleb `Permission denied` või `This command has to be run under the root user`"
    Failis `site.yml` puudub rida `become: true`. Paketi paigaldamiseks on vaja root-õigusi.

### 2.2 Vaikeväärtus ja mall

Kirjuta faili `roles/nginx/defaults/main.yml`:

```yaml
nginx_port: 80
```

`defaults/` on rolli vaikeväärtused. Rolli kasutaja saab neid playbook'is või inventory's muuta.

Loo mall `roles/nginx/templates/index.html.j2`:

```jinja2
<html>
  <body>
    <h1>Tere, {{ inventory_hostname }}!</h1>
    <p>See leht töötab pordil {{ nginx_port }}.</p>
  </body>
</html>
```

Lisa faili `roles/nginx/tasks/main.yml` lõppu:

```yaml
- name: avaleht on mallist
  ansible.builtin.template:
    src: index.html.j2
    dest: /usr/share/nginx/html/index.html
```

`src` on lihtsalt faili nimi: roll otsib malli ise kaustast `templates/`.

```bash
ansible-playbook -i inventory.ini site.yml
curl http://proxmox1
```

??? success "Oodatav tulemus"
    Leht näitab `Tere, proxmox1!` ja `See leht töötab pordil 80.`

??? warning "Kui `curl http://proxmox1` ei leia masinat"
    Nimi `proxmox1` on ainult failis `~/.ssh/config`. Kasuta `curl` jaoks sõlme IP-aadressi või käivita see sõlmes: `ssh proxmox1 "curl -s localhost"`.

## Osa 3 · Viga: muutuja, mis ei muuda porti

Muuda failis `roles/nginx/defaults/main.yml` väärtuseks `nginx_port: 8080`.

**Ennusta:** kas nginx hakkab pärast playbook'i kuulama porti 8080?

```bash
ansible-playbook -i inventory.ini site.yml
ssh proxmox1 "curl -s localhost:8080; curl -s localhost"
```

??? success "Oodatav tulemus"
    Port 8080 ei vasta. Port 80 vastab ja leht ütleb „See leht töötab pordil 8080.“

??? question "Leia põhjus"
    `nginx_port` on praegu ainult tekst lehe sees. Ükski ülesanne ei muuda nginx'i konfiguratsiooni. Millist faili peab mall muutma, et nginx kuulaks teist porti?

Muutuja olemasolu ei tähenda, et see midagi mõjutab. Pordi muutmiseks peab muutuja olema nginx'i konfiguratsioonis. Seda teed osas 4.

## Osa 4 · Konfiguratsioonimall ja handler

Nginx loeb AlmaLinuxis lisakonfiguratsiooni kaustast `/etc/nginx/conf.d/`. Loo mall `roles/nginx/templates/lab11.conf.j2`, mis lisab teise serveri sinu pordil:

```jinja2
# {{ ansible_managed }}
server {
    listen {{ nginx_port }};
    root /usr/share/nginx/html;
}
```

Lisa faili `roles/nginx/tasks/main.yml` lõppu ülesanne, mis kopeerib malli ja teatab muutusest handler'ile:

```yaml
- name: lisaserver kuulab porti nginx_port
  ansible.builtin.template:
    src: lab11.conf.j2
    dest: /etc/nginx/conf.d/lab11.conf
  notify: laadi nginx uuesti
```

Kirjuta handler faili `roles/nginx/handlers/main.yml`:

```yaml
- name: laadi nginx uuesti
  ansible.builtin.service:
    name: nginx
    state: reloaded
```

`notify:` väärtus peab olema täpselt sama mis handler'i `name:`.

**Ennusta:** kas handler käivitub esimesel ja teisel käivitusel?

```bash
ansible-playbook -i inventory.ini site.yml | tee logid/01-port.txt
ssh proxmox1 "curl -s localhost:8080"
ansible-playbook -i inventory.ini site.yml | tee logid/02-uuesti.txt
```

??? success "Oodatav tulemus"
    Esimesel käivitusel on mall `changed` ja väljundis on `RUNNING HANDLER [nginx : laadi nginx uuesti]`. Port 8080 vastab nüüd sinu lehega. Teisel käivitusel on kõik `ok`, `changed=0` ja handler ei käivitu, sest fail ei muutunud.

??? warning "Kui port 8080 ei vasta, aga viga ei tulnud"
    Vaata sõlmes, kas nginx on konfiguratsiooni vastu võtnud: `ssh proxmox1 "sudo nginx -t"`. Kui sõlmes töötab tulemüür (`sudo firewall-cmd --state` vastab `running`), ava port: `sudo firewall-cmd --add-port=8080/tcp`.

## Osa 5 · Muutuja playbook'is

Viiel serveril võib olla viis eri porti. Rolli `defaults/` jääb samaks ja väärtus antakse playbook'is. Pane failis `roles/nginx/defaults/main.yml` tagasi `nginx_port: 80` ja muuda faili `site.yml`:

```yaml
- hosts: web
  become: true
  roles:
    - role: nginx
      vars:
        nginx_port: 8081
```

```bash
ansible-playbook -i inventory.ini site.yml
ssh proxmox1 "curl -s localhost:8081"
```

??? success "Oodatav tulemus"
    Port 8081 vastab. Playbook'is antud väärtus on tähtsam kui rolli `defaults/`.

## Osa 6 · Galaxy roll

Kõike ei pea ise kirjutama. [Ansible Galaxy](https://galaxy.ansible.com/) on avalik rollide hoidla. Projekti sõltuvused kirjutatakse faili `requirements.yml`, et järgmine inimene saaks need ühe käsuga paigaldada. Loo fail:

```yaml
roles:
  - name: geerlingguy.git
    version: "3.0.1"
```

```bash
ansible-galaxy install -r requirements.yml
ansible-galaxy list
```

Roll paigaldub kausta `~/.ansible/roles/`. See kaust ei lähe repositooriumi, repositooriumi läheb ainult `requirements.yml`. Lisa roll faili `site.yml` teiseks:

```yaml
  roles:
    - role: nginx
      vars:
        nginx_port: 8081
    - geerlingguy.git
```

```bash
ansible-playbook -i inventory.ini site.yml
ssh proxmox1 "git --version"
```

??? warning "Kui roll ei lae alla"
    Kontrolli, kas sinu arvuti jõuab Galaxy serverini: `curl -sI https://galaxy.ansible.com`. Kui versiooni `3.0.1` ei leita, vaata rolli lehelt [geerlingguy.git](https://galaxy.ansible.com/ui/standalone/roles/geerlingguy/git/) uusimat versiooni ja kirjuta see faili.

??? question "Küsimus"
    Vaata käsuga `find ~/.ansible/roles/geerlingguy.git -maxdepth 1`. Kas struktuur on sama mis sinu rollil? Mida kontrolliksid enne, kui võõra rolli oma serveris käivitad?

## Töö esitamine

Repositooriumis on `site.yml`, `inventory.ini`, `requirements.yml`, roll `roles/nginx/` ja logid `logid/01-port.txt` ning `logid/02-uuesti.txt`. Faili `README.md` kirjuta kahe lausega, miks `nginx_port` osas 3 porti ei muutnud.

```bash
git add site.yml inventory.ini requirements.yml roles logid README.md
git status --short
git commit -m "N11: nginx'i roll, mall, handler ja Galaxy roll"
git push -u origin n11-rollid
```

Ava pull request harusse `main` ja liida see. Tulemuse näed Classroom 50-s.

## Lisaülesanded

??? example "1 · Teine roll"
    Loo roll `tulemyyr`, mis avab pordi `nginx_port` mooduliga [`ansible.posix.firewalld`](https://docs.ansible.com/ansible/latest/collections/ansible/posix/firewalld_module.html) (`port: "{{ nginx_port }}/tcp"`, `permanent: true`, `immediate: true`). Lisa roll faili `site.yml` enne rolli `nginx` ja jälgi käivitamise järjekorda. Kui sõlmes firewalld ei tööta, lisa rollile esimeseks ülesandeks selle käivitamine.

??? example "2 · Sõltuvus"
    Lisa faili `roles/nginx/meta/main.yml` plokk `dependencies:`, mis nõuab, et `tulemyyr` käivituks enne. Kas pead `tulemyyr`-i siis veel failis `site.yml` nimetama?
