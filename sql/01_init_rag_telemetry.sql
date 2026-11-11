-- Criar schema de observabilidade
CREATE SCHEMA IF NOT EXISTS rag_telemetry;

-- Tabela de logs de chamadas à LLM e busca vetorial
CREATE TABLE IF NOT EXISTS rag_telemetry.llm_execution_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id INT,
    user_id VARCHAR(100) NOT NULL,
    prompt_tokens INT NOT NULL,
    completion_tokens INT NOT NULL,
    total_tokens INT NOT NULL,
    estimated_cost_usd NUMERIC(10, 6) NOT NULL,
    vector_search_latency_ms INT NOT NULL,
    llm_latency_ms INT NOT NULL,
    model_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- ÍNDICES DE PERFORMANCE PARA CONSULTAS EM TEMPO REAL E BI
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_llm_execution_logs_created_at
    ON rag_telemetry.llm_execution_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_llm_execution_logs_model_created
    ON rag_telemetry.llm_execution_logs (model_name, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_llm_execution_logs_user_id
    ON rag_telemetry.llm_execution_logs (user_id);

CREATE INDEX IF NOT EXISTS idx_llm_execution_logs_document_id
    ON rag_telemetry.llm_execution_logs (document_id);

-- -----------------------------------------------------------------------------
-- VIEW PADRÃO: FinOps Diário
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW rag_telemetry.vw_daily_finops AS
SELECT
    DATE_TRUNC('day', created_at) AS usage_date,
    model_name,
    COUNT(id) AS total_queries,
    SUM(total_tokens) AS total_tokens_used,
    SUM(estimated_cost_usd) AS total_cost_usd,
    AVG(vector_search_latency_ms) AS avg_vector_latency_ms,
    AVG(llm_latency_ms) AS avg_llm_latency_ms
FROM rag_telemetry.llm_execution_logs
GROUP BY 1, 2
ORDER BY 1 DESC;

-- -----------------------------------------------------------------------------
-- MATERIALIZED VIEW: FinOps Otimizado para Alta Carga no Apache Superset
-- Utilize 'REFRESH MATERIALIZED VIEW CONCURRENTLY rag_telemetry.mv_daily_finops;' via cron/pg_cron
-- -----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS rag_telemetry.mv_daily_finops AS
SELECT
    DATE_TRUNC('day', created_at) AS usage_date,
    model_name,
    COUNT(id) AS total_queries,
    SUM(total_tokens) AS total_tokens_used,
    SUM(estimated_cost_usd) AS total_cost_usd,
    AVG(vector_search_latency_ms) AS avg_vector_latency_ms,
    AVG(llm_latency_ms) AS avg_llm_latency_ms
FROM rag_telemetry.llm_execution_logs
GROUP BY 1, 2
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_daily_finops
    ON rag_telemetry.mv_daily_finops (usage_date, model_name);
