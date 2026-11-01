---
tags:
  - Ansible
  - Playbook
  - Praktikum
---

# Praktikum: esimene Ansible'i playbook

Täna kirjutad task'i kaupa playbooki, mis paigaldab sõlme `proxmox1` nginx'i, käivitab selle ja kopeerib sinna sinu veebilehe. Ansible töötab sinu arvutis (kontroll-node) ja ühendub sõlmega 1. nädalal seadistatud SSH-võtmega `kursus_ed25519`. Mõisted inventory, playbook ja idempotentsus on [loengus](lecture.md), ametlik sissejuhatus on [Getting started with Ansible](https://docs.ansible.com/ansible/latest/getting_started/index.html).

**Edenemine:** laboritahvel <http://192.168.125.187:8091/> (VPN-iga).

??? abstract "Õpiväljundid"
    Praktikumi lõpuks oskad:

    1. ehitada playbooki task'i kaupa ja testida seda igal sammul;
    2. leida veateate järgi kolme tüüpilise vea põhjuse (permission denied, katkine idempotentsus, sisu ja olemasolu erinevus);
    3. selgitada idempotentsust näite põhjal: millal on tulemus `changed` ja millal `ok` ning miks `shell:` idempotentsuse lõhub;
    4. paigaldada playbookiga nginx'i nii, et monitooringu skript `monitor.sh` näitab teenust töötavana.

2. nädala monitooringu skript `monitor.sh` teatas „nginx EI tööta“, sest nginx'i polnud sõlme paigaldatud. Käsitsi paigaldades on lihtne jätta teenus lubamata (`enable`) ja tehtud sammud kirja panemata. Playbook teeb sama töö korratavalt ja on ise sammude kirjeldus. Mõnes kohas lõhud playbooki meelega, et näha, milline viga sellest tekib.

<figure markdown="span">
```mermaid
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#ede7f6','primaryBorderColor':'#5e35b1','primaryTextColor':'#212121','lineColor':'#7e57c2'}}}%%
graph LR
    subgraph SA["Sinu arvuti = kontroll-node"]
        INV["inventory.ini<br/>(web: proxmox1)"]
        PB["nginx.yml<br/>(playbook)"]
        ANS(["ansible-playbook"])
        INV --> ANS
        PB --> ANS
    end
    ANS -->|"SSH (kursus_ed25519)"| N1["proxmox1<br/>nginx paigaldatud + käib"]
    ANS -. "lisaülesanne" .-> N2[proxmox2]
    ANS -. "lisaülesanne" .-> N3[proxmox3]
```
  <figcaption>Joonis 3.1. Sinu arvuti loeb inventory ja playbooki ning saadab muudatuse SSH kaudu (1. nädala võtmega) sõlme. Sõlme Ansible'it ei paigaldata, seal on vaja ainult SSH-d ja Pythonit (Talvik, 2025).</figcaption>
</figure>

## Osa 1 · Seadistus: kontrolli ühendust

!!! warning "Ansible ei tööta Windowsi käsurealt"
    Ansible vajab *NIX-käsurida: Mac, Linux või WSL2. Windowsi cmd ega PowerShell ei sobi kontroll-node'iks. Võimalused on järgmised:

    - Kui sul on WSL2, Mac või Linux, käivita Ansible oma arvutist sõlme vastu. Nii tehakse seda ka töökeskkonnas.
    - Kui *NIX-käsurida pole käepärast, käivita Ansible sõlmes endas sõlme enda vastu (`localhost`). See pole tavapärane kasutus, kuid õppimiseks sobib.
    - Kahtluse korral küsi õpetajalt, kumb võimalus sinu arvutis sobib.

Ansible paigaldati sinu arvutisse 1. nädala praktikumis. Ava projektikaust VS Code'is (`code .`) ja terminal klahvidega `` Ctrl+` ``. Failis `inventory.ini` peab olema sõlm `proxmox1` grupis `web`:

```ini
[web]
proxmox1
```

Testi ühendust mooduliga [`ping`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ping_module.html). Moodul kontrollib SSH-ühendust ja Pythoni olemasolu, ICMP-d see ei kasuta:

```bash
ansible -i inventory.ini web -m ping
```

??? success "Oodatav tulemus"
    Väljundis on `SUCCESS` ja `"pong"`. Ilma selleta järgmised osad ei tööta.

??? info "Millise kasutajana Ansible sõlme logib?"
    Ansible logib sisse sama kasutajana, kellega töötab `ssh proxmox1`, sest `User` ja võti tulevad konfiguratsioonifailist `~/.ssh/config`. Kooli sõlmedes on see `kasutaja`. Kontrolli seda:

    ```bash
    ansible -i inventory.ini web -m command -a "whoami"
    ```

    Väljund peab olema `kasutaja`, sama kasutaja, kellega ise SSH-ga ühendud. See näitab, et Ansible kasutab täpselt sama SSH-ühendust nagu sina.

    Tootmiskeskkonnas on Ansible'il sageli oma teenuskonto (näiteks `ansible`) ja inimese isiklikku kontot ei kasutata. Nii on ligipääs auditeeritav ja piiratud. Meie kursusel piisab ühest kontost `kasutaja` ja root-õigused saadakse `become` abil (osa 3).

??? warning "Kui tuleb `UNREACHABLE`"
    Kontrolli, kas `ssh proxmox1` töötab käsitsi. Ansible kasutab sama SSH-ühendust nagu sina: kui SSH käsitsi ei ühendu, ei ühendu ka Ansible.

## Osa 2 · Baas: esimene task

Playbook algab ühest task'ist, mis paigaldab nginx'i paketi. Loo fail `nginx.yml`, edaspidi lisad sellele task'e:

```yaml
---
- name: Paigalda ja seadista nginx
  hosts: web
  become: true                        # root-õigused (sudo)

  tasks:
    - name: Paigalda nginx pakett
      ansible.builtin.package:         # valib ise dnf (Alma) või apt (Ubuntu)
        name: nginx
        state: present                 # "peab olemas olema"
```

Selles failis:

- `hosts: web` on grupp failist `inventory.ini`;
- `become: true` on vajalik, sest paketi paigaldamiseks on vaja root-õigusi;
- [`ansible.builtin.package`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/package_module.html) on universaalne paketimoodul. Koolisõlmes on Alma (`dnf`), kuid sama task töötab ka Ubuntus (`apt`), seega pole eri distributsioonide jaoks vaja eraldi task'e kirjutada.

**Ennusta:** kas esimene käivitus annab `ok` või `changed`?

```bash
ansible-playbook -i inventory.ini nginx.yml
```

??? success "Oodatav tulemus"
    `changed=1`, sest nginx'i polnud sõlmes ja Ansible paigaldas selle.

Kontrolli sõlmes, et nginx on olemas:

```bash
ssh proxmox1 "nginx -v"
```

??? warning "Kui käivitus annab vea"
    - YAML-i süntaksiviga tuleb tavaliselt valest taandest või tabulaatorist. VS Code näitab taanet, täpse rea leiab käsk `ansible-playbook -i inventory.ini nginx.yml --syntax-check`.
    - `No package nginx available` tähendab, et Alma repositoorium puudub. Kontrolli käsuga `ssh proxmox1 "sudo dnf repolist"`, kas `appstream` on loendis.

## Osa 3 · Become puudu: permission denied

Kui `become` puudub, töötab Ansible sõlmes tavakasutajana. Muuda rida `become: true` kommentaariks (`# become: true`) ja käivita playbook:

```bash
ansible-playbook -i inventory.ini nginx.yml
```

??? success "Oodatav tulemus"
    Task ebaõnnestub teatega, mis sarnaneb `Permission denied` või `This command has to be run under the root user`.

??? question "Leia põhjus enne parandamist"
    SSH-kasutaja ei ole root, kuid paketi paigaldamiseks on vaja root-õigusi. Milline rida ütles Ansible'ile, et käsk tuleb käivitada sudo abil, ja mis juhtus, kui selle eemaldasid? Miks Ansible ei kasuta sudo't vaikimisi?

Pane rida `become: true` tagasi ja käivita playbook uuesti. Edaspidi kontrolli `Permission denied` puhul kõigepealt, kas task vajab root-õigusi ja kas `become` on sisse lülitatud.

## Osa 4 · Laienda: teenus ja idempotentsus

Nginx on paigaldatud, kuid kas teenus töötab ja käivitub ka pärast taaskäivitust? Lisa teine task (`tasks:` alla). Moodul [`service`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_module.html) haldab teenuse olekut:

```yaml
    - name: Käivita ja luba nginx
      ansible.builtin.service:
        name: nginx
        state: started         # käivita nüüd
        enabled: true          # käivitu ka pärast reboot'i
```

**Ennusta:** milline task on nüüd `ok` ja milline `changed`?

```bash
ansible-playbook -i inventory.ini nginx.yml
```

??? success "Oodatav tulemus"
    Paigaldus on `ok`, sest nginx on juba olemas. Teenuse task on `changed`, sest teenus käivitati esimest korda.

??? question "Mõtle"
    Käivita playbook veel kord. Nüüd on mõlemad task'id `ok`. Kust Ansible teadis, et midagi pole vaja teha?

`enabled: true` on seadistus, mis käsitsi paigaldades kergesti ununeb. Nüüd on see failis kirjas.

## Osa 5 · Katkine idempotentsus: shell on alati changed

Ülesanne on kirjutada nginx'i versioon faili. Kõigepealt tee see moodulit `shell:` kasutades, et näha, mis juhtub idempotentsusega:

```yaml
    - name: Kirjuta nginx versioon faili
      ansible.builtin.shell: nginx -v 2> /tmp/nginx_version.txt
```

**Ennusta:** mida näitab see task kolmandal käivitusel?

```bash
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
```

??? success "Oodatav tulemus"
    Task on igal käivitusel `changed`. Kolm käivitust annavad kolm korda `changed`.

??? question "Leia põhjus"
    `package` ja `service` kontrollivad olekut enne tegutsemist. `shell:` ei kontrolli midagi: moodul käivitab käsu ja raporteerib vaikimisi `changed`, sest Ansible ei tea, mida käsk tegi. Miks on pidev `changed` halb, kui sul on 50 sõlme ja playbook käib cron'is?

Kui käsku on vaja käivitada ainult üks kord, lisa `creates`. Siis jätab Ansible task'i vahele, kui fail on juba olemas:

```yaml
    - name: Kirjuta nginx versioon faili
      ansible.builtin.shell: nginx -v 2> /tmp/nginx_version.txt
      args:
        creates: /tmp/nginx_version.txt
```

Käivita playbook kaks korda.

??? success "Oodatav tulemus"
    Teisel korral on task `ok` ja idempotentsus on taastatud.

Enne kui kirjutad `shell:`, kontrolli, kas mõni moodul teeb sama asja. Mooduli [`shell`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html) dokumentatsioonis on kirjas, millal kasutada hoopis moodulit `command`. Kõige sagedamini läheb idempotentsus katki just `shell:` task'ides.

## Osa 6 · Oma leht

Nginx näitab vaikimisi oma lehte. Sinu leht jõuab sõlme mooduliga `copy`. Loo fail `index.html`:

```html
<h1>Ansible töötab: [sinu nimi]</h1>
```

Lisa task (Alma nginx serveerib faile kaustast `/usr/share/nginx/html/`):

```yaml
    - name: Kopeeri index.html
      ansible.builtin.copy:
        src: index.html
        dest: /usr/share/nginx/html/index.html
        mode: '0644'
```

`src` on fail sinu arvutis, `dest` on sihtkoht sõlmes. Käivita playbook ja vaata lehte sõlme seest:

```bash
ansible-playbook -i inventory.ini nginx.yml
ssh proxmox1 "curl -s localhost"
```

??? success "Oodatav tulemus"
    Väljundis on sinu leht. `curl localhost` sõlme seest ei läbi tulemüüri. Väljast brauseriga avaneb leht ainult siis, kui port 80 on firewalld'is avatud (vaata lisaülesannet 4).

??? warning "Kui `curl` annab `Connection refused`"
    Teenus ei tööta. Kontrolli osa 4 task'i ja teenuse olekut käsuga `ssh proxmox1 systemctl status nginx`.

## Osa 7 · Lõpp-test ja monitooringu skript

Viimane idempotentsuse test: käivita playbook ilma midagi muutmata.

```bash
ansible-playbook -i inventory.ini nginx.yml
```

??? success "Oodatav tulemus"
    `PLAY RECAP` näitab: kõik `ok`, `changed=0`.

Käivita sõlmes 2. nädala monitooringu skript, mis siis teatas „EI tööta“. Kui sõlmes skripti `monitor.sh` ei ole, kontrolli teenust käsuga `ssh proxmox1 systemctl is-active nginx`.

```bash
ssh proxmox1 "bash ~/monitor.sh && cat ~/monitor.log"
```

??? success "Oodatav tulemus"
    ```
    ... - nginx töötab
    ```

Nginx'i paigaldus on nüüd playbookis kirjas: seda saab korrata ja see on Gitis.

??? question "Mõtle"
    Sul on 50 sõlme ja see playbook käib cron'is iga tund. Mida ütleks monitooringule `changed=0` ja mida `changed=5`? Kumb tulemus viitaks sellele, et keegi on sõlme käsitsi muutnud?

??? note "Kontrollnimekiri"
    - [ ] `ansible -m ping` annab sinu sõlmest vastuseks `pong`
    - [ ] `Permission denied` korral kontrollid kõigepealt `become` seadistust
    - [ ] Oskad selgitada, miks `shell:` on vaikimisi alati `changed`, kuid `package` ja `copy` ei ole
    - [ ] Tead, millal `creates` taastab idempotentsuse
    - [ ] Lõpp-test: kõik `ok`, `changed=0`
    - [ ] `curl localhost` näitab sinu lehte
    - [ ] `monitor.sh` või `systemctl is-active nginx` ütleb, et nginx töötab

## Töö esitamine

Esita repositooriumis playbook, leht, inventar ja viimase muutmata käivituse logi, milles on `changed=0`. Repositooriumi loob Classroom 50 kutselink. Töö läheb harusse `n03-nginx` ja sealt pull request'iga `main`-i, PR-i link läheb GitHub Projecti.

```bash
ansible-playbook -i inventory.ini nginx.yml | tee logid/play_recap.txt
git switch -c n03-nginx
git add nginx.yml index.html inventory.ini logid/play_recap.txt
git commit -m "N3: nginx playbook"
git push -u origin n03-nginx
```

Tulemuse näed Classroom 50-s.

## Lisaülesanded

??? example "1 · Kolm sõlme korraga"
    Lisa faili `inventory.ini` gruppi `[web]` sõlmed `proxmox2` ja `proxmox3` ning käivita sama playbook kõigis. Üks fail haldab kolme sõlme.

??? example "2 · `--check`"
    Käivita `ansible-playbook -i inventory.ini nginx.yml --check`. Mida see režiim teeb, kui tegelikke muudatusi ei tehta? Millal on see enne tootmiskeskkonda kasulik?

??? example "3 · `--syntax-check`"
    Kustuta meelega üks koolon ja käivita `--syntax-check`. Kuidas Ansible vea esitab?

??? example "4 · Tulemüür"
    Ava Almas port 80 (`ansible.posix.firewalld` või `firewall-cmd`), et leht avaneks ka väljast brauseriga. Miks on port vaikimisi suletud?
