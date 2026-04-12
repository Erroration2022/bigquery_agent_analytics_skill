-- Model Comparison
-- Compares latency, token usage, and error rates across different models.
-- Use when evaluating model swaps or investigating version-specific regressions.
-- Requires: base_llm_responses CTE.

WITH llm_responses AS (
  SELECT
    JSON_VALUE(attributes, '$.model')                                        AS model_id,
    CAST(JSON_VALUE(attributes, '$.usage_metadata.prompt_tokens')     AS INT64)   AS prompt_tokens,
    CAST(JSON_VALUE(attributes, '$.usage_metadata.completion_tokens') AS INT64)   AS completion_tokens,
    CAST(JSON_VALUE(attributes, '$.usage_metadata.total_tokens')      AS INT64)   AS total_tokens,
    CAST(JSON_VALUE(latency_ms, '$.total_ms')                         AS FLOAT64) AS total_latency_ms,
    CAST(JSON_VALUE(latency_ms, '$.time_to_first_token_ms')           AS FLOAT64) AS ttft_ms,
    status
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE event_type = 'LLM_RESPONSE'
    AND timestamp BETWEEN @start AND @end
)
SELECT
  model_id,
  COUNT(*)                                                       AS calls,
  ROUND(COUNTIF(status = 'ERROR') / COUNT(*) * 100, 2)           AS error_rate_pct,
  ROUND(AVG(total_tokens), 0)                                    AS avg_total_tokens,
  ROUND(AVG(prompt_tokens), 0)                                   AS avg_prompt_tokens,
  ROUND(AVG(completion_tokens), 0)                               AS avg_completion_tokens,
  ROUND(AVG(total_latency_ms), 0)                                AS avg_latency_ms,
  APPROX_QUANTILES(total_latency_ms, 100)[OFFSET(50)]            AS p50_latency_ms,
  APPROX_QUANTILES(total_latency_ms, 100)[OFFSET(95)]            AS p95_latency_ms,
  ROUND(AVG(ttft_ms), 0)                                         AS avg_ttft_ms
FROM llm_responses
GROUP BY model_id
ORDER BY calls DESC;
