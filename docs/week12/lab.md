---
tags:
  - Ansible
  - IaC
  - Infrastruktuur
  - Praktikum
---

# Praktikum: terve serveripark koodina

Loengus nägid inventory gruppe, faile `group_vars` ja `host_vars`, idempotentsust infrastruktuuri tasemel ning Ansible'i ja Terraformi võrdlust. Selles praktikumis võtad nädala 11 faili `site.yml` ja nginx'i rolli ning laiendad need ühelt serverilt serveripargile. Vahepeal tekitad kolm tahtlikku viga: host ei kuulu gruppi, muutuja on vales failis ja server on käsitsi muudetud. Kui loengu teemad on veel segased, loe uuesti [loengut](lecture.md).

Juhtmasin on sinu arvuti ja töötad VS Code'is. `site.yml` ja `roles/` on nädalast 11. Sihtmasina vali [töökeskkonna](../kodulabor.md) juhendi järgi.

Täna on vaja kahte hosti: kodus kaks VM-i, kaks WSL-i või üks masin kahe kasutajaga, koolis kaks Proxmoxi VM-i. Kodu ja kooli vahel erinevad ainult faili `inventory.ini` read.

??? abstract "Õpiväljundid"

    Selle praktikumi lõpuks oskad:

    1. laiendada ühe hosti playbook'i inventory gruppide abil mitmele hostile;
    2. eraldada kaks keskkonda `group_vars` abil: sama kood, erinevad väärtused;
    3. leida kolme vea põhjuse: host ei kuulu gruppi, muutuja on vales failis, server on triivinud;
    4. tekitada käsitsi triivi ja lasta Ansible'il see parandada (`changed` näitab muudatust);
    5. võrrelda Ansible'it ja Terraformi tehtud töö põhjal.

## Osa 1 · Lähtepunkt: üks host töötab

Ava nädala 11 töökaust (`~/ansible-lab`) VS Code'is. Kontrolli, et eelmine töö käivitub:

```bash
cd ~/ansible-lab
ansible-playbook -i inventory.ini site.yml
```

Kui playbook lõpeb vigadeta ja `curl http://<host>` näitab sinu nginx'i lehte, liigu edasi. Kui ei, paranda see enne, sest kogu praktikum põhineb sellel.

Praegu on failis `inventory.ini` üks host ja üks rida. Täna teed sellest serveripargi.

## Osa 2 · Teine host gruppi

Lisa faili `inventory.ini` grupp ja teine host. Inventory süntaks on kirjas lehel [How to build your inventory](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html).

```ini
[web]
<host1> ansible_user=<kasutaja>
<host2> ansible_user=<kasutaja>
```

Muuda faili `site.yml` nii, et see sihib gruppi (mitte `all`):

```yaml
- hosts: web
  become: true
  roles:
    - nginx
```

Enne playbook'i käivitamist kontrolli ühendust mõlema hostiga:

```bash
ansible web -i inventory.ini -m ping
```

Mõlemad hostid peavad vastama `SUCCESS` ja `pong`. Seejärel käivita playbook:

```bash
ansible-playbook -i inventory.ini site.yml
```

??? warning "Kui ühes hostis on `UNREACHABLE`"
    Teine host ei tööta või SSH-ühendus ei toimi. Kontrolli käsuga `ansible <grupp> -m ping` ja paranda selle hosti rida failis `inventory.ini`.

Kokkuvõttes `PLAY RECAP` on kaks hosti ja mõlemas käivitusid ülesanded. Üks käsk seadistas kaks serverit. Kontrolli mõlemat:

```bash
curl http://<host1>
curl http://<host2>
```

??? question "Mõtle"
    Sa ei muutnud rolli ega ülesandeid, ainult inventory't ja rida `hosts:`. Miks piisas sellest, et kaks serverit said identse seadistuse? Mitu rida muudaksid, kui hoste oleks 50?

## Osa 3 · Viga: host ei kuulu gruppi

Lisa faili `inventory.ini` kolmas host, aga tahtlikult grupi plokist välja (faili algusesse, enne rida `[web]`):

```ini
<host3> ansible_user=<kasutaja>

[web]
<host1> ansible_user=<kasutaja>
<host2> ansible_user=<kasutaja>
```

Käivita playbook:

```bash
ansible-playbook -i inventory.ini site.yml
```

`PLAY RECAP` näitab endiselt kahte hosti. `<host3>` jäi vahele ja nginx'i sinna ei paigaldatud, aga Ansible ei andnud ka viga.

??? question "Leia põhjus enne parandamist"
    `site.yml` sihib gruppi `web`. Host, mis on kirjas enne esimest rida `[grupp]`, kuulub Ansible'is erigruppi `ungrouped`, mitte gruppi `web`. Miks on selline vaikne vahelejätmine ohtlikum kui veateade? Mida tähendaks töökohas, et üks server jäi seadistamata ja keegi ei märganud?

Kontrolli, millistele hostidele playbook rakendub:

```bash
ansible web -i inventory.ini --list-hosts
```

`<host3>` ei ole loendis. Paranda viga: vii `<host3>` rida ploki `[web]` sisse. Käivita playbook uuesti, nüüd on `PLAY RECAP` kokkuvõttes kolm hosti.

!!! tip
    Käsk `ansible <grupp> --list-hosts` näitab, millistele hostidele playbook rakendub. Kontrolli seda enne käivitamist, mitte pärast seda, kui 50 tootmisserverit said vale muudatuse.

## Osa 4 · Kaks keskkonda `group_vars` abil

Praegu on kõik hostid ühesugused. Töökohas on tavaliselt eraldi tootmise grupp ja testimise grupp (`staging`) erinevate väärtustega. Teed kaks keskkonda sama koodiga.

Muuda fail `inventory.ini` kaheks grupiks:

```ini
[production]
<host1> ansible_user=<kasutaja>

[staging]
<host2> ansible_user=<kasutaja>
```

Loo muutujafailid. Ansible loeb need nime järgi automaatselt nagu nädalal 4 ([Organizing host and group variables](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html#organizing-host-and-group-variables)).

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

Kasuta muutujat rolli mallis. Ava `roles/nginx/templates/index.html.j2` ja lisa rida:

```jinja2
<p>Keskkond: {{ keskkond }}</p>
```

Muuda faili `site.yml` nii, et see sihib mõlemat gruppi:

```yaml
- hosts: production, staging
  become: true
  roles:
    - nginx
```

Käivita playbook ja kontrolli mõlemat hosti:

```bash
ansible-playbook -i inventory.ini site.yml
curl http://<host1>
curl http://<host2>
```

`<host1>` näitab „TOOTMINE“ ja `<host2>` näitab „STAGING“. Roll, mall ja playbook on samad, erineb ainult see, milline `group_vars` fail hostile kehtib.

??? warning "Kui tuleb viga `'keskkond' is undefined`"
    `group_vars` kaust on vales kohas või faili nimi ei ole sama mis grupi nimi. Kaust `group_vars` peab olema faili `inventory.ini` kõrval ja faili nimi täpselt sama mis grupp.

??? question "Mõtle"
    Sa ei teinud rollist kahte koopiat, kood on üks. Kui tahaksid kolmandat keskkonda (`dev`), mitu koodifaili peaksid muutma ja mitu muutujafaili looma? Selles vahes ongi IaC mõte.

## Osa 5 · Viga: muutuja vales failis

Hoiatustekst peab olema ainult tootmises. Lisa see tahtlikult valesse kohta: faili `group_vars/all.yml`, mis rakendub kõigile hostidele, mitte faili `production.yml`.

Loo `group_vars/all.yml`:

```yaml
hoiatus: "PISUT ETTEVAATLIK - TOOTMISKESKKOND"
```

Lisa mallile rida:

```jinja2
<p>{{ hoiatus }}</p>
```

Käivita playbook ja vaata mõlemat hosti:

```bash
ansible-playbook -i inventory.ini site.yml
curl http://<host1>
curl http://<host2>
```

Hoiatus on mõlemas hostis, ka testkeskkonnas, kuhu see ei kuulu.

??? question "Leia põhjus enne parandamist"
    `group_vars/all.yml` rakendub kõigile hostidele, sõltumata grupist. Milline failinimi paneks muutuja kehtima ainult grupile `[production]`? (Vihje: sama loogika nagu `web.yml` → `[web]`.)

Paranda viga: vii rida `hoiatus` failist `all.yml` faili `production.yml`. Kustuta `all.yml` või jäta see tühjaks. Käivita playbook ja kontrolli, et hoiatus on ainult hostis `<host1>`.

!!! tip
    Kui muutuja on seal, kus seda ei peaks olema, kontrolli, millises `group_vars` failis see on. `all.yml` kehtib kõigile, `<grupp>.yml` ainult sellele grupile ja `host_vars/<host>.yml` ainult sellele hostile.

## Osa 6 · Triiv: Ansible parandab käsitsi tehtud muudatuse

Serverid on praegu koodis kirjeldatud olekus. Logi käsitsi ühte serverisse ja riku seal midagi:

```bash
ssh <kasutaja>@<host1>
sudo rm /var/www/html/index.html
sudo systemctl stop nginx
exit
```

Server on nüüd triivinud: seda muudeti käsitsi ja see ei vasta enam koodis kirjeldatud olekule.

```bash
curl http://<host1>
```

Server ei vasta. Ära paranda seda käsitsi, käivita ainult playbook:

```bash
ansible-playbook -i inventory.ini site.yml
```

Vaata kokkuvõtet `PLAY RECAP`: `<host1>` näitab `changed` (Ansible leidis, et fail puudub ja teenus ei tööta, ning parandas need) ja `<host2>` näitab `ok` (see oli korras ja seda ei muudetud).

```bash
curl http://<host1>
```

Server vastab jälle. Sa ei andnud Ansible'ile käsku faili tagasi panna ega teenust käivitada. Ansible võrdles tegelikku olekut koodiga ja parandas erinevuse.

??? warning "Kui triiv ei parane"
    Playbook'is puudub `become: true` või roll ei halda seda faili. Kontrolli rolli ülesandeid ja `become` rida.

??? question "Mõtle"
    Playbook käivitub cron'iga iga tund. Mida tähendab, kui hommikul on ühes serveris `changed=5`, kuigi keegi ei tohtinud midagi muuta? Mida tähendab, kui kõik on alati `changed=0`? Kumb number on turvasignaal?

## Osa 7 · `host_vars`: ühe hosti erisus

Mõnikord vajab üks server erisust (näiteks teist porti), ilma et terve grupp muutuks. Selleks on `host_vars`.

Loo `host_vars/<host2>.yml` (failinimi on täpselt sama mis hosti nimi inventory's):

```yaml
nginx_port: 80
erimärkus: "See host on ainuke, millel on eriseade"
```

Lisa mallile rida:

```jinja2
{% if erimärkus is defined %}<p>{{ erimärkus }}</p>{% endif %}
```

Käivita playbook ja kontrolli:

```bash
ansible-playbook -i inventory.ini site.yml
curl http://<host1>
curl http://<host2>
```

Erimärkus on ainult hostis `<host2>`, sest `host_vars` on kitsam kui `group_vars`. Tingimus `{% if ... is defined %}` hoiab ära vea hostis, kus muutujat ei ole (Jinja2, nädal 4).

??? warning "Kui `host_vars` ei rakendu"
    Failinimi ei ole sama mis hosti nimi inventory's. Nimi peab klappima täht-tähelt.

??? question "Mõtle"
    Ulatusi on kolm: `all.yml` (kõik), `<grupp>.yml` (grupp) ja `host_vars/<host>.yml` (üks host). Kui sama muutuja on kõigis kolmes erineva väärtusega, milline võidab? Kontrolli vastust tabelist [Variable precedence](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable). Miks on mõistlik, et kitsam ulatus võidab?

## Osa 8 · Ansible ja Terraform: võrdlus tehtud töö põhjal

Nädalatel 10–11 kasutasid Terraformi, nüüd Ansible'it. Selles osas võrdled tööriistu oma tehtud töö põhjal. Taustaks sobib HashiCorpi leht [Terraform vs. Chef, Puppet, etc.](https://developer.hashicorp.com/terraform/intro/vs/chef-puppet).

Loo repositooriumisse fail `docs/week12/vordlus.md` (mitte sihtmasinasse) ja vasta küsimustele.

**Küsimus 1:** Sa just paigaldasid Ansible'iga nginx'i kahte serverisse. Kust need serverid **tulid**: kas Ansible lõi need või olid need juba olemas ja Ansible seadistas nende **sisu**? Milline tööriist oleks serverid ise **loonud**?

**Küsimus 2:** Terraform hoiab olekufaili (mäletab, mida ta lõi). Ansible ei hoia. Miks ei vaja Ansible idempotentsuseks olekufaili ja mida ta selle asemel iga kord teeb? (Vihje: osa 6, triiv.)

**Küsimus 3:** Kirjelda **üks** konkreetne töövoog, kus kasutaksid **mõlemat**: mida teeb Terraform, mida Ansible, mis järjekorras ja milline info liigub ühelt tööriistalt teisele.

Saada fail GitHubi. Nädala 7 konveier käivitub ka selle muudatuse peal.

??? note "Kontrollnimekiri"

    - Failis `inventory.ini` on mitu gruppi ja `ansible <grupp> --list-hosts` näitab õigeid hoste.
    - Üks `site.yml` seadistab kaks keskkonda, mõlemal on oma `keskkond` väärtus.
    - Kui muutuja on vales kohas, tead, mis vahe on failidel `all.yml`, `<grupp>.yml` ja `host_vars`.
    - Käsitsi tekitatud triivi parandab playbook: `<host1>` näitab `changed` ja `<host2>` näitab `ok`.
    - Oskad selgitada, miks `changed=0` tähendab, et triivi ei ole.
    - `vordlus.md` on repositooriumis: Ansible loob või seadistab, olekufail, kombineeritud töövoog.
    - `host_vars` annab ühele hostile erisuse ilma gruppi muutmata.

## Lisaülesanded

??? example "1 · `--limit`"
    käivita `site.yml` ainult ühes hostis (`--limit <host1>`). Millal on see tootmises kasulik?

??? example "2 · `--check` ja `--diff`"
    `ansible-playbook site.yml --check --diff` näitab, mida playbook **muudaks**, ilma muudatusi tegemata ([Check mode](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_checkmode.html)). Riku üks host käsitsi, käivita `--check --diff` ja vaata, kuidas triiv on näha ilma parandamata. Miks on see enne tootmist väga kasulik?

??? example "3 · `[production:children]`"
    tee grupp `all_web`, mis sisaldab nii gruppi `production` kui ka `staging`. Siht faili `site.yml` sellele grupile. Millal on grupp gruppidest kasulik?

??? example "4 · Vault mitmele keskkonnale"
    anna gruppidele `production` ja `staging` erinevad Vaultiga krüpteeritud paroolid (`group_vars/production/vault.yml`). Kuidas hoida kahte eri saladust sama koodiga? (Nädala 4 Vault ja selle nädala `group_vars`.)
