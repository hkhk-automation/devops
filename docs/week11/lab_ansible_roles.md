---
tags:
  - Ansible
  - Rollid
  - Praktikum
---

# Praktikum: Ansible rollid

Loengus nägid rolli struktuuri, käsku `ansible-galaxy init` ja plokki `roles:`. Selles praktikumis kirjutad nginx'i rolli osade kaupa: skelett, ülesanded, vaikeväärtused, mall, siis üks tahtlik viga ja lõpuks Galaxy roll. Iga sammu järel käivitad playbook'i ja kontrollid tulemust. Kui rollide põhimõtted on veel segased, loe uuesti [loengut](lecture_ansible_roles.md).

Juhtmasin on sinu arvuti ja töötad VS Code'is. Sihtmasina vali [töökeskkonna](../kodulabor.md) juhendi järgi: kodus kohalik masin, koolis Proxmox. Fail `inventory.ini` on nädalast 3.

??? abstract "Õpiväljundid"

    Selle praktikumi lõpuks oskad:

    1. luua rolli skeleti käsuga `ansible-galaxy init` ja tead iga kausta otstarvet;
    2. kirjutada töötava nginx'i rolli osade kaupa (ülesanded, vaikeväärtused, mall);
    3. käivitada rolli failist `site.yml` ja muutuja üle kirjutada;
    4. leida põhjuse, miks muutuja `nginx_port` ei muuda tegelikku porti;
    5. paigaldada ja kasutada Galaxy kogukonna rolli.

## Osa 1 · Skelett: `ansible-galaxy init`

Roll on kokkulepitud kaustastruktuur, mis paneb ülesanded, muutujad, mallid ja handlerid ette antud kohtadesse. Ansible teab neid kohti ise, seega ei pea `include_vars` käsitsi kirjutama.

Ava töökaust VS Code'is (`code .`) ja terminal klahvidega `` Ctrl+` ``. Loo esimene roll:

```bash
mkdir -p ~/ansible-lab/roles
cd ~/ansible-lab/roles
ansible-galaxy init nginx
find nginx -type f
```

Väljundis on standardstruktuur (`tasks/`, `defaults/`, `handlers/`, `templates/`, `files/`, `vars/`, `meta/`).

??? warning "Kui `ansible-galaxy init` annab vea „existing directory“"
    Kaust on juba olemas ja `init` ei kirjuta olemasolevat üle. Kustuta kaust (`rm -rf nginx`) või vali rollile teine nimi.

??? question "Mõtle"
    `defaults/main.yml` ja `vars/main.yml` hoiavad mõlemad muutujaid. Loe tabelit [Variable precedence](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable). Kumb võidab, kui sama muutuja on mõlemas? Miks on rollide vaikekäitumine just selline?

Enamikku kaustadest (`files`, `tests`, `vars`, `meta`) täna ei kasutata. Ansible eeldab struktuuri ka siis, kui kõiki kaustu ei kasutata.

## Osa 2 · nginx'i roll

Täidad skeleti osade kaupa ja käivitad iga sammu järel playbook'i.

### 2.1 Ülesanded: ainult paigaldus

Ava `nginx/tasks/main.yml` ja kirjuta sinna ainult paigaldus:

```yaml
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes
```

Rolli testimiseks on vaja lihtsat playbook'i (osas 4 vaatad käivitamist põhjalikumalt). Loo `~/ansible-lab/site.yml`:

```yaml
- hosts: all
  become: true
  roles:
    - nginx
```

```bash
cd ~/ansible-lab
ansible-playbook -i inventory.ini site.yml
```

??? warning "Kui tuleb viga `roles/nginx: not found`"
    `ansible-playbook` otsib kausta `roles/` käivitamise kohast. Kontrolli, et oled kaustas `~/ansible-lab`, mitte `roles/nginx` sees.

??? warning "Kui ülesanne annab `ok`, aga midagi ei muutu, või tuleb `Permission denied`"
    Playbook'is puudub `become: true`. Ilma selleta ei saa Ansible pakette paigaldada ega kausta `/var/www/html/` kirjutada.

Kontrolli sihtmasinas, et pakett on paigaldatud, aga teenus ei tööta veel:

```bash
ssh <kasutaja>@<IP> "systemctl status nginx"
```

Lisa faili `tasks/main.yml` teenuse käivitamine:

```yaml
- name: Start and enable nginx
  service:
    name: nginx
    state: started
    enabled: true
```

Käivita playbook uuesti ja kontrolli:

```bash
curl http://<IP>
```

Vastuseks on nginx'i vaikeleht „Welcome to nginx!“.

??? question "Mõtle"
    Käivitasid playbook'i kaks korda ilma muudatusteta. Kas tulemus oli `changed` või `ok`? Mida see ütleb idempotentsuse kohta (nädalad 3–4)?

### 2.2 Vaikeväärtused: muutuv port

Ava `nginx/defaults/main.yml`:

```yaml
nginx_port: 80
```

Vaikeväärtused kirjutab üle iga teine muutuja, need on mõeldud ülekirjutamiseks. Muutujast on kasu alles siis, kui seda kuskil kasutatakse. Järgmises sammus kasutab seda mall.

### 2.3 Mall: Jinja2 kasutab muutujat

Loo `nginx/templates/index.html.j2`:

```jinja2
<html>
  <body>
    <h1>Tere, {{ inventory_hostname }}!</h1>
    <p>See leht töötab pordil {{ nginx_port }}.</p>
  </body>
</html>
```

Lisa faili `tasks/main.yml` lõppu:

```yaml
- name: Deploy index.html from template
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
```

Käivita playbook ja kontrolli käsuga `curl http://<IP>`. Leht on nüüd dünaamiline ja sisaldab hostinime.

??? warning "Kui leht ei muutu"
    Brauser näitab sageli vahemälus olevat vana lehte. Kontrolli käsuga `curl`, mitte brauseriga. Vaata ka, kas ülesanne `template` käivitus (`ansible-playbook -v`).

## Osa 3 · Viga: muutuja, mis ei muuda midagi

Malli järgi töötab leht pordil `{{ nginx_port }}`. Muuda failis `defaults/main.yml` väärtuseks `nginx_port: 8080`, käivita playbook ja proovi:

```bash
curl http://<IP>:8080
```

Server ei vasta. Leht ütleb „8080“, aga nginx kuulab endiselt porti 80.

??? question "Leia põhjus"
    `nginx_port` on praegu ainult HTML-i sees olev tekst. Ükski ülesanne ei muuda nginx'i konfiguratsiooni (mitte HTML-i). Milline fail peaks olema malliks tehtud, et port muutuks? (Vihje: `/etc/nginx/sites-available/default`, rida `listen {{ nginx_port }};`.)

See viga on tahtlik: muutuja olemasolu ei tähenda, et see midagi mõjutab. Pordi muutmine nginx'i konfiguratsioonis on lisaülesanne 1. Taasta väärtus `nginx_port: 80`.

## Osa 4 · Rolli käivitamine

Osas 2 kasutasid lihtsat faili `site.yml`. Rolli saab käivitada kahel kujul. Lihtne kuju:

```yaml
roles:
  - nginx
```

Kui muutuja on vaja üle kirjutada, saab seda teha playbook'i tasandil ja rolli sisu ei pea muutma:

```yaml
roles:
  - role: nginx
    vars:
      nginx_port: 8080
```

Mõlemad kujud käivitavad sama rolli: `- nginx` on lihtne loend, `- role: nginx` koos plokiga `vars:` lubab anda parameetreid. Käivita playbook ja veendu, et see lõpeb vigadeta.

??? question "Mõtle"
    Miks on parem hoida `nginx_port` playbook'i plokis `vars:` kui muuta iga kord rolli `defaults/`? Mõtle viiele serverile, millest igaühel on oma port.

## Osa 5 · Galaxy roll

Kõike ei pea ise kirjutama. [Ansible Galaxy](https://galaxy.ansible.com/) on avalik rollide hoidla. Paigalda sealt tuntud roll:

```bash
ansible-galaxy install geerlingguy.git
ansible-galaxy list
```

??? warning "Kui tuleb `command not found` või roll ei lae"
    `ansible-galaxy` paigaldub koos Ansible'iga, kontrolli käsuga `ansible --version`. Kui käsk töötab, aga roll ei lae, kontrolli võrguühendust Galaxy serveriga.

Roll paigaldub kausta `~/.ansible/roles/`. See on jagatud sõltuvus, mitte sinu projekti osa. Lisa roll faili `site.yml` teiseks:

```yaml
roles:
  - nginx
  - geerlingguy.git
```

```bash
ansible-playbook -i inventory.ini site.yml
ssh <kasutaja>@<IP> "git --version"
```

??? question "Mõtle"
    Vaata käsuga `find ~/.ansible/roles/geerlingguy.git -type f`. Kas struktuur on sama mis sinu rollil? Mida kontrolliksid enne, kui võõra rolli oma serveris käivitad?

??? note "Kontrollnimekiri"

    - `ansible-galaxy init nginx` lõi täieliku struktuuri.
    - `curl http://<IP>` näitab sinu HTML-i, mitte vaikelehte.
    - Leht sisaldab tegelikku hostinime (`{{ inventory_hostname }}`).
    - Teine käivitus on idempotentne ega anna vigu.
    - Oskad selgitada, miks `nginx_port` üksi ei muutnud tegelikku porti.
    - `geerlingguy.git` on paigaldatud ja `git --version` töötab sihtmasinas.
    - `site.yml` käivitab plokis `roles:` kaks rolli.

## Lisaülesanded

??? example "1 · Port nginx'i konfiguratsioonis"
    Loo `templates/nginx.conf.j2` faili `/etc/nginx/sites-available/default` põhjal, kirjuta sinna `listen {{ nginx_port }};` ja lisa ülesanne `template` koos reaga `notify: restart nginx`.

??? example "2 · Handlerid"
    Loo failis `handlers/main.yml` handler `restart nginx` (`service: state: restarted`). Käivita see `notify:` abil ja veendu, et handler käivitub ainult siis, kui fail muutus. Handlerite kirjeldus on lehel [Handlers](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_handlers.html).

??? example "3 · Teine roll"
    Loo roll `firewall` (`ufw allow {{ nginx_port }}`), lisa see faili `site.yml` kolmandaks ja jälgi käivitamise järjekorda.

??? example "4 · Sõltuvus"
    Lisa faili `nginx/meta/main.yml` plokk `dependencies:`, mis nõuab, et `firewall` käivituks enne. Kas pead `firewall`-i siis veel eraldi plokis `roles:` nimetama?

??? warning "Kui handler ei käivitu"
    `notify:` väärtus peab olema täpselt sama mis handleri `name:`, iga täht ja tühik.
