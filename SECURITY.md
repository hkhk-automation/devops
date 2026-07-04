# Turvapoliitika

Õppematerjalide repo. Siin ei ole tootmissüsteemi ega kasutajaandmeid — aga materjalid õpetavad saladuste käsitlemist, ja repo ise peab olema puhas eeskuju.

## Sisukord

- [Mida see repo ei sisalda](#mida-see-repo-ei-sisalda)
- [Kui leiad lekkinud saladuse](#kui-leiad-lekkinud-saladuse)
- [Teavitamine](#teavitamine)

## Mida see repo ei sisalda

Selles repos **ei tohi** olla:

- paroole, API-võtmeid, tokeneid ega privaatvõtmeid
- `.env`, `.vault_pass`, `terraform.tfstate` ega muid saladusi sisaldavaid faile
- tudengite isikuandmeid

Materjalides esinevad paroolid (nt `secret123`, `SuperSalajane123`) on **teadlikult võltsid** näidised. Neid ei tohi kunagi päris keskkonnas kasutada — labid õpetavad just seda (vt N2 `.gitignore`, N4 Ansible Vault).

## Kui leiad lekkinud saladuse

Kui märkad repo ajaloos päris saladust (mitte näidist):

1. Ära ava avalikku issue'd selle sisuga.
2. Teavita Maria Talvikut otse.
3. Saladus tuleb **kohe välja vahetada** — Git-ajaloost eemaldamine üksi ei aita, kuna see on juba nähtud olnud (sama õppetund mis N2 labis).

## Teavitamine

Turvaprobleemid, katkised lingid või vigased näited — teavita repo omanikku (Maria Talvik) või ava issue, kui asi ei ole tundlik.
