-- CTE: agent_tree
-- Reconstructs agent delegation chains using parent_span_id self-joins.
-- Use this CTE to find which agent called which, detect delegation loops,
-- and understand multi-agent orchestration flows.

WITH agent_tree AS (
  SELECT
    a.trace_id,
    a.span_id           AS child_span,
    a.agent              AS child_agent,
    a.event_type         AS child_event,
    a.timestamp          AS child_timestamp,
    b.span_id            AS parent_span,
    b.agent              AS parent_agent,
    b.event_type         AS parent_event
  FROM `{PROJECT}.{DATASET}.{TABLE}` a
  LEFT JOIN `{PROJECT}.{DATASET}.{TABLE}` b
    ON  a.parent_span_id = b.span_id
    AND a.trace_id       = b.trace_id
  WHERE a.timestamp BETWEEN @start AND @end
)
