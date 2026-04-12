-- Session Cost Estimate
-- Aggregates token usage per session and estimates cost.
-- Pricing is approximate; adjust the per-token rates for your models.
-- Requires: base_sessions CTE + base_llm_responses CTE.

WITH llm_responses AS (
  SELECT
    session_id,
    JSON_VALUE(attributes, '$.model')                                        AS model_id,
    CAST(JSON_VALUE(attributes, '$.usage_metadata.prompt_tokens')     AS INT64) AS prompt_tokens,
    CAST(JSON_VALUE(attributes, '$.usage_metadata.completion_tokens') AS INT64) AS completion_tokens
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE event_type = 'LLM_RESPONSE'
    AND timestamp BETWEEN @start AND @end
),
session_tokens AS (
  SELECT
    session_id,
    model_id,
    COUNT(*)                    AS llm_calls,
    SUM(prompt_tokens)          AS total_prompt_tokens,
    SUM(completion_tokens)      AS total_completion_tokens
  FROM llm_responses
  GROUP BY session_id, model_id
)
SELECT
  session_id,
  model_id,
  llm_calls,
  total_prompt_tokens,
  total_completion_tokens,
  -- Approximate cost: adjust rates per model as needed
  -- Default rates below are placeholders (USD per 1M tokens)
  ROUND(total_prompt_tokens     / 1000000.0 * 3.0, 4)  AS est_prompt_cost_usd,
  ROUND(total_completion_tokens / 1000000.0 * 15.0, 4)  AS est_completion_cost_usd,
  ROUND(
    (total_prompt_tokens / 1000000.0 * 3.0)
    + (total_completion_tokens / 1000000.0 * 15.0), 4
  ) AS est_total_cost_usd
FROM session_tokens
ORDER BY est_total_cost_usd DESC;
