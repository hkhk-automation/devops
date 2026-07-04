---
tags:
  - Ansible
  - Rollid
  - Praktikum
---

# Ansible rollid — käed külge — Labor (Valik 2)

**Kestus:** 4 tundi
**Tase:** Algaste
**Eeldused:** Loeng antud (rolli struktuur, `ansible-galaxy init`, `roles:`). Ansible playbook/inventory/vars (nädalad 3–4), Jinja2. Kui udu — [tagasi loengusse](lecture_ansible_roles.md).
**Kontroll-node:** sinu arvuti, **VS Code**. Sihtmärk sinu valik (vt [Töökeskkond](../kodulabor.md)) — kodus lokaalne, koolis Proxmox. `inventory.ini` on nädalast 3.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Genereerid rolli skeleti `ansible-galaxy init`-iga ja tunned iga kausta otstarvet
    2. Kirjutad töötava nginx-rolli kihthaaval (tasks → defaults → template)
    3. Kutsud rolli välja `site.yml`-ist, kirjutad muutuja üle
    4. **Diagnoosid** miks `nginx_port` muutuja ei muuda tegelikku porti
    5. Paigaldad ja kasutad Galaxy kogukonna rolli

---

Labi loogika: **skelett → tasks → laienda → template → viga (port ei muutu) → Galaxy roll.** Ehitad rolli kihthaaval, testid igal sammul. Fragmendid, mitte terve fail korraga.

---

## Osa 1 · Skelett — `ansible-galaxy init` (30 min)

Roll on kokkulepitud kaustastruktuur, mis paneb tasks, muutujad, mallid ja handlerid **ette antud kohtadesse**. Ansible teab neid kohti ise — sa ei kirjuta `include_vars` käsitsi.

Ava töökaust VS Code'is (`code .`), terminal `` Ctrl+` ``. Genereeri esimene roll:

```bash
mkdir -p ~/ansible-lab/roles
cd ~/ansible-lab/roles
ansible-galaxy init nginx
find nginx -type f
```

Näed standardstruktuuri (`tasks/`, `defaults/`, `handlers/`, `templates/`, `files/`, `vars/`, `meta/`).

!!! tip
    `ansible-galaxy init` "existing directory" — kaust juba on. `rm -rf nginx` või teine nimi; `init` ei kirjuta olemasoleva peale.

??? question "Mõtle"
    `defaults/main.yml` ja `vars/main.yml` mõlemad hoiavad muutujaid. Loe [precedence-dokumentatsiooni](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable). Kumb võidab, kui sama muutuja on mõlemas? Miks valis Ansible rollidele just sellise vaikekäitumise?

Enamikku kaustadest (`files`, `tests`, `vars`, `meta`) sa täna ei puuduta. See on tahtlik — Ansible eeldab struktuuri ka siis kui kõike ei kasuta.

---

## Osa 2 · Kirjuta nginx-roll (60 min)

Täidame skeleti kihiti — iga sammu järel testime.

### 2.1 Tasks — ainult paigaldus

Ava `nginx/tasks/main.yml`, kirjuta **ainult** paigaldus:

```yaml
---
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes
```

Testimiseks vajad minimaalset playbook'i (kirjutame korralikult Osas 3). Loo `~/ansible-lab/site.yml`:

```yaml
---
- hosts: all
  become: true
  roles:
    - nginx
```

```bash
cd ~/ansible-lab
ansible-playbook -i inventory.ini site.yml
```

!!! tip
    `roles/nginx: not found` — `ansible-playbook` otsib `roles/`-i **käivituskohast**. Kontrolli et oled `~/ansible-lab`-is, mitte `roles/nginx` sees.

Kontrolli sihtmärgis et pakett on, teenus veel maas:

```bash
ssh <kasutaja>@<IP> "systemctl status nginx"
```

Lisa `tasks/main.yml`-i käivitus:

```yaml
- name: Start and enable nginx
  service:
    name: nginx
    state: started
    enabled: true
```

Käivita uuesti, kontrolli:

```bash
curl http://<IP>
```

Näed "Welcome to nginx!" vaikimisi lehte.

??? question "Mõtle"
    Käivitasid playbook'i kaks korda ilma muutmata. "changed" või "ok"? Mida see ütleb idempotentsuse kohta (nädal 3–4)?

### 2.2 Defaults — muutuv port

Ava `nginx/defaults/main.yml`:

```yaml
---
nginx_port: 80
```

Defaults on madalaima prioriteediga — mõeldud **ülekirjutamiseks**. Kasutu, kuni keegi seda ei kasuta — anname otstarbe malliga.

### 2.3 Template — Jinja2 kasutab muutujat

Loo `nginx/templates/index.html.j2`:

```jinja2
<html>
  <body>
    <h1>Tere, {{ inventory_hostname }}!</h1>
    <p>See leht töötab pordil {{ nginx_port }}.</p>
  </body>
</html>
```

Lisa `tasks/main.yml`-i lõppu:

```yaml
- name: Deploy index.html from template
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
```

Käivita, kontrolli `curl http://<IP>` — dünaamiline leht hostinimega.

!!! tip
    Leht ei muutu? Brauseri vahemälu petab sagedamini kui Ansible. Kasuta `curl`, mitte brauserit.

---

## Osa 3 · Viga — muutuja, mis ei muuda midagi (30 min)

Malli järgi "töötab pordil {{ nginx_port }}". Muuda `defaults/main.yml`-is `nginx_port: 8080`, käivita, ja proovi:

```bash
curl http://<IP>:8080
```

**Ei vasta.** Leht ütleb "8080", aga nginx kuulab ikka 80.

??? question "Diagnoosi"
    `nginx_port` on praegu ainult HTML-i sees **dekoratiivne tekst**. Kuskil pole task'i, mis nginx'i **konfiguratsiooni** (mitte HTML-i) muudaks. Mis fail peaks olema malliks tehtud, et port päriselt muutuks? (Vihje: `/etc/nginx/sites-available/default`, `listen {{ nginx_port }};`.)

See on tahtlik lõks — muutuja olemasolu ei tähenda et ta midagi mõjutab. Päris pordi muutmine jääb lisaülesandeks. Taasta `nginx_port: 80`.

---

## Osa 4 · Kutsu roll korralikult (25 min)

Osas 2 kasutasid minimaalset `site.yml`-i. Vaatame väljakutsumise korralikult. Lihtne vorm:

```yaml
roles:
  - nginx
```

Muutuja ülekirjutamine playbook'i tasandil (ei pea rolli sisse minema):

```yaml
roles:
  - role: nginx
    vars:
      nginx_port: 8080
```

Pane tähele: `- nginx` (lihtne nimekiri) vs `- role: nginx` + `vars:`. Mõlemad sama roll, teine lubab parameetreid. Käivita, veendu et läbib.

??? question "Mõtle"
    Miks parem hoida `nginx_port` playbook'i `vars:`-is, mitte minna iga kord rolli `defaults/`-i muutma? Mõtle 5 serverit, igaühel oma port.

---

## Osa 5 · Galaxy roll (35 min)

Kõike ise kirjutama ei pea. Paigalda tuntud roll:

```bash
ansible-galaxy install geerlingguy.git
ansible-galaxy list
```

!!! tip
    `command not found` — Galaxy tuleb Ansible'iga kaasa; kontrolli `ansible --version`.

Roll paigaldub globaalsesse `~/.ansible/roles/`-i (jagatud sõltuvus, mitte su projekti osa). Lisa `site.yml`-i teiseks rolliks:

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
    Vaata `find ~/.ansible/roles/geerlingguy.git -type f`. Kas struktuur on sama mis su enda rollil? Mida sa kontrolliksid, enne kui võõra rolli oma serveril käivitad?

---

## Lõppkontroll — oskad ilma juhendita

- [ ] `ansible-galaxy init nginx` genereeris täieliku struktuuri
- [ ] `curl http://<IP>` näitab **sinu** HTML-i, mitte vaikimisi lehte
- [ ] Leht sisaldab tegelikku hostinime (`{{ inventory_hostname }}`)
- [ ] Teine käivitus idempotentne (ei tekita vigu)
- [ ] Selgitad miks `nginx_port` üksi ei muutnud tegelikku porti
- [ ] `geerlingguy.git` paigaldatud, `git --version` töötab sihtmärgis
- [ ] `site.yml` kutsub kahte rolli `roles:` plokis

---

## Lisaülesanded (kui jõuad ette)

1. **Päris port.** Loo `templates/nginx.conf.j2` (baseeru `/etc/nginx/sites-available/default`), `listen {{ nginx_port }};`, lisa `template` task + `notify: restart nginx`.
2. **Handlers.** `handlers/main.yml`: `restart nginx` (`service: state: restarted`). Kutsu `notify:`-ga, veendu et käivitub ainult siis kui fail muutus.
3. **Teine roll.** Loo `firewall` roll (`ufw allow {{ nginx_port }}`), lisa `site.yml`-i kolmandaks, jälgi järjekorda.
4. **Dependency.** `nginx/meta/main.yml`-i `dependencies:` plokk, mis nõuab `firewall`-i enne. Kas pead siis `firewall`-i veel eraldi `roles:`-is mainima?

---

## Veaotsing

| Probleem | Lahendus |
|---|---|
| `init` — "existing directory" | `rm -rf roles/nginx` või uus nimi |
| `roles/nginx: not found` | Käivita `ansible-playbook` projekti juurest (kus `roles/`) |
| Task "ok" iga kord, midagi ei muutu | `become: true` puudub |
| Muudatus `index.html.j2`-s ei kajastu | `curl`, mitte brauser; kontrolli et `template` task jooksis (`-v`) |
| `nginx_port` ei mõjuta kuulamisporti | Roll muudab ainult HTML-i, mitte konfi — vt Lisaülesanne 1 |
| `geerlingguy.git` ei lae | Kontrolli võrku (Galaxy server) |
| Handler ei käivitu | `notify:` nimi peab **sõna-sõnalt** kattuma handleri `name:`-ga |
| `Permission denied` `/var/www/html/` | `become: true` puudub |

*Tabel 11.1. Levinumad tõrked ja lahendused.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| Ansible Roles | <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html> | Struktuur, käivitamine |
| Variable precedence | <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable> | `defaults` vs `vars` |
| Ansible Galaxy | <https://galaxy.ansible.com/> | Kogukonna rollid |
| Ansible Handlers | <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html> | Lisaülesanne 2 |
