---
tags:
  - Ansible
  - Konfiguratsioon
---

# Ansible'i seaded: `ansible.cfg`

Fail `ansible.cfg` sisaldab Ansible'i seadeid. Kursusel on see projekti juurkaustas ja Ansible'i käsud käivitad samast kaustast. Siis loeb Ansible seaded sealt ise ja võtit `-i inventory.ini` ei pea iga käsu juurde kirjutama.

## Kursuse fail

N3 ja N4 jaoks piisab kahest reast. Fail läheb koos playbook'iga Giti:

```ini
[defaults]
inventory = inventory.ini
```

Sektsioon `[defaults]` sisaldab üldseadeid. Rida `inventory` ütleb, et inventarifail on `inventory.ini` samas kaustas. Käsk `ansible all -m ping` töötab siis ilma võtmeta `-i`.

??? warning "Rida `host_key_checking = False`"
    Mõnes juhendis on failis ka rida `host_key_checking = False`. See lülitab välja serveri hostivõtme kontrolli, mida õppisid N1-s (`known_hosts`). Sinu sõlmed on N1-st juba failis `known_hosts`, seega seda rida vaja ei ole. Ära pane seda rida tootmise projekti.

Kõik seaded koos vaikeväärtuste ja keskkonnamuutujate nimedega on lehel [Ansible Configuration Settings](https://docs.ansible.com/ansible/latest/reference_appendices/config.html). Failis piisab nendest ridadest, mida soovid muuta, ülejäänud väärtused võtab Ansible oma vaikeseadetest.

## Kust Ansible seaded võtab

Ansible otsib konfiguratsioonifaili selles järjekorras:

1. fail, millele osutab keskkonnamuutuja `ANSIBLE_CONFIG`;
2. `ansible.cfg` kaustas, kust käsk käivitati;
3. `~/.ansible.cfg` kodukaustas;
4. `/etc/ansible/ansible.cfg`.

Kasutatakse esimest leitud faili, teisi faile Ansible ei loe ega liida kokku. Paljusid seadeid saab muuta ka keskkonnamuutujaga, näiteks `ANSIBLE_GATHERING=explicit`. Keskkonnamuutuja on tähtsam kui faili väärtus. Iga seade keskkonnamuutuja nimi on kirjas seadete lehel.

## Kuidas kontrollida

Käsk [`ansible-config`](https://docs.ansible.com/ansible/latest/cli/ansible-config.html) näitab, milline fail on kasutusel ja millised väärtused kehtivad:

```bash
ansible-config dump --only-changed
```

Väljundis on ainult need seaded, mis erinevad vaikeväärtusest, ja iga rea juures on näha, kust väärtus tuli (fail või keskkonnamuutuja). Leia väljundist rida `CONFIG_FILE`: see näitab, millist faili Ansible luges.
