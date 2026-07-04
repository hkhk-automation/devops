# Terraform Kodutöö: Moodulid ja Korduvkasutus

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

**Eesmärk:** Õppida Terraform mooduleid ja for_each kasutamist

## Projekti Kirjeldus

Looge Terraform moodul, mis automatiseerib projektikaustas loomist erinevate meeskondade jaoks. Iga meeskond vajab standardset projektistruktuuri, kuid erinevate seadistustega.

**Mida ehitate:**
- Korduvkasutatav projekti moodul
- Mitme meeskonna projektide automaatne loomine
- Konfiguratsioonifailide genereerimine

---

## Ülesanne 1: Projekti struktuur (2 punkti)

### 1.1 Kaustade loomine

Looge järgmine struktuuri:

```bash
terraform-modules-homework/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    └── project-setup/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```text

### 1.2 Mooduli muutujad

Kirjutage `modules/project-setup/variables.tf`:

```hcl
variable "project_name" {
  description = "Projekti nimi"
  type        = string
  
  validation {
    condition     = length(var.project_name) > 2
    error_message = "Projekti nimi peab olema vähemalt 3 tähemärki."
  }
}

variable "team_name" {
  description = "Meeskonna nimi"
  type        = string
}

variable "environment" {
  description = "Keskkond (dev, test, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Lubatud keskkonnad: dev, test, prod."
  }
}

variable "include_docker" {
  description = "Kas lisada Docker konfiguratsioon"
  type        = bool
  default     = false
}
```text

---

## Ülesanne 2: Mooduli loomine (4 punkti)

### 2.1 Põhiline moodul

Kirjutage `modules/project-setup/main.tf`:

```hcl
# Lokaalid kalkulatsioonid
locals {
  project_full_name = "${var.team_name}-${var.project_name}"
  
  # Erinevad seadistused keskkonna kohta
  env_settings = {
    dev = {
      port = 3000
      debug = true
    }
    test = {
      port = 3001
      debug = true
    }
    prod = {
      port = 80
      debug = false
    }
  }
}

# Projekti põhikaust
resource "local_file" "project_dir" {
  content  = ""
  filename = "${local.project_full_name}/.gitkeep"
}

# Alamkaustad
resource "local_file" "subdirs" {
  for_each = toset(["src", "config", "docs", "scripts"])
  
  content  = ""
  filename = "${local.project_full_name}/${each.key}/.gitkeep"
}

# Projekti konfiguratsioon
resource "local_file" "config" {
  content = jsonencode({
    project = var.project_name
    team = var.team_name
    environment = var.environment
    settings = local.env_settings[var.environment]
    created_at = timestamp()
  })
  
  filename = "${local.project_full_name}/config/project.json"
}

# README fail
resource "local_file" "readme" {
  content = <<-EOF
    # ${local.project_full_name}
    
    **Meeskond:** ${var.team_name}
    **Projekt:** ${var.project_name}
    **Keskkond:** ${var.environment}
    
    ## Struktuuri
    - src/ - lähtekood
    - config/ - konfiguratsioonid
    - docs/ - dokumentatsioon
    - scripts/ - skriptid
    
    ## Seadistused
    - Port: ${local.env_settings[var.environment].port}
    - Debug: ${local.env_settings[var.environment].debug}
  EOF
  
  filename = "${local.project_full_name}/README.md"
}

# Docker konfiguratsioon (tingimislik)
resource "local_file" "dockerfile" {
  count = var.include_docker ? 1 : 0
  
  content = <<-EOF
    FROM node:16-alpine
    WORKDIR /app
    COPY . .
    EXPOSE ${local.env_settings[var.environment].port}
    CMD ["npm", "start"]
  EOF
  
  filename = "${local.project_full_name}/Dockerfile"
}

# Käivitamise skript
resource "local_file" "start_script" {
  content = <<-EOF
    #!/bin/bash
    echo "Käivitan ${local.project_full_name} projekti"
    echo "Keskkond: ${var.environment}"
    echo "Port: ${local.env_settings[var.environment].port}"
    
    if [ -f "package.json" ]; then
        npm start
    else
        echo "package.json puudub"
    fi
  EOF
  
  filename = "${local.project_full_name}/scripts/start.sh"
  file_permission = "0755"
}
```text

### 2.2 Mooduli väljundid

Kirjutage `modules/project-setup/outputs.tf`:

```hcl
output "project_path" {
  description = "Projekti kausta tee"
  value       = local.project_full_name
}

output "project_info" {
  description = "Projekti andmed"
  value = {
    name = var.project_name
    team = var.team_name
    environment = var.environment
    full_name = local.project_full_name
    has_docker = var.include_docker
  }
}

output "created_files" {
  description = "Loodud failid"
  value = concat([
    "${local.project_full_name}/config/project.json",
    "${local.project_full_name}/README.md",
    "${local.project_full_name}/scripts/start.sh"
  ], var.include_docker ? ["${local.project_full_name}/Dockerfile"] : [])
}
```text

---

## Ülesanne 3: Mooduli kasutamine (3 punkti)

### 3.1 Peamised muutujad

Kirjutage `variables.tf`:

```hcl
variable "teams" {
  description = "Meeskondade ja projektide konfiguratsioon"
  type = map(object({
    projects = list(object({
      name = string
      environment = string
      include_docker = bool
    }))
  }))
}
```text

### 3.2 Peamine konfiguratsioon

Kirjutage `main.tf`:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Kõikide projektide nimekiri
locals {
  all_projects = flatten([
    for team_name, team in var.teams : [
      for project in team.projects : {
        key = "${team_name}-${project.name}"
        team_name = team_name
        project_name = project.name
        environment = project.environment
        include_docker = project.include_docker
      }
    ]
  ])
  
  # Muuda map'iks for_each jaoks
  projects_map = {
    for project in local.all_projects : project.key => project
  }
}

# Loo kõik projektid
module "projects" {
  source = "./modules/project-setup"
  
  for_each = local.projects_map
  
  project_name = each.value.project_name
  team_name = each.value.team_name
  environment = each.value.environment
  include_docker = each.value.include_docker
}

# Üldine kokkuvõte
resource "local_file" "summary" {
  content = jsonencode({
    total_projects = length(local.all_projects)
    teams_count = length(var.teams)
    projects_by_team = {
      for team_name, team in var.teams : team_name => length(team.projects)
    }
    created_at = timestamp()
  })
  
  filename = "projects-summary.json"
}
```text

### 3.3 Väljundid

Kirjutage `outputs.tf`:

```hcl
output "all_projects" {
  description = "Kõik loodud projektid"
  value = {
    for key, project in module.projects : key => project.project_info
  }
}

output "projects_by_environment" {
  description = "Projektide arv keskkonniti"
  value = {
    for env in ["dev", "test", "prod"] : env => length([
      for key, project in module.projects : project.project_info
      if project.project_info.environment == env
    ])
  }
}

output "summary" {
  description = "Kokkuvõte"
  value = {
    total_projects = length(module.projects)
    total_teams = length(var.teams)
    docker_projects = length([
      for key, project in module.projects : project.project_info
      if project.project_info.has_docker
    ])
  }
}
```bash

---

## Ülesanne 4: Konfiguratsioon ja testimine (1 punkt)

### 4.1 Muutujate väärtused

Kirjutage `terraform.tfvars`:

```hcl
teams = {
  frontend = {
    projects = [
      {
        name = "dashboard"
        environment = "dev"
        include_docker = true
      },
      {
        name = "mobile-app"
        environment = "test"
        include_docker = false
      }
    ]
  }
  
  backend = {
    projects = [
      {
        name = "api"
        environment = "prod"
        include_docker = true
      },
      {
        name = "auth-service"
        environment = "dev"
        include_docker = true
      }
    ]
  }
  
  devops = {
    projects = [
      {
        name = "monitoring"
        environment = "prod"
        include_docker = false
      }
    ]
  }
}
```text

### 4.2 Käivitamine

```bash
# Initsialiseerige
terraform init

# Vaadake plaan
terraform plan

# Rakendage
terraform apply

# Kontrollige tulemusi
terraform output
ls -la
cat projects-summary.json
```text

### 4.3 Testimine

1. Käivitage üks projektiskript:
```bash
chmod +x frontend-dashboard/scripts/start.sh
./frontend-dashboard/scripts/start.sh
```text

2. Vaadake loodud konfiguratsioonifaile:
```bash
cat frontend-dashboard/config/project.json
cat backend-api/README.md
```bash

3. Muutke `terraform.tfvars` - lisage uus projekt või muutke environment. Rakendage muudatused.

---

## Esitamise nõuded

### Kohustuslikud failid
1. Kõik `.tf` failid (main.tf, variables.tf, outputs.tf)
2. Mooduli failid `modules/project-setup/` kaustas
3. `terraform.tfvars` fail
4. Kõik genereeritud projektikaustad
5. `projects-summary.json` fail

### Demonstratsioon
- Näidake, kuidas lisada uut projekti
- Muutke olemasoleva projekti konfiguratsiooni
- Selgitage for_each ja locals kasutamist

### Lühike analüüs (0.5 lk)
1. Mida õppisite moodulite kohta?
2. Millised olid keerulisemad osad?
3. Kuidas saaksite seda praktikas kasutada?

---

## Hindamise kriteeriumid (10 punkti)

- **Mooduli struktuur ja töö** (3p)
- **for_each ja locals kasutamine** (3p)
- **Konfiguratsioonifailide genereerimine** (2p)
- **Muutujate valideerimine** (1p)
- **Dokumentatsioon ja mõistmine** (1p)
