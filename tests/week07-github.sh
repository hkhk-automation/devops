#!/bin/bash
# Nädal 7 labi test päris GitHubis: käib docs/week07/lab.md osad 2-7 läbi ja kontrollib,
# et iga push annab juhendis lubatud tulemuse (roheline / punane / skipped, õige veateade logis)
# ja et ruleset blokeerib punase testiga PR-i merge'i.
# (tests/week07.sh kontrollib samu samme VM-is ilma GitHubita.)
#
# Kasutus (masinas, kus `gh` on sisse logitud; Dockerit pole vaja, kõik jookseb runneris):
#   bash week07-github.sh
# Teeb sinu kontole ajutise AVALIKU repo n07-test-<aeg> (ruleset töötab tasuta kontol ainult avalikus repos).
# Lõpus lülitab repos Actions'i välja ja kustutab repo, kui gh-l on delete_repo õigus.
set -uo pipefail

KASUTAJA=$(gh api user --jq .login) || { echo "gh ei ole sisse logitud"; exit 1; }
REPO="$KASUTAJA/n07-test-$(date +%m%d%H%M)"
D=$(mktemp -d)
OK=0; FAIL=0; L=""
ok()   { echo "OK   $1"; OK=$((OK+1)); }
fail() { echo "FAIL $1"; [ -n "${2:-}" ] && echo "$2" | tail -8 | sed 's/^/     /'; FAIL=$((FAIL+1)); }

oota_run() {  # $1 sha, $2 sündmus -> run id
  local sha=$1 ev=${2:-push} id="" i
  for i in $(seq 60); do
    id=$(gh run list -R "$REPO" --commit "$sha" --event "$ev" --workflow CI --json databaseId --jq '.[0].databaseId' 2>/dev/null)
    [ -n "$id" ] && break; sleep 5
  done
  [ -z "$id" ] && return 1
  gh run watch "$id" -R "$REPO" >/dev/null 2>&1
  echo "$id"
}
jobid() { gh run view "$1" -R "$REPO" --json jobs --jq '[.jobs[] | "\(.name)=\(.conclusion)"] | sort | join(" ")'; }

samm() {  # samm "nimi" "oodatud job'id" [muster logis]
  local nimi=$1 oodatud=$2 muster=${3:-} id tul
  git add -A && git commit -qm "$nimi" && git push -q origin HEAD 2>/dev/null
  id=$(oota_run "$(git rev-parse HEAD)") || { fail "$nimi: run'i ei tekkinud"; return; }
  tul=$(jobid "$id"); L=$(gh run view "$id" -R "$REPO" --log 2>/dev/null)
  [ "$tul" != "$oodatud" ] && { fail "$nimi: job'id '$tul', oodati '$oodatud'" "$(grep -iE 'error|failed' <<<"$L" | sed 's/^.*Z //' | head -8)"; return; }
  if [ -n "$muster" ] && ! grep -qE "$muster" <<<"$L"; then fail "$nimi: logis pole '$muster'" "$(grep -iE 'error' <<<"$L" | sed 's/^.*Z //' | head -8)"; return; fi
  ok "$nimi ($tul)"
}

koristus() {
  gh api -X PUT "repos/$REPO/actions/permissions" -F enabled=false >/dev/null 2>&1
  if gh repo delete "$REPO" --yes >/dev/null 2>&1; then echo "Ajutine repo $REPO kustutatud."
  else echo "Ajutine repo jäi alles (Actions väljas): https://github.com/$REPO  (kustuta: gh repo delete $REPO --yes)"; fi
  rm -rf "$D"
}
trap koristus EXIT

# --- Osa 0: avalik repo README-ga, N5 Flask
gh repo create "$REPO" --public --add-readme >/dev/null || { echo "repo loomine ebaõnnestus"; exit 1; }
gh api -X PUT "repos/$REPO/subscription" -F subscribed=false -F ignored=true >/dev/null  # punased run'id ei saada meile
sleep 3
git clone -q "https://github.com/$REPO.git" "$D/r" && cd "$D/r" || exit 1
git config user.email test@example.com; git config user.name "N7 test"
git switch -qc n07-ci
mkdir -p flask .github/workflows
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
echo ".venv/" > .gitignore
# --- Osa 1
cat > flask/test_app.py <<'EOF'
from app import app


def test_avaleht_vastab():
    vastus = app.test_client().get("/")
    assert vastus.status_code == 200
    assert "Tere" in vastus.get_data(as_text=True)
EOF
W=.github/workflows/ci.yml

# --- Osa 2
cat > $W <<'EOF'
name: CI

on: push

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "tere runnerist"
EOF
samm "Osa 2: tere runnerist" "test=success" "tere runnerist"

# --- Osa 3
cat > $W <<'EOF'
name: CI

on: push

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
      - run: pytest flask -v
EOF
samm "Osa 3.1: pytest puudub (127)" "test=failure" "command not found|exit code 127"
python3 - "$W" <<'EOF'
import sys; p=sys.argv[1]; s=open(p).read()
s=s.replace("      - run: pytest flask -v\n","      - run: pip install pytest\n      - run: pytest flask -v\n")
open(p,"w").write(s)
EOF
samm "Osa 3.2: koodi pole (exit 4)" "test=failure" "file or directory not found: flask"
python3 - "$W" <<'EOF'
import sys; p=sys.argv[1]; s=open(p).read()
s=s.replace("    steps:\n","    steps:\n      - uses: actions/checkout@v7\n",1)
open(p,"w").write(s)
EOF
samm "Osa 3.3: Flask puudub" "test=failure" "No module named 'flask'"
sed -i 's|run: pip install pytest|run: pip install -r flask/requirements.txt pytest|' $W
samm "Osa 3.3: parandus" "test=success" "test_avaleht_vastab PASSED"

# --- Osa 4
sed -i '1i import requests' flask/app.py
samm "Osa 4: requests puudub CI-s" "test=failure" "No module named 'requests'"
sed -i '/^import requests$/d' flask/app.py
samm "Osa 4: parandus" "test=success"

# --- Osa 5.1: PR trigger, PR
sed -i 's/^on: push$/on:\n  push:\n  pull_request:/' $W
samm "Osa 5.1: push + pull_request" "test=success"
gh pr create -R "$REPO" -B main -H n07-ci -t "N7" -b "test" >/dev/null
if id=$(oota_run "$(git rev-parse HEAD)" pull_request) && [ "$(jobid "$id")" = "test=success" ]; then ok "Osa 5.1: PR-il check test roheline"; else fail "Osa 5.1: PR check puudub/punane"; fi

# --- Osa 5.2: ruleset
cat > "$D/rs.json" <<'EOF'
{"name":"main-lukk","target":"branch","enforcement":"active",
 "conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},
 "rules":[{"type":"pull_request","parameters":{"required_approving_review_count":0,"dismiss_stale_reviews_on_push":false,"require_code_owner_review":false,"require_last_push_approval":false,"required_review_thread_resolution":false}},
          {"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":false,"required_status_checks":[{"context":"test"}]}}]}
EOF
if gh api -X POST "repos/$REPO/rulesets" --input "$D/rs.json" >/dev/null 2>&1; then ok "Osa 5.2: ruleset main-lukk loodud"; else fail "Osa 5.2: ruleset'i ei saanud luua"; fi

# --- Osa 5.3: punane test blokeerib merge'i
sed -i 's/"Tere" in/"Tervist" in/' flask/test_app.py
samm "Osa 5.3: test punane" "test=failure" "AssertionError: assert 'Tervist' in 'Tere konteinerist!'"
sleep 10
st=$(gh pr view n07-ci -R "$REPO" --json mergeStateStatus --jq .mergeStateStatus)
[ "$st" = "BLOCKED" ] && ok "Osa 5.3: merge blokeeritud ($st)" || fail "Osa 5.3: mergeStateStatus=$st, oodati BLOCKED"
sed -i 's/"Tervist" in/"Tere" in/' flask/test_app.py
samm "Osa 5.3: parandus" "test=success"

# --- Osa 6: konteiner job, /health puudub
cat >> $W <<'EOF'

  konteiner:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: docker build -t flask-app ./flask
      - run: docker run -d -p 5000:5000 --name flask1 flask-app
      - run: curl -fsS --retry 10 --retry-all-errors --retry-delay 1 localhost:5000/health
EOF
samm "Osa 6: /health puudub" "konteiner=failure test=success" "error: 404"
cat >> $W <<'EOF'
      - if: failure()
        run: docker logs flask1
EOF
samm "Osa 6: docker logs failure korral" "konteiner=failure test=success" 'GET /health HTTP/1.1" 404'

# --- Osa 7
cat >> flask/test_app.py <<'EOF'


def test_health_vastab_ok():
    vastus = app.test_client().get("/health")
    assert vastus.status_code == 200
    assert vastus.get_json() == {"status": "ok"}
EOF
samm "Osa 7.1: test enne koodi punane, konteiner vahele" "konteiner=skipped test=failure" "assert 404 == 200"
python3 - <<'EOF'
p="flask/app.py"; s=open(p).read()
s=s.replace('    return "Tere konteinerist!"\n','    return "Tere konteinerist!"\n\n@app.route("/health")\ndef health():\n    return {"status": "ok"}\n',1)
open(p,"w").write(s)
EOF
cat >> flask/test_app.py <<'EOF'


def test_olematu_annab_404():
    assert app.test_client().get("/olematu").status_code == 404
EOF
samm "Osa 7.2-7.3: kõik roheline" "konteiner=success test=success" "3 passed"
sleep 15
st=$(gh pr view n07-ci -R "$REPO" --json mergeStateStatus --jq .mergeStateStatus)
[ "$st" = "CLEAN" ] && ok "Osa 9: PR merge lubatud ($st)" || fail "Osa 9: mergeStateStatus=$st, oodati CLEAN"

echo
echo "Kokku: $OK OK, $FAIL FAIL"
[ "$FAIL" = 0 ]
