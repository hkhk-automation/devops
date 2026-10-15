#!/bin/bash
# Nädal 6 labori test (Docker Compose): käib docs/week06/lab.md sammud läbi ja kontrollib,
# et iga "meelega viga" annab juhendis lubatud tulemuse ja iga parandus töötab.
#
# Kasutus (VM-is, kus Docker on nädal 5 Osa 0 järgi paigaldatud ja kasutaja on docker grupis):
#   bash week06.sh
# Vajab vabu porte 5000 ja 8080. Töökaust ~/lab06-test, lõpus koristab (down -v, kaust kustub).
# Väljund: iga samm OK/FAIL, lõpus kokkuvõte.
set -uo pipefail

D="$HOME/lab06-test"
OK=0; FAIL=0
ok()   { echo "OK   $1"; OK=$((OK+1)); }
fail() { echo "FAIL $1"; [ -n "${2:-}" ] && echo "$2" | tail -5 | sed 's/^/     /'; FAIL=$((FAIL+1)); }
check() { local nimi=$1; shift; if out=$("$@" 2>&1); then ok "$nimi"; else fail "$nimi" "$out"; fi; }
oota() { local i; for i in $(seq 60); do "$@" >/dev/null 2>&1 && return 0; sleep 1; done; return 1; }
dc() { docker compose "$@"; }

command -v docker >/dev/null || { echo "docker puudub (nädal 5 Osa 0)"; exit 1; }
docker info >/dev/null 2>&1 || { echo "docker ei vasta: kas kasutaja on docker grupis? (nädal 5 Osa 0)"; exit 1; }
for p in 5000 8080; do ss -ltn | grep -qE "[:.]$p " && { echo "port $p on kinni, vabasta see enne testi"; exit 1; }; done

[ -e "$D" ] && { echo "$D on juba olemas, kustuta see enne testi"; exit 1; }
mkdir -p "$D/app" "$D/nginx" && cd "$D" || exit 1
trap 'cd "$D" 2>/dev/null && docker compose down -v >/dev/null 2>&1' EXIT

# Nädal 5 Flask (host 0.0.0.0, nagu N5 parandus) + labi Osa 3 /db-check
cat > app/app.py <<'EOF'
import os
import psycopg2
from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():
    return "Tere konteinerist!"

@app.route("/db-check")
def db_check():
    try:
        conn = psycopg2.connect(os.environ["DATABASE_URL"], connect_timeout=3)
        conn.close()
        return "DB OK\n"
    except Exception as e:
        return f"DB viga: {e}\n", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF
printf 'flask==3.0.3\npsycopg2-binary\n' > app/requirements.txt
cat > app/Dockerfile <<'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# --- Osa 1: üks teenus
cat > docker-compose.yml <<'EOF'
services:
  web:
    build: ./app
    ports:
      - "5000:5000"
EOF
dc up -d --build >/dev/null 2>&1
check "Osa 1: web vastab pordil 5000" oota sh -c 'curl -s localhost:5000 | grep -q Tere'

# --- Osa 2: db ilma paroolita sureb
cat >> docker-compose.yml <<'EOF'
  db:
    image: postgres:16
EOF
dc up -d db >/dev/null 2>&1
check "Osa 2: db ilma paroolita: logis 'password is not specified'" oota sh -c 'docker compose logs db | grep -q "password is not specified"'
check "Osa 2: db konteiner on seisma jäänud" oota sh -c '! docker compose ps --status running --services | grep -qx db'

cat > docker-compose.yml <<'EOF'
services:
  web:
    build: ./app
    ports:
      - "5000:5000"
    environment:
      DATABASE_URL: postgresql://postgres:secret123@127.0.0.1:5432/appdb
    depends_on:
      - db
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret123
      POSTGRES_DB: appdb
EOF
dc up -d db >/dev/null 2>&1
check "Osa 2: db parooliga: 'ready to accept connections'" oota sh -c 'docker compose logs db | grep -q "ready to accept connections"'

# --- Osa 3: 127.0.0.1 -> Connection refused, db -> OK
dc up -d --build >/dev/null 2>&1
oota sh -c 'curl -s localhost:5000 | grep -q Tere'
check "Osa 3: 127.0.0.1 annab 'Connection refused'" oota sh -c 'curl -s localhost:5000/db-check | grep -q "Connection refused"'
sed -i 's/@127.0.0.1:/@db:/' docker-compose.yml
dc up -d >/dev/null 2>&1
check "Osa 3: host db annab 'DB OK'" oota sh -c 'curl -s localhost:5000/db-check | grep -q "DB OK"'

# --- Osa 4: nginx vale pordiga -> 502; vale nimega -> ei käivitu; parandus -> vastab
cat >> docker-compose.yml <<'EOF'
  nginx:
    image: nginx:1.27
    ports:
      - "8080:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - web
EOF
printf 'server {\n    listen 80;\n    location / {\n        proxy_pass http://web:8000;\n    }\n}\n' > nginx/default.conf
dc up -d >/dev/null 2>&1
check "Osa 4: port 8000 annab 502" oota sh -c '[ "$(curl -s -o /dev/null -w "%{http_code}" localhost:8080)" = 502 ]'
check "Osa 4: nginx logis 'while connecting to upstream'" oota sh -c 'docker compose logs nginx | grep -q "while connecting to upstream"'

sed -i 's|http://web:8000|http://app:5000|' nginx/default.conf
dc up -d --force-recreate nginx >/dev/null 2>&1
check "Osa 4 vihje: vale nimi -> 'host not found in upstream'" oota sh -c 'docker compose logs nginx | grep -q "host not found in upstream"'
check "Osa 4 vihje: vale nimega nginx ei käi" oota sh -c '! docker compose ps --status running --services | grep -qx nginx'

sed -i 's|http://app:5000|http://web:8000|' nginx/default.conf
dc up -d --force-recreate nginx >/dev/null 2>&1
oota sh -c '[ "$(curl -s -o /dev/null -w "%{http_code}" localhost:8080)" = 502 ]'
sed -i 's|http://web:8000|http://web:5000|' nginx/default.conf
dc restart nginx >/dev/null 2>&1
check "Osa 4: pärast 'restart nginx' vastab 8080 (juhendi tee)" oota sh -c 'curl -s localhost:8080 | grep -q Tere'

# web ports maha
python3 - <<'EOF'
s = open("docker-compose.yml").read()
s = s.replace('    build: ./app\n    ports:\n      - "5000:5000"\n', '    build: ./app\n', 1)
open("docker-compose.yml", "w").write(s)
EOF
dc up -d >/dev/null 2>&1
check "Osa 4: ilma web portideta vastab 8080" oota sh -c 'curl -s localhost:8080 | grep -q Tere'
check "Osa 4: port 5000 enam ei vasta" sh -c '! curl -s -m 3 localhost:5000 >/dev/null'

# --- Osa 5: ilma volume'ita andmed kaovad, volume'iga jäävad
sql() { docker compose exec -T db psql -U postgres -d appdb -tAc "$1"; }
oota sql "select 1"
sql "CREATE TABLE test (id int); INSERT INTO test VALUES (1);" >/dev/null
dc down >/dev/null 2>&1; dc up -d >/dev/null 2>&1; oota sql "select 1"
check "Osa 5: ilma volume'ita on tabel kadunud" sh -c '! docker compose exec -T db psql -U postgres -d appdb -tAc "SELECT * FROM test" >/dev/null 2>&1'

python3 - <<'EOF'
s = open("docker-compose.yml").read()
s = s.replace('      POSTGRES_DB: appdb\n', '      POSTGRES_DB: appdb\n    volumes:\n      - pgdata:/var/lib/postgresql/data\n', 1)
s += "\nvolumes:\n  pgdata:\n"
open("docker-compose.yml", "w").write(s)
EOF
dc up -d >/dev/null 2>&1; oota sql "select 1"
sql "CREATE TABLE test (id int); INSERT INTO test VALUES (1);" >/dev/null
dc down >/dev/null 2>&1; dc up -d >/dev/null 2>&1; oota sql "select 1"
check "Osa 5: volume'iga on rida alles" sh -c '[ "$(docker compose exec -T db psql -U postgres -d appdb -tAc "SELECT * FROM test")" = 1 ]'

# --- Osa 6: .env, trükiviga annab hoiatuse ja tühja parooli
printf 'POSTGRES_PASSWORD=secret123\nPOSTGRES_DB=appdb\n' > .env
sed -i 's/      POSTGRES_PASSWORD: secret123/      POSTGRES_PASSWORD: ${POSTGRES_PASWORD}/' docker-compose.yml
check "Osa 6: trükiviga -> 'variable is not set'" sh -c 'docker compose config 2>&1 | grep -q "POSTGRES_PASWORD\" variable is not set"'
check "Osa 6: trükiviga -> parool on tühi" sh -c 'docker compose config 2>/dev/null | grep -qE "POSTGRES_PASSWORD: \"\"$"'
sed -i -e 's/\${POSTGRES_PASWORD}/${POSTGRES_PASSWORD}/' \
       -e 's/      POSTGRES_DB: appdb/      POSTGRES_DB: ${POSTGRES_DB}/' \
       -e 's|postgres:secret123@db:5432/appdb|postgres:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}|' docker-compose.yml
check "Osa 6: parandatud: config ilma hoiatuseta" sh -c '! docker compose config 2>&1 | grep -q "not set"'
check "Osa 6: compose-failis pole enam parooli" sh -c '! grep -q secret123 docker-compose.yml'
dc up -d >/dev/null 2>&1
check "Osa 6: db-check läbi nginx-i 'DB OK'" oota sh -c 'curl -s localhost:8080/db-check | grep -q "DB OK"'

# --- Osa 7: down jätab volume'i alles
dc down >/dev/null 2>&1
check "Osa 7: pärast down on volume alles" sh -c 'docker volume ls -q | grep -q "lab06-test_pgdata"'
dc down -v >/dev/null 2>&1
check "Osa 7: down -v kustutab volume'i" sh -c '! docker volume ls -q | grep -q "lab06-test_pgdata"'

echo
echo "Kokku: $OK OK, $FAIL FAIL  ($(docker compose version --short 2>/dev/null), $(. /etc/os-release; echo "$PRETTY_NAME"))"
cd "$HOME" && rm -rf -- "$HOME/lab06-test"
[ "$FAIL" -eq 0 ]
