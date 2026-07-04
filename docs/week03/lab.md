---
tags:
  - Ansible
  - Playbook
  - Praktikum
---

# Esimene Ansible playbook — käed külge — Labor

**Kestus:** 4 tundi
**Eeldused:** Loeng antud (inventory, push-mudel, idempotentsus, moodulid). Git põhialused. Kui udu — [tagasi loengusse](lecture.md). Siit edasi **ainult käed külge**.
**Kontroll-node:** sinu arvuti, kogu töö **VS Code'is** (failid redaktoris, käsud integreeritud terminalis).
**Sihtmärk:** üks Ubuntu-server sinu valik — [Kodulabor](../kodulabor.md), WSL2, oma VM, pilv (kodus); Proxmox (koolis). Playbook on kõigil identne, vahet teeb üks rida `inventory.ini`-s.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Seadistad Ansible kontroll-node'i ja inventory oma sihtmärgile
    2. Ehitad playbooki kiht-kihi haaval, testides igal sammul
    3. **Diagnoosid** kolm tüüpilist viga veateate järgi (permission denied, katkine idempotentsus, vale moodul)
    4. Selgitad idempotentsust näite peal — miks `changed` vs `ok`, ja miks `shell:` selle lõhub
    5. Taastad korratava seisu ise tehtud sasi järel

---

Labi loogika: **setup → baas → viga → paranda → laienda → viga → taasta.** Sa ei kopeeri valmis playbookit. Sa ehitad selle task-haaval, lõhud võtmekohtades meelega, ja saad aru **miks**. Tervet faili näed üks kord — edasi ainult "lisa see task".

---

## Osa 1 · Setup — Ansible, inventory, ühendus (30 min)

Paigalda Ansible oma arvutisse:

```bash
# Linux/WSL
sudo apt update && sudo apt install -y ansible
# macOS
brew install ansible
```

```bash
ansible --version
```

Ava projektikaust VS Code'is (`code .`), terminal `` Ctrl+` ``. Loo `inventory.ini` — sisu **sõltub su sihtmärgist**:

```ini
[web]
<sihtmärgi-IP> ansible_user=<kasutaja>
```

| Sihtmärk | Rida `inventory.ini`-s |
|---|---|
| Kodulabor (Vagrant) | `192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key` |
| WSL2 / lokaalne VM | `127.0.0.1 ansible_user=sinu_kasutaja` (või VM-i IP) |
| Proxmox (koolis) | `192.168.x.x ansible_user=õpetajalt` |
| Pilve-server | `avalik-IP ansible_user=ubuntu` |

*Tabel 3.1. Sama rida, erinevad sihtmärgid.*

Testi ühendust (`ping` moodul — mitte ICMP, vaid SSH + Python kontroll):

```bash
ansible all -i inventory.ini -m ping
```

`SUCCESS` + `"pong"` — valmis. **Ära edasi mine enne kui pong tuleb.**

!!! tip
    `UNREACHABLE` — kas server käib ja `ssh <kasutaja>@<IP>` töötab käsitsi? Ansible ei tee midagi maagilist: kui SSH käsitsi ei ühendu, ei ühendu ka Ansible.

---

## Osa 2 · Baas — esimene task (30 min)

Loo `nginx.yml`. **Ainus kord terve fail** — edasi lisad task'e:

```yaml
---
- name: Paigalda ja seadista nginx   # playbooki nimi, ilmub väljundis
  hosts: web                         # grupp inventory'st
  become: yes                        # root-õigused (sudo)

  tasks:
    - name: Paigalda nginx pakett
      apt:
        name: nginx
        state: present               # "peab olemas olema"
        update_cache: yes            # apt update enne paigaldust
```

Ridade lahtiseletus:

- `hosts: web` — grupp `inventory.ini`-st, playbook jookseb kõigil selle grupi masinatel.
- `become: yes` — nginx paigaldus vajab root-õigusi.
- `state: present` — kui nginx juba olemas, jätab Ansible vahele. Idempotentsuse esimene vihje.

```bash
ansible-playbook -i inventory.ini nginx.yml
```

`changed=1`, task **changed**. Kontrolli:

```bash
ssh <kasutaja>@<IP> "nginx -v"
```

(Kodulaboris kiirem: `vagrant ssh -c "nginx -v"`.)

---

## Osa 3 · Become puudu — permission denied (30 min)

Eemalda **meelega** rida `become: yes` (kommenteeri välja: `# become: yes`). Käivita:

```bash
ansible-playbook -i inventory.ini nginx.yml
```

**Viga:** midagi stiilis `Permission denied` või `Failed to lock apt`.

??? question "Diagnoosi enne kui parandad"
    Sinu `<kasutaja>` ei ole root. `apt install` vajab root-õigusi. Mis rida ütles Ansible'ile "tee seda sudo-ga", ja mis juhtus kui selle ära võtsid? Miks Ansible ei kasuta sudo't vaikimisi?

**Paranda** — pane `become: yes` tagasi, käivita, veendu et läbib.

See on esimene asi, mida kontrollida kui näed `Permission denied`: kas task vajab root-õigusi ja kas `become` on peal.

---

## Osa 4 · Laienda — teenus ja idempotentsus (30 min)

Nginx on paigaldatud, aga kas teenus töötab ja käivitub pärast reboot'i? **Lisa teine task** (fragment, `tasks:` alla):

```yaml
    - name: Käivita ja luba nginx
      service:
        name: nginx
        state: started         # käivita nüüd
        enabled: yes           # käivitu ka pärast reboot'i
```

```bash
ansible-playbook -i inventory.ini nginx.yml
```

**Vaata `PLAY RECAP` hoolikalt.** Esimene task **ok** (nginx juba paigaldatud — Ansible ei tee midagi), teine **changed** (teenus käivitati esmakordselt).

??? question "Mõtle"
    Käivita **veel kord**. Nüüd on mõlemad **ok**. Ansible ei paigaldanud uuesti, ei käivitanud uuesti. Kust ta teadis, et pole midagi teha? See ongi idempotentsus. Osas 5 lõhume selle.

---

## Osa 5 · Katkine idempotentsus — shell alati changed (45 min)

Tahad kontrollida nginx versiooni ja kirjutada selle faili. **Vale viis** — lisa see task `shell:` mooduliga:

```yaml
    - name: Kirjuta nginx versioon faili
      shell: nginx -v 2> /tmp/nginx_version.txt
```

```bash
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
ansible-playbook -i inventory.ini nginx.yml
```

**Vaata:** see task on **changed** iga kord. Alati. Kolm käivitust, kolm `changed`.

??? question "Diagnoosi"
    Moodulid nagu `apt` ja `service` **kontrollivad seisu** enne tegutsemist ("kas juba paigaldatud?"). `shell:` ei kontrolli midagi — ta lihtsalt käivitab käsu ja raporteerib alati `changed`, sest Ansible ei tea mida see käsk tegi. Miks on "alati changed" halb, kui sul on 50 serverit ja cron?

**Paranda** — kaks võimalust:

1. Kui käsk peab jooksma ainult kord, lisa `creates` (Ansible jätab vahele kui fail juba olemas):

```yaml
    - name: Kirjuta nginx versioon faili
      shell: nginx -v 2> /tmp/nginx_version.txt
      args:
        creates: /tmp/nginx_version.txt
```

Käivita kaks korda — teine kord **ok**. Idempotentsus taastatud.

2. Veel parem oleks üldse vältida `shell:`-i ja kasutada mõnda moodulit, kui see olemas. `shell:`/`command:` on viimane abinõu, mitte esimene valik.

!!! tip
    Reegel: enne kui kirjutad `shell:`, küsi kas mõni moodul teeb sama. `shell:` on koht, kus idempotentsus tavaliselt sureb.

---

## Osa 6 · Laienda — oma leht (30 min)

**Loo fail** `index.html`:

```html
<h1>Ansible töötab!</h1>
```

**Lisa task** (fragment):

```yaml
    - name: Kopeeri index.html
      copy:
        src: index.html
        dest: /var/www/html/index.html
        mode: '0644'
```

`src` = sinu masinas, `dest` = serveris.

```bash
ansible-playbook -i inventory.ini nginx.yml
```

Ava brauseris `http://<sihtmärgi-IP>` — "Ansible töötab!".

---

## Osa 7 · Kas `copy` on nutikas? (30 min)

Muuda `index.html` sisu ("Versioon 2") ja käivita:

```bash
ansible-playbook -i inventory.ini nginx.yml
```

`copy` task on **changed** — fail muutus, Ansible uuendas. Käivita **uuesti** ilma muutmata:

```bash
ansible-playbook -i inventory.ini nginx.yml
```

Nüüd **ok** — fail on juba õige.

??? question "Diagnoosi"
    `copy` võrdleb faili **sisu** (checksum), mitte ainult olemasolu. Kui sisu klapib, ei tee midagi. Kui oleksid teinud `shell: cp index.html /var/www/html/`, oleks see olnud **changed** ka siis kui midagi ei muutunud. Mis vahe on `copy` ja `shell: cp` idempotentsuse mõttes?

Siin näed miks moodul > `shell`: moodul teab kuidas seisu kontrollida, `cp` ei tea.

---

## Osa 8 · Taasta ja lõpp-test (15 min)

Lõplik idempotentsuse test — käivita ilma midagi muutmata:

```bash
ansible-playbook -i inventory.ini nginx.yml
```

`PLAY RECAP` — **kõik ok, null changed** (kui `shell` task on `creates`-iga korras). See on tervik: playbookit võib jooksutada lõputult, tulemus sama.

??? question "Mõtle"
    Kui sul oleks 50 serverit ja see playbook cron'is iga tund — mida tähendaks su monitooringule, kui iga käivitus näitaks `changed=0` vs `changed=5`? Kumb ütleks "keegi näppis servereid käsitsi"?

Katsetasid ja keerasid sassi? Kodulaboris `vagrant destroy -f && vagrant up` annab puhta masina 2 minutiga, playbook ehitab kõik uuesti. Korratava seadistuse mõte: taastamine on odav.

---

## Lõppkontroll — oskad ilma juhendita

- [ ] `ansible -m ping` annab `pong` su sihtmärgile
- [ ] `Permission denied` nägemisel kontrollid kohe `become`
- [ ] Selgitad miks `shell:` on alati `changed` ja `apt`/`copy` ei ole
- [ ] Tead millal `creates`/`args` idempotentsust päästab
- [ ] Lõpp-test: kõik `ok`, `changed=0`
- [ ] Brauser näitab sinu lehte

---

## Lisaülesanded (kui jõuad ette)

1. **`--check`:** `ansible-playbook ... --check` — mida teeb ilma reaalsete muudatusteta? Millal kasulik enne tootmist?
2. **`handlers`:** lisa handler, mis taaskäivitab nginx'i ainult siis kui `index.html` muutus (`notify`). Miks parem kui alati restart?
3. **Teine grupp:** lisa inventory'sse teine host, jooksuta mõlemal. `--limit` ühele.

---

## Veaotsing

| Veateade | Põhjus | Lahendus |
|---|---|---|
| `UNREACHABLE` | Server maas või SSH katki | `ssh` käsitsi, kontrolli inventory rida |
| `Permission denied` / `Failed to lock apt` | `become` puudub | `become: yes` |
| Task alati `changed` | `shell:`/`command:` ei kontrolli seisu | Moodul, või `args: creates:` |
| `changed` ka muutmata failil | `shell: cp` sisu ei võrdle | `copy` moodul (checksum) |
| YAML süntaksiviga | Taane katki, tab-id | VS Code näitab taanet, tühikud mitte tabid |

*Tabel 3.2. Iga rida on viga, mille sa selles labis ise tekitasid ja parandasid.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| Ansible Getting Started | <https://docs.ansible.com/ansible/latest/getting_started/index.html> | Alustamine |
| apt / service / copy moodulid | <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/> | Parameetrid |
| shell vs command | <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html> | Millal (mitte) kasutada |
| Idempotency (glossary) | <https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html> | Definitsioon |
