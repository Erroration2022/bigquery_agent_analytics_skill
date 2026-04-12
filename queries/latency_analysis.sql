-- Latency Analysis
-- Breaks down latency by event type with percentiles.
-- Separates TTFT (time to first token) from total latency for LLM calls.
-- Requires: base_llm_responses CTE, base_tool_calls CTE.

-- LLM latency breakdown
WITH llm_responses AS (
  SELECT
    agent,
    JSON_VALUE(attributes, '$.model')                                       AS model_id,
    CAST(JSON_VALUE(latency_ms, '$.total_ms')              AS FLOAT64)      AS total_latency_ms,
    CAST(JSON_VALUE(latency_ms, '$.time_to_first_token_ms') AS FLOAT64)     AS ttft_ms
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE event_type = 'LLM_RESPONSE'
    AND timestamp BETWEEN @start AND @end
)
SELECT
  agent,
  model_id,
  COUNT(*)                                                       AS calls,
  ROUND(AVG(total_latency_ms), 0)                                AS avg_total_ms,
  ROUND(AVG(ttft_ms), 0)                                         AS avg_ttft_ms,
  ROUND(AVG(total_latency_ms) - AVG(ttft_ms), 0)                 AS avg_generation_ms,
  APPROX_QUANTILES(total_latency_ms, 100)[OFFSET(50)]            AS p50_total_ms,
  APPROX_QUANTILES(total_latency_ms, 100)[OFFSET(95)]            AS p95_total_ms,
  APPROX_QUANTILES(ttft_ms, 100)[OFFSET(95)]                     AS p95_ttft_ms
FROM llm_responses
GROUP BY agent, model_id
ORDER BY avg_total_ms DESC;
