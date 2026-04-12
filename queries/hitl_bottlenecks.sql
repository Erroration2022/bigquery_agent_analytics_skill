-- HITL Bottleneck Analysis
-- Measures time spent waiting for human-in-the-loop interactions.
-- Pairs HITL requests with their completions to compute wait time.
-- High HITL wait time is often the biggest invisible cost in agent sessions.

WITH hitl_requests AS (
  SELECT
    session_id,
    agent,
    invocation_id,
    trace_id,
    event_type,
    timestamp AS request_time
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE event_type IN (
    'HITL_CREDENTIAL_REQUEST',
    'HITL_CONFIRMATION_REQUEST',
    'HITL_INPUT_REQUEST'
  )
  AND timestamp BETWEEN @start AND @end
),
hitl_completions AS (
  SELECT
    session_id,
    invocation_id,
    event_type,
    timestamp AS completion_time
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE event_type IN (
    'HITL_CREDENTIAL_REQUEST_COMPLETED',
    'HITL_INPUT_REQUEST_COMPLETED'
  )
  AND timestamp BETWEEN @start AND @end
)
SELECT
  r.agent,
  r.event_type                                                         AS request_type,
  COUNT(*)                                                             AS total_requests,
  COUNTIF(c.completion_time IS NOT NULL)                               AS completed,
  ROUND(AVG(TIMESTAMP_DIFF(c.completion_time, r.request_time, SECOND)), 1) AS avg_wait_sec,
  MAX(TIMESTAMP_DIFF(c.completion_time, r.request_time, SECOND))       AS max_wait_sec
FROM hitl_requests r
LEFT JOIN hitl_completions c
  ON  r.session_id    = c.session_id
  AND r.invocation_id = c.invocation_id
GROUP BY r.agent, r.event_type
ORDER BY avg_wait_sec DESC;
