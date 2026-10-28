#!/bin/bash
# Nädal 9 labori test (iseseisev): käib docs/week09/lab.md Osad 3-4 läbi samade käskudega,
# salvestab logid nagu õpilane ja jooksutab nende peal C50 testid (classroom50/it24-automatiseerimine/lab09-tests.json).
#
# Kasutus (masinas, kus on docker + compose v2, python3 ja ansible-playbook):
#   bash week09.sh [lab09-starter kaust] [lab09-tests.json]
# Vaikimisi ~/hkhk-automation/lab09-starter ja ~/classroom50/it24-automatiseerimine/lab09-tests.json.
# Vajab vabu porte 8080, 8081, 8090. Töökaust ~/lab09 (kausta nimi määrab konteinerite nimed), lõpus koristab.
set -uo pipefail

STARTER="${1:-$HOME/hkhk-automation/lab09-starter}"
TESTID="${2:-$HOME/classroom50/it24-automatiseerimine/lab09-tests.json}"
D="$HOME/lab09"
OK=0; FAIL=0
ok()   { echo "OK   $1"; OK=$((OK+1)); }
fail() { echo "FAIL $1"; [ -n "${2:-}" ] && echo "$2" | tail -5 | sed 's/^/     /'; FAIL=$((FAIL+1)); }
has()  { local nimi=$1 fail=$2 muster=$3; grep -qE "$muster" "$fail" && ok "$nimi" || fail "$nimi" "$(cat "$fail")"; }

command -v docker >/dev/null && docker compose version >/dev/null 2>&1 || { echo "docker või compose v2 puudub"; exit 1; }
command -v ansible-playbook >/dev/null || { echo "ansible-playbook puudub (pip install ansible-core)"; exit 1; }
[ -e "$D" ] && { echo "$D on juba olemas, kustuta see enne"; exit 1; }

cp -r "$STARTER" "$D" && cd "$D" && rm -rf .git
docker rm -f lab09-skript >/dev/null 2>&1

# Osa 3
docker compose up -d 2>&1 | tee logid/01-up.txt >/dev/null
has "3.2 esimene up: Started" logid/01-up.txt 'Started'
curl -fs localhost:8080 | grep -q 'Welcome to nginx' && ok "3.2 nginx vastab 8080" || fail "3.2 nginx vastab 8080"
docker compose up -d 2>&1 | tee logid/02-up-uuesti.txt >/dev/null
has "3.3 teine up: Running" logid/02-up-uuesti.txt 'Running'
! grep -qE 'Created|Started' logid/02-up-uuesti.txt && ok "3.3 teine up: ei loonud midagi" || fail "3.3 teine up: ei loonud midagi" "$(cat logid/02-up-uuesti.txt)"
docker rm -f lab09-cache-1 2>&1 | tee logid/03-taastamine.txt >/dev/null
docker compose up -d 2>&1 | tee -a logid/03-taastamine.txt >/dev/null
has "3.4 cache loodi uuesti" logid/03-taastamine.txt 'cache-1 +(Created|Started)'
has "3.4 web jäi alles" logid/03-taastamine.txt 'web-1 +Running'
sed -i 's/"8080:80"/"8081:80"/' compose.yaml
docker compose up -d 2>&1 | tee logid/04-port.txt >/dev/null
has "3.5 web loodi uuesti (Recreate)" logid/04-port.txt 'web-1 +Recreate'
has "3.5 cache jäi alles" logid/04-port.txt 'cache-1 +Running'
bash run.sh 2>&1 | tee logid/05-run-kaks-korda.txt >/dev/null
bash run.sh 2>&1 | tee -a logid/05-run-kaks-korda.txt >/dev/null
has "3.6 teine run: Conflict" logid/05-run-kaks-korda.txt 'Conflict|already in use'
has "3.6 skript trükib ikka valmis" logid/05-run-kaks-korda.txt 'valmis'
cat > run.sh <<'SH'
#!/bin/bash
if docker ps -a --format '{{.Names}}' | grep -qx lab09-skript; then
  echo "lab09-skript on juba olemas, ei tee midagi"
else
  docker run -d --name lab09-skript -p 8090:80 nginx:1.27-alpine
  echo "valmis"
fi
SH
docker rm -f lab09-skript >/dev/null
bash run.sh 2>&1 | tee logid/06-run-parandatud.txt >/dev/null
bash run.sh 2>&1 | tee -a logid/06-run-parandatud.txt >/dev/null
has "3.7 parandatud: juba olemas" logid/06-run-parandatud.txt 'juba olemas'

# Osa 4
cp lisa/triiv.yml triiv.yml; rm -f /tmp/lab09-nginx.conf
export ANSIBLE_LOCALHOST_WARNING=False ANSIBLE_INVENTORY_UNPARSED_WARNING=False
ansible-playbook triiv.yml >/dev/null; ansible-playbook triiv.yml | grep -q 'changed=0' && ok "4.1 teine jooks changed=0" || fail "4.1 teine jooks changed=0"
sed -i 's/1m/50m/' /tmp/lab09-nginx.conf
ansible-playbook triiv.yml --check --diff 2>&1 | tee logid/07-triiv-ansible.txt >/dev/null
cat /tmp/lab09-nginx.conf >> logid/07-triiv-ansible.txt
grep -q 50m /tmp/lab09-nginx.conf && ok "4.1 --check ei muutnud faili" || fail "4.1 --check ei muutnud faili"
ansible-playbook triiv.yml >> logid/07-triiv-ansible.txt 2>&1; cat /tmp/lab09-nginx.conf >> logid/07-triiv-ansible.txt
grep -q 'size 1m' /tmp/lab09-nginx.conf && ok "4.1 tavaline jooks kirjutas üle" || fail "4.1 tavaline jooks kirjutas üle"
docker compose exec -T web sh -c 'echo "MATI PARANDAS" > /usr/share/nginx/html/index.html'
curl -s localhost:8081 > logid/08-triiv-konteiner.txt
docker compose up -d >> logid/08-triiv-konteiner.txt 2>&1
curl -s localhost:8081 | tee -a logid/08-triiv-konteiner.txt | grep -q 'MATI' && ok "4.2 up -d jättis triivi alles" || fail "4.2 up -d jättis triivi alles"
docker compose up -d --force-recreate >> logid/08-triiv-konteiner.txt 2>&1
sleep 2; curl -s localhost:8081 | tee -a logid/08-triiv-konteiner.txt | grep -q 'Welcome to nginx' && ok "4.2 force-recreate eemaldas triivi" || fail "4.2 force-recreate eemaldas triivi"

# C50 testid nende logide peal (README osad jäävad punaseks, need on käsitsi täidetavad)
if [ -f "$TESTID" ]; then
  echo "--- C50 testid (2, 3, 11, 12 on README/kodekloud ja jäävad siin punaseks) ---"
  python3 - "$TESTID" <<'PY'
import json, subprocess, sys
for t in json.load(open(sys.argv[1]))["tests"]:
    r = subprocess.run(["bash", "-c", t["run"]], capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=120)
    print(("OK   " if r.returncode == 0 else "--   ") + t["name"] + ("" if r.returncode == 0 else ": " + r.stdout.strip()[:100]))
PY
fi

docker compose down >/dev/null 2>&1; docker rm -f lab09-skript >/dev/null 2>&1
cd "$HOME" && rm -rf "$D"
echo "Kokku: $OK OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
