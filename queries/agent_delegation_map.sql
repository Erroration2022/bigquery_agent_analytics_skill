-- Agent Delegation Map
-- Shows which agents delegate to which other agents and how often.
-- Detects runaway delegation loops (A -> B -> A).
-- Requires: base_agent_tree CTE.

WITH agent_tree AS (
  SELECT
    a.trace_id,
    a.agent   AS child_agent,
    b.agent   AS parent_agent
  FROM `{PROJECT}.{DATASET}.{TABLE}` a
  INNER JOIN `{PROJECT}.{DATASET}.{TABLE}` b
    ON  a.parent_span_id = b.span_id
    AND a.trace_id       = b.trace_id
  WHERE a.timestamp BETWEEN @start AND @end
    AND a.agent IS NOT NULL
    AND b.agent IS NOT NULL
    AND a.agent != b.agent
)
SELECT
  parent_agent,
  child_agent,
  COUNT(*)               AS delegation_count,
  COUNT(DISTINCT trace_id) AS unique_traces
FROM agent_tree
GROUP BY parent_agent, child_agent
ORDER BY delegation_count DESC;
