---
tags:
  - Ansible
  - Konfiguratsioonihaldus
  - Kodutöö
---

# Kodutöö — dev ja prod keskkonnad

**Eeldused:** w04 labor tehtud — `nginx.yml` kasutab `group_vars/all.yml` faili ja `templates/index.html.j2` malli, töötab `--ask-vault-pass`-iga.

---

## Ülesanne

Praegu kehtivad su muutujad **kõikidele** hostidele ühtemoodi (`group_vars/all.yml`). Päris elus on dev ja prod erinevad — dev-serveril on debug nähtav, prod-serveril mitte. (Vähemalt teoorias. Praktikas leiab keegi debug-info alati prod'ist, tavaliselt klient.) Tekita see erinevus muutujatega, playbook'i ennast puutumata.

**Samm 1 — inventory täiendamine**

Lisa `inventory.ini`-sse kaks gruppi (kui sul on üks VM, pane mõlemad ajutiselt sama hosti peale — oluline on grupistruktuur):

```ini
[dev]
dev-server ansible_host=<VM-IP> ansible_user=<kasutaja>

[prod]
prod-server ansible_host=<VM-IP> ansible_user=<kasutaja>
```

**Samm 2 — grupi-spetsiifilised muutujad**

```bash
nano group_vars/dev.yml
```

```yaml
keskkond_nimi: "ARENDUS"
näita_debug_info: true
```

```bash
nano group_vars/prod.yml
```

```yaml
keskkond_nimi: "PRODUKTSIOON"
näita_debug_info: false
```

!!! tip
    Miks need ei lähe `all.yml`-i: `group_vars/dev.yml` kehtib ainult `dev` grupile. `all.yml` jääb sellele, mis on tõesti kõikjal sama (nt `paketi_nimi: nginx`).

**Samm 3 — malli täiendamine**

```html
<p>Keskkond: {{ keskkond_nimi }}</p>
```

**Samm 4 — käivita mõlema grupi vastu**

```bash
ansible-playbook -i inventory.ini nginx.yml --limit dev --ask-vault-pass
```

Leht peaks näitama "ARENDUS".

```bash
ansible-playbook -i inventory.ini nginx.yml --limit prod --ask-vault-pass
```

Nüüd "PRODUKTSIOON" — sama playbook, sama mall, erinev tulemus, sest muutujad tulid erinevast failist.

!!! tip
    "no hosts matched" — kontrolli et grupi nimi `[dev]` failis kattub täpselt käsureal antuga, ja `dev-server` rida on grupi pealkirja **all**.

??? question "Mõtle"
    Mõlemad käivitused kasutasid sama `nginx.yml`-i ja sama malli. Mis see sulle ütleb selle kohta, kus peaks keskkonna-spetsiifiline info hea Ansible projekti struktuuris elama?

---

## Esitamine

1. Commit'i muudatused (`inventory.ini`, `group_vars/dev.yml`, `group_vars/prod.yml`, muudetud mall).
2. **Ära kunagi** commit'i `group_vars/vault.yml`-i lahtikrüpteerituna — `ansible-vault`-iga loodud kujul on ta juba turvaline.
3. Uus branch (nt `week04-dev-prod`), push, ava **Pull Request** main vastu — läbi reeglite, nagu nädal 2.
4. PR kirjelduses näita mõlema keskkonna väljundit (ekraanipilt või terminal) — dev ja prod peavad selgelt erinema.

---

## Enesekontroll

- [ ] `group_vars/dev.yml` ja `group_vars/prod.yml` on erineva sisuga
- [ ] `--limit dev` näitab "ARENDUS"
- [ ] `--limit prod` näitab "PRODUKTSIOON"
- [ ] PR on avatud ja sisaldab tõendust mõlema keskkonna erinevusest
