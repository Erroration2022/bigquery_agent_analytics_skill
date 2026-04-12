-- CTE: sessions
-- Aggregates agent_events to one row per session.
-- Provides duration, event counts, agent count, error count.
-- Use this CTE for session-level rollups and cost estimation.

WITH sessions AS (
  SELECT
    session_id,
    user_id,
    MIN(timestamp)                                              AS session_start,
    MAX(timestamp)                                              AS session_end,
    TIMESTAMP_DIFF(MAX(timestamp), MIN(timestamp), SECOND)      AS duration_sec,
    COUNT(*)                                                    AS total_events,
    COUNTIF(event_type = 'LLM_RESPONSE')                        AS llm_calls,
    COUNTIF(event_type = 'TOOL_COMPLETED')                      AS tool_calls,
    COUNTIF(status = 'ERROR')                                   AS error_count,
    COUNT(DISTINCT agent)                                       AS agents_involved,
    COUNT(DISTINCT invocation_id)                                AS invocation_count
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE timestamp BETWEEN @start AND @end
  GROUP BY session_id, user_id
)
