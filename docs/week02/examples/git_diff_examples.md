# Git Diff ja Diff Väljundi Analüüs

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️
 
**Eesmärk:** Õppida lugema ja analüüsima diff väljundit versioonihalduse kontekstis

---

## Diff'i Roll Versioonihalduses

Diff on fundamentaalne tööriist, mis näitab failide vahelisi erinevusi. Moodsa tarkvaraarenduse kontekstis on diff'i lugemise oskus kriitilise tähtsusega mitmel põhjusel.

Code review protsessis analüüsivad arendajad diff'e, et mõista kolleegide tehtud muudatusi ja anda tagasisidet. Debugging'u käigus aitab diff tuvastada, millised muudatused võisid vea tekitada. Merge konfliktide lahendamisel on vaja täpselt mõista, kus ja miks konfliktid tekivad.

Git kasutab universaalset unified diff formaati, mis pärineb Unix/Linux maailmast ja on saanud de facto standardiks versioonihalduses.

---

## 1. Diff Väljundi Struktuur ja Süntaks

### 1.1 Unified Diff Anatoomia

Unified diff koosneb mitmest erinevast osast, millest igaüks kannab spetsiifilist informatsiooni:

```diff
--- original_file.py    2023-12-01 10:00:00 +0000
+++ modified_file.py    2023-12-01 10:05:00 +0000
@@ -5,7 +5,8 @@
 def process_data(data):
     if not data:
         return None
-    return data.strip()
+    cleaned = data.strip()
+    return cleaned.lower()
     
 def validate_input(input_str):
```text

**Struktuuri komponendid:**

**Faili header (`---` ja `+++` read):** Näitab võrreldavate failide nimesid ja ajatemplit. Konventsiooniliselt `---` märgib "vana" versiooni ja `+++` "uut" versiooni.

**Hunk header (`@@` rida):** Sisaldab kriitist informatsiooni muudatuste asukoha kohta. Formaat `@@ -old_start,old_count +new_start,new_count @@` näitab, et vanas failis algab muudatus realt `old_start` ja hõlmab `old_count` rida, uues failis algab realt `new_start` ja hõlmab `new_count` rida.

**Muudatuste read:** Iga rida algab ühe kolmest sümbolist:
- `-` (miinus) tähistab vanas failis olnud, kuid uuest eemaldatud rida
- `+` (pluss) tähistab uues failis lisatud rida
- ` ` (tühik) tähistab mõlemas failis muutumatuna säilinud kontekstirida

### 1.2 Konteksti Mõistmine

Unified diff sisaldab tavaliselt kolm kontekstirida enne ja pärast iga muudatust. See kontekst aitab:
- Täpselt lokaliseerida muudatuse asukohta
- Mõista muudatuse konteksti koodis
- Patch'ide rakendamisel õiges kohas paigutada

---

## 2. Praktilised Diff Analüüsi Näited

### 2.1 Lihtne Funktsiooni Täiustamine

Vaatleme järgmist näidet, kus täiustatakse kasutajanime valideerimise funktsiooni:

**Algne versioon (user_validator.py):**
```python
def validate_username(username):
    if len(username) < 3:
        return False
    if not username.isalnum():
        return False
    return True
```text

**Täiustatud versioon:**
```python
def validate_username(username):
    if not isinstance(username, str):
        raise TypeError("Username must be a string")
    if len(username) < 3:
        return False
    if len(username) > 20:
        return False
    if not username.isalnum():
        return False
    if username[0].isdigit():
        return False
    return True
```text

**Unified diff:**
```diff
--- user_validator.py	2023-12-01 10:00:00 +0000
+++ user_validator.py	2023-12-01 10:15:00 +0000
@@ -1,6 +1,12 @@
 def validate_username(username):
+    if not isinstance(username, str):
+        raise TypeError("Username must be a string")
     if len(username) < 3:
         return False
+    if len(username) > 20:
+        return False
     if not username.isalnum():
         return False
+    if username[0].isdigit():
+        return False
     return True
```text

**Analüüs:**
Diff näitab kolme olulist täiustust: tüübi kontroll, pikkuse ülempiiri kontroll ja numbriga algavate kasutajanimede keelamine. Muudatused on loogiliselt järjestatud ja ei mõjuta olemasolevat loogikat.

### 2.2 Keerukas Refaktoreerimine

Vaatleme keerukama näite puhul, kuidas diff aitab mõista arhitektuurilisi muudatusi:

**Algne versioon (data_manager.py):**
```python
import json

class DataManager:
    def __init__(self, filename):
        self.filename = filename
        self.data = self.load_data()
    
    def load_data(self):
        try:
            with open(self.filename, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            return {}
    
    def save_data(self):
        with open(self.filename, 'w') as f:
            json.dump(self.data, f)
    
    def get_value(self, key):
        return self.data.get(key)
    
    def set_value(self, key, value):
        self.data[key] = value
        self.save_data()
```text

**Refaktoreeritud versioon koos error handling'u ja logging'iga:**

**Diff väljund:**
```diff
--- data_manager.py	2023-12-01 10:00:00 +0000
+++ data_manager.py	2023-12-01 10:30:00 +0000
@@ -1,24 +1,42 @@
 import json
+import logging
+from pathlib import Path
 
 class DataManager:
     def __init__(self, filename):
-        self.filename = filename
+        self.filename = Path(filename)
         self.data = self.load_data()
+        self.logger = logging.getLogger(__name__)
     
     def load_data(self):
         try:
-            with open(self.filename, 'r') as f:
+            if not self.filename.exists():
+                self.logger.info(f"File {self.filename} does not exist, creating empty dataset")
+                return {}
+            
+            with self.filename.open('r') as f:
                 return json.load(f)
-        except FileNotFoundError:
+        except json.JSONDecodeError as e:
+            self.logger.error(f"Invalid JSON in {self.filename}: {e}")
             return {}
+        except PermissionError as e:
+            self.logger.error(f"Permission denied accessing {self.filename}: {e}")
+            raise
     
     def save_data(self):
-        with open(self.filename, 'w') as f:
-            json.dump(self.data, f)
+        try:
+            with self.filename.open('w') as f:
+                json.dump(self.data, f, indent=2)
+            self.logger.debug(f"Data saved to {self.filename}")
+        except PermissionError as e:
+            self.logger.error(f"Cannot save to {self.filename}: {e}")
+            raise
     
     def get_value(self, key):
         return self.data.get(key)
     
     def set_value(self, key, value):
+        old_value = self.data.get(key)
         self.data[key] = value
+        self.logger.debug(f"Updated {key}: {old_value} -> {value}")
         self.save_data()
```text

**Analüüsi sammud:**

Importide muudatused näitavad uute sõltuvuste lisamist - `logging` ja `pathlib.Path`.

Error handling on märkimisväärselt täiustatud - lihtne `FileNotFoundError` käsitlus on asendatud detailsema lähenemisega, mis käsitleb JSON decode vigu ja õiguste probleeme.

Logging funktsioonid on lisatud läbivalt kogu klassi, andes ülevaate operatsioonidest ja võimalikest probleemidest.

### 2.3 Merge Conflict Diff

Merge konfliktide puhul näeb diff teistsugune välja:

```diff
<<<<<<< HEAD
def calculate_total(items):
    return sum(item.price for item in items)
=======
def calculate_total(items):
    total = 0
    for item in items:
        total += item.price * (1 - item.discount)
    return total
>>>>>>> feature/discount-calculation
```bash

See näitab konflikti, kus üks branch kasutab lihtsat `sum()` funktsiooni, teine arvestab allahindlustega.

---

## 3. Git Diff Käsud ja Variandid

### 3.1 Töökataloog vs Staging Area

```bash
git diff
```text

See käsk näitab muudatusi, mis on tehtud töökataloogi failides, kuid pole veel staging area'sse lisatud:

```diff
diff --git a/app.py b/app.py
index 1a2b3c4..5d6e7f8 100644
--- a/app.py
+++ b/app.py
@@ -15,7 +15,8 @@ def main():
     config = load_configuration()
     
     if config.debug_mode:
-        print("Debug mode is enabled")
+        logger = setup_logging(config.log_level)
+        logger.info("Debug mode is enabled")
     
     app = create_application(config)
     return app.run()
```text

### 3.2 Staging Area vs Viimane Commit

```bash
git diff --staged
# või
git diff --cached
```text

Näitab, millised muudatused on staging area's ja lähevad järgmisse commit'i:

```diff
diff --git a/requirements.txt b/requirements.txt
index abcd123..efgh456 100644
--- a/requirements.txt
+++ b/requirements.txt
@@ -5,3 +5,4 @@ requests==2.28.1
 flask==2.2.2
 sqlalchemy==1.4.41
 pytest==7.1.3
+black==22.8.0
```text

### 3.3 Commit'ide Võrdlus

```bash
# Viimase kahe commit'i võrdlus
git diff HEAD~1 HEAD

# Konkreetsete commit'ide võrdlus
git diff abc123..def456

# Branch'ide võrdlus
git diff main..feature/new-api
```text

Näide branch'ide võrdlusest:

```diff
diff --git a/api/endpoints.py b/api/endpoints.py
index 1234567..890abcd 100644
--- a/api/endpoints.py
+++ b/api/endpoints.py
@@ -20,6 +20,15 @@ def get_user(user_id):
     except UserNotFound:
         return jsonify({'error': 'User not found'}), 404

+@app.route('/api/users', methods=['POST'])
+def create_user():
+    data = request.get_json()
+    try:
+        user = User.create(data)
+        return jsonify(user.to_dict()), 201
+    except ValidationError as e:
+        return jsonify({'error': str(e)}), 400
+
 @app.route('/api/health')
 def health_check():
     return jsonify({'status': 'healthy'})
```text

---

## 4. Diff Analüüsi Strateegia

### 4.1 Süstemaatiline Lähenemise Metoodika

**Esimene samm - Ülevaate saamine:** Alustage hunk header'ite vaatamisest, et mõista muudatuste mahu ja asukohta. Küsige endalt: kui palju faile on mõjutatud ja kui suured on muudatused?

**Teine samm - Konteksti mõistmine:** Vaadake kontekstiridu, et mõista, millises funktsioonis või meetodis muudatused toimuvad. See aitab mõista muudatuste eesmärki.

**Kolmas samm - Muudatuste tüüpide tuvastamine:** Eristage, kas tegemist on:
- Bug fix'iga (tavaliselt väikesed, fokuseeritud muudatused)
- Uue feature'i lisamisega (tavaliselt suuremad, mitut funktsiooni mõjutavad muudatused)
- Refaktoreerimisega (struktuuri muutused ilma funktsionaalsust muutmata)
- Performance optimiseerimisega

**Neljas samm - Mõju hindamine:** Analüüsige, kas muudatused võivad:
- Muuta API'd (breaking changes)
- Mõjutada performance'i
- Tuua kaasa uusi sõltuvusi
- Nõuda dokumentatsiooni uuendamist

### 4.2 Code Review Kontekstis

Code review käigus diff analüüsimisel keskenduge järgmistele aspektidele:

**Funktsionaalsus:** Kas kood teeb seda, mida peaks? Kas loogiline voog on õige?

**Loetavus:** Kas muudatused teevad koodi selgemaks või keerulisemaks?

**Testimine:** Kas on vaja lisada uusi teste? Kas olemasolevad testid vajavad uuendamist?

**Turvalisus:** Kas muudatused võivad tuua kaasa turvaprobleeme?

---

## 5. Tavalisemad Diff Mustrid

### 5.1 Import'ide Muudatused

```diff
 import os
 import sys
+import logging
+from datetime import datetime
 from pathlib import Path
-from typing import List
+from typing import List, Dict, Optional
```text

Selline muster näitab tavaliselt funktsionaalsuse laiendamist.

### 5.2 Konfiguratsiooni Muudatused

```diff
 config = {
     'database_url': 'postgresql://localhost/mydb',
     'debug': True,
-    'log_level': 'INFO'
+    'log_level': 'DEBUG',
+    'cache_timeout': 300,
+    'api_rate_limit': 1000
 }
```text

### 5.3 Error Handling Täiustamine

```diff
 def process_file(filename):
-    with open(filename, 'r') as f:
-        return f.read()
+    try:
+        with open(filename, 'r') as f:
+            return f.read()
+    except FileNotFoundError:
+        logger.error(f"File {filename} not found")
+        return None
+    except PermissionError:
+        logger.error(f"Permission denied for {filename}")
+        raise
```text

---

## 6. Harjutused ja Praktilised Ülesanded

### 6.1 Diff Analüüsi Harjutus

Analüüsige järgmist diff'i:

```diff
--- calculator.py	2023-12-01 10:00:00 +0000
+++ calculator.py	2023-12-01 10:15:00 +0000
@@ -1,12 +1,19 @@
+import math
+
 def add(a, b):
     return a + b

 def subtract(a, b):
     return a - b

-def multiply(a, b):
-    return a * b
+def multiply(*args):
+    result = 1
+    for num in args:
+        result *= num
+    return result

-def divide(a, b):
-    return a / b
+def divide(a, b):
+    if b == 0:
+        raise ValueError("Cannot divide by zero")
+    return a / b

+def power(base, exponent):
+    return math.pow(base, exponent)
```text

**Analüüsi küsimused:**

1. Millised on peamised muudatused?
2. Kas mõni muudatus on breaking change?
3. Millised on turva- või vigade seisukohast olulised parandused?
4. Kas kood on muutunud paremaks?

### 6.2 Merge Conflict Analüüs

```diff
<<<<<<< HEAD
def send_notification(user, message):
    if user.email_enabled:
        send_email(user.email, message)
=======
def send_notification(user, message):
    if user.notification_preferences.email:
        email_service.send(user.email, message)
    if user.notification_preferences.sms:
        sms_service.send(user.phone, message)
>>>>>>> feature/multi-channel-notifications
```bash

Analüüsige konflikti ja kirjeldage, kuidas seda lahendada.

---

## 7. Täiendavad Diff Tööriistad ja Tehnikad

### 7.1 Graafilised Diff Tööriistad

Käsurea kõrval on kasulikud ka graafilised tööriistad:

- **VS Code** built-in diff viewer
- **GitKraken** visuaalne Git klient
- **Meld** cross-platform diff tööriist
- **Beyond Compare** kommertsiaal diff tööriist

### 7.2 Spetsialiseeritud Git Diff Käsud

```bash
# Ainult failide nimed
git diff --name-only

# Statistika muudatuste kohta
git diff --stat

# Sõnade tasemel diff
git diff --word-diff

# Ignore whitespace muudatused
git diff -w

# Show function context
git diff --function-context
```bash

### 7.3 Custom Diff Drivers

Git võimaldab seadistada erinevaid diff driver'eid konkreetsete failitüüpide jaoks:

```bash
# .gitattributes failis
*.py diff=python
*.md diff=markdown
```text

---

## Kokkuvõte

Diff'i lugemise oskus on fundamentaalne versioonihalduses. See võimaldab:

**Mõista muudatuste konteksti** - näha, miks ja kuidas kood muutus
**Teha kvaliteetseid code review'sid** - analüüsida kolleegide tööd
**Lahendada merge konflikte** - mõista konfliktide põhjuseid
**Debug'ida efektiivselt** - leida, millised muudatused vigu tekitasid
**Jälgida projekti arengut** - mõista koodi evolusiooni

Regulaarne harjutamine erinevate diff'ide analüüsimisega arendab intuitsiooni koodi muudatuste mõistmisel ja teeb tööst versioonihaldussüsteemidega palju efektiivsema.

Diff'i lugemise oskus on investeering, mis tasub end ära kogu programmeerimiskarjääri vältel.
