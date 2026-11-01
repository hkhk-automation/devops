---
tags:
  - Ansible
  - Konfiguratsioon
---

# Ansible'i seaded: `ansible.cfg`

Fail `ansible.cfg` sisaldab Ansible'i seadeid ja asub samas kaustas, kus on playbook. Kui käivitad Ansible'i sellest kaustast, loeb Ansible seaded sealt ise ja võtit `-i inventory.ini` ei pea iga käsu järele kirjutama.

## Kursuse fail

N3 ja N4 praktikumis piisab kahest reast. Fail läheb koos playbookiga Giti:

```ini
[defaults] # (1)!
inventory = inventory.ini # (2)!
host_key_checking = False # (3)!
```

1. Sektsioon `[defaults]` sisaldab üldseadeid. Teised sektsioonid on näiteks `[privilege_escalation]` ja `[ssh_connection]`.
2. Ansible kasutab inventory-faili `inventory.ini` samast kaustast. Käsk `ansible all -m ping` töötab siis ilma võtmeta `-i`.
3. Esimesel ühendusel uue serveriga ei küsita, kas hostivõtit usaldada (`yes/no`). Töökohas jäetakse see kontroll tavaliselt sisse.

Kõik seaded koos vaikeväärtuste ja keskkonnamuutujate nimedega on lehel [Ansible Configuration Settings](https://docs.ansible.com/ansible/latest/reference_appendices/config.html). Failis piisab nendest ridadest, mida soovid muuta, ülejäänud väärtused võtab Ansible oma vaikeseadetest.

## Kust Ansible seaded võtab

Ansible otsib konfiguratsioonifaili selles järjekorras:

1. fail, millele osutab keskkonnamuutuja `ANSIBLE_CONFIG`;
2. `ansible.cfg` kaustas, kust käsk käivitati;
3. `~/.ansible.cfg` kodukaustas;
4. `/etc/ansible/ansible.cfg`.

Kasutatakse esimest leitud faili, teisi faile Ansible ei loe ega liida kokku. Üksikut seadet saab muuta ka keskkonnamuutujaga, mille nimi on seade nimi suurtähtedega ja eesliitega `ANSIBLE_` (näiteks `ANSIBLE_GATHERING=explicit`). See kehtib faili väärtuse asemel.

## Kuidas kontrollida

Käsk [`ansible-config`](https://docs.ansible.com/ansible/latest/cli/ansible-config.html) näitab, milline fail on kasutusel ja millised väärtused kehtivad:

```bash
ansible-config dump --only-changed
```

Väljundis on ainult need seaded, mis erinevad vaikeväärtusest, ja iga rea juures on näha, kust väärtus tuli (fail või keskkonnamuutuja). Esimene rida `CONFIG_FILE` näitab, millist faili Ansible luges.
