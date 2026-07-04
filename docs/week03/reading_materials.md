# Ansible süvakäsitlus

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

Ansible'i agentless arhitektuur erineb fundamentaalselt teistest konfiguratsioonihalduse tööriistadest. Selle mõistmine on kriitiline, sest see mõjutab kõike - alates jõudlusest kuni turvalisuseni.

```mermaid
graph TD
    A[Control Node] -->|SSH| B[Web Server 1]
    A -->|SSH| C[Web Server 2]
    A -->|SSH| D[Database Server]
    A -->|SSH| E[Load Balancer]
    
    F[Puppet Master] -->|Pull Request| G[Puppet Agent 1]
    F -->|Pull Request| H[Puppet Agent 2]
    F -->|Pull Request| I[Puppet Agent 3]
    
    subgraph "Ansible Architecture"
        A
        B
        C
        D
        E
    end
    
    subgraph "Traditional Agent-based"
        F
        G
        H
        I
    end
```bash

Traditsiooniline agent-põhine lähenemine nõuab iga hallatava süsteemi jaoks spetsiaalse tarkvara installimist. Puppet agent, Chef client, Salt minion - kõik need peavad töötama taustal, tarbima ressursse ja olema pidevalt ajakohased. Ansible'i SSH-põhine kommunikatsioon kasutab aga infrastruktuuri, mis juba eksisteerib igas Unix-põhises süsteemis.

| Aspekt | Ansible (Agentless) | Puppet/Chef (Agent-based) |
|--------|---------------------|---------------------------|
| Installatsioon | Ainult control node'il | Igal hallatav süsteemil |
| Ressursikasutus | Minimalne | Agent tarbib RAM/CPU |
| Turvalisus | SSH (standard protokoll) | Spetsiaalne agent port |
| Skaleeritavus | Paralleelne SSH | Agent pull interval |
| Võrguliiklus | Push-based | Pull-based |
| Offline töö | Võimalik | Piiratud |

SSH-protokoll pole juhuslik valik. See on kõige laialdasemalt kasutatav ja hästi testitud remote access protokoll enterprise keskkonnas. SSH võtmed on juba hallatud, port 22 on juba avatud, logid juba konfiguratsiooni jaoks olemas. Ansible lihtsalt kasutab seda, mis juba seal on.

## Playbook'i täitmise tsükkel

```mermaid
graph TD
    A[User: ansible-playbook site.yml] --> B[Ansible: Parse YAML]
    B --> C[Ansible: Build task list]
    C --> D[For each host]
    D --> E[SSH: Establish connection]
    E --> F[For each task]
    F --> G[Transfer module]
    G --> H[Execute module]
    H --> I[Return results]
    I --> J[Check idempotency]
    J --> K{More tasks?}
    K -->|Yes| F
    K -->|No| L[Close connection]
    L --> M{More hosts?}
    M -->|Yes| D
    M -->|No| N[Report results]
    
    style A fill:#e1f5fe
    style N fill:#c8e6c9
```bash

Arhitektuuri teine oluline aspekt on push vs pull mudel. Puppet ja Chef kasutavad pull mudelit - agendid küsivad regulaarselt serverilt, kas on midagi uut teha. Ansible kasutab push mudelit - käivitad playbook'i siis, kui tahad muudatust. See annab täpse kontrolli selle üle, millal ja kuidas muudatused rakendatakse.

## YAML kui konfiguratsioonikeel

YAML pole lihtsalt data formaat - see on konfiguratsioonikeel, mis peegeldab hirarhilisi seoseid viisil, mida JSON või XML ei suuda sama intuitiivselt edastada. Ansible'is muutub YAML struktuuri mõistmine eriti oluliseks, sest see määrab täitmise järjekorra ja konteksti.

| YAML Element | Ansible Kontekst | Näide |
|--------------|------------------|--------|
| Document | Playbook algus | `---` |
| List | Tasks, hosts, vars | `- name: Install nginx` |
| Dictionary | Task parameetrid | `apt: name=nginx state=present` |
| String | Väärtused | `name: "My task"` |
| Boolean | Flags | `become: yes` |
| Variable | Jinja2 template | `{{ ansible_hostname }}` |

```mermaid
graph LR
    A[YAML Document] --> B[Play 1]
    A --> C[Play 2]
    
    B --> D[hosts: webservers]
    B --> E[vars: app_name]
    B --> F[tasks]
    
    F --> G[Task 1: Install]
    F --> H[Task 2: Configure]
    F --> I[Task 3: Start]
    
    G --> J[Module: apt]
    H --> K[Module: template]
    I --> L[Module: service]
```bash

YAML'i range taandrimise süsteem pole bürokraatia - see on funktsioon. Taandrimine määrab andmete hierarhia ja seeläbi ka Ansible'i käitumise. Vale taandrimine võib tähendada, et task käivitatakse vale host'i vastu või üldse vahele jäetakse.

## Moodulite ökosüsteem ja idempotentsus

Ansible'i jõud peitub selle laialdases moodulite kogumikus. Iga moodul pole lihtsalt funktsioon - see on abstraktsioon konkreetse tehnoloogia või süsteemi haldamiseks. Mooduli valik mõjutab otseselt seda, kui hooldatav ja turvalisne teie automatiseering on.

| Mooduli kategooria | Näited | Kasutusjuhud |
|-------------------|--------|--------------|
| System | `service`, `user`, `cron` | OS taseme haldus |
| Package | `apt`, `yum`, `pip` | Tarkvara installimine |
| File | `copy`, `template`, `lineinfile` | Failide haldus |
| Network | `uri`, `get_url`, `firewalld` | Võrgu konfigureerimine |
| Cloud | `ec2`, `azure_rm_*`, `gcp_*` | Pilve ressursid |
| Database | `mysql_user`, `postgresql_db` | Andmebaasi haldus |

```mermaid
graph TD
    A[Ansible Task] --> B{Check Current State}
    B -->|State OK| C[Skip - No Change]
    B -->|State Different| D[Apply Change]
    D --> E[Verify New State]
    E -->|Success| F[Report Changed]
    E -->|Failure| G[Report Error]
    
    style C fill:#90EE90
    style F fill:#FFD700
    style G fill:#FF6B6B
```bash

Idempotentsus on Ansible'i südames. See tähendab, et sama playbook'i korduvad käivitamised ei muuda süsteemi olukorda, kui soovitud olek on juba saavutatud. See pole automaatne - iga moodul peab seda toetama oma loogikaga.

Idempotentse mooduli kirjutamine nõuab kolme sammu: kontrollida praegust olukorda, võrrelda soovitud olukorraga, ja muuta ainult vajadusel. Halvasti kirjutatud moodul võib iga käivitamisel midagi muuta, isegi kui pole vaja.

## Inventory haldamise strateegiad

Inventory pole lihtsalt hostide nimekiri - see on abstraktsioon teie infrastruktuuri kohta. Hästi disainitud inventory peegeldab teie organisatsiooni struktuuri ja muudab automatiseerimise intuitiivseks.

| Inventory tüüp | Struktuur | Sobivus |
|----------------|-----------|---------|
| Static (INI) | `[webservers]` | Väikesed, stabiilsed keskkonnad |
| Static (YAML) | Hierarhiline | Komplekssed grupid ja muutujad |
| Dynamic | Script/plugin | Pilve keskkonnad |
| Mixed | Static + dynamic | Hübriid infrastruktuur |

```mermaid
graph TD
    A[Inventory Root] --> B[Production]
    A --> C[Staging]
    A --> D[Development]
    
    B --> E[Web Tier]
    B --> F[App Tier]
    B --> G[DB Tier]
    
    E --> H[web-prod-01]
    E --> I[web-prod-02]
    
    F --> J[app-prod-01]
    F --> K[app-prod-02]
    
    G --> L[db-prod-01]
    
    style B fill:#FF6B6B
    style C fill:#FFD700
    style D fill:#90EE90
```bash

Grupi muutujad (`group_vars`) võimaldavad defineerida konfiguratsiooni, mis rakendub kõigile grupi liikmetele. Host muutujad (`host_vars`) alistavad grupi muutujad konkreetse hosti jaoks. See hierarhia loob paindliku süsteemi, kus saate määrata üldseid reegleid ja teha erandeid vajadusel.

Dynamic inventory muutub oluliseks pilve keskkonnas, kus serverid tulevad ja lähevad. AWS EC2 plugin võib automaatselt avastada instance'id, grupeerida neid tagide järgi ja pakkuda metadata't muutujatena. See tähendab, et teie Ansible kood töötab sõltumata sellest, mitu instance'i parasjagu töötab.
