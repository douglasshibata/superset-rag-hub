import os

ROW_LIMIT = 50000
SUPERSET_WEBSERVER_PORT = int(os.getenv("SUPERSET_PORT", "8088"))

# Permite acesso de relatórios e visualizações embarcadas
ENABLE_TEMPLATE_PROCESSING = True
PUBLIC_ROLE_LIKE = os.getenv("PUBLIC_ROLE_LIKE", "Gamma")

# Chave secreta de sessão
SECRET_KEY = os.getenv("SUPERSET_SECRET_KEY", "chavedemutaparasuperset123_change_in_prod")

# Conexão do banco interno do Superset (Metadados)
SQLALCHEMY_DATABASE_URI = os.getenv(
    "SUPERSET_DATABASE_URI",
    "postgresql://admin:admin_password_change_me@postgres:5432/superset_metadata"
)