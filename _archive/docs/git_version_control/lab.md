# Git Versioonikontrolli Labor: Git & GitHub Praktiline Rakendamine

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Praktiliselt harjutada kõiki Git'i peamisi funktsioone ja GitHub workflow'd

---

## 1. Git Alused ja Kohalik Kasutamine

### 1.1 Git Seadistamine ja Esimene Repository

Enne Git'i kasutamist tuleb see korralikult seadistada. Git vajab kasutaja identiteeti, et teada, kes muudatusi teeb.

Avage terminal ja kontrollige, kas Git on teie arvutis installeeritud:

```bash
git --version
```bash

Kui Git ei ole installeeritud, installige see oma operatsioonisüsteemi jaoks.

Seadistage oma kasutajainfo (kasutage oma tegelikke andmeid):

```bash
git config --global user.name "Teie Nimi"
```text

Seadistage email:

```bash
git config --global user.email "teie.email@example.com"
```text

Kontrollige, et seadistused on õigesti salvestatud:

```bash
git config --list
```text

Valikuliselt määrake tekstiredaktor:

```bash
git config --global core.editor "code --wait"
```text

Looge uus kaust oma projektile:

```bash
mkdir git-practice-lab
```text

Minge selle kausta sisse:

```bash
cd git-practice-lab
```bash

Algatage selles kaustas Git repository:

```bash
git init
```text

Kontrollige repository olukorda:

```bash
git status
```text

Looge README fail käsitsi või käsureaga:

```bash
echo "# Git Praktika Projekt" > README.md
```text

Lisage faili veel sisu:

```bash
echo "See on Git'i õppimise projekt." >> README.md
echo "" >> README.md
echo "Siin harjutame kõiki Git'i põhifunktsioone." >> README.md
```text

Kontrollige uuesti repository olukorda:

```bash
git status
```text

Lisage README fail staging area'sse:

```bash
git add README.md
```text

Kontrollige olukorda pärast add käsku:

```bash
git status
```text

Tehke oma esimene commit:

```bash
git commit -m "Algne commit: lisa README fail"
```text

Vaadake commit'ide ajalugu:

```bash
git log
```text

Vaadake ka lühemat versiooni:

```bash
git log --oneline
```bash

**Kontrollpunkt:** Kontrollige, et teil on `.git` kaust ja üks commit ajaloos.

### 1.2 Failide Haldamine ja Workflow

Git'i põhiline töövoog koosneb kolmest etapist: töökataloog → staging area → repository. Harjutame seda workflow'd.

Looge uus Python fail nimega `kalkulaator.py`:

```bash
touch kalkulaator.py
```text

Avage fail tekstiredaktoris ja sisestage järgmine kood:

```python
def liida(a, b):
    """Liida kaks arvu."""
    return a + b

def lahuta(a, b):
    """Lahuta teine arv esimesest.""" 
    return a - b

if __name__ == "__main__":
    print("Kalkulaator: 5 + 3 =", liida(5, 3))
    print("Kalkulaator: 10 - 4 =", lahuta(10, 4))
```text

Salvestage fail ja sulgege redaktor.

Kontrollige repository olukorda:

```bash
git status
```text

Lisage fail staging area'sse:

```bash
git add kalkulaator.py
```text

Kontrollige olukorda pärast add käsku:

```bash
git status
```text

Tehke commit:

```bash
git commit -m "Lisa põhiline kalkulaator"
```text

Nüüd laiendame kalkulaatorit. Avage `kalkulaator.py` uuesti ja lisage faili lõppu:

```python

def korruta(a, b):
    """Korruta kaks arvu."""
    return a * b

def jaga(a, b):
    """Jaga esimene arv teisega."""
    if b != 0:
        return a / b
    return 'Viga: nulliga jagamine!'
```text

Salvestage fail.

Vaadake, millised muudatused on tehtud:

```bash
git diff
```text

Kontrollige repository olukorda:

```bash
git status
```text

Lisage muudatused staging area'sse:

```bash
git add kalkulaator.py
```text

Tehke commit:

```bash
git commit -m "Lisa korrutamise ja jagamise funktsioonid"
```text

```mermaid
graph TD
    WD[Töökataloog<br/>Working Directory]
    SA[Staging Area<br/>Index]
    LR[Repository<br/>Local]
    
    WD -->|git add| SA
    SA -->|git commit| LR
    LR -->|git checkout| WD
    
    style WD fill:#e1f5fe
    style SA fill:#fff3e0
    style LR fill:#e8f5e8
```bash

### 1.3 Täiendavad Git Operatsioonid

Looge uus Python fail:

```bash
touch tervitus.py
```text

Avage fail ja sisestage:

```python
print("Tere, Git maailm!")
```text

Salvestage fail.

Looge `.gitignore` fail:

```bash
touch .gitignore
```text

Avage `.gitignore` ja sisestage:

```
*.pyc
__pycache__/
.env
*.log
```text

Salvestage fail.

Lisage mõlemad failid korraga:

```bash
git add .
```text

Kontrollige olukorda:

```bash
git status
```text

Tehke commit:

```bash
git commit -m "Lisa tervitusskript ja gitignore"
```text

Nüüd harjutame muudatuste tagasivõtmist. Avage `kalkulaator.py` ja lisage faili lõppu:

```python
print("Vigane kood siin")
```text

Salvestage fail.

Vaadake muudatust:

```bash
git diff
```text

Võtke muudatus tagasi:

```bash
git restore kalkulaator.py
```text

Kontrollige, et muudatus on tagasi võetud:

```bash
git status
```bash

**Kontrollpunkt:** Teil peaks olema 3-4 commit'i erinevate failidega.

---

## 2. Branching ja Merging

### 2.1 Harude Loomine ja Arendamine

Git'i harud võimaldavad parallel arendust. Loome kaks erinevat feature haru.

Vaadake praeguseid harusid:

```bash
git branch
```text

Looge uus haru ja lülituge sellele:

```bash
git checkout -b feature/string-utils
```bash

Looge uus Python fail:

```bash
touch string_tools.py
```text

Avage fail ja sisestage:

```python
def pöörda_tekst(tekst):
    """Pööra tekst tagurpidi."""
    return tekst[::-1]

def loe_sõnu(tekst):
    """Loe sõnade arv tekstis."""
    return len(tekst.split())

def suure_tähega(tekst):
    """Muuda iga sõna esimene täht suureks."""
    return ' '.join(sõna.capitalize() for sõna in tekst.split())

if __name__ == "__main__":
    test_tekst = "tere git maailm"
    print("Algne:", test_tekst)
    print("Tagurpidi:", pöörda_tekst(test_tekst))
    print("Sõnade arv:", loe_sõnu(test_tekst))
    print("Suurtähtedega:", suure_tähega(test_tekst))
```text

Salvestage fail.

Lisage fail ja tehke commit:

```bash
git add string_tools.py
git commit -m "Lisa string'ide töötlemise moodul"
```text

Looge teine feature haru:

```bash
git checkout -b feature/advanced-math
```bash

Looge uus Python fail:

```bash
touch täpsem_matemaatika.py
```text

Avage fail ja sisestage:

```python
import math

def astenda(alus, eksponent):
    """Tõsta arv astmesse."""
    return alus ** eksponent

def ruutjuur(arv):
    """Arvuta ruutjuur."""
    if arv < 0:
        return "Viga: negatiivne arv"
    return math.sqrt(arv)

def faktoriaal(n):
    """Arvuta faktoriaal."""
    if n < 0:
        return "Viga: negatiivne arv"
    if n <= 1:
        return 1
    return n * faktoriaal(n - 1)

if __name__ == "__main__":
    print("2^3 =", astenda(2, 3))
    print("√16 =", ruutjuur(16))
    print("5! =", faktoriaal(5))
```text

Salvestage fail.

Lisage fail ja tehke commit:

```bash
git add täpsem_matemaatika.py
git commit -m "Lisa täpsema matemaatika moodul"
```text

Vaadake harude ajalugu graafiliselt:

```bash
git log --oneline --graph --all
```text

```mermaid
graph TD
    A[README] --> B[Kalkulaator]
    B --> C[Tervitus + .gitignore]
    C --> D[String tools]
    D --> E[Advanced math]
    
    style A fill:#e1f5fe
    style E fill:#c8e6c9
```text

### 2.2 Harude Merge'imine

Minge main harule:

```bash
git checkout main
```text

Merge'ige string-utils haru:

```bash
git merge feature/string-utils
```text

Testage tulemust:

```bash
python3 string_tools.py
```text

Merge'ige advanced-math haru:

```bash
git merge feature/advanced-math
```yaml

Testage:

```bash
python3 täpsem_matemaatika.py
```text

Vaadake lõplikku ajalugu:

```bash
git log --oneline --graph
```text

### 2.3 Merge Konfliktide Lahendamine

Loome tahtlikult merge konflikti, et harjutada selle lahendamist.

Looge konflikt tekitav haru:

```bash
git checkout -b fix/kalkulaator-väljund
```text

Avage `kalkulaator.py` ja muutke print laused:

```python
if __name__ == "__main__":
    print("KALKULAATOR: 5 + 3 =", liida(5, 3))
    print("KALKULAATOR: 10 - 4 =", lahuta(10, 4))
```text

Salvestage fail.

Lisage muudatus ja tehke commit:

```bash
git add kalkulaator.py
git commit -m "Muuda väljund suurtähtedega"
```text

Minge main harule:

```bash
git checkout main
```text

Avage `kalkulaator.py` ja muutke print laused teisiti:

```python
if __name__ == "__main__":
    print("Arvutus: 5 + 3 =", liida(5, 3))
    print("Arvutus: 10 - 4 =", lahuta(10, 4))
```text

Salvestage fail.

Lisage muudatus ja tehke commit:

```bash
git add kalkulaator.py
git commit -m "Muuda väljund lühemaks"
```text

Proovige merge'ida - tekib konflikt:

```bash
git merge fix/kalkulaator-väljund
```text

Vaadake konflikti:

```bash
cat kalkulaator.py
```text

Avage `kalkulaator.py` tekstiredaktoris ja lahendage konflikt. Eemaldage konfliktimärgid (`<<<<<<<`, `=======`, `>>>>>>>`) ja valige sobiv versioon.

Näiteks jätke:

```python
if __name__ == "__main__":
    print("KALKULAATOR: 5 + 3 =", liida(5, 3))
    print("KALKULAATOR: 10 - 4 =", lahuta(10, 4))
```text

Salvestage fail.

Lisage lahendatud fail:

```bash
git add kalkulaator.py
```text

Lõpetage merge:

```bash
git commit
```text

Kustutage kasutatud haru:

```bash
git branch -d fix/kalkulaator-väljund
```text

**Kontrollpunkt:** Olete edukalt merge konflikti lahendanud.

---

## 3. GitHub ja Remote Repositories

### 3.1 SSH Seadistamine GitHub'iga

SSH võtmed on turvaline viis GitHub'iga autentimiseks.

Kontrollige olemasolevaid SSH võtmeid:

```bash
ls -la ~/.ssh/
```text

Looge uus SSH võti (kasutage oma email'i):

```bash
ssh-keygen -t ed25519 -C "teie.email@example.com"
```text

Vajutage Enter vaikimisi failikoha jaoks.

Vajutage Enter tühja parooliga (või sisestage parool).

Käivitage SSH agent:

```bash
eval "$(ssh-agent -s)"
```text

Lisage võti SSH agentisse:

```bash
ssh-add ~/.ssh/id_ed25519
```text

Kopeerige avalik võti:

```bash
cat ~/.ssh/id_ed25519.pub
```text

**GitHub'is:**
1. Minge Settings → SSH and GPG keys
2. Klikkige "New SSH key"
3. Kleepige avalik võti
4. Salvestage

Testege SSH ühendust:

```bash
ssh -T git@github.com
```bash

### 3.2 Remote Repository ja Koostöö

**GitHub'is looge uus repository:**
1. Klikkige "New repository"
2. Nimi: `git-practice-lab`
3. Public repository
4. ÄRA lisage README (teil on juba olemas)
5. Create repository

Ühendage kohalik repo GitHub'iga:

```bash
git remote add origin git@github.com:TEIE-KASUTAJANIMI/git-practice-lab.git
```text

Kontrollige remote'e:

```bash
git remote -v
```text

Push'ige esimest korda:

```bash
git push -u origin main
```text

```mermaid
graph LR
    LR[Lokaalne<br/>Repository]
    RR[GitHub<br/>Repository]
    
    LR -->|git push| RR
    RR -->|git pull| LR
    RR -->|git clone| LR2[Teine kohalik<br/>Repository]
    
    style LR fill:#e8f5e8
    style RR fill:#fff3e0
    style LR2 fill:#e1f5fe
```text

### 3.3 Pull Requests ja Koostöö

Looge uus feature dokumentatsiooni jaoks:

```bash
git checkout -b feature/dokumentatsioon
```text

Looge uus fail:

```bash
touch KASUTAMINE.md
```text

Avage fail ja sisestage:

```markdown
# Git Praktika Projekti Kasutamine

## Failide kirjeldus

- `kalkulaator.py` - Põhilised matemaatilised operatsioonid
- `täpsem_matemaatika.py` - Keerukamad matemaatikafunktsioonid  
- `string_tools.py` - Tekstide töötlemise tööriistad
- `tervitus.py` - Lihtne tervitusprogramm

## Programmide käivitamine

```bash
python3 kalkulaator.py
python3 täpsem_matemaatika.py
python3 string_tools.py
python3 tervitus.py
```text

## Arendamisjuhised

1. Tehke uus feature haru
2. Arendage funktsioon
3. Testite koodi
4. Tehke commit
5. Looge Pull Request

## Testimine

Kõik programmid peaks töötama ilma vigadeta.
```

Salvestage fail.

Lisage fail ja tehke commit:

```bash
git add KASUTAMINE.md
git commit -m "Lisa kasutamise dokumentatsioon"
```text

Push'ige haru:

```bash
git push origin feature/dokumentatsioon
```text

**GitHub'is looge Pull Request:**
1. Minge oma repository lehele
2. Klikkige "Compare & pull request"
3. Kirjutage hea pealkiri ja kirjeldus
4. Create pull request
5. Review ja merge pull request
6. Delete branch

Kohalikult uuendage ja puhastage:

```bash
git checkout main
git pull origin main
git branch -d feature/dokumentatsioon
git remote prune origin
```bash

**Kontrollpunkt:** Olete edukalt teinud Pull Request workflow.

---

## 4. Täpsemad Git Funktsioonid

### 4.1 Git Stash - Ajutine Salvestamine

Alustage tööd. Avage `kalkulaator.py` ja lisage lõppu:

```python
# Pooleli olev funktsioon
# TODO: lõpeta see
```text

Salvestage fail.

Aga vajate kiirestina teist tööd teha:

```bash
git stash
```text

Kontrollige olukorda:

```bash
git status
```text

Tehke kiire parandus. Avage `README.md` ja lisage lõppu:

```markdown

## Viimati uuendatud
$(date)
```text

Salvestage fail.

Lisage ja commit'ige:

```bash
git add README.md
git commit -m "Lisa kuupäev README'sse"
```text

Taastage stash'itud töö:

```bash
git stash pop
```text

Lõpetage töö. Avage `kalkulaator.py` ja muutke kommentaar:

```python
# Pooleli olev funktsioon - nüüd valmis
print("Uus funktsioon lisatud!")
```text

Salvestage fail.

Lisage ja commit'ige:

```bash
git add kalkulaator.py
git commit -m "Lisa pooleli olnud funktsioon"
```bash

### 4.2 Git Rebase - Ajaloo Puhastamine

Looge mitu väikest commit'i. Looge fail:

```bash
touch VERSIOON.md
```text

Avage fail ja sisestage:

```markdown
# Versioon 1.0
```text

Salvestage, lisage ja commit'ige:

```bash
git add VERSIOON.md
git commit -m "Lisa versiooni fail"
```text

Avage `VERSIOON.md` uuesti ja lisage:

```markdown
- Kalkulaator
```text

Salvestage ja commit'ige:

```bash
git add VERSIOON.md
git commit -m "Lisa kalkulaator versiooni"
```text

Lisage veel:

```markdown
- String tools
```text

Commit'ige:

```bash
git add VERSIOON.md
git commit -m "Lisa string tools versiooni"
```text

Lisage veel:

```markdown
- Täpsem matemaatika
```text

Commit'ige:

```bash
git add VERSIOON.md
git commit -m "Lisa matemaatika versiooni"
```text

Ühendage viimased 4 commit'i üheks:

```bash
git rebase -i HEAD~4
```bash

Editor avaneb. Muutke viimased 3 "pick" → "squash" (või "s"). Salvestage ja sulgege. Uues editoris redigeerige commit sõnumit.

**Kontrollpunkt:** Oskate kasutada Git'i täpsemaid funktsioone.

---

## 5. Projekti Lõpetamine ja Hindamine

### 5.1 Lõplik Kontroll

Kontrollige projekti struktuuri:

```bash
ls -la
```bash

Vaadake Git ajalugu:

```bash
git log --oneline --graph -10
```text

Kontrollige remote'e:

```bash
git remote -v
```text

Kontrollige harusid:

```bash
git branch -a
```text

Vaadake viimased commit'id:

```bash
git log --oneline -5
```bash

Kontrollige Git seadistusi:

```bash
git config --list | grep user
```bash

### 5.2 Git Aliases - Boonusülesanne

Seadistage kasulikud lühendid:

```bash
git config --global alias.st status
```text

```bash
git config --global alias.co checkout
```text

```bash
git config --global alias.br branch
```text

```bash
git config --global alias.ci commit
```text

```bash
git config --global alias.lg 'log --oneline --graph --all'
```text

Testage aliaseid:

```bash
git st
git lg
```bash

---

## Esitamine ja Hindamine

**Esitamisnõuded:**
- GitHub repository link: `https://github.com/TEIE-KASUTAJANIMI/git-practice-lab`
- Repository peab sisaldama kõiki harjutuste faile
- Nähtav clean Git history
- Vähemalt üks Pull Request tehtud ja merge'itud
- README.md peab sisaldama projekti kirjeldust

**Hindamiskriteeriumid:**

| Kriteerium | Punktid | Kirjeldus |
|------------|---------|-----------|
| Repository seadistamine | 15% | Õige Git config, SSH seadistus |
| Põhilised Git käsud | 25% | add, commit, status, log |
| Branching ja merging | 25% | Harude loomine, merge'imine, konfliktide lahendamine |
| GitHub workflow | 20% | Remote repo, pull requests |
| Täpsemad funktsioonid | 10% | stash, rebase vms |
| Koodi kvaliteet | 5% | Clean history, head commit sõnumid |


**Õnnitleme! Olete läbinud Git'i põhilise praktika.**
