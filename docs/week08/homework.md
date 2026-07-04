---
tags:
  - CD
  - GHCR
  - Kodutöö
---

# Kodutöö — Automaatne ehitamine ja levitamine

> **Eelmine nädal:** CI pipeline testis koodi automaatselt.
> **Täna:** Laiendad pipeline'i — CD ehitab ja pusib image'i GHCR-i. Branch: `n08-lab`.
> **Järgmine nädal:** IaC mõtteviis (async nädal).

---

## Ülesanne

Nädal 8 praktikumis kirjutasid CD pipeline'i. Kodutöö eesmärk on veenduda, et kõik osad töötavad iseseisvalt — ilma õpetaja abita.

### Mida pead kontrollima

Kontrolli, et sinu pipeline teeb järgmist:

**CI osa (pull request):**

- [ ] Testid käivituvad automaatselt igal PR-il
- [ ] Testide ebaõnnestumise korral pipeline peatub — merge ei ole lubatud

**CD osa (merge main branchi):**

- [ ] Image ehitatakse ainult pärast edukaid teste (`needs: test`)
- [ ] Image ehitatakse ainult maini pushil, mitte PR-idel (`if: github.ref == 'refs/heads/main'`)
- [ ] Image pushitakse GHCR-i kahe tagiga: `latest` ja commit hash

**Tõestus:**

- [ ] Image on nähtav GitHubi repo "Packages" vahekaardil
- [ ] Image käivitub Proxmox VM-il edukalt (`docker run ...`)
- [ ] `curl http://localhost:5000` annab VM-il vastuse

---

## Esitamine

Esita **repo / run'i link GitHub Projectis**.

Repo peab sisaldama:
- Toimiv `.github/workflows/ci.yml` (CI + CD)
- Dockerfile juurekaustas
- Testid `tests/` kaustas
- Actions vahekaardil viimase workflow roheliseks minevad logid

---

## Levinud probleemid

**Image ei ilmu Packages all?**
Kontrolli `permissions: packages: write` blokki pipeline failis.

**Pipeline käivitub PR-il, aga image'it ei ehitata?**
See on õige käitumine — `if: github.ref == 'refs/heads/main'` takistab image ehitamist PR-idel. Mergi PR-i, siis ehitatakse.

**VM-il `docker pull` annab `unauthorized` vea?**
Pead VM-il GHCR-i sisse logima: `echo "token" | docker login ghcr.io -u kasutajanimi --password-stdin`
---

## Venitusülesanne (valikuline, lisapunktid)

Kui kõik eelnev töötab, lisa Trivy haavatavuse skaneerimine pipeline'i.

Nõuded:
- Trivy skannib image'i pärast ehitamist
- CRITICAL haavatavused katkestavad pipeline'i (`exit-code: 1`)
- Proovi tahtlikult vana base image'iga (`python:3.6-slim`) — pipeline peab katkema
- Dokumenteeri oma `week08/trivy_test.md` failis, mis viga leiti ja kuidas selle parandasid

Esitamine: sama repo link + `week08/trivy_test.md` fail repos.
