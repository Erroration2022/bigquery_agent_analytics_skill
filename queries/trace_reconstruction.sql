-- Trace Reconstruction
-- Reconstructs the full timeline of a single trace (agent session turn).
-- Use when the user provides a trace_id and wants to see what happened.

SELECT
  timestamp,
  event_type,
  agent,
  invocation_id,
  span_id,
  parent_span_id,
  JSON_VALUE(content, '$.response')    AS llm_response,
  JSON_VALUE(content, '$.tool')        AS tool_name,
  JSON_VALUE(content, '$.tool_origin') AS tool_origin,
  CAST(JSON_VALUE(latency_ms, '$.total_ms') AS FLOAT64) AS latency_ms,
  status,
  error_message
FROM `{PROJECT}.{DATASET}.{TABLE}`
WHERE trace_id = @trace_id
ORDER BY timestamp ASC;
