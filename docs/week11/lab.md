---
tags:
  - Ansible
  - Rollid
  - Praktikum
---

# Praktikum: Ansible'i rollid

N3 ja N4 praktikumis oli nginx'i paigaldus ühes playbook'is. Täna kirjutad sama töö rolliks: ülesanded, vaikeväärtused, mallid ja handler'id on eraldi kaustades, ning playbook `site.yml` ainult käivitab rolli. Rolli kaustad on seletatud [loengus](lecture.md).

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

??? abstract "Õpiväljundid"
    Praktikumi lõpuks oskad:

    1. luua rolli käsuga `ansible-galaxy init` ja selgitada, milleks on kaustad `tasks/`, `defaults/`, `templates/` ja `handlers/`;
    2. kirjutada nginx'i rolli osade kaupa ja käivitada seda failist `site.yml`;
    3. muuta rolli muutujat playbook'is, ilma rolli sisu muutmata;
    4. leida põhjuse, miks muutuja `nginx_port` lehel ei muuda porti, mida nginx kuulab;
    5. kasutada Galaxy rolli ja kirjutada see faili `requirements.yml`.

Iga ülesande kood on kokkuvolditud plokis. Loe enne selgitus, siis ava plokk, lisa kood faili ja käivita. Rida **Ennusta** tähendab, et enne käsku mõtled läbi, mis juhtub. Vastus on kokkuvolditud plokis.

## Osa 1 · Repositoorium ja rolli kaustad

Töötad oma arvutis (juhtsõlm) nagu N3 ja N4 praktikumis, sihtmasin on `proxmox1`. Starteris on fail `inventory.ini` (rühm `web`, sõlm `proxmox1`) ning tühjad kaustad `roles/` ja `logid/`. Klooni oma Lab 11 repositoorium (link on Classroom 50-s):

```bash
git clone <sinu-repo-URL> ~/lab11 && cd ~/lab11
ansible -i inventory.ini web -m ping
```

??? success "Oodatav tulemus"
    `proxmox1 | SUCCESS` ja `"ping": "pong"`. Kui ühendus ei tööta, kontrolli SSH-d nagu N3-s: `ssh proxmox1 hostname`.

Kõik failiteed selles juhendis on kausta `~/lab11` suhtes. Rolli kaustu ei pea käsitsi looma. Käsk `ansible-galaxy init` loob rolli skeleti:

```bash
ansible-galaxy init --init-path roles nginx
find roles/nginx -maxdepth 1
```

??? success "Oodatav tulemus"
    Kaustas `roles/nginx/` on alamkaustad `tasks`, `defaults`, `handlers`, `templates`, `files`, `vars`, `meta` ja `tests` ning fail `README.md`.

??? warning "Kui `ansible-galaxy init` annab vea „already exists“"
    Kaust on juba olemas. Vaata, mis seal on (`find roles/nginx`). Kui seal on sinu varasem töö, jätka sellega. Ära kustuta kausta ega kasuta võtit `--force`, siis kaob sinu töö.

Täna kasutad kaustu `tasks`, `defaults`, `templates` ja `handlers`. Ülejäänud kaustad võivad tühjaks jääda.

??? question "Küsimus"
    `defaults/main.yml` ja `vars/main.yml` hoiavad mõlemad muutujaid. Vaata tabelit [Variable precedence](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable). Kumba paned väärtuse, mida rolli kasutaja peaks saama muuta?

    ??? success "Vastus"
        `defaults/main.yml`. Rolli vaikeväärtused on tabelis kõige nõrgemad ja iga teine koht (inventory, playbook, käsurida) kirjutab need üle. `vars/main.yml` on tabelis kõrgemal, sinna pannakse rolli sisemised väärtused.

## Osa 2 · nginx'i roll

### 2.1 Paigaldus ja teenus

Rolli ülesanded on failis `roles/nginx/tasks/main.yml`. Süntaks on sama mis playbook'i plokis `tasks:`, aga ilma `hosts:` ja `tasks:` reata, sest masinad valib playbook. Esimesed kaks ülesannet on samad mis N3-s: pakett on paigaldatud ning teenus töötab ja käivitub ka pärast taaskäivitust.

??? example "Ülesanne: kirjuta `roles/nginx/tasks/main.yml`"
    Asenda faili sisu (`---` rida võib jääda):

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

Roll ei tee midagi, kuni playbook selle käivitab. Playbook `site.yml` ütleb, millisele rühmale roll rakendub, ja `become: true` annab paketi paigaldamiseks root-õigused.

??? example "Ülesanne: loo `site.yml`"
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
    Mõlemad ülesanded on `ok`, sest nginx on juba paigaldatud ja töötab. Väljundis on ülesande nime ees rolli nimi: `TASK [nginx : nginx on paigaldatud]`. Roll kirjeldab soovitud olekut ja kui tegelik olek on juba sama, ei muuda roll midagi.

??? warning "Kui tuleb viga `the role 'nginx' was not found`"
    `ansible-playbook` otsib rolle kaustast `roles/` faili `site.yml` kõrval. Kontrolli, et oled kaustas `~/lab11` ja et roll on kaustas `roles/nginx`, mitte `nginx`.

??? warning "Kui tuleb `Permission denied` või `This command has to be run under the root user`"
    Failis `site.yml` puudub rida `become: true`.

### 2.2 Vaikeväärtus ja mall

Kaust `defaults/` hoiab rolli vaikeväärtusi. Rolli kasutaja saab neid playbook'is või inventory's muuta, rolli sisu ei pea selleks puutuma.

??? example "Ülesanne: kirjuta `roles/nginx/defaults/main.yml`"
    ```yaml
    nginx_port: 80
    ```

Mallid on rolli kaustas `templates/`. Moodulile `template` piisab faili nimest, sest roll otsib malli ise oma kaustast.

??? example "Ülesanne: loo mall `roles/nginx/templates/index.html.j2`"
    ```jinja2
    <html>
      <body>
        <h1>Tere, {{ inventory_hostname }}!</h1>
        <p>See leht töötab pordil {{ nginx_port }}.</p>
      </body>
    </html>
    ```

??? example "Ülesanne: lisa `roles/nginx/tasks/main.yml` lõppu"
    ```yaml
    - name: avaleht on mallist
      ansible.builtin.template:
        src: index.html.j2
        dest: /usr/share/nginx/html/index.html
    ```

```bash
ansible-playbook -i inventory.ini site.yml
ssh proxmox1 "curl -s localhost"
```

??? success "Oodatav tulemus"
    Ülesanne `avaleht on mallist` on `changed`. Leht näitab `Tere, proxmox1!` ja `See leht töötab pordil 80.`

## Osa 3 · Muutuja, mis ei muuda porti

Muuda failis `roles/nginx/defaults/main.yml` väärtuseks `nginx_port: 8080`.

**Ennusta:** kas nginx hakkab pärast playbook'i kuulama porti 8080?

```bash
ansible-playbook -i inventory.ini site.yml
ssh proxmox1 "curl -s localhost:8080; curl -s localhost"
```

??? success "Oodatav tulemus"
    Port 8080 ei vasta (`Connection refused`). Port 80 vastab ja leht ütleb „See leht töötab pordil 8080.“

??? question "Leia põhjus"
    Millistes failides muutujat `nginx_port` kasutatakse? Millist faili peab muutma, et nginx kuulaks teist porti?

    ??? success "Vastus"
        `nginx_port` on ainult lehe tekstis. Ükski ülesanne ei muuda nginx'i konfiguratsiooni, nii et nginx kuulab endiselt porti 80. Pordi muutmiseks peab muutuja olema nginx'i konfiguratsioonifailis.

## Osa 4 · Konfiguratsioonimall ja handler

AlmaLinuxis loeb nginx lisakonfiguratsiooni kaustast `/etc/nginx/conf.d/`. Mall lisab sinna teise serveri ploki, mis kuulab porti `nginx_port`. Rida `{{ ansible_managed }}` kirjutab faili algusesse märke, et faili haldab Ansible ja käsitsi muutmine kirjutatakse üle.

??? example "Ülesanne: loo mall `roles/nginx/templates/lab11.conf.j2`"
    ```jinja2
    # {{ ansible_managed }}
    server {
        listen {{ nginx_port }};
        root /usr/share/nginx/html;
    }
    ```

Uus konfiguratsioon hakkab kehtima alles siis, kui nginx selle uuesti laadib. Võti `notify:` teatab muutusest handler'ile. Handler käivitub play lõpus ja ainult siis, kui ülesanne oli `changed`.

??? example "Ülesanne: lisa `roles/nginx/tasks/main.yml` lõppu"
    ```yaml
    - name: lisaserver kuulab porti nginx_port
      ansible.builtin.template:
        src: lab11.conf.j2
        dest: /etc/nginx/conf.d/lab11.conf
      notify: laadi nginx uuesti
    ```

Rolli handler'id on failis `roles/nginx/handlers/main.yml`. Väärtus `notify:` peab olema täpselt sama mis handler'i `name:`.

??? example "Ülesanne: kirjuta `roles/nginx/handlers/main.yml`"
    ```yaml
    - name: laadi nginx uuesti
      ansible.builtin.service:
        name: nginx
        state: reloaded
    ```

**Ennusta:** kas handler käivitub esimesel ja teisel käivitusel?

```bash
ansible-playbook -i inventory.ini site.yml | tee logid/01-port.txt
ssh proxmox1 "curl -s localhost:8080"
ansible-playbook -i inventory.ini site.yml | tee logid/02-uuesti.txt
```

??? success "Oodatav tulemus"
    Esimesel käivitusel on mall `changed` ja väljundis on `RUNNING HANDLER [nginx : laadi nginx uuesti]`. Port 8080 vastab nüüd sinu lehega. Teisel käivitusel on kõik `ok`, kokkuvõttes `changed=0` ja handler ei käivitu, sest fail ei muutunud.

??? warning "Kui port 8080 ei vasta, aga viga ei tulnud"
    Kontrolli, kas nginx võttis konfiguratsiooni vastu: `ssh proxmox1 "sudo nginx -t"`. Kui sõlmes töötab tulemüür (`sudo firewall-cmd --state` vastab `running`), ava port: `ssh proxmox1 "sudo firewall-cmd --add-port=8080/tcp"`.

??? warning "Kui tuleb viga `The requested handler 'laadi nginx uuesti' was not found`"
    Handler'i nimi ja `notify:` väärtus erinevad. Võrdle neid tähthaaval, ka tühikuid.

## Osa 5 · Muutuja playbook'is

Viiel serveril võib olla viis eri porti. Rolli `defaults/` jääb samaks ja väärtus antakse playbook'is rolli juures. Pane failis `roles/nginx/defaults/main.yml` tagasi `nginx_port: 80`.

??? example "Ülesanne: muuda `site.yml`"
    ```yaml
    - hosts: web
      become: true
      roles:
        - role: nginx
          vars:
            nginx_port: 8081
    ```

**Ennusta:** kumb väärtus kehtib, 80 rolli `defaults/`-ist või 8081 playbook'ist?

```bash
ansible-playbook -i inventory.ini site.yml
ssh proxmox1 "curl -s localhost:8081"
```

??? success "Oodatav tulemus"
    Port 8081 vastab ja leht ütleb „See leht töötab pordil 8081.“ Playbook'is rolli juures antud väärtus kirjutab rolli `defaults/` üle.

## Osa 6 · Galaxy roll

Kõiki rolle ei pea ise kirjutama. [Ansible Galaxy](https://galaxy.ansible.com/) on avalik rollide hoidla. Projekti sõltuvused kirjutatakse faili `requirements.yml`, et järgmine inimene saaks need ühe käsuga paigaldada. Versioon on failis kirjas, et igaüks paigaldaks täpselt sama rolli.

??? example "Ülesanne: loo `requirements.yml`"
    ```yaml
    roles:
      - name: geerlingguy.git
        version: "3.0.1"
    ```

```bash
ansible-galaxy install -r requirements.yml
ansible-galaxy list
```

??? success "Oodatav tulemus"
    `- geerlingguy.git (3.0.1) was installed successfully` ja nimekirjas on rida `- geerlingguy.git, 3.0.1`.

Roll paigaldub kausta `~/.ansible/roles/`. See kaust ei lähe repositooriumi, repositooriumi läheb ainult `requirements.yml`.

??? example "Ülesanne: lisa roll `site.yml`-i teiseks"
    ```yaml
      roles:
        - role: nginx
          vars:
            nginx_port: 8081
        - geerlingguy.git
    ```

```bash
ansible-playbook -i inventory.ini site.yml | tee logid/03-galaxy.txt
ssh proxmox1 "git --version"
```

??? success "Oodatav tulemus"
    Väljundis on ülesanded kujul `TASK [geerlingguy.git : ...]` ja sõlmes vastab `git version ...`.

??? warning "Kui roll ei laadi alla"
    Kontrolli, kas sinu arvuti jõuab Galaxy serverini: `curl -sI https://galaxy.ansible.com`. Kui versiooni `3.0.1` ei leita, vaata rolli lehelt [geerlingguy.git](https://galaxy.ansible.com/ui/standalone/roles/geerlingguy/git/) uusimat versiooni ja kirjuta see faili.

??? question "Küsimus"
    Vaata käsuga `find ~/.ansible/roles/geerlingguy.git -maxdepth 1`. Kas struktuur on sama mis sinu rollil? Mida kontrolliksid enne, kui võõra rolli oma serveris käivitad?

    ??? success "Vastus"
        Struktuur on sama (`tasks`, `defaults`, `handlers`, `meta` jne). Enne kasutamist vaata failist `tasks/main.yml`, mida roll masinas muudab, ja Galaxy lehelt, millal rolli viimati uuendati ning millised operatsioonisüsteemid on toetatud.

## Töö esitamine

Repositooriumis on `site.yml`, `requirements.yml`, roll `roles/nginx/` ja logid kaustas `logid/`.

```bash
git add site.yml requirements.yml roles logid
git commit -m "nginx'i roll malli ja handler'iga, Galaxy roll geerlingguy.git"
git push
```

Tulemuse näed Classroom 50-s.

## Lisaülesanded

??? example "1 · Teine roll"
    Loo roll `tulemyyr`, mis avab pordi `nginx_port` mooduliga [`ansible.posix.firewalld`](https://docs.ansible.com/ansible/latest/collections/ansible/posix/firewalld_module.html) (`port: "{{ nginx_port }}/tcp"`, `permanent: true`, `immediate: true`). Lisa roll faili `site.yml` enne rolli `nginx` ja vaata väljundist käivitamise järjekorda. Kui sõlmes firewalld ei tööta, lisa rollile esimeseks ülesandeks selle käivitamine.

??? example "2 · Sõltuvus"
    Lisa faili `roles/nginx/meta/main.yml` plokk `dependencies:`, mis nõuab, et `tulemyyr` käivituks enne. Kas pead `tulemyyr`-i siis veel failis `site.yml` nimetama?
