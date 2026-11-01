# SSH-võti PowerShellist Linuxi serveritesse

> Kui võti on loodud Windowsi PowerShellis, siis Linuxi juhendi käsud (`ssh-copy-id`)
> ei tööta ja avaliku võtme faili kopeerimisel tekib kodeeringu probleem.
> Windows PowerShell 5.1 salvestab ümbersuunamisel (`>`) faili kodeeringus UTF-16 koos BOM-iga
> ja lisab rea lõppu CRLF-i (`\r`). Sellise võtme lükkab server tagasi ilma selgituseta
> ja kasutaja näeb ainult teadet „Permission denied“.
> Seepärast suunatakse võti toru kaudu otse `ssh` abil serverisse ja vahepeal faili ei kirjutata.

## 1. Genereeri võti (PowerShell)

```powershell
# Loo ed25519 võtmepaar (tugevam ja lühem kui RSA)
ssh-keygen -t ed25519 -C "opilane@windows"
# Vajuta Enter -> võti salvestub siia:
#   privaatvõti:  C:\Users\<kasutaja>\.ssh\id_ed25519
#   avalik võti:  C:\Users\<kasutaja>\.ssh\id_ed25519.pub
# Parool (passphrase) on soovitatav.
```

## 2. Lisa avalik võti serverisse (ÕIGE käsk)

```powershell
# Torutab avaliku võtme otse serverisse. Faili ei kirjutata, seega kodeering ei rikne.
# Korda iga serveri kohta (server1, server2, server3).
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh kasutaja@server "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

> Käsku `ssh-copy-id` Windowsis ei ole, seega ära seda kasuta.
> Ära kasuta ka ümbersuunamist `>` (`... > authorized_keys`), sest just see rikub kodeeringu.

## 3. Logi sisse

```powershell
ssh kasutaja@server
# Kui ei tööta, vaata üksikasjalikku väljundit:
ssh -vvv kasutaja@server
# Otsi ridu: "Offering public key" ja "Server accepts key".
```

## 4. Õigused Linuxi serveris

```bash
chmod 700 ~/.ssh                      # kaust: ainult omanik
chmod 600 ~/.ssh/authorized_keys      # fail: ainult omanik
# Kodukaust EI tohi olla grupile/teistele kirjutatav:
chmod 750 ~                           # (või 700)
# Kui võti oli juba katki kopeeritud, eemalda CRLF:
sed -i 's/\r$//' ~/.ssh/authorized_keys
```

> SSH on failiõiguste suhtes range. Kui kausta `~/.ssh` või faili `authorized_keys` õigused
> on liiga laiad, jätab server võtme kasutamata ja klient ei näe selle kohta veateadet.
> Põhjus on kirjas serveri logis.

## 5. Õigused Windowsis (privaatvõti)

```powershell
cd $env:USERPROFILE\.ssh
# OpenSSH keeldub võtmest, mis on "liiga avatud" -> anna ligipääs ainult endale:
icacls id_ed25519 /inheritance:r
icacls id_ed25519 /grant:r "$($env:USERNAME):(R)"
```

## 6. ssh-agent (kui kasutad `ssh-add`)

```powershell
# Windowsis on teenus vaikimisi VÄLJAS -> lülita sisse, muidu ssh-add annab vea:
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

??? abstract "Kokkuvõte: miks Linuxi juhend Windowsis ei töötanud"
    Käsku `ssh-copy-id` Windowsis ei ole ja faili kirjutamisel läheb võti UTF-16 kodeeringu ja CRLF-reavahetuste tõttu katki.
    Lahendus on suunata võti toru kaudu otse `ssh` abil serverisse (punkt 2) ja kontrollida õigusi (punktid 4 ja 5).
