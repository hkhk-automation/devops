# Git Käsude Dokumentatsioon

## Põhikäsud

### 1. Projekti alustamine
```bash
git init                    # Loo uus Git repository
git clone <url>            # Kopeeri olemasolev repository
```

### 2. Failide haldamine
```bash
git add <fail>             # Lisa fail staging area'sse
git add .                  # Lisa kõik failid
git commit -m "sõnum"      # Salvesta muudatused
git status                 # Vaata olekut
```

### 3. Harude haldamine
```bash
git branch                 # Näita kõiki harusid
git branch <nimi>          # Loo uus haru
git checkout <nimi>        # Mingi haru
git checkout -b <nimi>     # Loo ja mingi haru
git merge <nimi>           # Ühenda harud
```

### 4. Serveriga suhtlemine
```bash
git push origin <haru>     # Saada muudatused serverisse
git pull origin <haru>     # Võta muudatused serverist
git fetch origin           # Võta teave serverist
```

## Täiendavad käsud

### 5. Ajaloo vaatamine
```bash
git log                    # Näita kõiki commit'e
git log --oneline          # Lühike ajalugu
git log --graph            # Visuaalne ajalugu
```

### 6. Muudatuste haldamine
```bash
git stash                  # Peida muudatused
git stash pop              # Taasta muudatused
git reset --soft HEAD~1    # Eemalda viimane commit
```

### 7. Konfliktide lahendamine
```bash
git diff                   # Vaata erinevusi
git merge --abort          # Tühista merge
git rebase                 # Korralda ajalugu
```

## Praktilised näited

### Uue projekti alustamine
```bash
mkdir minu-projekt
cd minu-projekt
git init
echo "# Minu Projekt" > README.md
git add README.md
git commit -m "Lisa README"
```

### Haru töö
```bash
git checkout -b uus-funktsioon
# Tee muudatusi...
git add .
git commit -m "Lisa uus funktsioon"
git checkout main
git merge uus-funktsioon
```

### Cherry-pick näide
```bash
git log --oneline
# abc1234 Lisa funktsioon
# def5678 Paranda viga
git cherry-pick def5678
```
