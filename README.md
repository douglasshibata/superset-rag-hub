# 📊 Superset RAG Analytics Hub: BI, FinOps & Observabilidade

Esta solução estende o pipeline RAG do Paperless-ngx adicionando uma camada completa de Business Intelligence (BI) com o **Apache Superset** conectado ao **PostgreSQL** (que serve como Single Source of Truth - SSOT da telemetria) e coletando métricas do **Qdrant** e da engine de IA.

---

## 🏗️ 1. Visão Geral da Arquitetura

```text
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                 DASHBOARD & BI                                   │
│                        ┌───────────────────────────────┐                         │
│                        │    Apache Superset (BI UI)    │                         │
│                        └───────────────+───────────────┘                         │
└────────────────────────────────────────────────┼─────────────────────────────────┘
                                                 │ SQL (SQLAlchemy)
                                                 ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                            DATA & STORAGE LAYER                                  │
│  ┌─────────────────────────────┐               ┌──────────────────────────────┐  │
│  │   PostgreSQL 16 (SSOT)      │               │   Qdrant / Vector Store      │  │
│  │  • docs, tags, audit, logs  │               │  • vector metrics, counts    │  │
│  └──────────────▲──────────────┘               └──────────────▲───────────────┘  │
└─────────────────┼─────────────────────────────────────────────┼──────────────────┘
                  │                                             │
┌─────────────────┼─────────────────────────────────────────────┼──────────────────┐
│                 │          PAPERLESS-RAG-ENGINE               │                  │
│  ┌──────────────┴──────────────┐               ┌──────────────┴──────────────┐  │
│  │   Control Plane (Go API)    │               │   Worker / Pipeline Engine  │  │
│  └─────────────────────────────┘               └─────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 2. Como Implantar a Stack com Segurança

1. **Configure as Variáveis de Ambiente:**
   No diretório `superset-rag-hub/docker/`, copie o arquivo de exemplo `.env.example` para `.env`:
   ```bash
   cp .env.example .env
   ```
   Edite o `.env` definindo credenciais fortes e uma chave secreta para a sessão do Apache Superset (`SUPERSET_SECRET_KEY`).

2. **Inicie os Containers:**
   ```bash
   docker compose up -d
   ```

3. **Acesse a Interface do Apache Superset:**
   Navegue até `http://localhost:8088` em seu navegador.
   - **Login por Padrão:** O usuário definido no `.env` (`SUPERSET_ADMIN_USER`).

4. **Conecte o Banco de Dados no Superset:**
   - Acesse **Settings > Database Connections** e clique em **+ Database**.
   - Selecione **PostgreSQL**.
   - Insira a URL SQLAlchemy de conexão usando o host interno do container:
     ```text
     postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/paperless
     ```

5. **Exporte/Crie Datasets:**
   - Adicione o schema `rag_telemetry` e explore as views otimizadas (`vw_daily_finops`, `vw_user_cost_breakdown`, `vw_latency_sla_monitoring`, `mv_daily_finops`).

---

## ⚡ 3. Otimização de Banco de Dados (High-Performance BI)

Para suportar grandes volumes de requisições de IA sem degradar a performance do PostgreSQL ou travar dashboards no Superset:

1. **Índices Estratégicos:**
   - `idx_llm_execution_logs_created_at`: Acelera filtros por intervalo de tempo.
   - `idx_llm_execution_logs_model_created`: Otimiza agrupações e comparações de custo por modelo de LLM.
   - `idx_llm_execution_logs_user_id`: Otimiza consultas de rateio por departamento/usuário.

2. **Materialized View (`rag_telemetry.mv_daily_finops`):**
   - Para ambientes de alta escala (milhões de logs/dia), utilize a view materializada `mv_daily_finops`.
   - Atualize periodicamente sem bloquear leituras executando:
     ```sql
     REFRESH MATERIALIZED VIEW CONCURRENTLY rag_telemetry.mv_daily_finops;
     ```

---

## 🛡️ 4. Segurança e AppSec

- **Zero Credenciais Hardcoded:** Todas as credenciais de banco e chaves de criptografia são injetadas via variáveis de ambiente (`.env`).
- **Isolamento de Redes:** Os serviços comunicam-se via rede interna do Docker (`superset-postgres`), sem expor credenciais em texto plano nos scripts de inicialização.
- **Sessões Seguras:** O Superset utiliza `SUPERSET_SECRET_KEY` configurado externamente para assinar cookies e tokens CSRF.

---

## 🔄 5. Resiliência na Ingestão de Telemetria (Go API / Worker)

Para evitar que chamadas de telemetria criem gargalos ou causem *database lock* na ingestão de logs:

1. **Buffered Worker Channels (Go API):**
   - A API armazena eventos de log em um canal Go em memória (`chan TelemetryEvent`, tamanho de buffer Ex: 5.000).
2. **Asynchronous Batch Processing:**
   - Workers de background descarregam o buffer em lotes (*bulk insert*) a cada N segundos ou N registros (Ex: 100 registros ou a cada 2s).
3. **Fallback & Circuit Breaking:**
   - Em caso de indisponibilidade pontual do banco relacional, os logs são temporariamente redirecionados para Redis ou retidos localmente, evitando queda do serviço principal de RAG.
