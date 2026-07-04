---
tags:
  - IaC
  - Terraform
  - Iseseisev
---

# Nädal 9 — Infrastruktuur koodina: mõtteviis (ASYNC)

!!! info "Iseseisev nädal"
    Seekord serverit vaja pole — puhas mõtteharjutus. Töötad iseseisvalt, esitad GitHubi enne järgmist sessiooni. Eelmine nädal sulgus CI/CD ring (image GHCR-i). Nüüd valmistume Terraformiks — deklaratiivne vs imperatiivne. Järgmine sessioon: Terraform, esimene kontakt (90 min).

---

## Taust — miks see nädal on tähtis?

Kursuse jooksul oled kasutanud mitmeid tööriistu. Igaüks lahendab erineva probleemi, aga neil on midagi ühist: nad kõik kirjeldavad kuidagi seda, **mis peab olema**.

Nädal 10 tutvud Terraformiga — tööriistaga, mis haldab infrastruktuuri (servereid, võrke, salvestust) koodina. Et Terraform'ist aru saada, pead esmalt mõistma, mis vahe on **deklaratiivsel** ja **imperatiivsel** lähenemisel.

---

## Lugemismaterjal (loe enne ülesannet)

### Deklaratiivne vs imperatiivne — meenutus loengu materjalist

**Imperatiivne** — kirjeldad **sammud** (kuidas teha):
```bash
mkdir /opt/app
cd /opt/app
git clone https://github.com/example/app .
pip install -r requirements.txt
systemctl start myapp
```
Sa ütled masinale täpselt, mida ta peab tegema, millises järjestuses.

**Deklaratiivne** — kirjeldad **lõppseisundit** (mis peab olema):
```yaml
- name: rakendus on paigaldatud
  hosts: servers
  tasks:
    - git:
        repo: https://github.com/example/app
        dest: /opt/app
    - service:
        name: myapp
        state: started
```
Sa ütled, mis peab olemas olema. Tööriist otsustab ise, milliseid samme on vaja.

### Idempotentsus — meenutus

Deklaratiivsed tööriistad on üldjuhul **idempotentsed** — sama konfiguratsiooni saab rakendada mitu korda, tulemus on alati sama. Imperatiivne skript võib teine kord käivitades probleeme tekitada (nt kui kaust on juba olemas).

---

## Ülesanne

Esita GitHubi oma reposes fail: `docs/week09/iac_mindset.md`

Loo see fail oma arvutis, täida sisu, lisa ja push GitHubi.

```bash
# Loo kaust, kui pole
mkdir -p docs/week09

# Loo fail
touch docs/week09/iac_mindset.md
```

---

### Osa 1 — Võrdlustabel (kohustuslik)

Täida järgmine tabel **nädala 2–8 materjalide põhjal**. Iga tööriist peab saama lahtri iga veeru kohta.

| Tööriist | Lähenemine (deklaratiivne / imperatiivne) | Mida haldab | Idempotentne? |
|---|---|---|---|
| Bash skript | | | |
| Git | | | |
| Ansible | | | |
| Docker (Dockerfile) | | | |
| Docker Compose | | | |
| GitHub Actions | | | |
| Terraform | ? | ? | ? |

**Juhised:**

- **Lähenemine:** kirjuta "deklaratiivne" või "imperatiivne" (või "mõlemat", kui see sobib)
- **Mida haldab:** ühe lausega, näiteks "serverite konfiguratsioon", "konteinerite käivitamine", "koodi versioonid"
- **Idempotentne?:** "jah", "ei", või "sõltub"
- **Terraform rida:** jäta tühjaks — täidad nädal 10 sessioonis, kus vaatame koos üle

---

### Osa 2 — Ennustus (kohustuslik)

Kirjuta **3 lauset** (kokku, mitte üks lause küsimuse kohta) järgmisele küsimusele:

> Mida teeb Terraform teisiti kui Ansible?

Kirjuta aus ennustus — ei pea olema täiesti õige. Vaatame neid ennustusi nädal 10 sessioonis koos üle ja arutame, mis klapib, mis mitte. Vigade tegemine on lubatud.

Vihjed mõtlemiseks (ärge googelda vastust — mõelge ise):
- Ansible haldab **konfiguratsiooni** (mis on serveris sees). Terraform haldab **infrastruktuuri** (serverid ise, võrgud, tulemüürid). Mis vahe see teeb?
- Ansible'il ei ole "seisundit" — ta rakendab konfiguratsiooni ja unustab. Terraform mäletab, mida ta on loonud. Mida see tähendab kustutamisel?

---

### Osa 3 — Venitusülesanne (valikuline)

!!! tip "Valikuline — neile, kes tahavad rohkem"

Loe [12-Factor App metoodikat](https://12factor.net) — täpsemalt jaotised:
- **III. Config** — konfiguratsiooni hoidmine keskkonnamuutujates
- **IV. Backing services** — teenused kui lisatavad ressursid  
- **V. Build, release, run** — build etappide eraldamine

Lisa tabelisse viies veerg: **12-Factor nõuetele vastav?**

Igasse lahtrisse: **üks sõna** (jah / osaliselt / ei) **+ üks lause** selgituseks.

Näide:
```
| Docker Compose | deklaratiivne | mitme teenuse käitamine | jah | osaliselt — 
  toetab env muutujaid (Factor III), aga ei erista build/run etappe (Factor V) |
```

---

## Esitamine

1. Loo fail `docs/week09/iac_mindset.md` oma repos
2. Täida mõlemad osad (Osa 1 + Osa 2)
3. Commit ja push:

```bash
git add docs/week09/iac_mindset.md
git commit -m "nädal 9: IaC mõtteviis tabel ja ennustus"
git push
```

**Tähtaeg:** enne järgmise nädala sessiooni algust.

Esita Moodles link failile GitHubis (mitte repo, vaid konkreetne fail — "Raw" vaade ei ole vajalik, lihtsalt GitHubi failivaade).

---

## Kontrollimine

Enne esitamist veendu, et:

- [ ] `docs/week09/iac_mindset.md` on GitHubis nähtav
- [ ] Tabel on täidetud (v.a Terraform rida)
- [ ] Ennustus on kirjutatud — 3 lauset
- [ ] Commit'i sõnum on mõistlik (mitte "asdfgh", "update" ega Märteni "asjad")
