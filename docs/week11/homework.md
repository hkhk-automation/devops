---
tags:
  - Ansible
  - Rollid
  - Kodutöö
---

# Kodutöö: Ansible'i rollid

Praktikumis tegid nginx'i rolli, millel on mall ja handler. Kodutöös lisad rollile teise muutuja ja teed N4 praktikumi chrony osast eraldi rolli, ilma samm-sammulise juhiseta.

## Osa 1 · Teine muutuja

Lisa faili `roles/nginx/defaults/main.yml` muutuja `nginx_server_name` väärtusega `localhost` ja kasuta seda mallis `roles/nginx/templates/lab11.conf.j2` ploki `server` sees reana `server_name {{ nginx_server_name }};`. Anna muutujale failis `site.yml` rolli `vars:` all uus väärtus, näiteks `proxmox1.lab`.

```bash
ansible-playbook -i inventory.ini site.yml | tee logid/k1-muutus.txt
ansible-playbook -i inventory.ini site.yml | tee logid/k2-uuesti.txt
ssh proxmox1 "grep server_name /etc/nginx/conf.d/lab11.conf"
```

??? success "Oodatav tulemus"
    Failis `k1-muutus.txt` on mall `changed` ja handler `laadi nginx uuesti` käivitus. Failis `k2-uuesti.txt` on `changed=0` ja handler'it pole. Sõlmes on failis rida `server_name proxmox1.lab;`.

## Osa 2 · Roll chrony

N4 praktikumi osas 11 paigaldas playbook chrony, kirjutas mallist faili `/etc/chrony.d/hallatud.conf` ja taaskäivitas handler'iga teenuse `chronyd`. Tee sellest roll `chrony`:

- skelett käsuga `ansible-galaxy init`;
- NTP serverite loend muutujana rolli `defaults/main.yml`-is;
- mall `{% for %}` tsükliga rolli kaustas `templates/`;
- handler rolli `handlers/main.yml`-is;
- roll lisatud faili `site.yml` rolli `nginx` järele.

```bash
ansible-playbook -i inventory.ini site.yml | tee logid/k3-chrony.txt
ssh proxmox1 "chronyc sources"
```

??? success "Oodatav tulemus"
    Väljundis on ülesanded kujul `TASK [chrony : ...]`. `chronyc sources` näitab sinu rollis kirjas olevaid servereid. Teine käivitus annab `changed=0`.

??? tip "Vihje"
    Pakett on `chrony`, teenus on `chronyd`. Kui sinu N4 repositooriumis on chrony osa olemas, saad ülesanded ja malli sealt kopeerida. Malli tee ülesandes on rollis ainult faili nimi.

## Töö esitamine

```bash
git add roles site.yml logid
git commit -m "nginx_server_name muutuja ja chrony roll"
git push
```

Tähtaja näed Classroom 50-s.
