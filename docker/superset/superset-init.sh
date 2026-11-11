#!/bin/bash
# ---------------------------------------------------------------------------
# superset-init.sh: Inicialização e execução do Apache Superset
# ---------------------------------------------------------------------------
# set -e garante que o script pare se qualquer comando obrigatório falhar
set -e

# Configurações de credenciais com fallback seguro
ADMIN_USER="${SUPERSET_ADMIN_USER:-admin}"
ADMIN_PASS="${SUPERSET_ADMIN_PASSWORD:-admin_secure_password_change_me}"
ADMIN_EMAIL="${SUPERSET_ADMIN_EMAIL:-admin@company.com}"
DB_URI="${SUPERSET_DATABASE_URI:-postgresql://admin:admin_password_change_me@postgres:5432/superset_metadata}"

echo "🐘 [1/4] Verificando existência da base de metadados no PostgreSQL..."

# Script Python integrado para validar e criar o banco automaticamente
/app/.venv/bin/python - << 'EOF'
import os
import sys
from urllib.parse import urlparse
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

db_uri = os.getenv("SUPERSET_DATABASE_URI", "postgresql://admin:admin_password_change_me@postgres:5432/superset_metadata")
url = urlparse(db_uri)

target_db = url.path.lstrip('/') or 'superset_metadata'
user = url.username or 'admin'
password = url.password or 'admin_password_change_me'
host = url.hostname or 'postgres'
port = url.port or 5432

try:
    conn = psycopg2.connect(dbname="postgres", user=user, password=password, host=host, port=port)
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cur = conn.cursor()

    cur.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (target_db,))
    if not cur.fetchone():
        print(f"⚡ Base '{target_db}' não encontrada. Criando automaticamente...")
        cur.execute(f'CREATE DATABASE "{target_db}";')
        print(f"✅ Base '{target_db}' criada com sucesso!")
    else:
        print(f"✅ Base '{target_db}' já existe e está pronta para uso.")

    cur.close()
    conn.close()
except Exception as err:
    print(f"⚠️ Atenção ao verificar base de dados: {err}", file=sys.stderr)
EOF

echo "🔐 [2/4] Inicializando usuário administrador ($ADMIN_USER)..."
superset fab create-admin \
    --username "$ADMIN_USER" \
    --firstname Admin \
    --lastname User \
    --email "$ADMIN_EMAIL" \
    --password "$ADMIN_PASS" || true

echo "🔄 [3/4] Aplicando migrações no banco de dados (db upgrade)..."
superset db upgrade

echo "⚙️ [4/4] Inicializando permissões e papéis padrão do Superset..."
superset init

echo "🚀 Inicialização concluída! Iniciando servidor Web na porta 8088..."
# O comando 'exec' faz o servidor web assumir o PID 1, mantendo o container ativo
exec superset run -h 0.0.0.0 -p 8088 --with-threads