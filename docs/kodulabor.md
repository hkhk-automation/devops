---
tags:
  - Keskkond
---

# Töökeskkond

Kursusel on kaks rolli. **Juhtsõlm** on sinu arvuti: seal on VS Code, Git, Ansible ja projekti failid. **Hallatav sõlm** on Linuxi server, mida seadistad. Koolis on need AlmaLinuxi virtuaalmasinad `proxmox1`–`proxmox3`. Iga praktikumi alguses on kirjas, millises masinas käsud käivitad.

Juhendid on tehtud AlmaLinuxi jaoks. Kodus sobib ka Ubuntu, aga siis on mõned paketid, failiteed ja tulemüüri käsud teised.

## Koolis

Proxmoxi masinate IP-aadressid ja kasutajanime saad õpetajalt. SSH-ühenduse seadistad N1 praktikumis.

## Kodus

Kodus pääsed kooli masinatele VPN-iga. VPN-i profiili annab õpetaja. Kui VPN-i ei ole, saad osa nädalaid teha oma Linuxi masinas:

??? note "Tabel 1. Mida saab kodus teha"
    | Nädalad | Kodus |
    |---|---|
    | Git (N2), GitHub Actions (N7–N8) | oma arvutis ja GitHubis |
    | Ansible ja Docker (N3–N6, N11) | oma Linuxi masinas, kus on SSH ja `sudo` |
    | OpenTofu ja Proxmox (N10) | ainult VPN-iga, sest vaja on kooli Proxmoxi |

Oma Linuxi masina saad teha ühel neist viisidest:

??? note "Tabel 1. Kodused variandid"
    | Variant | Lühidalt |
    |---|---|
    | WSL2 (Windows) | `wsl --install`, Ubuntu töötab Windowsi sees |
    | VirtualBox või VMware VM | AlmaLinuxi või Ubuntu Serveri ISO. Võrk host-only: masinal on oma IP, kuhu teed SSH |
    | Pilveserver | väike server (Hetzner, DigitalOcean jt). See on tasuline ja internetist nähtav: luba ainult SSH-võtmega sisselogimine |
    | Vagrant | ühe käsuga korratav VM |

Kontrolli, et keskkond töötab:

```bash
ssh <kasutaja>@<IP>
sudo whoami
```

Kui `sudo whoami` vastab `root`, saad alustada. Mida iga nädal veel vajab (Python, Docker, internet), on kirjas praktikumi alguses.

## VS Code

Ava projektikaust käsuga `code .` ja kasuta integreeritud terminali (`` Ctrl+` ``). Laiendusega Remote-SSH saad faile otse serveris muuta. Pea meeles, et Remote-SSH terminal on serveris, mitte sinu arvutis.
