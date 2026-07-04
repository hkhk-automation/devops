# Git Versioonikontroll

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

#### Giti ajalugu ja areng

Git ei tekkinud vaakumis - see lahendas reaalseid probleeme, millega silmitsi seisis Linux kerneli arendustiim 2005. aastal. Linus Torvalds oli aastatega kasutanud erinevaid versioonikontrolli lahendusi, kuid ükski ei vastanud kerneli arenduse kõrgetele nõudmistele. BitKeeper, mida nad kasutasid, muutus äkitselt tasuliseks ning alternatiivid nagu CVS ja Subversion olid liiga aeglased ja tsentraliseeritud.

```mermaid
gantt
    title Git'i ajalugu
    dateFormat YYYY
    section BitKeeper ajastu
    BitKeeper kasutamine    :done, bk1, 2000, 2005
    Linux kernel arendus   :done, bk2, 2000, 2005
    section Git'i sünd
    BitKeeper'i litsents muutub :done, git1, 2005, 2005
    Linus alustab Git'i loomist :done, git2, 2005, 2005
    Esimene Git'i versioon 2 nädalaga :done, git3, 2005, 2005
    section Moderne ajastu
    GitHub'i käivitamine   :done, gh1, 2008, 2008
    Git muutub populaarseks :done, git4, 2010, 2010
    Git on de facto standard :done, git5, 2020, 2020
```text

Giti loomise ajendiks oli vajadus kiire, hajutatud versioonikontrolli järele, mis suudaks käsitleda tuhandeid arendajaid üle maailma. Torvalds lõi Giti kahe nädalaga, keskendudes kolmele põhiprintsiibile: kiirus, lihtne disain ja tugev mittelineaarse arenduse tugi. Need põhimõtted on siiani Giti südames.

Giti hajutatud olemus tähendab, et iga arendaja masinas on täielik koopia repositooriumi ajaloost. See erineb fundamentaalselt tsentraliseeritud süsteemidest nagu SVN, kus üks keskne server hoiab kogu ajalugu.

```mermaid
graph TB
    subgraph "Tsentraliseeritud (SVN)"
        CS[Keskne Server]
        WC1[Töökataloog 1]
        WC2[Töökataloog 2]
        WC3[Töökataloog 3]
        
        CS --> WC1
        CS --> WC2
        CS --> WC3
    end
    
    subgraph "Hajutatud (Git)"
        R1[Repositoorium 1]
        R2[Repositoorium 2]
        R3[Repositoorium 3]
        RS[Jagatud repositoorium]
        
        R1 <--> RS
        R2 <--> RS
        R3 <--> RS
        R1 <--> R2
        R2 <--> R3
    end
```bash

#### Giti sisemused

Giti geniaalsus peitub selle arhitektuuris. Git kasutab sisu-adresseeritavat salvestust, kus iga faili sisu räsitakse SHA-1 algoritmiga. See räsi muutub faili unikaalseks identifikaatoriks, tagades andmete terviklikkuse ja võimaldades kiiret duplikaatide tuvastamist.

```mermaid
graph TD
    subgraph "Git'i objektide mudel"
        C[Commit]
        T[Tree]
        B1[Blob: file1.txt]
        B2[Blob: file2.txt]
        B3[Blob: file3.txt]
        ST[Subtree]
        
        C --> T
        T --> B1
        T --> B2
        T --> ST
        ST --> B3
    end
```bash

Git kasutab nelja põhilist objekti tüüpi. Blob'id sisaldavad failide sisu, puud (trees) kirjeldavad kataloogi struktuuri, commit'id salvestavad hetktõmmised koos metaandmetega ning tag'id märgistavad olulisi versioonipunkte. Need objektid moodustavad suunatud atsüklilise graafi, mis esitab projekti ajalugu.

Kolmeastmeline arhitektuur - töökataloog, staged area ja repositoorium - annab arendajatele täpse kontrolli selle üle, mida nad commit'ivad.

```mermaid
graph LR
    WD[Töökataloog<br/>Working Directory]
    SA[Staged Area<br/>Index]
    LR[Lokaalne Repositoorium<br/>Local Repository]
    RR[Kaugrepositoorium<br/>Remote Repository]
    
    WD -->|git add| SA
    SA -->|git commit| LR
    LR -->|git push| RR
    RR -->|git pull| WD
    LR -->|git checkout| WD
```bash

#### Hargnemisstrateegia

Erinevad tiimid kasutavad erinevaid hargnemisstrateegiaid sõltuvalt oma vajadustest. Git Flow on struktureeritud lähenemine, mis kasutab mitut püsivat haru: master (või main) stabiilsete versioonide jaoks, develop jooksvaks arendustööks, feature harusid uute funktsioonide jaoks ning release ja hotfix harusid spetsiifiliste ülesannete täitmiseks.

```mermaid
graph TD
    A[Initial] --> B[Dev work]
    B --> C[Add login]
    C --> D[Fix login]
    D --> E[Integration]
    E --> F[Prepare release]
    F --> G[v1.0 Release]
    G --> H[Fix critical bug]
    H --> I[v1.0.1 Release]
    
    style A fill:#e1f5fe
    style G fill:#c8e6c9
    style I fill:#c8e6c9
```text

GitHub Flow on lihtsam alternatiiv, mis sobib paremini pideva integratsiooni keskkonnas. Selles mudelis on ainult üks main haru, millest luuakse feature harud. Iga feature haru merge'itakse tagasi main'i pärast code review'd.

```mermaid
graph TD
    A[Initial] --> B[Feature 1]
    B --> C[Start component]
    C --> D[Add tests]
    D --> E[Finalize]
    E --> F[Deploy]
    F --> G[Fix bug]
    G --> H[Deploy fix]
    
    style A fill:#e1f5fe
    style F fill:#c8e6c9
    style H fill:#c8e6c9
```bash

## Lugemisküsimused

Pärast lugemist vasta järgmistele küsimustele oma GitHub repositooriumis failis `git_reading_reflection.md`:

1. **Millise probleemi lahendamiseks Git loodi ja kuidas see erineb tsentraliseeritud versioonikontrolli süsteemidest?**

2. **Selgita Giti nelja objekti tüüpi (blob, tree, commit, tag) ja kuidas need omavahel seotud on.**

3. **Millal kasutaksid Git Flow'd ja millal GitHub Flow'd? Anna konkreetsed näited.**

4. **Kirjelda, mis toimub Giti kolmes etapis: töökataloog → staged area → repositoorium.**

---

## Viited ja lisalugemine

- [Pro Git raamat](https://git-scm.com/book) - põhjalik Git'i käsiraamat
- [Git internals dokumentatsioon](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)
- [Atlassian Git tutorials](https://www.atlassian.com/git/tutorials)
- [GitHub Flow guide](https://docs.github.com/en/get-started/quickstart/github-flow)
