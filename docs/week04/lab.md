---
tags:
  - Ansible
  - Jinja2
  - Turvalisus
---

# Muutujad, Jinja2 ja Vault — käed külge — Labor

**Kestus:** 4 tundi
**Eeldused:** Loeng antud (muutujad, precedence, Jinja2, Vault). Nädal 3 lab tehtud — töötav `nginx.yml`. Kui udu — [tagasi loengusse](lecture.md). Siit edasi **ainult käed külge**.
**Kontroll-node:** sinu arvuti, kogu töö **VS Code'is**.
**Sihtmärk:** sinu valik (vt [Töökeskkond](../kodulabor.md)) — kodus lokaalne, koolis Proxmox. Sama `nginx.yml` mis nädal 3.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Tõstad kõvakodeeritud väärtused `group_vars`-i ja selgitad miks
    2. Kirjutad Jinja2 malli ja tead miks `template:` ≠ `copy:`
    3. **Diagnoosid** kolm viga veateate järgi (undefined variable, mall ei asendu, decryption failed)
    4. Krüpteerid saladuse Vault'iga ja käivitad playbooki sellega
    5. Taastad korratava seisu ise tehtud sasi järel

---

Labi loogika: **baas → laienda → viga → paranda → laienda → viga → taasta.** Sa ei kopeeri valmis lahendust. Ehitad kihthaaval, tekitad võtmevead ise, diagnoosid veateate järgi.

---

## Osa 1 · Setup + baas

Ava projektikaust VS Code'is (`code .`), käivita sihtmärk, kontrolli et nädal 3 `nginx.yml` töötab:

```bash
ansible-playbook -i inventory.ini nginx.yml
```

Läbib? Edasi. Ei? Paranda enne — see labi ehitab otse selle peale.

---

## Osa 2 · Hardcode → muutuja

Su playbookis on väärtus otse task'i sees, nt:

```yaml
    - name: Paigalda nginx
      apt:
        name: nginx
        state: present
```

Too `nginx` muutujasse. Lisa play-tasandile `vars:` plokk ja viita sellele task'is:

```yaml
  vars:
    paketi_nimi: nginx
```

```yaml
        name: "{{ paketi_nimi }}"
```

```bash
ansible-playbook -i inventory.ini nginx.yml
```

Sama tulemus. Väärtus on nüüd loogikast eraldi.

!!! tip
    `"{{ paketi_nimi }}"` **peab** olema jutumärkides. Ilma nendeta üritab YAML `{{ }}` ise ära süüa ja saad `template error`. Esimene YAML-i gotcha.

---

## Osa 3 · Undefined variable — kust Ansible otsib

`vars:` otse playbookis töötab, aga kasvades segunevad muutujad loogikaga. Ansible'il on parem koht: `group_vars/all.yml` rakendub automaatselt kõigile hostidele.

Loo kaust ja fail (projektikausta, `inventory.ini` kõrvale):

```bash
mkdir group_vars
```

Pane `group_vars/all.yml`-i:

```yaml
paketi_nimi: nginx
```

Nüüd **eemalda meelega** see rida playbook'i `vars:` plokist — ja aja **valesti**: pane `group_vars` fail ekslikult mujale (nt kausta `vars/` mitte `group_vars/`), või kirjuta muutuja nimi valesti (`pakett_nimi`). Käivita:

```bash
ansible-playbook -i inventory.ini nginx.yml
```

**Viga:** `The task includes an option with an undefined variable ... 'paketi_nimi' is undefined`.

??? question "Diagnoosi enne kui parandad"
    Ansible otsib `group_vars/`-i **täpselt** `inventory.ini` kõrvalt, ja nimi peab tähthaaval klappima. Kaks võimalikku põhjust "undefined" jaoks — kaust vales kohas VÕI nimi ei kattu. Kumb sinul?

**Paranda:** `group_vars/all.yml` õigesse kohta, nimi täpselt `paketi_nimi`. Käivita — läbib. `vars:` plokk võib nüüd tühjaks jääda.

---

## Osa 4 · Template vs copy — miks `{{ }}` ei asendu

Tahad dünaamilist `index.html`-i (serveri nimi sees). Loo mall `templates/index.html.j2`:

```html
<h1>Server: {{ inventory_hostname }}</h1>
```

Lisa task — aga kasuta **meelega** `copy:` (nagu varem faili puhul):

```yaml
    - name: Pane leht üles
      copy:
        src: templates/index.html.j2
        dest: /var/www/html/index.html
```

```bash
ansible-playbook -i inventory.ini nginx.yml
```

Ava brauseris. Näed lehel sõna-sõnalt `{{ inventory_hostname }}`, mitte serveri nime.

??? question "Diagnoosi"
    `copy:` viib faili **muutmata**. Jinja2 `{{ }}` töödeldakse ainult `template:` mooduliga. Mis moodul peab siin `copy:` asemel olema?

**Paranda** — `copy:` → `template:`:

```yaml
    - name: Pane leht üles
      template:
        src: templates/index.html.j2
        dest: /var/www/html/index.html
```

```bash
ansible-playbook -i inventory.ini nginx.yml
```

Nüüd näitab leht serveri nime. `{{ inventory_hostname }}` väärtust sa kuskile ei pannud — see on Ansible sisseehitatud fakt.

---

## Osa 5 · Vault — saladuse krüpteerimine

Praegu on kõik muutujad tavatekstis. Päris elus lähevad sinna paroolid. Loo krüpteeritud fail (Ansible küsib **krüpteerimisparooli** — mõtle välja ja **jäta meelde**):

```bash
ansible-vault create group_vars/vault.yml
```

Redaktoris:

```yaml
db_password: SuperSalajane123
```

Salvesta, sulge. Kontrolli:

```bash
cat group_vars/vault.yml
```

Näed jama (`$ANSIBLE_VAULT;1.1;AES256...`), mitte oma parooli. Kasuta muutujat malli (demoks):

```html
<p>DB seadistatud: {{ db_password is defined }}</p>
```

---

## Osa 6 · Decryption failed — Vault ilma paroolita

Käivita playbook **tavaliselt** (nagu seni):

```bash
ansible-playbook -i inventory.ini nginx.yml
```

**Viga:** `Attempting to decrypt but no vault secrets found`.

??? question "Diagnoosi"
    Ansible leidis `group_vars/vault.yml`, aga see on krüpteeritud, ja sa ei andnud parooli. Mis lipp käsule puudu?

**Paranda** — anna Vault'i parool:

```bash
ansible-playbook -i inventory.ini nginx.yml --ask-vault-pass
```

Sisesta Osa 5 parool. Leht näitab `True`.

!!! warning
    Ansible Vault ei paku "unusta parool" nuppu. Vale parool = fail on kadunud, teed uuesti. Sina ja see parool — üks teist peab meeles pidama, ja fail ei pea.

??? question "Mõtle"
    Kui commit'iksid krüpteeritud `vault.yml`-i GitHubi — kas see oleks turvaline? Ja mis on **selle** faili ja Märteni `.env` vahe?

---

## Osa 7 · Vault parool eraldi faili

`--ask-vault-pass` iga kord on tüütu, ja CI/CD ei saa parooli käsitsi trükkida. Pane parool faili:

```bash
echo "SuperSalajane123" > .vault_pass
```

```bash
ansible-playbook -i inventory.ini nginx.yml --vault-password-file .vault_pass
```

Läbib ilma küsimata.

!!! warning
    `.vault_pass` on **selge tekstiga parool**. See ei tohi **kunagi** Gitti sattuda. Lisa kohe:

    ```bash
    echo ".vault_pass" >> .gitignore
    ```

    Sama loogika mis Märteni `.env`. Vault kaitseb `vault.yml`-i, aga `.vault_pass` on võti — võtit ei jäeta ukse külge.

---

## Osa 8 · Taasta ja kontroll

Lõplik käivitus, kõik koos:

```bash
ansible-playbook -i inventory.ini nginx.yml --vault-password-file .vault_pass
```

??? question "Mõtle"
    Loetle mis on nüüd Git-is (turvaline) ja mis EI tohi olla: `nginx.yml`, `group_vars/all.yml`, `templates/`, `group_vars/vault.yml` (krüpteeritud), `.vault_pass`. Kumb kahest viimasest on ohtlik?

---

## Lõppkontroll — oskad ilma juhendita

- [ ] `group_vars/all.yml` hoiab muutujaid, playbookis pole hardcode'i
- [ ] "undefined variable" nägemisel kontrollid kohe kausta asukohta + nime
- [ ] Tead miks mall vajab `template:`, mitte `copy:`
- [ ] `--ask-vault-pass` või `--vault-password-file` — tead millal kumbki
- [ ] `.vault_pass` on `.gitignore`-is
- [ ] Selgitad mis Git-is tohib olla ja mis mitte

---

## Lisaülesanded (kui jõuad ette)

1. **group_vars grupile:** tee `group_vars/web.yml` sama muutujaga teise väärtusega. Kumb peale jääb, `all.yml` või `web.yml`? Miks?
2. **Jinja2 loogika:** lisa malli `{% if db_password is defined %}...{% endif %}`. Millal mall-loogika kasulik?
3. **ansible-vault edit:** `ansible-vault edit group_vars/vault.yml` vs `view`. Mis vahe?

---

## Veaotsing

| Veateade | Põhjus | Lahendus |
|---|---|---|
| `'paketi_nimi' is undefined` | `group_vars/` vales kohas või nimi ei kattu | Kaust `inventory.ini` kõrvale, nimi täpselt |
| Mall näitab `{{ muutuja }}` sõna-sõnalt | Kasutad `copy:`, mitte `template:` | `template:` moodul |
| `no vault secrets found` | Krüpteeritud fail ilma paroolita | `--ask-vault-pass` või `--vault-password-file` |
| `Decryption failed` | Vale Vault parool | Õige parool; fail pole taastatav vale parooliga |
| `"{{ x }}"` annab template error | Jutumärgid puudu YAML-is | `"{{ x }}"` jutumärkidesse |

*Tabel 4.1. Iga rida on viga, mille sa selles labis ise tekitasid ja parandasid.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| Ansible Variables | <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html> | group_vars, precedence |
| Templating (Jinja2) | <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_templating.html> | `template:` |
| Ansible Vault | <https://docs.ansible.com/ansible/latest/vault_guide/index.html> | Vault käsud |
| Jinja2 | <https://jinja.palletsprojects.com/> | Süntaks |
