# SSH-võti PowerShellist Linuxi serveritesse

> Kui võti on tehtud Windowsi PowerShellis, siis Linuxi juhendi käsud (`ssh-copy-id`)
> ei tööta ja avaliku võtme faili kopeerimisel tekib **encoding-probleem**:
> PowerShell salvestab UTF-16 + BOM ja lisab rea lõppu CRLF (`\r`), mille peale
> server võtme vaikselt tagasi lükkab (näed ainult "Permission denied").
> Seepärast EI kirjutata võtit faili — see torutatakse otse `ssh` kaudu serverisse.

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
# Torutab avaliku võtme otse serverisse — ei kirjuta faili, seega EI riku encodingut.
# Korda iga serveri kohta (server1, server2, server3).
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh kasutaja@server "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

> `ssh-copy-id` Windowsis PUUDUB — ära seda käsku kasuta.
> Ära kasuta ka `>` ümbersuunamist (`... > authorized_keys`) — just see rikub kodeeringu.

## 3. Logi sisse

```powershell
ssh kasutaja@server
# Kui ei tööta, käivita diagnostikaga:
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

> SSH on õiguste suhtes range: kui `~/.ssh` või `authorized_keys` on liiga avatud,
> ignoreeritakse võtit ilma veateateta.

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

---

**Kokkuvõte, miks Linuxi juhend ei töötanud:**
`ssh-copy-id` puudub Windowsis, ja faili kirjutamisel läheb võti UTF-16/CRLF tõttu katki.
Lahendus: toruta võti otse `ssh` kaudu (punkt 2) ja kontrolli õigusi (punktid 4–5).
