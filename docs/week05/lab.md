---
tags:
  - Docker
  - Konteinerid
  - Praktikum
---

# Docker — käed külge — Labor

**Kestus:** 4 tundi
**Eeldused:** Loeng antud (image ≠ konteiner, Dockerfile, build/run). Kui udu — [tagasi loengusse](lecture.md). Siit edasi on **ainult käed külge**, teooriat ei korrata.
**Keskkond:** Docker seal kus töötad — kohalik (Docker Desktop / Engine), WSL, või server. Kood ja käsud **VS Code'is**. `localhost` = masin kus Docker jookseb.

---

!!! abstract "Õpiväljundid"

    Selle labi lõpuks sa:

    1. Ehitad töötava image'i ja käivitad konteineri, ilma juhendisse piilumata
    2. **Diagnoosid** kolm tüüpilist Docker-viga nende veateate järgi (mitte pähe õpitult)
    3. Selgitad miks rebuild ei uuenda töötavat konteinerit — ja parandad selle
    4. Loed `docker ps` / `logs` väljundit tõrkeotsinguks
    5. Taastad puhta seisu pärast seda kui oled ise midagi katki teinud

---

Selle labi loogika: **baas → katki → paranda → laienda → viga → taasta.** Sa ei kopeeri valmis lahendust — sa ehitad, lõhud meelega, ja saad aru **miks**. Iga samm lisab ainult ühe tüki. Kui tahad tervet faili korraga kopeerida: see labi pole selleks.

---

## Osa 1 · Baas — töötav image (30 min)

Loo kaust ja mine sisse:

```bash
mkdir w05 && cd w05
```

Loo fail `Dockerfile` (täpselt see nimi). See on **ainus kord**, kui näed tervet faili — edasi lisad ridu ühekaupa:

```dockerfile
FROM ubuntu
RUN apt update && apt install -y nginx
CMD ["nginx", "-g", "daemon off;"]
```

Ehita ja käivita:

```bash
docker build -t minu-nginx .
docker run -d -p 8080:80 --name web1 minu-nginx
curl localhost:8080
```

Näed nginx tervituslehte. Baas töötab. **Ära mine edasi enne kui see vastab.**

!!! tip
    `Connection refused` — kontrolli `docker ps`. Kui `web1` pole seal, `docker logs web1` ütleb miks.

---

## Osa 2 · Katki — ja miks (40 min)

Nüüd teed **meelega** vea, mille kõik teevad täpselt ühe korra. Lisa `Dockerfile`-i teine paketirida — aga jäta `-y` **teadlikult ära**:

Muuda keskmine rida selliseks (lisa `curl` install ilma `-y`-ta):

```dockerfile
RUN apt update && apt install nginx curl
```

Ehita:

```bash
docker build -t minu-nginx .
```

**Vaata mis juhtub.** Build peatub kohas, kus apt küsib `Do you want to continue? [Y/n]` — ja jääb toppama või katkeb, sest ehitamise ajal ei ole kedagi, kes vastaks.

??? question "Diagnoosi enne kui parandad"
    Miks töötab sama `apt install nginx curl` sinu enda terminalis, aga Docker build'is ripub? Mis vahe on interaktiivsel terminalil ja build-keskkonnal?

**Paranda:** pane `-y` tagasi. `-y` = "jah kõigele", sest build-keskkonnas pole inimest:

```dockerfile
RUN apt update && apt install -y nginx curl
```

```bash
docker build -t minu-nginx .
```

Läbib. See on reegel, mitte soovitus: Dockerfile'is `apt install` **alati** `-y`.

---

## Osa 3 · Laienda — oma sisu image'isse (40 min)

Baas serveerib nginx'i vaikimisi lehte. Paneme oma. Loo `w05` kausta fail `index.html`:

```html
<h1>Versioon 1</h1>
```

Lisa `Dockerfile`-i **üks uus rida**, `CMD` ette (näita ainult uut rida, mitte tervet faili):

```dockerfile
COPY index.html /var/www/html/index.html
```

Ehita ja **proovi vana konteineriga**:

```bash
docker build -t minu-nginx .
curl localhost:8080
```

??? question "Ennusta enne vaatamist"
    Mida `curl` nüüd näitab — "Versioon 1", vana vaikimisi leht, või vea?

Näed ikka **vana** lehte. See pole viga — see on Osa 4.

---

## Osa 4 · Rebuild ei uuenda konteinerit (40 min)

Ehitasid uue image'i, aga `curl` näitab vana. Miks?

**Diagnoosi:**

```bash
docker ps
docker images
```

`docker ps` näitab et `web1` jookseb. `docker images` näitab et `minu-nginx` on **äsja** ehitatud (vaata `CREATED`). Kaks fakti, üks järeldus:

??? question "Miks?"
    `web1` käivitati Osas 1, **vanast** image'ist. `docker build` tegi uue image'i, aga ei puutunud töötavat konteinerit. Konteiner on külmutatud hetk sellest image'ist, mis kehtis tema **käivitamise** ajal. Miks Docker seda ei uuenda automaatselt? (Vihje: kujuta et keegi ehitab katkise image'i reedel 16:55, ja kõik konteinerid tootmises uueneksid ise.)

**Taasta õige seis:**

```bash
docker stop web1
docker rm web1
docker run -d -p 8080:80 --name web1 minu-nginx
curl localhost:8080
```

Nüüd "Versioon 1". Jäta meelde see jada: **stop → rm → run**. Uus image ei jõua tootmisse ilma selleta.

---

## Osa 5 · Port juba kinni (30 min)

Proovi käivitada teine konteiner samast image'ist, **sama pordiga**:

```bash
docker run -d -p 8080:80 --name web2 minu-nginx
```

Saad vea: `port is already allocated`.

??? question "Diagnoosi"
    `web1` hoiab juba porti 8080. Kaks konteinerit ei saa jagada sama host-porti. Mis on lahendus, kui tahad **mõlemat** korraga jooksma? (Vihje: kumb number `-p X:80`-s on host-port?)

**Paranda:** anna `web2`-le teine host-port:

```bash
docker run -d -p 8081:80 --name web2 minu-nginx
curl localhost:8081
```

Nüüd jooksevad mõlemad — `8080` ja `8081`, üks image, kaks konteinerit.

---

## Osa 6 · Surnud konteiner (30 min)

Muuda `Dockerfile` `CMD` rida selliseks (võta `daemon off;` ära):

```dockerfile
CMD ["nginx"]
```

Ehita ja käivita puhtalt:

```bash
docker build -t minu-nginx .
docker run -d -p 8082:80 --name web3 minu-nginx
docker ps
```

`web3` pole `docker ps`-is. Ta suri kohe.

**Diagnoosi:**

```bash
docker ps -a
docker logs web3
```

??? question "Miks?"
    Ilma `daemon off;` läheb nginx taustale ja põhiprotsess (PID 1) lõpeb kohe. Konteiner elab **täpselt nii kaua kui elab tema põhiprotsess**. Protsess lõppes → konteiner lõppes. Mis siis `daemon off;` teeb, et konteiner elus püsib?

**Paranda:** pane `daemon off;` tagasi, ehita, käivita. `web3` jääb seekord püsti.

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

---

## Osa 7 · Taasta puhas seis (20 min)

Tegid sassi — kolm konteinerit, üks image. Koristame nagu päris elus:

```bash
docker ps -a
docker stop web1 web2 web3
docker rm web1 web2 web3
docker ps -a
```

Kontrolli et midagi ei jäänud rippuma, ja et image on alles:

```bash
docker images
```

??? question "Mõtle"
    Miks Docker nõuab enne konteineri kustutamist selle peatamist (`stop` enne `rm`)? Mis läheks valesti, kui `rm` tapaks jooksva konteineri kohe?

Tahad ka image'i minema:

```bash
docker rmi minu-nginx
```

---

## Lõppkontroll — oskad ilma juhendita

- [ ] Ehitad töötava nginx image'i nullist, mälu järgi
- [ ] Selgitad **miks** `apt install` vajab `-y` Dockerfile'is (mitte lihtsalt "peab")
- [ ] Kui rebuild "ei mõju", tead kohe et vaja **stop → rm → run**
- [ ] `port is already allocated` — tead põhjust ja lahendust ilma googeldamata
- [ ] Surnud konteiner — `docker logs` + PID 1 loogika
- [ ] `docker ps -a` on tühi kui pead selle tühjaks tegema

---

## Lisaülesanded (kui jõuad ette)

1. **`docker exec`:** mine jooksva `web1` sisse (`docker exec -it web1 bash`), muuda `/var/www/html/index.html` käsitsi. `docker stop web1` + `docker start web1` (mitte rm+run) — kas muudatus säilis? `rm`+`run` — kas säilis? Selgita vahet.
2. **`--no-cache`:** ehita `docker build --no-cache -t minu-nginx .`. Mis on aeglasem ja miks? Millal seda vaja?
3. **Oma port konteineris:** pane nginx kuulama porti 8000 konteineri **sees** (nõuab config-faili `COPY`-t). Mis muutub `-p`-s?

---

## Veaotsing

| Veateade | Põhjus | Lahendus |
|---|---|---|
| Build ripub `[Y/n]` juures | `apt install` ilma `-y` | Lisa `-y` |
| `Connection refused` | `-p` puudub, või konteiner ei jookse | `docker ps`, `docker logs` |
| Vana sisu pärast rebuild'i | Konteiner vanast image'ist | `stop` → `rm` → `run` |
| `port is already allocated` | Host-port kinni | Teine host-port `-p` vasakul |
| Konteiner sureb kohe | Põhiprotsess lõppes (nt `daemon off;` puudub) | `docker logs`, paranda `CMD` |
| `image is being used` | Konteinerid veel olemas | Eemalda konteinerid enne `rmi` |

*Tabel 5.1. Iga rida on viga, mille sa selles labis ise tekitasid ja parandasid.*

---

## Allikad

| Allikas | URL | Miks |
|---|---|---|
| Dockerfile reference | <https://docs.docker.com/reference/dockerfile/> | Kõik käsud |
| `docker run` | <https://docs.docker.com/reference/cli/docker/container/run/> | Lipud, pordid |
| `docker logs` | <https://docs.docker.com/reference/cli/docker/container/logs/> | Tõrkeotsing |
| Play with Docker | <https://labs.play-with-docker.com/> | Liivakast brauseris |
