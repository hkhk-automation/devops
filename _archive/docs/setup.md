---
title: Arenduskeskkond Vagrantiga
tags:
  - ansible
  - vagrant
  - setup
---

# Mis on Vagrant?

Vagrant on tööriist, mis haldab virtuaalmasinaid deklaratiivse `Vagrantfile` abil. Eelis käsitsi VM-ide loomisest:

- Kiirem: 1 käsk vs kümned käsitsi klõpsud
- Korduv: sama seadistus igal masinal
- Jagatav: `Vagrantfile` on tekst, hoia GitHubis

## Mida `Vagrantfile` teeb allpool toodud näites

- Loob 2 Ubuntu 22.04 VM-i (VirtualBox)
- Controller: `192.168.56.10` (siin jookseb Ansible)
- Web server: `192.168.56.11` (hallatav sihtmasin)
- Kasutajad: `vagrant/vagrant` (vaikimisi), luuakse `ansible` kasutaja parooliga `ansible123`
- Sudo: passwordless
- SSH: lubatakse parooliga autentimine esialgseks seadistuseks

## Eeltingimused

- VirtualBox
- Vagrant
- Windows: soovituslik terminal on Git Bash: <https://git-scm.com/download/win>

## Näidis Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # Controller (Ansible control node)
  config.vm.define "controller" do |c|
    c.vm.hostname = "controller"
    c.vm.network "private_network", ip: "192.168.56.10"
    c.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
    c.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      sudo apt-get install -y ansible openssh-server
      sudo useradd -m -s /bin/bash ansible || true
      echo "ansible:ansible123" | sudo chpasswd
      echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-ansible
      sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sudo systemctl restart ssh
    SHELL
  end

  # Web server (managed node)
  config.vm.define "web" do |w|
    w.vm.hostname = "web"
    w.vm.network "private_network", ip: "192.168.56.11"
    w.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
    w.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      sudo apt-get install -y openssh-server
      sudo useradd -m -s /bin/bash ansible || true
      echo "ansible:ansible123" | sudo chpasswd
      echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-ansible
      sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sudo systemctl restart ssh
    SHELL
  end
end
```

## Kiirkäivitamine

```bash
vagrant up
vagrant status
vagrant ssh controller
```

## Inventar näide

```ini
[controller]
192.168.56.10 ansible_user=ansible ansible_password=ansible123

[web]
192.168.56.11 ansible_user=ansible ansible_password=ansible123
```


