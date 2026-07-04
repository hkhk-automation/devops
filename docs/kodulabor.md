---
tags:
  - Keskkond
---

# Töökeskkond

Praktikumides on sul vaja **üht Linux-serverit** (Ubuntu), kuhu pääsed **SSH-ga** ja kus saad `sudo`. Redaktor kõikjal: **VS Code**. Rohkem pole vaja — playbook ja konteiner on kõigil sama, vahet teeb ainult IP `inventory.ini`-s.

## Koolis

Proxmox VM — IP ja kasutaja saad õpetajalt. SSH sisse, valmis.

## Kodus — sinu valik

VPN-i kooli pole, seega kodus tee **lokaalselt**. Kuidas täpselt — sinu otsus. Ainus nõue: Ubuntu, SSH töötab, saad `sudo`.

| Variant | Lühidalt |
|---|---|
| WSL2 (Windows) | `wsl --install`, Ubuntu jookseb Windowsi sees |
| VirtualBox / VMware VM | Ubuntu Server ISO, host-only või NAT võrk |
| Pilve-server | väike Ubuntu (Hetzner, DigitalOcean vms), avalik IP |
| Vagrant | kui tahad ühe käsuga korratavat VM-i — valikuline, mitte kohustuslik |

Ükskõik milline — kontrolli et töötab:

```bash
ssh <kasutaja>@<IP>
sudo whoami
```

`sudo whoami` peab vastama `root`. Kui jah — keskkond on valmis.

## VS Code

Ava projektikaust `code .`, kasuta integreeritud terminali (`` Ctrl+` ``). Kui sihtmärk on eemal serveris, laseb **Remote-SSH** laiendus sul redigeerida otse serveris — valikuline, aga mugav.

## Miks nii

Labid on sihtmärgist sõltumatud. Sama `inventory.ini` rida, ainult IP ja kasutaja muutuvad. Vali keskkond üks kord — edasi ei mõtle sellele.
