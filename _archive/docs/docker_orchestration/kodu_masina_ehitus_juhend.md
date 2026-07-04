# Lihtne VM Setup Docker/Kubernetes Õppimiseks

!!! tip "Navigeerimine"
    Kasuta paremal olevat sisukorda kiireks navigeerimiseks ↗️

## 1. Kõik Virtualization Valikud

### Local Solutions

| Variant | OS Support | Setup Aeg | Keerukus | Maksumus | Sobib |
|---------|------------|-----------|----------|----------|-------|
| **Multipass** | Win/Mac/Linux | 5 min | Madal | Tasuta | Algajatele |
| **VirtualBox** | Win/Mac/Linux | 20 min | Keskmine | Tasuta | Õppimiseks |
| **Vagrant + VirtualBox** | Win/Mac/Linux | 15 min | Keskmine | Tasuta | Reproducible |
| **WSL2** | Ainult Windows | 10 min | Madal | Tasuta | Windows dev |
| **VMware** | Win/Mac/Linux | 25 min | Keskmine | Tasuline | Professional |

### Cloud Solutions

| Platvorm | Setup Aeg | Keerukus | Maksumus/kuu | **Free Trial** | Sobib |
|----------|-----------|----------|--------------|----------------|-------|
| **GitHub Codespaces** | 2 min | Madal | 0-36€ | 120 CPU-h/kuu | Students/Teams |
| **GitPod** | 2 min | Madal | 0-25€ | 50h/kuu | Git workflows |
| **AWS EC2** | 10 min | Kõrge | 15-50€ | **12 kuud tasuta** | Enterprise |
| **Azure VM** | 10 min | Kõrge | 20-60€ | **12 kuud + $200** | Microsoft stack |
| **Google Cloud VM** | 10 min | Kõrge | 10-40€ | **90 päeva + $300** | Google services |

### Tasuta Trial'ide detailid

| Platvorm | Free Credit | Kestus | VM Specs | Piirangud |
|----------|-------------|--------|----------|-----------|
| **AWS Free Tier** | - | 12 kuud | t2.micro (1 vCPU, 1GB) | 750h/kuu |
| **Azure Free** | $200 | 12 kuud | B1s (1 vCPU, 1GB) | Krediidi piires |
| **Google Cloud** | $300 | 90 päeva | e2-micro (1 vCPU, 1GB) | Krediidi piires |
| **GitHub Education** | - | Õpingute ajal | 2-4 core, 8GB | 120 CPU-h/kuu |

## VM Network Setup

### Multipass Network
```bash
# Vaata VM IP aadressi
multipass list
# või
multipass info dev-lab

# VM sees kontrolli network'i
ip addr show
ping google.com

# Host'ist ühenda VM'iga
ssh ubuntu@VM_IP_ADDRESS
```text

### VirtualBox Network (Täpsemad seaded)

| Network Mode | Host Access | Internet | VM-VM | Sobib |
|--------------|-------------|----------|-------|-------|
| **NAT** | Port forward |  |  | Lihtne setup |
| **Bridged** | Direct IP |  |  | Production-like |
| **Host-Only** | Direct IP |  |  | Isolated dev |

**Soovitatav setup - Bridged:**
```bash
# VirtualBox'is:
# Settings > Network > Adapter 1
# Attached to: Bridged Adapter
# Name: [Your network card]

# VM käivitamise järel:
ip addr show  # Näed VM IP aadressi
```text

---

## VSCode Setup ja Extensions

### 1. VSCode Installimine + Essential Extensions

```bash
# Kohustuslikud extensions:
- Remote - SSH (Microsoft)
- Docker (Microsoft)  
- Kubernetes (Microsoft)
- YAML (Red Hat)

# Kasulikud development extensions:
- GitLens (Git history)
- Auto Rename Tag
- Bracket Pair Colorizer
- Material Icon Theme
```text

### 2. SSH Connection Setup

**Host masinas (Windows PowerShell/macOS Terminal):**
```bash
# 1. Genereeri SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# 2. Kopeeri public key VM'i
# Multipass:
multipass transfer ~/.ssh/id_ed25519.pub dev-lab:/home/ubuntu/.ssh/authorized_keys

# VirtualBox (pärast bridged network setup):
ssh-copy-id ubuntu@VM_IP_ADDRESS
```text

**SSH Config (～/.ssh/config):**
```bash
Host dev-lab
    HostName VM_IP_ADDRESS  # Asenda tegeliku IP'ga
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    Port 22
```text

### 3. VSCode Remote Connection

```bash
# 1. VSCode's vajuta F1
# 2. Tüübi: "Remote-SSH: Connect to Host"
# 3. Vali "dev-lab" või lisa uus host
# 4. Sisesta SSH command: ssh ubuntu@VM_IP_ADDRESS
# 5. VSCode avaneb connected mode's
```text

**Test connection:**
```bash
# VSCode terminal's (VM sees):
docker --version
kubectl version --client
git --version
```text

## Süsteeminõuded

| Komponent | Minimaalne | Soovitatav |
|-----------|------------|------------|
| **RAM** | 8GB | 16GB |
| **CPU** | 4 tuuma | 6+ tuuma |
| **Storage** | 50GB SSD | 100GB SSD |
| **Internet** | 10 Mbps | 50+ Mbps |

## Valige variant:

### Variant A: Multipass (soovitatud)
```bash
# Windows/macOS/Linux
multipass launch --name dev-lab --memory 8G --disk 50G --cpus 4
multipass shell dev-lab
```text

### Variant B: VirtualBox
```bash
# Manual setup:
# 1. Download Ubuntu Server 22.04 LTS
# 2. Create VM: 8GB RAM, 4 CPU, 50GB disk  
# 3. Install Ubuntu
# 4. SSH into VM
```text

### Variant C: WSL2 (ainult Windows)
```bash
wsl --install -d Ubuntu
# Restart required, then open Ubuntu terminal
```text

---

## OS-spetsiifilised seadistamise juhendid

### Windows Setup {#windows-setup}

**Windows 10/11:**
```bash
# 1. Install Multipass
# Download from: https://multipass.run/install

# 2. Enable WSL2 (alternative)
wsl --install -d Ubuntu

# 3. Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# 4. Install VSCode
# Download from: https://code.visualstudio.com/
```text

**Windows PowerShell setup:**
```powershell
# Enable developer mode
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install Chocolatey (optional)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```text

### macOS Setup {#macos-setup}

**macOS (Intel/Apple Silicon):**
```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Multipass
brew install --cask multipass

# 3. Install Docker Desktop
brew install --cask docker

# 4. Install VSCode
brew install --cask visual-studio-code
```text

**Apple Silicon specific:**
```bash
# For Apple Silicon Macs, use ARM64 images
multipass launch --name dev-lab --memory 8G --disk 50G --cpus 4 --cloud-init cloud-config.yaml
```text

### Linux Setup {#linux-setup}

**Ubuntu/Debian:**
```bash
# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install Multipass
sudo snap install multipass --classic

# 3. Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 4. Install VSCode
sudo snap install code --classic
```text

**CentOS/RHEL/Fedora:**
```bash
# 1. Install Multipass
sudo dnf install snapd
sudo snap install multipass --classic

# 2. Install Docker
sudo dnf install docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# 3. Install VSCode
sudo dnf install code
```text

---

## 2. Post-Install Setup (VM sees)

Kui VM töötab, käivitage need käsud:

```bash
# Süsteemi uuendamine
sudo apt update && sudo apt upgrade -y

# Development tools
sudo apt install -y git curl wget vim tree htop

# Docker install
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Minikube install
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Kubectl install  
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Start Minikube
minikube start --driver=docker --memory=4096 --cpus=2
```bash

---

## 3. Git Setup

```bash
# Configure Git
git config --global user.name "Sinu Nimi"
git config --global user.email "sinu.email@example.com"

# Generate SSH key for GitHub
ssh-keygen -t ed25519 -C "sinu.email@example.com"
cat ~/.ssh/id_ed25519.pub

# Copy output and add to GitHub Settings > SSH Keys
```text

---

## 4. Test Everything

```bash
# Test Docker
docker run hello-world

# Test Kubernetes
kubectl get nodes

# Test Git
git clone https://github.com/your-username/your-repo.git
```text

---

## 5. Daily Workflow

```bash
# Start VM
multipass shell dev-lab  # või VirtualBox/WSL2

# Work in projects directory
mkdir -p ~/projects
cd ~/projects

# Use git normally
git clone <repository>
cd <project>
# Edit files, commit, push
```bash

---

## Kui midagi ei tööta

**Docker permission error:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```text

**Minikube ei käivitu:**
```bash
minikube delete
minikube start --driver=docker
```text

**VM aeglane:**
- Suurendage RAM vähemalt 8GB-le
- Veenduge, et SSD on kasutusel
