# Nädal 11 - Korduvkasutatav infrastruktuur

> **Eelmine nädal:** Nägime Terraformi lifecyclei - init, plan, apply, destroy.
> **Täna:** Kaks rada - vali vastavalt enesekindlusele.
> **Järgmine nädal:** Nähtavus - Prometheus + Grafana.

## Rada A - Terraform moodulid

Kirjuta konfiguratsioon nullist: muutujad, outputs, for_each.
Seejärel paki korduvkasutatavasse moodulisse ja kutsu kahel korral.
Vt: lab_terraform_modules.md

## Rada B - Ansible rollid

Refaktori nädal 3-4 playbook rolliks kasutades ansible-galaxy init.
Installi üks Galaxy kogukonna roll. Kirjuta site.yml mis kutsub mõlemaid.
Vt: lab_ansible_roles.md

## Mõlemad rajad lõpetavad kirjaliku ülesandega

Kirjuta 3 lauset: kuidas on rolli/mooduli muster sarnane programmeerimise funktsioonidele?

## Venitusülesanne

Rada A: Lisa muutuja validatsioon. Testi vale väärtusega - mis juhtub?
Rada B: Lisa assert task - ebaõnnestub selge veateatega kui nõutav muutuja puudub.
