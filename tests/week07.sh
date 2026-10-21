#!/bin/bash
# Nädal 7 labori test (CI): käib docs/week07/lab.md kohalikud sammud läbi ja kontrollib,
# et iga "meelega viga" annab juhendis lubatud tulemuse ja iga parandus töötab.
# GitHubi runnerit see ei jooksuta: workflow'd kontrollitakse YAML-i ja käskude tasemel,
# runneri sammud (pytest, docker build/run, curl) korratakse siin VM-is.
#
# Kasutus (VM-is, kus Docker on nädal 5 Osa 0 järgi paigaldatud ja kasutaja on docker grupis):
#   bash week07.sh
# Vajab vaba porti 5000 ja internetti (pip, Docker Hub). Töökaust ~/lab07-test, lõpus koristab.
# Väljund: iga samm OK/FAIL, lõpus kokkuvõte.
set -uo pipefail

D="$HOME/lab07-test"
OK=0; FAIL=0
ok()   { echo "OK   $1"; OK=$((OK+1)); }
fail() { echo "FAIL $1"; [ -n "${2:-}" ] && echo "$2" | tail -5 | sed 's/^/     /'; FAIL=$((FAIL+1)); }
check() { local nimi=$1; shift; if out=$("$@" 2>&1); then ok "$nimi"; else fail "$nimi" "$out"; fi; }

command -v docker >/dev/null || { echo "docker puudub (nädal 5 Osa 0)"; exit 1; }
docker info >/dev/null 2>&1 || { echo "docker ei vasta: kas kasutaja on docker grupis? (nädal 5 Osa 0)"; exit 1; }
ss -ltn | grep -qE "[:.]5000 " && { echo "port 5000 on kinni, vabasta see enne testi"; exit 1; }
[ -e "$D" ] && { echo "$D on juba olemas, kustuta see enne testi"; exit 1; }

mkdir -p "$D/flask" "$D/.github/workflows" && cd "$D" || exit 1
trap 'docker rm -f flask7 >/dev/null 2>&1' EXIT

# Nädal 5 Flask (lõppseis: 0.0.0.0) + Dockerfile (requirements enne koodi)
cat > flask/app.py <<'EOF'
from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():
    return "Tere konteinerist!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF
echo 'flask==3.0.3' > flask/requirements.txt
cat > flask/Dockerfile <<'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# --- Osa 0: venv
python3 -m venv .venv >/dev/null 2>&1
check "Osa 0: venv loodud" test -x .venv/bin/pytest -o -x .venv/bin/pip
.venv/bin/pip install -q -r flask/requirements.txt pytest >/dev/null 2>&1
check "Osa 0: pytest venv'is olemas" test -x .venv/bin/pytest
PYTEST=.venv/bin/pytest

# --- Osa 1: esimene test, meelega viga, parandus
cat > flask/test_app.py <<'EOF'
from app import app


def test_avaleht_vastab():
    vastus = app.test_client().get("/")
    assert vastus.status_code == 200
    assert "Tere" in vastus.get_data(as_text=True)
EOF
check "Osa 1: 1 passed" sh -c "$PYTEST flask -v | grep -q '1 passed'"
sed -i 's/"Tere" in/"Tervist" in/' flask/test_app.py
out=$($PYTEST flask -v 2>&1); rc=$?
check "Osa 1: vale tekst -> exit 1" test "$rc" -eq 1
check "Osa 1: väljundis AssertionError koos tegeliku tekstiga" sh -c "echo \"\$1\" | grep -q \"assert 'Tervist' in 'Tere konteinerist!'\"" _ "$out"
sed -i 's/"Tervist" in/"Tere" in/' flask/test_app.py

# --- Osa 2: baas-workflow parsib
cat > .github/workflows/ci.yml <<'EOF'
name: CI

on: push

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "tere runnerist"
EOF
yamlok() { .venv/bin/python -c 'import sys,yaml; yaml.safe_load(open(sys.argv[1]))' "$1"; }
.venv/bin/pip install -q pyyaml >/dev/null 2>&1
check "Osa 2: ci.yml on korrektne YAML" yamlok .github/workflows/ci.yml

# --- Osa 3: tühi masin. Runneri olukorrad korratakse puhtas venv'is / tühjas kaustas.
python3 -m venv /tmp/lab07-tyhi-$$ >/dev/null 2>&1; T=/tmp/lab07-tyhi-$$
check "Osa 3.1: ilma pytestita -> command not found (127)" sh -c "PATH=$T/bin:/usr/bin:/bin; cd /tmp; pytest flask -v >/dev/null 2>&1; [ \$? -eq 127 ]"
$T/bin/pip install -q pytest >/dev/null 2>&1
check "Osa 3.2: ilma koodita -> 'file or directory not found', exit 4" sh -c "cd /tmp && out=\$($T/bin/pytest flask -v 2>&1); rc=\$?; echo \"\$out\" | grep -q 'file or directory not found: flask' && [ \$rc -eq 4 ]"
check "Osa 3.3: ilma Flaskita -> No module named 'flask'" sh -c "cd '$D' && $T/bin/pytest flask -v 2>&1 | grep -q \"No module named 'flask'\""
$T/bin/pip install -q -r flask/requirements.txt >/dev/null 2>&1
check "Osa 3.3: pärast requirements'it 1 passed" sh -c "cd '$D' && $T/bin/pytest flask -v | grep -q '1 passed'"

# --- Osa 4: töötab minu masinas
sed -i '1i import requests' flask/app.py
.venv/bin/pip install -q requests >/dev/null 2>&1
check "Osa 4: venv'is (requests olemas) roheline" sh -c "$PYTEST flask -q | grep -q passed"
check "Osa 4: puhtas keskkonnas No module named 'requests'" sh -c "$T/bin/pytest flask -v 2>&1 | grep -q \"No module named 'requests'\""
sed -i '/^import requests$/d' flask/app.py
check "Osa 4: import eemaldatud -> puhtas keskkonnas roheline" sh -c "$T/bin/pytest flask -q | grep -q passed"
rm -rf "$T"

# --- Osa 6: konteiner, /health puudub -> curl 22 / 404
docker build -q -t lab07-flask ./flask >/dev/null 2>&1
check "Osa 6: image ehitub" docker image inspect lab07-flask
docker run -d -p 5000:5000 --name flask7 lab07-flask >/dev/null 2>&1
curl -fsS --retry 10 --retry-all-errors --retry-delay 1 localhost:5000/health >/dev/null 2>&1; rc=$?
check "Osa 6: /health puudub -> curl exit 22 (404)" test "$rc" -eq 22
check "Osa 6: docker logs näitab GET /health 404" sh -c 'docker logs flask7 2>&1 | grep -q "GET /health HTTP/1.1\" 404"'
docker rm -f flask7 >/dev/null 2>&1

# --- Osa 7: test enne koodi
cat >> flask/test_app.py <<'EOF'


def test_health_vastab_ok():
    vastus = app.test_client().get("/health")
    assert vastus.status_code == 200
    assert vastus.get_json() == {"status": "ok"}
EOF
check "Osa 7.1: uus test punane, assert 404 == 200" sh -c "$PYTEST flask -v 2>&1 | grep -q 'assert 404 == 200'"
python3 - <<'EOF'
p = "flask/app.py"
s = open(p).read()
s = s.replace('    return "Tere konteinerist!"\n',
              '    return "Tere konteinerist!"\n\n@app.route("/health")\ndef health():\n    return {"status": "ok"}\n', 1)
open(p, "w").write(s)
EOF
cat >> flask/test_app.py <<'EOF'


def test_olematu_annab_404():
    assert app.test_client().get("/olematu").status_code == 404
EOF
check "Osa 7.3: 3 passed" sh -c "$PYTEST flask -v | grep -q '3 passed'"
docker build -q -t lab07-flask ./flask >/dev/null 2>&1
docker run -d -p 5000:5000 --name flask7 lab07-flask >/dev/null 2>&1
check "Osa 7.2: konteineris /health vastab ok" sh -c 'curl -fsS --retry 10 --retry-all-errors --retry-delay 1 localhost:5000/health | grep -q "\"status\":\"ok\""'
docker rm -f flask7 >/dev/null 2>&1

# --- Lõppseis: labi Osa 3 + 5 + 6 workflow koos
cat > .github/workflows/ci.yml <<'EOF'
name: CI

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
      - run: pip install -r flask/requirements.txt pytest
      - run: pytest flask -v

  konteiner:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: docker build -t flask-app ./flask
      - run: docker run -d -p 5000:5000 --name flask1 flask-app
      - run: curl -fsS --retry 10 --retry-all-errors --retry-delay 1 localhost:5000/health
      - if: failure()
        run: docker logs flask1
EOF
check "Lõpp: ci.yml on korrektne YAML" yamlok .github/workflows/ci.yml
check "Lõpp: kaks job'i, konteiner needs test, push + pull_request" .venv/bin/python - <<'EOF'
import yaml
d = yaml.safe_load(open(".github/workflows/ci.yml"))
on = d.get(True, d.get("on"))           # PyYAML loeb võtme "on" kui True
assert set(d["jobs"]) == {"test", "konteiner"}, d["jobs"].keys()
assert d["jobs"]["konteiner"]["needs"] == "test"
assert "push" in on and "pull_request" in on
EOF

echo
echo "Kokku: $OK OK, $FAIL FAIL  ($(.venv/bin/pytest --version 2>&1), $(docker --version), $(. /etc/os-release; echo "$PRETTY_NAME"))"
docker rmi lab07-flask >/dev/null 2>&1
cd "$HOME" && rm -rf -- "$D"
[ "$FAIL" -eq 0 ]
