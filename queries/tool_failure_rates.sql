-- Tool Failure Rates
-- Failure rate per tool, split by tool_origin (built-in vs custom).
-- Requires: base_tool_calls CTE.

WITH tool_calls AS (
  SELECT
    JSON_VALUE(content, '$.tool')        AS tool_name,
    JSON_VALUE(content, '$.tool_origin') AS tool_origin,
    CAST(JSON_VALUE(latency_ms, '$.total_ms') AS FLOAT64) AS tool_latency_ms,
    status
  FROM `{PROJECT}.{DATASET}.{TABLE}`
  WHERE event_type = 'TOOL_COMPLETED'
    AND timestamp BETWEEN @start AND @end
)
SELECT
  tool_name,
  tool_origin,
  COUNT(*)                                                     AS total_calls,
  COUNTIF(status = 'ERROR')                                    AS failures,
  ROUND(COUNTIF(status = 'ERROR') / COUNT(*) * 100, 2)         AS fail_rate_pct,
  ROUND(AVG(tool_latency_ms), 0)                                AS avg_latency_ms,
  APPROX_QUANTILES(tool_latency_ms, 100)[OFFSET(95)]            AS p95_latency_ms
FROM tool_calls
GROUP BY tool_name, tool_origin
ORDER BY failures DESC;
