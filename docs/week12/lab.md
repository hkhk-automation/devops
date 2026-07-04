---
tags:
  - Ansible
  - IaC
  - Infrastruktuur
  - Praktikum
---

# Infrastruktuur koodina — Ansible IaC — käed külge — Labor

**Kestus:** 4 tundi
**Eeldused:** Loeng antud (inventory grupid, group_vars/host_vars, idempotentsus infra tasemel, Ansible vs Terraform). Nädalad 3–4 (playbook, muutujad, Vault), nädal 11 (rollid, `site.yml`). Kui udu — [tagasi loengusse](lecture.md). Siit edasi **ainult käed külge**.
**Kontroll-node:** sinu arvuti, **VS Code**. `site.yml` ja `roles/` nädalast 11.
**Sihtmärk:** sinu valik (vt [Töökeskkond](../kodulabor.md)) — täna vajad **kahte** hosti. Kodus: kaks VM-i / kaks WSL-i / üks masin kahe kasutajaga. Koolis: kaks Proxmox VM-i. Vahe kooli/kodu vahel on ikka üks asi: `inventory.ini` read.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Laiendad ühe hosti playbook'i mitmele hostile inventory gruppidega
    2. Eraldad kaks keskkonda `group_vars`-iga — **sama kood**, erinevad väärtused
    3. **Diagnoosid** kolm viga: host ei kuulu gruppi, muutuja vales failis, drift
    4. Tekitad käsitsi drifti ja lased Ansible'il selle parandada (`changed` räägib)
    5. Võrdled Ansible't ja Terraformi konkreetse töö peal, mitte definitsioonist

---

Labi loogika: **baas (üks host) → laienda (mitu hosti) → viga → paranda → laienda (group_vars) → viga → drift → taasta.** Sa ei alusta nullist — võtad nädal 11 `site.yml` + nginx-rolli ja kasvatad selle ühe serveri asjast serveripargi asjaks. Fragmendid, mitte terve fail.

---

## Osa 1 · Baas — üks host töötab (kordus nädalast 11)

Ava nädal 11 töökaust (`~/ansible-lab`) VS Code'is. Kontrolli et eelmine töö jookseb:

```bash
cd ~/ansible-lab
ansible-playbook -i inventory.ini site.yml
```

Läbib, `curl http://<host>` näitab su nginx-lehte? Edasi. Ei? Paranda enne — see labi ehitab otse selle peale.

Vaata praegust `inventory.ini`-t — üks host, üks rida. Täna teeme sellest pargi.

---

## Osa 2 · Laienda — teine host gruppi

Lisa `inventory.ini`-sse **grupp** ja **teine host**:

```ini
[web]
<host1> ansible_user=<kasutaja>
<host2> ansible_user=<kasutaja>
```

Muuda `site.yml` sihtima gruppi (mitte `all`):

```yaml
- hosts: web
  become: true
  roles:
    - nginx
```

Testi ühendust **mõlemaga** enne playbook'i:

```bash
ansible web -i inventory.ini -m ping
```

Kaks `SUCCESS` + `pong`. Nüüd jooksuta:

```bash
ansible-playbook -i inventory.ini site.yml
```

Vaata `PLAY RECAP` — **kaks hosti**, mõlemal task'id. Üks käsk, kaks serverit. Kontrolli mõlemat:

```bash
curl http://<host1>
curl http://<host2>
```

??? question "Mõtle"
    Sa ei muutnud rolli ega task'e — ainult inventory't ja `hosts:` rida. Miks piisas sellest, et kaks serverit saaks identse seadistuse? Kui hoste oleks 50, mitu rida sa muudaksid?

---

## Osa 3 · Viga — host ei kuulu gruppi

Lisa `inventory.ini`-sse kolmas host, aga **meelega grupi plokist väljapoole** (faili algusesse, enne `[web]` rida):

```ini
<host3> ansible_user=<kasutaja>

[web]
<host1> ansible_user=<kasutaja>
<host2> ansible_user=<kasutaja>
```

Jooksuta:

```bash
ansible-playbook -i inventory.ini site.yml
```

`PLAY RECAP` näitab ikka **kahte** hosti. `<host3>` jäi vahele — nginx sinna ei paigaldatud, aga viga ka ei antud. Vaikne möödaminek.

??? question "Diagnoosi enne kui parandad"
    `site.yml` ütleb `hosts: web`. Host, mis on kirjas **enne** esimest `[grupp]` rida, kuulub Ansible's erigruppi `ungrouped` — mitte `web`-i. Miks on see vaikne (ei anna viga) ohtlikum kui vali viga? Kus päris elus tähendaks "üks server jäi seadistamata, aga keegi ei märganud"?

Kontrolli kellele playbook päriselt rakendub:

```bash
ansible web -i inventory.ini --list-hosts
```

`<host3>` ei ole loendis. **Paranda** — vii `<host3>` rida `[web]` ploki **sisse**. Jooksuta, `PLAY RECAP` = kolm hosti.

!!! tip
    `ansible <grupp> --list-hosts` on su sõber iga kord kui kahtled, kellele playbook mõjub. Kontrolli **enne** jooksutamist, mitte pärast, kui tootmises 50 serverit said valesid muudatusi.

---

## Osa 4 · Laienda — kaks keskkonda group_vars'iga

Praegu on kõik hostid ühesugused. Päris elus on `web` grupp tootmine ja sul on eraldi `staging` grupp teiste väärtustega. Teeme kaks keskkonda, **sama koodiga**.

Muuda `inventory.ini` kaheks grupiks:

```ini
[production]
<host1> ansible_user=<kasutaja>

[staging]
<host2> ansible_user=<kasutaja>
```

Loo muutujafailid (Ansible loeb nimede järgi automaatselt, meenuta nädal 4):

`group_vars/production.yml`:

```yaml
keskkond: "TOOTMINE"
nginx_port: 80
```

`group_vars/staging.yml`:

```yaml
keskkond: "STAGING"
nginx_port: 80
```

Kasuta muutujat rolli mallis. Ava `roles/nginx/templates/index.html.j2`, lisa rida:

```jinja2
<p>Keskkond: {{ keskkond }}</p>
```

Sihi `site.yml` mõlemale grupile:

```yaml
- hosts: production, staging
  become: true
  roles:
    - nginx
```

Jooksuta, kontrolli mõlemat:

```bash
ansible-playbook -i inventory.ini site.yml
curl http://<host1>
curl http://<host2>
```

`<host1>` ütleb "TOOTMINE", `<host2>` "STAGING" — **sama roll, sama mall, sama playbook**, erineb ainult see, mis `group_vars` fail hostile kehtib.

??? question "Mõtle"
    Sa ei teinud rollist kaht koopiat. Kood on üks. Kui tahaksid kolmandat keskkonda (`dev`), mitu **koodifaili** peaksid muutma vs mitu **muutujafaili** looma? Selles vahes ongi IaC mõte.

---

## Osa 5 · Viga — muutuja vales failis

Tahad, et **ainult** tootmises oleks eraldi hoiatustekst. Lisa see **meelega valesse kohta** — `group_vars/all.yml`-i (mis rakendub kõigile), mitte `production.yml`-i:

Loo `group_vars/all.yml`:

```yaml
hoiatus: "PISUT ETTEVAATLIK — TOOTMISKESKKOND"
```

Lisa mallile:

```jinja2
<p>{{ hoiatus }}</p>
```

Jooksuta, vaata mõlemat:

```bash
ansible-playbook -i inventory.ini site.yml
curl http://<host1>
curl http://<host2>
```

Hoiatus ilmub **mõlemale** — ka stagingule, kuhu see ei kuulu.

??? question "Diagnoosi enne kui parandad"
    `group_vars/all.yml` rakendub **kõigile** hostidele, sõltumata grupist. Sa tahtsid ainult tootmist. Mis failinimi paneks muutuja kehtima ainult `[production]` grupile? (Vihje: sama loogika mis `web.yml` → `[web]`.)

**Paranda** — vii `hoiatus` rida `all.yml`-ist `production.yml`-i. Kustuta `all.yml` (või jäta tühjaks). Jooksuta, kontrolli — hoiatus ainult `<host1>`-l.

!!! tip
    Muutuja "ilmub kohta, kus ei peaks" = kontrolli **millises** `group_vars` failis ta on. `all.yml` = kõik, `<grupp>.yml` = ainult see grupp, `host_vars/<host>.yml` = ainult see host. Kolm taset, kolm ulatust.

---

## Osa 6 · Drift — Ansible parandab käsitsi rikutu

Nüüd IaC võimsaim hetk. Su serverid on koodis kirjeldatud seisus. Mängi Märtenit — mine käsitsi ühte serverisse ja **riku** midagi:

```bash
ssh <kasutaja>@<host1>
sudo rm /var/www/html/index.html
sudo systemctl stop nginx
exit
```

Server on nüüd "triivinud" — keegi (sina) muutis teda käsitsi, ta ei vasta enam koodis kirjeldatud seisule:

```bash
curl http://<host1>
```

Ei vasta. Nüüd **ära paranda käsitsi**. Jooksuta lihtsalt playbook:

```bash
ansible-playbook -i inventory.ini site.yml
```

Vaata `PLAY RECAP`: `<host1>` näitab **changed** (Ansible märkas, et fail puudu ja teenus maas, ja parandas), `<host2>` näitab **ok** (tema oli korras, teda ei puututud).

```bash
curl http://<host1>
```

Vastab jälle. Sa ei öelnud Ansible'ile "pane fail tagasi, käivita teenus" — ta **võrdles** tegelikku seisu koodiga ja parandas vahe ise.

??? question "Mõtle"
    Kujuta et see playbook jookseb cron'is iga tund. Mida tähendaks, kui hommikul näed `changed=5` ühel serveril, kuigi keegi ei tohtinud midagi muuta? Ja mida tähendaks, kui kõik on alati `changed=0`? Kumb number on turvasignaal?

---

## Osa 7 · host_vars — üks host, oma erisus

Vahel vajab **üks konkreetne** server erisust (nt teine port), ilma et terve grupp muutuks. Selleks on `host_vars`.

Loo `host_vars/<host2>.yml` (failinimi = hosti nimi täpselt nagu inventory's):

```yaml
nginx_port: 80
erimärkus: "See host on ainuke, millel on eriseade"
```

Lisa mallile:

```jinja2
{% if erimärkus is defined %}<p>{{ erimärkus }}</p>{% endif %}
```

Jooksuta, kontrolli:

```bash
ansible-playbook -i inventory.ini site.yml
curl http://<host1>
curl http://<host2>
```

Erimärkus ainult `<host2>`-l — `host_vars` on kitsam kui `group_vars`. `{% if ... is defined %}` hoiab ära vea seal, kus muutujat pole (meenuta Jinja2 nädalast 4).

??? question "Mõtle"
    Kolm ulatust: `all.yml` (kõik) → `<grupp>.yml` (grupp) → `host_vars/<host>.yml` (üks). Kui sama muutuja on kõigis kolmes eri väärtusega, kumb võidab? Miks on selline "kitsam võidab" loogika mõistlik?

---

## Osa 8 · Ansible vs Terraform — võrdlus töö peal

Nädalatel 10–11 tegid Terraformi. Nüüd Ansible. Aeg mõista, **millal kumb** — mitte definitsioonist, vaid oma käega tehtu põhjal.

Loo repo-sse fail `docs/week12/vordlus.md` (mitte sihtmärgile) ja vasta:

**Küsimus 1:** Sa just paigaldasid nginx'i kahele serverile Ansible'iga. Kust need serverid **tulid** — kas Ansible lõi need, või olid nad juba olemas ja Ansible läks nende **sisse**? Mis tööriist oleks serverid ise **loonud**?

**Küsimus 2:** Terraform hoiab "state-faili" (mäletab, mida ta lõi). Ansible ei hoia. Miks Ansible ei vaja state-faili, et olla idempotentne — mida ta selle asemel iga kord teeb? (Vihje: Osa 6 drift.)

**Küsimus 3:** Kirjelda **üks** konkreetne töövoog, kus kasutaksid **mõlemat**: mida teeb Terraform, mida Ansible, mis järjekorras, ja mis info liigub ühelt teisele.

Push'i see repo-sse — las nädal 7 pipeline jookseb ka selle peal.

---

## Lõppkontroll — oskad ilma juhendita

- [ ] `inventory.ini` mitme grupiga, `ansible <grupp> --list-hosts` näitab õigeid
- [ ] Üks `site.yml` seadistab kaks keskkonda, mõlemal oma `keskkond` väärtus
- [ ] "Muutuja vales kohas" nägemisel tead: `all.yml` vs `<grupp>.yml` vs `host_vars`
- [ ] Tekitad drifti käsitsi, playbook parandab, `<host1>` **changed** ja `<host2>` **ok**
- [ ] Selgitad `changed=0` tähendust tervisekontrollina
- [ ] `vordlus.md` repos: Ansible loob vs seadistab, state, kombineeritud voog
- [ ] `host_vars` annab ühele hostile erisuse ilma gruppi muutmata

---

## Lisaülesanded (kui jõuad ette)

1. **`--limit`:** jooksuta `site.yml` ainult ühel hostil (`--limit <host1>`). Millal tootmises kasulik?
2. **`--check` + `--diff`:** `ansible-playbook site.yml --check --diff` — näitab mida **muudaks**, ilma tegemata. Riku üks host käsitsi, jooksuta `--check --diff`, vaata kuidas drift on näha ilma parandamata. Miks on see enne tootmist kullaväärt?
3. **`[production:children]`:** tee grupp `all_web`, mis sisaldab nii `production` kui `staging`. Sihi `site.yml` sellele. Millal grupp-gruppidest kasulik?
4. **Vault mitmele keskkonnale:** anna `production` ja `staging` grupile **erinevad** Vault-krüpteeritud paroolid (`group_vars/production/vault.yml`). Kuidas hoida kaks eri saladust sama koodiga? (Nädal 4 Vault + selle nädala group_vars.)

---

## Veaotsing

| Veateade / sümptom | Põhjus | Lahendus |
|---|---|---|
| `PLAY RECAP` näitab vähem hoste kui inventory's | Host enne esimest `[grupp]` rida (`ungrouped`) | Vii host grupi ploki sisse |
| Muutuja ilmub valesse keskkonda | `all.yml`-is, mitte `<grupp>.yml`-is | Õige ulatusega fail |
| `'muutuja' is undefined` | `group_vars` fail vales kohas või nimi ei kattu | Fail `inventory.ini` kõrval, nimi = grupp/host täpselt |
| `host_vars` ei rakendu | Failinimi ≠ hosti nimi inventory's | Nimi tähthaaval sama |
| Drift ei parane | `become: true` puudub, või roll ei kata seda faili | Kontrolli rolli task'e; `become` |
| `UNREACHABLE` ühel hostil | Teine host maas / SSH katki | `ansible <grupp> -m ping`, paranda inventory rida |
| Sama muutuja mitmes failis, vale võidab | Precedence: host_vars > group_vars > all | Kitsam ulatus võidab |

*Tabel 12.1. Iga rida on viga, mille sa selles labis ise tekitasid või kohtad.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| Ansible inventory | <https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html> | Grupid, children |
| group_vars / host_vars | <https://docs.ansible.com/ansible/latest/playbook_guide/intro_inventory.html#organizing-host-and-group-variables> | Muutujate ulatus |
| Variable precedence | <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable> | Kitsam võidab |
| `--check` mode | <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html> | Drift ilma parandamata |
| Ansible vs Terraform | <https://developer.hashicorp.com/terraform/intro/vs/chef-puppet> | Millal kumb |
