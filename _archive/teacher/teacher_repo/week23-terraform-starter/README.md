# Week 23: Terraform Infrastructure as Code

## Mis on Terraform?

Terraform on tööriist, mis võimaldab hallata infrastruktuuri (serverid, võrgud, andmebaasid) kui koodi. Kujutage ette seda nagu "retsepti" - kirjutad üles, mida soovid, ja Terraform teeb selle sinu eest.

### Miks Terraform?

- **Lihtne** - üks fail kirjeldab kogu infrastruktuuri
- **Turvaline** - vähem inimeste vigu
- **Kiire** - automatiseeritud juurutamine
- **Taaskasutatav** - sama kood töötab erinevates keskkondades

## Projekti struktuur

```
terraform-basics-starter/
├── examples/
│   ├── simple-local/          # Lihtne kohalik näide
│   ├── aws-basic/             # AWS põhilised ressursid
│   └── multi-environment/     # Mitme keskkonna näide
├── templates/
│   ├── main.tf.example        # Põhiline Terraform fail
│   ├── variables.tf.example   # Muutujate näide
│   └── outputs.tf.example     # Väljundite näide
└── docs/
    ├── terraform-basics.md    # Terraform'i põhialused
    └── aws-resources.md       # AWS ressursid
```

## Kuidas kasutada

1. **Kopeerige näide** - valige sobiv näide examples/ kaustast
2. **Muutke väärtusi** - seadistage oma väärtused
3. **Käivitage** - `terraform init`, `terraform plan`, `terraform apply`

## Näited

### Lihtne kohalik näide (ei vaja cloud'i)

```hcl
# Looge lihtne tekstifail
resource "local_file" "hello" {
  content  = "Hello, Terraform!"
  filename = "hello.txt"
}
```

### AWS näide (vajab AWS kontot)

```hcl
# Looge EC2 server
resource "local_file" "web_config" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = {
    Name = "Web Server"
  }
}
```

## Õppimise sammud

1. **Alustage lihtsast** - kasutage local provider'it
2. **Õppige süntaksit** - HCL keel on lihtne
3. **Proovige AWS** - kui olete valmis
4. **Ehitage suuremat** - mitme keskkonna infrastruktuur

## Abi ja ressursid

- [Terraform Documentation](https://www.terraform.io/docs)
- [HCL Language](https://www.terraform.io/docs/language)
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
