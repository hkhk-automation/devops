# SSH-võtme lisamine Linuxi serverisse PowerShelli kaudu

Windowsi OpenSSH-kliendis ei ole käsku `ssh-copy-id`. Avaliku võtme saab Linuxi serverisse lisada PowerShelli kaudu. Windows PowerShell 5.1 salvestab vaikimisi ümbersuunamisel (`>`) faili kodeeringus UTF-16LE ([PowerShelli kodeering](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding)). Selline fail ei sobi võtmefailiks. Seepärast edastad selles juhendis võtme otse SSH-ühenduse kaudu ja Windowsis vahefaili ei loo.

Kursusel kasutad võtit `kursus_ed25519`, sama mis [praktikumis](lab.md).

## 1. Loo võtmepaar

Võtmepaar luuakse sama käsuga nagu Linuxis. Kui sul on võti `kursus_ed25519` juba olemas, ära kirjuta seda üle: kui `ssh-keygen` küsib `Overwrite (y/n)?`, vasta `n`.

```powershell
ssh-keygen -t ed25519 -C "eesnimi@kool" -f "$env:USERPROFILE\.ssh\kursus_ed25519"
# privaatvõti:  C:\Users\<kasutaja>\.ssh\kursus_ed25519
# avalik võti:  C:\Users\<kasutaja>\.ssh\kursus_ed25519.pub
```

Privaatvõtit on soovitatav kaitsta paroolifraasiga (passphrase).

## 2. Lisa avalik võti serverisse

Käsk loeb avaliku võtme ja edastab selle toru kaudu SSH-ühendusse. Esimesel korral küsib SSH serveri kasutajakonto parooli. Korda käsku iga sõlme kohta (`proxmox1`, `proxmox2`, `proxmox3`):

```powershell
type "$env:USERPROFILE\.ssh\kursus_ed25519.pub" | ssh <kasutaja>@<sõlme-IP> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

Osa `>> ~/.ssh/authorized_keys` käivitub Linuxi serveris, mitte PowerShellis. See lisab võtme olemasoleva faili lõppu. Ära asenda `>>` märgiga `>`, sest siis kirjutatakse olemasolevad võtmed üle.

## 3. Kontrolli võtmega sisselogimist

```powershell
ssh -i "$env:USERPROFILE\.ssh\kursus_ed25519" <kasutaja>@<sõlme-IP>
```

Kui võtmega autentimine töötab, ei küsita enam kasutajakonto parooli. Kui määrasid võtmele paroolifraasi, küsitakse seda. See ei ole viga. Korduva sisestamise vältimiseks kasuta `ssh-agent`-i (osa 4).

## 4. Soovi korral kasuta ssh-agent'i

Windowsis on teenus `ssh-agent` vaikimisi välja lülitatud ja `ssh-add` annab vea, kui teenus ei tööta. Teenuse sisselülitamiseks ava PowerShell administraatorina ([võtmete haldus Windowsis](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)):

```powershell
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

Seejärel lisa võti agenti tavalises PowerShelli aknas:

```powershell
ssh-add "$env:USERPROFILE\.ssh\kursus_ed25519"
```

## Veaotsing

Järgmisi samme kasuta ainult siis, kui võtmega sisselogimine ei õnnestu. Töötava seadistuse õigusi ära muuda.

??? warning "SSH üksikasjalik väljund"
    ```powershell
    ssh -vvv -i "$env:USERPROFILE\.ssh\kursus_ed25519" <kasutaja>@<sõlme-IP>
    ```
    Otsi ridu `Offering public key` ja `Server accepts key`. Kui esimene on olemas ja teist pole, lükkas server võtme tagasi. Põhjus on serveri logis (`sudo journalctl -u sshd -e`).

??? warning "Linuxi serveri failiõigused"
    SSH on failiõiguste suhtes range. Kui kausta `~/.ssh` või faili `authorized_keys` õigused on liiga avarad, jätab server võtme kasutamata ja klient veateadet ei näe:

    ```bash
    chmod 700 ~/.ssh                      # kaust: ainult omanik
    chmod 600 ~/.ssh/authorized_keys      # fail: ainult omanik
    chmod 750 ~                           # kodukaust ei tohi olla rühmale ega teistele kirjutatav
    ```

??? warning "Windowsi privaatvõtme õigused"
    OpenSSH ei kasuta privaatvõtit, mida saavad lugeda ka teised kasutajad. Anna ligipääs ainult endale:

    ```powershell
    cd "$env:USERPROFILE\.ssh"
    icacls kursus_ed25519 /inheritance:r
    icacls kursus_ed25519 /grant:r "$($env:USERNAME):(R)"
    ```

??? warning "Kodeering ja reavahetused"
    Kui võti jõudis serverisse Windowsi reavahetustega (CRLF), eemalda serveris rea lõpust märk `\r`:

    ```bash
    sed -i 's/\r$//' ~/.ssh/authorized_keys
    ```

    See käsk ei teisenda UTF-16 kodeeringus faili. Kui fail on UTF-16 (`file ~/.ssh/authorized_keys` näitab `UTF-16`), kustuta valed read ja lisa võti uuesti osa 2 käsuga.
