-- Token Usage Trends
-- Tracks prompt vs completion token usage over time by model.
-- Use to detect prompt bloat, cost spikes, and model efficiency changes.
-- Requires: base_llm_responses CTE.

WITH llm_responses AS (
  SELECT
    DATE(timestamp)                                                          AS dt,
    JSON_VALUE(attributes, '$.model')                                        AS model_id,
    CAST(JSON_VALUE(attributes, '$.usage_metadata.prompt_tokens')     AS INT64) AS prompt_tokens,
    CAST(JSON_VALUE(attributes, '$.usage_metadata.completion_tokens') AS INT64) AS completion_tokens,
    CAST(JSON_VALUE(attributes, '$.usage_metadata.total_tokens')      AS INT64) AS total_tokens
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE event_type = 'LLM_RESPONSE'
    AND timestamp BETWEEN @start AND @end
)
SELECT
  dt,
  model_id,
  COUNT(*)                         AS llm_calls,
  SUM(prompt_tokens)               AS total_prompt_tokens,
  SUM(completion_tokens)           AS total_completion_tokens,
  SUM(total_tokens)                AS total_tokens,
  ROUND(AVG(prompt_tokens), 0)     AS avg_prompt_tokens,
  ROUND(AVG(completion_tokens), 0) AS avg_completion_tokens
FROM llm_responses
GROUP BY dt, model_id
ORDER BY dt ASC, model_id;
