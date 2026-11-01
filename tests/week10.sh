#!/bin/bash
# Nädal 10 labori test: C50 testid (classroom50/it24-automatiseerimine/lab10-tests.json) kolmel variandil.
#   tühi starter   -> kõik põhitestid kukuvad
#   lahendus       -> kõik põhitestid läbivad (vm.tf juhendist, päris tofu init; logid on juhendi oodatud väljundid)
#   lahendus + kodutöö -> põhitestid ja BOONUS läbivad
#   tüüpiline viga -> terraform.tfvars Gitis, vormindamata vm.tf, teine plaan muudatusega
# Proxmoxiga see skript ei ühendu: logid on kirjutatud juhendi "Oodatav tulemus" plokkide järgi.
#
# Kasutus: bash week10.sh [lab10-starter] [lab10-tests.json]
# Vajab: python3, git, curl (tofu laetakse alla kausta /tmp/tofu nagu automaatkontrollis).
set -uo pipefail

STARTER="${1:-$HOME/hkhk-automation/lab10-starter}"
TESTID="${2:-$HOME/classroom50/it24-automatiseerimine/lab10-tests.json}"
JUHEND="$(dirname "$0")/../docs/week10/lab.md"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# vm.tf juhendi sammust 2.1 (esimene hcl plokk)
awk '/^```hcl/{f++; next} /^```/{if(f==1) exit} f==1' "$JUHEND" > "$TMP/vm.tf"
grep -q proxmox_virtual_environment_vm "$TMP/vm.tf" || { echo "vm.tf ei leitud juhendist"; exit 1; }

kaivita() {  # $1 = kaust, $2 = oodatud: lapi|kukub ; trükib iga testi tulemuse
  local d=$1 n=0 ok=0
  while IFS= read -r -d '' rida; do
    local nimi setup run
    nimi=$(python3 -c 'import json,sys;print(json.loads(sys.argv[1])["name"])' "$rida")
    setup=$(python3 -c 'import json,sys;print(json.loads(sys.argv[1]).get("setup",""))' "$rida")
    run=$(python3 -c 'import json,sys;print(json.loads(sys.argv[1])["run"])' "$rida")
    [ -n "$setup" ] && (cd "$d" && sh -c "$setup") >/dev/null 2>&1
    if out=$(cd "$d" && timeout 300 sh -c "$run" 2>&1); then echo "  läbib  $nimi"; ok=$((ok+1))
    else echo "  KUKUB  $nimi: $(echo "$out" | tail -1)"; fi
    n=$((n+1))
  done < <(python3 -c 'import json,sys
for t in json.load(open(sys.argv[1]))["tests"]: sys.stdout.write(json.dumps(t)+"\0")' "$TESTID")
  echo "  kokku $ok/$n läbis"
}

uus() {  # $1 = nimi -> kaust starteri koopiaga ja git repoga
  local d="$TMP/$1"
  cp -r "$STARTER" "$d"; rm -rf "$d/.git"
  git -C "$d" init -q -b main
  echo "$d"
}

commit() { git -C "$1" add -A && git -C "$1" -c user.name=t -c user.email=t@t commit -qm t; }

logid() {  # $1 = kaust
  local L="$1/logid"
  cat > "$L/01-plan.txt" <<'EOF'
OpenTofu will perform the following actions:

  # proxmox_virtual_environment_vm.veeb will be created
  + resource "proxmox_virtual_environment_vm" "veeb" {
      + name      = "tofu-mtamm"
      + vm_id     = 4100
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + ip = (known after apply)

Saved the plan to: tfplan
EOF
  printf '\e[0m\e[1mproxmox_virtual_environment_vm.veeb: Creating...\e[0m\nproxmox_virtual_environment_vm.veeb: Creation complete after 48s [id=4100]\n\n\e[0m\e[1m\e[32mApply complete! Resources: 1 added, 0 changed, 0 destroyed.\e[0m\r\n\nOutputs:\n\nip = "192.168.125.143"\n' > "$L/02-apply.txt"
  printf 'proxmox_virtual_environment_vm.veeb: Refreshing state... [id=4100]\n\n\e[0m\e[1m\e[32mNo changes.\e[0m\e[1m Your infrastructure matches the configuration.\e[0m\n' > "$L/03-plan-uuesti.txt"
  cat > "$L/04-malu.txt" <<'EOF'
  # proxmox_virtual_environment_vm.veeb will be updated in-place
  ~ resource "proxmox_virtual_environment_vm" "veeb" {
      ~ memory {
          ~ dedicated      = 1024 -> 2048
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
proxmox_virtual_environment_vm.veeb: Modifying... [id=4100]
proxmox_virtual_environment_vm.veeb: Modifications complete after 31s [id=4100]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
EOF
  cat > "$L/05-kasitsi-kustutatud.txt" <<'EOF'
  # proxmox_virtual_environment_vm.veeb will be created
  + resource "proxmox_virtual_environment_vm" "veeb" {
    }

Plan: 1 to add, 0 to change, 0 to destroy.
proxmox_virtual_environment_vm.veeb: Creating...
proxmox_virtual_environment_vm.veeb: Creation complete after 52s [id=4100]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
EOF
  cat > "$L/06-kirjeldus-eemaldatud.txt" <<'EOF'
  # proxmox_virtual_environment_vm.veeb will be destroyed
  # (because proxmox_virtual_environment_vm.veeb is not in configuration)
  - resource "proxmox_virtual_environment_vm" "veeb" {
    }

Plan: 0 to add, 0 to change, 1 to destroy.
proxmox_virtual_environment_vm.veeb: Refreshing state... [id=4100]

No changes. Your infrastructure matches the configuration.
EOF
  echo 'proxmox_virtual_environment_vm.veeb' > "$L/07-state.txt"
  printf 'Plan: 0 to add, 0 to change, 1 to destroy.\nproxmox_virtual_environment_vm.veeb: Destroying... [id=4100]\nproxmox_virtual_environment_vm.veeb: Destruction complete after 6s\n\nDestroy complete! Resources: 1 destroyed.\n' > "$L/08-destroy.txt"
}

lahendus() {  # $1 = kaust: juhendi järgi tehtud töö
  local d=$1
  cp "$TMP/vm.tf" "$d/vm.tf"
  sed -i 's/dedicated = 1024/dedicated = 2048/' "$d/vm.tf"   # samm 3.2
  cp "$d/terraform.tfvars.example" "$d/terraform.tfvars"      # samm 1.4 (gitignore'is)
  (cd "$d" && /tmp/tofu/tofu init -input=false -no-color >/dev/null && /tmp/tofu/tofu fmt >/dev/null) || { echo "tofu init kukkus"; exit 1; }
  echo '{"version":4,"resources":[]}' > "$d/terraform.tfstate"; touch "$d/tfplan"
  logid "$d"
  sed -i 's/^\*\*Sinu nimi:\*\* _vastus_/**Sinu nimi:** **Mari Tamm**/; s/^_vastus_$/Plaan näitas `No changes.` See on sama mis Ansible changed=0./' "$d/README.md"
}

kodutoo() {  # $1 = kaust: kodutöö juhendi järgi
  local d=$1
  python3 - "$d/versions.tf" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read()
a='      version = "~> 0.118.0"\n    }\n'
assert s.count(a)==1
s=s.replace(a, a+'    local = {\n      source  = "hashicorp/local"\n      version = "~> 2.9"\n    }\n')
open(p,'w').write(s)
PY
  printf '[tofu]\n${ip} ansible_user=kasutaja\n' > "$d/inventory.tftpl"
  cat > "$d/inventory.tf" <<'EOF'
resource "local_file" "inventory" {
  filename = "${path.module}/inventory.ini"
  content = templatefile("${path.module}/inventory.tftpl", {
    ip = proxmox_virtual_environment_vm.veeb.ipv4_addresses[1][0]
  })
}
EOF
  printf '[tofu]\n192.168.125.143 ansible_user=kasutaja\n' > "$d/logid/k1-inventory.ini"
  printf '192.168.125.143 | SUCCESS => {\n    "changed": false,\n    "ping": "pong"\n}\n' > "$d/logid/k1-ping.txt"
  (cd "$d" && /tmp/tofu/tofu init -input=false -no-color >/dev/null && /tmp/tofu/tofu fmt -check) || echo "  HOIATUS: kodutöö failid ei ole tofu fmt järgi vormindatud"
}

# tofu nagu automaatkontrollis
setup=$(python3 -c 'import json,sys;print([t for t in json.load(open(sys.argv[1]))["tests"] if t.get("setup")][0]["setup"])' "$TESTID")
sh -c "$setup" || { echo "tofu allalaadimine ei õnnestunud"; exit 1; }

echo "== tühi starter (kõik põhitestid peavad kukkuma)"
d=$(uus tyhi); commit "$d"; kaivita "$d"

echo "== lahendus (kõik põhitestid peavad läbima, BOONUS kukub)"
d=$(uus lahendus); lahendus "$d"; commit "$d"; kaivita "$d"

echo "== lahendus + kodutöö (kõik peavad läbima)"
d=$(uus kodutoo); lahendus "$d"; kodutoo "$d"; commit "$d"; kaivita "$d"

echo "== tüüpiline viga (testid 2, 3, 7 peavad kukkuma)"
d=$(uus viga); lahendus "$d"
git -C "$d" add -f terraform.tfvars
sed -i 's/^  name            =/  name =/' "$d/vm.tf"
printf 'Plan: 0 to add, 1 to change, 0 to destroy.\n' > "$d/logid/03-plan-uuesti.txt"
commit "$d"; kaivita "$d"
