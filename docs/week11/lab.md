---
tags:
  - Ansible
  - Rollid
  - Praktikum
---

# Praktikum: Ansible'i rollid

N3 praktikumis paigaldasid nginx'i ühe playbook'iga. Täna alustad samast: starteris on tavaline playbook, mis paigaldab nginx'i ja teeb avalehe. Kõigepealt muudad selles playbook'is midagi ja vaatad, mis serveris muutub. Siis tõstad sama töö rolliks: ülesanded, muutujad ja mall lähevad rolli kindlatesse kaustadesse ning playbook `site.yml` ainult käivitab rolli. Lõpuks lisad rollile handler'i. Rolli kaustad on seletatud [loengus](lecture.md).

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

??? abstract "Õpiväljundid"
    Praktikumi lõpuks oskad:

    1. muuta playbook'i malli ja ennustada, milline ülesanne on pärast muudatust `changed`;
    2. tõsta tavalise playbook'i ülesanded, muutujad ja malli rolli kaustadesse `tasks/`, `defaults/` ja `templates/`;
    3. kontrollida, et pärast rolliks tegemist on tulemus serveris sama;
    4. leida põhjuse, miks muutuja `nginx_port` lehel ei muuda porti, mida nginx kuulab;
    5. lisada rollile handler'i ja muuta rolli muutujat playbook'is.

Iga ülesande kood on kokkuvolditud plokis. Loe enne selgitus, siis ava plokk, lisa kood faili ja käivita. Rida **Ennusta** tähendab, et enne käsku mõtled läbi, mis juhtub. Vastus on kokkuvolditud plokis.

## Osa 1 · Tavaline playbook

Töötad oma arvutis (juhtsõlm) nagu N3 ja N4 praktikumis, sihtmasin on `proxmox1`. Starteris on fail `inventory.ini` (rühm `web`, sõlm `proxmox1`), playbook `playbook.yml`, mall `templates/index.html.j2` ja tühi kaust `logid/`. Klooni oma Lab 11 repositoorium (link on Classroom 50-s):

```bash
git clone <sinu-repo-URL> ~/lab11 && cd ~/lab11
ansible -i inventory.ini web -m ping
```

??? success "Oodatav tulemus"
    `proxmox1 | SUCCESS` ja `"ping": "pong"`. Kui ühendus ei tööta, kontrolli SSH-d nagu N3-s: `ssh proxmox1 hostname`.

Kõik failiteed selles juhendis on kausta `~/lab11` suhtes. Ava `playbook.yml` ja loe see läbi. Playbook'is on kolm osa: millistele masinatele see rakendub (`hosts`, `become`), muutuja (`vars`) ja kolm ülesannet (`tasks`).

??? example "Starteris on `playbook.yml`"
    ```yaml
    - hosts: web
      become: true
      vars:
        nginx_port: 80
      tasks:
        - name: nginx on paigaldatud
          ansible.builtin.package:
            name: nginx
            state: present

        - name: nginx töötab ja käivitub ka pärast taaskäivitust
          ansible.builtin.service:
            name: nginx
            state: started
            enabled: true

        - name: avaleht on mallist
          ansible.builtin.template:
            src: index.html.j2
            dest: /usr/share/nginx/html/index.html
    ```

??? example "Starteris on `templates/index.html.j2`"
    ```jinja2
    <html>
      <body>
        <h1>Tere, {{ inventory_hostname }}!</h1>
        <p>See leht töötab pordil {{ nginx_port }}.</p>
      </body>
    </html>
    ```

```bash
ansible-playbook -i inventory.ini playbook.yml
ssh proxmox1 "curl -s localhost"
```

??? success "Oodatav tulemus"
    nginx on `proxmox1`-s N3-st juba olemas, nii et kaks esimest ülesannet on `ok`. Ülesanne `avaleht on mallist` on `changed`, sest leht asendub malli sisuga. Leht näitab `Tere, proxmox1!` ja `See leht töötab pordil 80.`

??? warning "Kui tuleb `Permission denied` või `This command has to be run under the root user`"
    Failis `playbook.yml` puudub rida `become: true`.

### Kujunda oma leht

Mall on tavaline HTML-fail, kuhu Ansible paneb muutujate väärtused. Tee sellest oma leht: muuda pealkirja, lisa oma nimi ja paar rida enda kohta ning vali taustavärv. Jäta alles rida `See leht töötab pordil {{ nginx_port }}.`, seda läheb vaja osas 3.

??? example "Näide: `templates/index.html.j2`"
    ```jinja2
    <html>
      <body style="background: #e8f4ff; font-family: sans-serif;">
        <h1>Mari Maasika server {{ inventory_hostname }}</h1>
        <p>Õpin IT-süsteemide nooremspetsialistiks. Mulle meeldivad Linux ja korvpall.</p>
        <p>See leht töötab pordil {{ nginx_port }}.</p>
      </body>
    </html>
    ```

**Ennusta:** sa muutsid ainult malli. Milline kolmest ülesandest on järgmisel käivitusel `changed`?

```bash
ansible-playbook -i inventory.ini playbook.yml
ssh proxmox1 "curl -s localhost"
```

??? success "Oodatav tulemus"
    Ainult `avaleht on mallist` on `changed` ja curl näitab sinu lehte. Pakett ja teenus jäid samaks, nii et need ülesanded on `ok`. Ansible muudab ainult seda, mis erineb kirjeldatud olekust.

Käivita sama käsk veel kord.

??? success "Oodatav tulemus"
    Kõik ülesanded on `ok` ja kokkuvõttes on `changed=0`. Serveri olek on juba sama, mis playbook'is kirjas.

## Osa 2 · Sama töö rolliks

Kolme ülesandega playbook on veel loetav. Kui ülesandeid on kolmkümmend ja sama nginx'i paigaldust on vaja ka teises projektis, läheb üks fail segaseks ja seda on raske uuesti kasutada. Roll jagab sama sisu kindlatesse kaustadesse. Ansible teab, kust igast kaustast mida otsida, nii et faile ei pea playbook'is eraldi nimetama.

??? note "Tabel 11.1. Kuhu iga playbook'i osa rollis läheb"
    | Osa `playbook.yml`-is | Koht rollis |
    |---|---|
    | `tasks:` all olevad ülesanded | `roles/nginx/tasks/main.yml` |
    | `vars:` all olev muutuja | `roles/nginx/defaults/main.yml` |
    | mall `templates/index.html.j2` | `roles/nginx/templates/index.html.j2` |
    | `hosts:` ja `become:` | jäävad playbook'i, uus fail `site.yml` |

Rolli kaustad loob käsk `ansible-galaxy init`:

```bash
ansible-galaxy init --init-path roles nginx
find roles/nginx -maxdepth 1
```

??? success "Oodatav tulemus"
    Kaustas `roles/nginx/` on alamkaustad `tasks`, `defaults`, `handlers`, `templates`, `files`, `vars`, `meta` ja `tests` ning fail `README.md`. Täna kasutad kaustu `tasks`, `defaults`, `templates` ja `handlers`, ülejäänud võivad tühjaks jääda.

??? warning "Kui `ansible-galaxy init` annab vea „already exists“"
    Kaust on juba olemas. Vaata, mis seal on (`find roles/nginx`). Kui seal on sinu varasem töö, jätka sellega. Ära kustuta kausta ega kasuta võtit `--force`, siis kaob sinu töö.

### 2.1 Ülesanded

Rolli ülesanded on failis `roles/nginx/tasks/main.yml`. Süntaks on sama mis playbook'i plokis `tasks:`, aga ilma `hosts:` ja `tasks:` reata ning taandeta, sest masinad valib playbook.

??? example "Ülesanne: kirjuta `roles/nginx/tasks/main.yml`"
    Kopeeri `playbook.yml`-ist kolm ülesannet. Asenda faili sisu (`---` rida võib jääda):

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

    - name: avaleht on mallist
      ansible.builtin.template:
        src: index.html.j2
        dest: /usr/share/nginx/html/index.html
    ```

### 2.2 Muutuja ja mall

Kaust `defaults/` hoiab rolli vaikeväärtusi. Rolli kasutaja saab neid playbook'is või inventory's muuta, rolli sisu ei pea selleks puutuma.

??? example "Ülesanne: kirjuta `roles/nginx/defaults/main.yml`"
    ```yaml
    nginx_port: 80
    ```

Mall liigub rolli kausta `templates/`. Moodulile `template` piisab faili nimest, sest roll otsib malli ise oma kaustast. Käsk `git mv` tõstab faili ja Git näeb, et see on sama fail uues kohas.

```bash
git mv templates/index.html.j2 roles/nginx/templates/index.html.j2
```

??? question "Küsimus"
    `defaults/main.yml` ja `vars/main.yml` hoiavad mõlemad muutujaid. Vaata tabelit [Variable precedence](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable). Kumba paned väärtuse, mida rolli kasutaja peaks saama muuta?

    ??? success "Vastus"
        `defaults/main.yml`. Rolli vaikeväärtused on tabelis kõige nõrgemad ja iga teine koht (inventory, playbook, käsurida) kirjutab need üle. `vars/main.yml` on tabelis kõrgemal, sinna pannakse rolli sisemised väärtused.

### 2.3 Playbook, mis käivitab rolli

Roll ei tee midagi, kuni playbook selle käivitab. Uus playbook `site.yml` ütleb ainult, millisele rühmale roll rakendub ja et vaja on root-õigusi. Vana `playbook.yml` pole enam vaja.

??? example "Ülesanne: loo `site.yml` ja kustuta `playbook.yml`"
    ```yaml
    - hosts: web
      become: true
      roles:
        - nginx
    ```

    ```bash
    git rm playbook.yml
    ```

**Ennusta:** sa ei muutnud ühtegi ülesannet, ainult tõstsid need teise kohta. Kas ülesanded on `changed` või `ok`?

```bash
ansible-playbook -i inventory.ini site.yml
ssh proxmox1 "curl -s localhost"
```

??? success "Oodatav tulemus"
    Kõik kolm ülesannet on `ok` ja kokkuvõttes on `changed=0`. Leht on sama mis enne, sinu kujundatud leht. Väljundis on ülesande nime ees rolli nimi: `TASK [nginx : avaleht on mallist]`. Sama töö on nüüd rollis ja tulemus serveris ei muutunud.

??? warning "Kui tuleb viga `the role 'nginx' was not found`"
    `ansible-playbook` otsib rolle kaustast `roles/` faili `site.yml` kõrval. Kontrolli, et oled kaustas `~/lab11` ja et roll on kaustas `roles/nginx`, mitte `nginx`.

??? warning "Kui tuleb viga `Could not find or access 'index.html.j2'`"
    Mall ei ole rolli kaustas. Kontrolli käsuga `find roles/nginx/templates`, et fail on `roles/nginx/templates/index.html.j2`.

??? warning "Kui ülesanne `avaleht on mallist` on `changed`"
    Rolli mall erineb sellest, mis serveris on. Kõige sagedamini kopeeriti mall enne kujundamist. Vaata `cat roles/nginx/templates/index.html.j2`.

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

## Töö esitamine

Repositooriumis on `site.yml`, roll `roles/nginx/` ja logid kaustas `logid/`.

```bash
git add site.yml roles logid
git commit -m "nginx'i roll malli ja handler'iga"
git push
```

Tulemuse näed Classroom 50-s.

## Lisaülesanded

??? example "1 · Galaxy roll"
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

??? example "2 · Teine roll"
    Loo roll `tulemyyr`, mis avab pordi `nginx_port` mooduliga [`ansible.posix.firewalld`](https://docs.ansible.com/ansible/latest/collections/ansible/posix/firewalld_module.html) (`port: "{{ nginx_port }}/tcp"`, `permanent: true`, `immediate: true`). Lisa roll faili `site.yml` enne rolli `nginx` ja vaata väljundist käivitamise järjekorda. Kui sõlmes firewalld ei tööta, lisa rollile esimeseks ülesandeks selle käivitamine.

??? example "3 · Sõltuvus"
    Lisa faili `roles/nginx/meta/main.yml` plokk `dependencies:`, mis nõuab, et `tulemyyr` käivituks enne. Kas pead `tulemyyr`-i siis veel failis `site.yml` nimetama?
