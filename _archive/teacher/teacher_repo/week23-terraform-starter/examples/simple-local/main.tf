# Lihtne Terraform näide - ei vaja cloud'i
# See näide loob faile ja katalooge kohalikus failisüsteemis

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Looge lihtne tekstifail
resource "local_file" "hello" {
  content  = "Tere! See fail on loodud Terraform'i abil."
  filename = "${path.module}/hello.txt"
}

# Looge kataloog
resource "local_directory" "example" {
  path = "${path.module}/example_dir"
}

# Looge konfiguratsioonifail
resource "local_file" "config" {
  content = jsonencode({
    project_name = "Week 23 Lab"
    environment  = "development"
    created_by   = "Terraform"
    timestamp    = timestamp()
  })
  filename = "${path.module}/config.json"
}

# Looge skriptifail
resource "local_file" "script" {
  content = <<-EOF
    #!/bin/bash
    echo "Tere! See skript on loodud Terraform'i abil."
    echo "Projekti nimi: Week 23 Lab"
    echo "Aeg: $(date)"
  EOF
  filename = "${path.module}/script.sh"
}
