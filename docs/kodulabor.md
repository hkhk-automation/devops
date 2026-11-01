---
tags:
  - Keskkond
---

# Töökeskkond

Praktikumides on vaja üht Linuxi serverit, kuhu pääsed SSH-ga ja kus saad kasutada `sudo`-t. Koolis on see AlmaLinuxi virtuaalmasin, kodus sobib ka Ubuntu. Redaktoriks on VS Code. Playbook ja konteiner on kõigil samad, erinevad ainult IP-aadress ja kasutaja failis `inventory.ini`.

## Koolis

Proxmoxi virtuaalmasina IP-aadressi ja kasutajanime saad õpetajalt. Ühendu SSH-ga ja keskkond on valmis.

## Kodus

Kooli VPN-i kodus ei ole, seega tee kodus kõik oma arvutis. Variandi valid ise. Nõue on, et Linux töötab, SSH-ühendus toimib ja saad kasutada `sudo`-t.

??? note "Tabel 1. Kodused variandid"
    | Variant | Lühidalt |
    |---|---|
    | WSL2 (Windows) | `wsl --install`, Ubuntu töötab Windowsi sees |
    | VirtualBox või VMware VM | Ubuntu Serveri ISO, võrk host-only või NAT |
    | Pilveserver | väike Ubuntu server (Hetzner, DigitalOcean jt) avaliku IP-aadressiga |
    | Vagrant | ühe käsuga korratav VM |

Kontrolli, et keskkond töötab:

```bash
ssh <kasutaja>@<IP>
sudo whoami
```

Kui `sudo whoami` vastab `root`, on keskkond valmis.

## VS Code

Ava projektikaust käsuga `code .` ja kasuta integreeritud terminali (`` Ctrl+` ``). Kui sihtmärk on kaugserveris, saad laiendusega Remote-SSH faile otse serveris muuta.
