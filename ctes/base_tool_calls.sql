-- CTE: tool_calls
-- Flattens TOOL_COMPLETED events from the agent_events table.
-- Extracts tool name, origin, result, and latency from nested JSON fields.
-- ALWAYS use this CTE for tool performance and failure analysis.

WITH tool_calls AS (
  SELECT
    timestamp,
    agent,
    session_id,
    invocation_id,
    user_id,
    trace_id,
    span_id,
    JSON_VALUE(content, '$.tool')                          AS tool_name,
    JSON_VALUE(content, '$.tool_origin')                   AS tool_origin,
    JSON_VALUE(content, '$.result')                        AS tool_result,
    CAST(JSON_VALUE(latency_ms, '$.total_ms') AS FLOAT64)  AS tool_latency_ms,
    status,
    error_message
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE event_type = 'TOOL_COMPLETED'
    AND timestamp BETWEEN @start AND @end
)
