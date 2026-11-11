# 1. Imagem base oficial do Apache Superset
FROM apache/superset:latest

# 2. Muda temporariamente para o usuário root para realizar alterações administrativas
USER root

# 3. Instala o driver do PostgreSQL direcionando os ficheiros para a venv do Superset
#    - pip: usa o executável de instalação global do container
#    - --target: força a gravação diretamente na pasta de pacotes do Python 3.10 do Superset
#    - --trusted-host: autoriza o download através de firewalls/proxies corporativos
#    - --no-cache-dir: evita guardar ficheiros temporários, poupando espaço em disco
RUN pip install --no-cache-dir \
    --target /app/.venv/lib/python3.10/site-packages \
    --trusted-host pypi.org \
    --trusted-host files.pythonhosted.org \
    --trusted-host pypi.python.org \
    psycopg2-binary

# 4. Concede permissão de posse dos arquivos instalados ao usuário padrão 'superset'
RUN chown -R superset:superset /app/.venv/lib/python3.10/site-packages/psycopg2*

# 5. Copia os arquivos de configuração customizados e o script de inicialização
COPY superset_config.py /app/pythonpath/superset_config.py
COPY superset-init.sh /app/superset-init.sh

# 6. Remove caracteres de retorno de carro do Windows (\r) e concede permissão de execução
RUN sed -i 's/\r$//' /app/superset-init.sh && \
    chmod +x /app/superset-init.sh

# 7. Retorna para o usuário sem privilégios por boas práticas de segurança
USER superset

# 8. Define o script de inicialização como o ponto de entrada do container
ENTRYPOINT ["/app/superset-init.sh"]