-- Views adicionais otimizadas para leitura de BI no Apache Superset

-- 1. Eficiência Geral de Modelos de IA
CREATE OR REPLACE VIEW rag_telemetry.vw_model_efficiency AS
SELECT
    model_name,
    COUNT(id) AS total_requests,
    AVG(total_tokens) AS avg_tokens_per_request,
    AVG(estimated_cost_usd) AS avg_cost_per_request,
    AVG(llm_latency_ms) AS avg_llm_latency_ms
FROM rag_telemetry.llm_execution_logs
GROUP BY model_name;

-- 2. Rateio e Governança de Custos FinOps por Usuário / Departamento
CREATE OR REPLACE VIEW rag_telemetry.vw_user_cost_breakdown AS
SELECT
    user_id,
    model_name,
    COUNT(id) AS total_queries,
    SUM(prompt_tokens) AS total_prompt_tokens,
    SUM(completion_tokens) AS total_completion_tokens,
    SUM(total_tokens) AS total_tokens,
    SUM(estimated_cost_usd) AS total_cost_usd,
    MAX(created_at) AS last_activity_at
FROM rag_telemetry.llm_execution_logs
GROUP BY user_id, model_name;

-- 3. Monitoramento de SLAs de Latência e Saúde Operacional (Horário)
CREATE OR REPLACE VIEW rag_telemetry.vw_latency_sla_monitoring AS
SELECT
    DATE_TRUNC('hour', created_at) AS log_hour,
    model_name,
    COUNT(id) AS total_requests,
    AVG(vector_search_latency_ms) AS avg_vector_latency_ms,
    MAX(vector_search_latency_ms) AS max_vector_latency_ms,
    AVG(llm_latency_ms) AS avg_llm_latency_ms,
    MAX(llm_latency_ms) AS max_llm_latency_ms,
    AVG(vector_search_latency_ms + llm_latency_ms) AS avg_total_latency_ms
FROM rag_telemetry.llm_execution_logs
GROUP BY 1, 2
ORDER BY 1 DESC;
