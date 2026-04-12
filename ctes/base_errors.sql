-- CTE: errors
-- Extracts all events with status = 'ERROR' along with their full context.
-- Use this CTE as a starting point for any error investigation.

WITH errors AS (
  SELECT
    timestamp,
    event_type,
    agent,
    session_id,
    invocation_id,
    user_id,
    trace_id,
    span_id,
    content,
    attributes,
    latency_ms,
    error_message
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE status = 'ERROR'
    AND timestamp BETWEEN @start AND @end
)
