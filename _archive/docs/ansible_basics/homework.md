# LAMP Stack Playbook

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Õppida Ansible playbook'i loomist praktiliselt ja iseseisvalt lahendamist ja uurimist

---

## Ülesande kirjeldus

See kodutöö ei anna valmis koodi - see annab probleemid lahendamiseks! Kasutage lab'is õpitud oskusi ja Ansible dokumentatsiooni, et ehitada LAMP stack samm-sammult.

**Põhimõte:** Igal sammul antakse ülesanne, kontrollviis ja nõuanded. Kood peate ise kirjutama!

---

## 1. Projekti seadistamine

### 1.1 Looge projekti struktuur

**Mida vaja teha:**
Looge järgmine kataloogide ja failide struktuur (kasutage `mkdir` ja `touch` käske):

```bash
ansible-lamp/
├── inventory/
│   └── hosts.yml
├── group_vars/
│   └── webservers.yml  
├── templates/
│   ├── (failid lisate hiljem)
├── lamp-stack.yml
├── ansible.cfg
└── README.md
```

**Kontroll:** `tree ansible-lamp` peaks näitama õiget struktuuri

**Küsimus:** Miks kasutame group_vars/ kausta? (Vastake README.md'sse)

---

## 2. Inventory seadistamine

### 2.1 Inventory fail

**Probleem:** Vajate inventory faili, mis töötab nii localhost'iga kui ka teise serveriga.

**Nõuded:**
- Looge YAML formaat inventory (kasutage lab'is õpitut)
- Gruppi nimi: `webservers`
- Localhost peab kasutama `ansible_connection: local`
- Jätke kommentaaridesse näide teise serveri lisamiseks

**Fail:** `inventory/hosts.yml`

**Kontroll:** `ansible-inventory --list` peaks näitama teie servereid

🔍 **Uurige:** Käivitage `ansible webservers -m ping` - kas töötab?

### 2.2 Muutujate defineerimine

**Probleem:** LAMP stack vajab palju konfiguratsiooni. Kus muutujaid hoida?

**Nõuded:** Looge `group_vars/webservers.yml` ja defineerige:
- MySQL root parool
- Rakenduse andmebaasi nimi  
- Rakenduse kasutaja nimi ja parool
- PHP pakettide loend
- Document root tee
- Rakenduse nimi ja versioon

**Näpunäide:** Vaadake lab'i näiteid muutujate kohta

🤔 **Mõelge:** Millised muutujad peaksid olema "salajased"? Kuidas neid hiljem kaitsta?

**Kontroll:** `ansible webservers -m debug -a "var=hostvars[inventory_hostname]"` - kas näete oma muutujaid?

---

## 3. Vigane playbook parandamine

### 3.1 Parandage see vigane playbook

**Antud on vigane playbook algus. Leidke ja parandage vead:**

```yaml
---
- name: LAMP Stack Setup
  hosts: all                    # <- VIGA 1: vale grupp
  become: true
  
  tasks:
    - name: Update cache
      package:
        update_cache: true      # <- VIGA 2: vale moodul
        
    - name: Install Apache
      apt:
        name: apache            # <- VIGA 3: vale paketi nimi
        state: present
      notify: restart apache
      
    - name: Start Apache
      systemd:                  # <- VIGA 4: miks mitte service?
        name: apache2
        state: started
        
  handlers:                     # <- VIGA 5: handlers vale kohas?
    - name: restart apache
      service:
        name: apache2
        state: restarted
```bash

**Ülesanne:** 
1. Kopeerige see kood faili `lamp-stack.yml`
2. Leidke kõik 5+ viga
3. Parandage need
4. Lisage proper YAML vormistus (`---` alguses)

**Kontroll:** `ansible-playbook --syntax-check lamp-stack.yml`

🔍 **Uurige:** Mis vahe on `package` ja `apt` moodulil? Kumb on parem?

---

## 4. MySQL seadistamine

### 4.1 MySQL installimine ja turvamine

**Probleem:** MySQL vajab spetsiaalset seadistamist. Lab'is nägite lihtsaid näiteid.

**Teie ülesanne:**
1. Installige `mysql-server` ja `python3-pymysql`
2. Käivitage MySQL teenus
3. Seadke MySQL root kasutajale parool (kasutage group_vars muutujat)
4. Looge rakenduse andmebaas
5. Looge rakenduse kasutaja õigustega ainult sellele andmebaasile

**Moodulid, mida vajate:**
- `package` või `apt`
- `service` 
- `mysql_user`
- `mysql_db`

**Nõuanded:**
- MySQL root parooli seadistamine on keeruline - uurige `login_unix_socket` parameetrit
- `mysql_user` moodul vajab `login_user` ja `login_password` parameetrit
- Kasutage `priv: "database_name.*:ALL"` õigusteks

📚 **Uurige dokumentatsiooni:** `ansible-doc mysql_user`

**Kontroll:** 
```bash
mysql -u [teie_kasutaja] -p [teie_andmebaas] -e "SELECT 'Success!' as test;"
```text

🔍 **Debugimise küsimus:** Kui MySQL ühendus ei tööta, kuidas te viga otsite?

---

## 5. Template'ide loomine

### 5.1 Puudulik PHP template

**Antud on template algus. Lõpetage see:**

**Fail:** `templates/info.php.j2`

```php
<?php
// {{ app_name }} - Info leht
// TODO: lisage kuupäev kasutades ansible muutujat

echo "<h1>{{ ??? }}</h1>";  // TODO: kasutage app_name muutujat

echo "<h2>Serveri info</h2>";
// TODO: lisage hostname, IP, OS info

echo "<h2>MySQL test</h2>";
$host = 'localhost';
$database = '{{ ??? }}';  // TODO: kasutage õiget muutujat
$username = '{{ ??? }}';  // TODO: kasutage õiget muutujat  
$password = '{{ ??? }}';  // TODO: kasutage õiget muutujat

try {
    // TODO: kirjutage PDO ühenduse test
    // Kui õnnestub, näidake "Ühendus töötab!"
    // Kui ebaõnnestub, näidake error'it
} catch(PDOException $e) {
    // TODO: error handling
}

// TODO: lisage phpinfo() kutse
?>
```bash

**Ülesanne:**
1. Asendage kõik `{{ ??? }}` õigete muutujatega
2. Implementeerige MySQL PDO ühenduse test
3. Lisage proper error handling
4. Lisage phpinfo() väljund

**Nõuanded:**
- Vaadake lab'i template näiteid
- Ansible faktid: `{{ ansible_hostname }}`, `{{ ansible_default_ipv4.address }}`
- PHP PDO: `new PDO("mysql:host=$host;dbname=$database", $username, $password)`

**Kontroll:** PHP ei tohi sisaldada `{{ ??? }}` märke

### 5.2 HTML põhileht loomine

**Probleem:** Vajate ilusat HTML lehte, mis näitab LAMP stack'i infot.

**Nõuded:**
- Kasutage template'i `templates/index.html.j2`
- Näidake serveri infot (hostname, OS, kuupäev)
- Lisage link `/info.php` lehele
- Kasutage CSS'i, et see oleks ilus
- Kõik info peab tulema Ansible muutujatest/faktidest

💡 **Inspiratsioon:** Vaadake lab'i HTML näidet, aga ärge kopeerige!

🏆 **Väljakutse:** Kas oskate lisada JavaScripti, mis näitab praegust kellaaega?

**Kontroll:** HTML peab valideeruma (saate kontrollida https://validator.w3.org/)

---

## 6. Playbook lõpetamine

### 6.1 Tasks'ide implementeerimine

**Nüüd implementeerige playbook tasks'id:**

**Vajalikud sammud (kirjutage ise task'id):**
1. **Süsteemi ettevalmistus** - pakettide cache uuendamine
2. **Apache seadistamine** - installimine, käivitamine, document root loomine
3. **MySQL seadistamine** - (juba tegite sektsioonis 4)
4. **PHP seadistamine** - installimine koos moodulikega
5. **Template'ide deployment** - kopeerige template'id õigetesse kohtadesse
6. **Firewall** - lubage HTTP trafik
7. **Valideerimised** - kontrollige, et kõik töötab

💡 **Nõuanne:** Iga task vajab:
- Selget `name` välja
- Õiget moodulit
- Proper parameetreid
- Vajadusel `notify` handler'eid

**Tüüpilised moodulid:**
- `package`/`apt` - pakettide installimine
- `service` - teenuste haldamine
- `file` - kaustade loomine
- `template` - template'ide kopeerimine
- `uri` - HTTP testid
- `ufw` - firewall reeglid

🤔 **Küsimus:** Millises järjekorras task'id käivitada? Miks?

### 6.2 Handlers ja error handling

**Probleem:** Playbook peab olema robust ja käsitlema vigu.

**Nõuded:**
1. **Handlers** - Apache ja MySQL taaskäivitamise jaoks
2. **Error handling** - kasutage `failed_when`, `ignore_errors`, `retries`
3. **Valideerimised** - kontrollige teenuste olekut ja HTTP vastuseid
4. **Conditional tasks** - näiteks ainult Debian/Ubuntu süsteemides

**Näited error handling'ust:**
```yaml
- name: Test HTTP
  uri:
    url: http://localhost
  retries: 3
  delay: 10
  register: http_test
  failed_when: http_test.status != 200
```text

🤔 **Mõelge:** Millal kasutada `ignore_errors: yes` ja millal mitte?

---

## 7. Testimine ja debugimine

### 7.1 Systematic testimine

**Probleem:** Kuidas te veendute, et teie playbook töötab?

**Teie testiplaan:**
1. **Syntax check** - ?
2. **Dry run** - ?  
3. **Tegelik käivitamine** - ?
4. **Manuaalne testimine** - ?
5. **Idempotency test** - ?

**Täitke küsimärgid ja tehke iga test!**

💡 **Nõuanne:** Iga testi järel dokumenteerige tulemused

**Debugimise küsimused:**
- Kui Apache ei käivitu, kuidas te viga otsite?
- Kui MySQL ühendus ei tööta, millised logid vaatate?
- Kui template ei genereeru, kuidas te seda debugite?

### 7.2 Vigade parandamine

**Antud on levinud vead. Kas tunnete neid ära?**

**Viga 1:**
```
TASK [Install PHP] ****
fatal: [localhost]: FAILED! => {"msg": "No package matching 'php' found"}
```text
**Küsimus:** Mis probleem? Kuidas parandada?

**Viga 2:**
```
TASK [Test MySQL connection] ****
fatal: [localhost]: FAILED! => {"msg": "unable to connect to database"}
```text
**Küsimus:** Võimalikud põhjused? Kuidas debugida?

**Viga 3:**
```
TASK [Generate index.html] ****
fatal: [localhost]: FAILED! => {"msg": "template not found"}
```text
**Küsimus:** Mida kontrollida?

**Ülesanne:** Kirjutage README.md'sse troubleshooting sektsioon nende vigade jaoks!

---

## 8. Dokumenteerimine

### 8.1 README.md loomine

**Probleem:** Keegi teine peab teie projekti kasutama. Mis infot ta vajab?

**Nõutavad sektsioonid:**
1. **Projekt kirjeldus** - mis see teeb?
2. **Eeltingimused** - mida vaja installimisel?
3. **Kasutamise juhend** - sammhaaval käivitamine
4. **Konfiguratsioon** - kuidas muutujaid muuta?
5. **Testimine** - kuidas kontrollida, et töötab?
6. **Troubleshooting** - levinud probleemid ja lahendused
7. **Projekti struktuur** - failide selgitus

 **Test:** Andke README.md kolleegile - kas ta saab projekti käivitada?

### 8.2 Koodikommentaarid

**Probleem:** Teie playbook peab olema loetav ja mõistetav.

**Nõuded:**
- Iga task vajab selget `name` välja
- Keerulised osad vajavad kommentaare
- Muutujad vajavad selgitusi
- Template'id vajavad dokumenteerimist

**Näide heast kommentaarist:**
```yaml
# MySQL root parooli seadistamine on keeruline, sest:
# 1. Pärast installimist pole parool seatud
# 2. Kasutame unix_socket autentimist
# 3. Seejärel määrame parooli ja lülitume password auth'ile
- name: "Seadista MySQL root parool (esimene kord)"
  mysql_user:
    # ... resto kood
```bash

---

## 9. Esitamine

### 9.1 Repository link

Esitage **GitHub repository link** kursuse süsteemi järgmiste nõuetega:

**Repository peab sisaldama:**
- Täielikku funktsionaalset Ansible projekti
- README.md täieliku dokumentatsiooniga  
- Screenshot'e või video tõendusmaterjali
- Deployment logisid

**Repository peab olema:**
- Public (et õppejõud saaks üle vaadata)
- Korrektselt nimetatud (`ansible-lamp-practice` või sarnane)
- Professionaalselt organiseeritud

**Peab olema võimalik:**
- Repository kloonida
- Juhendite järgi setup teha
- Playbook edukalt käivitada
- Tulemust valideerida

**🎯 Edu!** Alustage kohe ja küsige abi, kui jääte kinni!
