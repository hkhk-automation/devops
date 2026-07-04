# Git Projekti Portfolio - Kodutöö

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Demonstreerida Git'i ja GitHub'i oskusi praktilise töö kaudu  

---

## Ülesande Kirjeldus

Looge lihtne projekt, mis demonstreerib kõiki Git'i ja GitHub'i peamisi oskusi. **Fookus on Git workflow'l, mitte koodi keerukusel.** Teie ülesanne on luua töötav Git/GitHub repositoorium koos õige branching strateegiaga.

## Oluline: Õige Git Flow

```mermaid
graph TD
    A[Initial] --> B[Setup]
    B --> C[Add script]
    C --> D[Add docs]
    D --> E[Feature merged]
    E --> F[Release v1.0]
    
    style A fill:#e1f5fe
    style F fill:#c8e6c9
```bash

**ALATI järgige:** feature → develop → main

**MITTE KUNAGI:** feature → main

---

## 1. Repository Loomine ja Seadistamine

### 1.1 GitHub Repository Loomine

Minge GitHub'i ja looge uus repository:

1. Klikkige rohelist "New" nuppu
2. Repository nimi: `its-git-demo` (või oma valik)
3. Tehke repository Public
4. Märkige "Add a README file"
5. Märkige "Add .gitignore" ja valige "Node" template
6. Märkige "Choose a license" ja valige "MIT License"
7. Klikkige "Create repository"

### 1.2 Repository Kloonimine

Kloonige repositoorium oma arvutisse:

```bash
git clone https://github.com/TEIE-KASUTAJANIMI/its-git-demo.git
cd its-git-demo
```text

### 1.3 Põhifailide Loomine

Muutke README.md faili ja lisage lõppu:

```markdown

## Projekti eesmärk
See projekt demonstreerib Git'i ja GitHub'i oskusi.
```text

Muutke .gitignore faili - lisage lõppu:

```
*.log
*.tmp
.env
```text

Tehke esimene commit:

```bash
git add .
git commit -m "docs: update README and gitignore"
git push origin main
```text

**Kontrollpunkt:** GitHub'is peaks näha teie commit'i.

---

## 2. Branching Strateegia Seadistamine

### 2.1 Develop Branch Loomine

Looge develop branch main'ist:

```bash
git checkout -b develop
```text

Push'ige develop branch GitHub'i:

```bash
git push origin develop
```text

### 2.2 Feature Branch Loomine

Looge feature branch develop'ist:

```bash
git checkout -b feature/system-info
```text

**Kontrollpunkt:** Teil peaks olema 3 branch'i: main, develop, feature/system-info.

---

## 3. Põhifunktsionaalsuse Arendamine

### 3.1 System Info Script Loomine

Looge fail nimega `system_info.sh`:

```bash
touch system_info.sh
```text

Avage fail tekstiredaktoris ja sisestage:

```bash
#!/bin/bash
echo "=== System Information ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Current directory: $(pwd)"
echo "Home directory: $HOME"
echo ""
echo "=== Disk Usage ==="
df -h | head -5
echo ""
echo "=== Memory Info ==="
free -h 2>/dev/null || echo "Memory info not available"
echo ""
echo "Script completed successfully!"
```text

Salvestage fail.

Tehke script käivitatavaks:

```bash
chmod +x system_info.sh
```text

Testige script'i:

```bash
./system_info.sh
```text

### 3.2 Dokumentatsiooni Loomine

Looge fail nimega `USAGE.md`:

```bash
touch USAGE.md
```text

Avage fail ja sisestage:

```markdown
# Usage Guide

## System Info Script

### Purpose
Shows basic system information.

### Usage
```bash
./system_info.sh
```text

### Output
Script displays:
- Current date and time
- Current user name
- Current directory path
- Disk usage information
- Memory information

### Requirements
- Bash shell
- Unix/Linux system
```

Salvestage fail.

### 3.3 GitHub Actions Seadistamine

Looge kataloogid:

```bash
mkdir -p .github/workflows
```text

Looge fail `.github/workflows/test.yml`:

```bash
touch .github/workflows/test.yml
```text

Avage fail ja sisestage:

```yaml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - run: |
        bash -n system_info.sh
        chmod +x system_info.sh
        ./system_info.sh
```text

Salvestage fail.

### 3.4 Muudatuste Commit'imine

Lisage kõik failid:

```bash
git add .
```text

Kontrollige olukorda:

```bash
git status
```text

Tehke commit:

```bash
git commit -m "feat: add system info script and documentation"
```text

Push'ige feature branch:

```bash
git push origin feature/system-info
```yaml

**Kontrollpunkt:** GitHub'is peaks näha teie feature branch'i.

---

## 4. GitHub Features Kasutamine

### 4.1 Issues Loomine

Minge GitHub'i oma repository lehele:

1. Klikkige "Issues" tab'i
2. Klikkige "New issue"
3. Pealkiri: "Add system info script"
4. Kirjeldus: "Need to create a script that shows system information"
5. Lisage label "enhancement"
6. Create issue

Looge teine issue:

1. Pealkiri: "Improve documentation"
2. Kirjeldus: "Add usage documentation for the scripts"
3. Lisage label "documentation"
4. Create issue

### 4.2 Pull Request Loomine

GitHub'is:

1. Klikkige "Pull requests" tab'i
2. Klikkige "New pull request"
3. Base branch: `develop` (OLULINE!)
4. Compare branch: `feature/system-info`
5. Pealkiri: "feat: add system info script and docs"
6. Kirjeldus: "This PR adds system information script with documentation. Closes #1"
7. Create pull request
8. Merge pull request
9. Delete branch

### 4.3 Cleanup pärast Merge'i

Kohalikult:

```bash
git checkout develop
git pull origin develop
git branch -d feature/system-info
git push origin --delete feature/system-info
```bash

### 4.4 GitHub Actions Kontrollimine

Minge GitHub'is "Actions" tab'ile ja kontrollige, et workflow töötab.

**Kontrollpunkt:** Actions peaks näitama rohelist checkmark'i.

---

## 5. Advanced Git Features

### 5.1 Merge Conflict Loomine ja Lahendamine

Develop branch'is:

```bash
git checkout develop
```text

Avage `README.md` ja lisage lõppu:

```markdown

## Status
Development version - active work in progress.
```text

Commit'ige:

```bash
git commit -am "docs: update status in develop"
```text

Main branch'is:

```bash
git checkout main
```text

Avage `README.md` ja lisage sama koha lähedale:

```markdown

## Status
Stable release version.
```text

Commit'ige:

```bash
git commit -am "docs: update status in main"
```text

Proovige merge'ida develop → main:

```bash
git merge develop
```bash

Git teeb konflikti! Avage `README.md` ja lahendage konflikt:

1. Leidke konfliktimärgid (`<<<<<<<`, `=======`, `>>>>>>>`)
2. Otsustage, millist versiooni hoida
3. Eemaldage konfliktimärgid
4. Salvestage fail

Lõpetage merge:

```bash
git add README.md
git commit
```text

### 5.2 Tagged Release Loomine

Tag'ige praegune versioon:

```bash
git tag v1.0.0
```text

Push'ige tag:

```bash
git push origin v1.0.0
```text

GitHub'is looge Release:

1. Minge "Releases" → "Create a new release"
2. Tag: v1.0.0
3. Title: "Version 1.0.0"
4. Kirjeldus: "First stable release with system info script"
5. Publish release

**Kontrollpunkt:** GitHub'is peaks näha v1.0.0 release'i.

---

## 6. Projekti Lõpetamine

### 6.1 README Uuendamine

Minge develop branch'ile:

```bash
git checkout develop
```text

Avage `README.md` ja asendage kogu sisu:

```markdown
# Git Demo Project

Lihtne projekt Git ja GitHub oskuste demonstreerimiseks.

## Projekti eesmärgid
See projekt näitab:
- Git branching ja merging
- GitHub collaboration
- Automatiseeritud testimine
- Dokumentatsiooni haldus

## Git Oskused
- Repository seadistamine
- Feature branch workflow
- Merge conflict lahendamine
- Pull Request'id
- GitHub Actions
- Tagged release'id

## Failid
- `system_info.sh` - Süsteemi info script
- `USAGE.md` - Kasutamise juhend
- `.github/workflows/test.yml` - Automaatne testimine

## Kasutamine
```bash
./system_info.sh
```bash

See on õppeprojekt Git workflow demonstreerimiseks.
```

Commit'ige:

```bash
git commit -am "docs: update project README"
```text

### 6.2 Lõplik Release

Merge develop → main:

```bash
git checkout main
git merge develop
```text

Tag'ige uus versioon:

```bash
git tag v1.1.0
```text

Push'ige kõik:

```bash
git push origin main
git push origin develop
git push origin v1.1.0
```bash

GitHub'is looge v1.1.0 release.

---

## Esitamine

**Esitage GitHub repository link:**

`https://github.com/TEIE-KASUTAJANIMI/its-git-demo`

**Repository peab sisaldama:**
- Vähemalt 10 commit'i
- Mitut branch'i (main, develop, feature)
- Issues ja Pull Request'id
- Töötavat GitHub Actions workflow'd
- Vähemalt 2 tagged release'i
- Merge conflict'i lahendamist commit'ides
- Kvaliteetseid commit sõnumeid
