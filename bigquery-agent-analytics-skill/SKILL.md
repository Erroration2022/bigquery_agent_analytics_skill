---
name: bigquery-agent-analytics-skill
description: >
  Analyze BigQuery Agent Analytics (BQAA) data — error rates, latency, token
  usage, tool failures, agent delegation flows, HITL bottlenecks, and session
  costs. Use when the user asks about agent performance, debugging, or cost
  analysis from a BQAA agent_events table.
license: MIT
compatibility: Requires Python 3.8+ and google-cloud-bigquery package
metadata:
  author: Erroration2022
  version: "2.0"
allowed-tools: Bash(python:*)
---

## Gotchas

- The `content` column is **polymorphic** — its JSON structure changes per
  `event_type`. Always filter by `event_type` before extracting content fields.
- `latency_ms` is a JSON column, not a number. Extract via
  `JSON_VALUE(latency_ms, '$.total_ms')` and CAST to FLOAT64.
- `parent_span_id` self-joins **must match on both `span_id` AND `trace_id`**.
  Omitting `trace_id` produces cross-trace garbage joins.
- The table is partitioned on `timestamp`. Forgetting a `WHERE timestamp`
  filter can scan terabytes. Always include a date range.
- `is_truncated = true` means the content was cut off — check
  `content_parts[].object_ref.uri` for the full payload in GCS.

## Execution

ALWAYS execute queries via the helper script. It auto-injects `{PROJECT}`,
`{DATASET}`, and `{TABLE}` from environment variables — never ask the user
for their project or dataset name.

```bash
python scripts/run_bq.py "SELECT ... FROM \`{PROJECT}.{DATASET}.{TABLE}\` WHERE ..."
```

**CRITICAL — dry-run every query before executing:**

```bash
python scripts/run_bq.py --dry-run "YOUR SQL"
```

- [ ] Run dry-run
- [ ] Check output: if `exceeds_limit` is `true`, tighten date filter and retry
- [ ] Only execute after dry-run confirms scan < 1 GB

## Methodology

Follow this checklist in strict order. Present findings at each step.

- [ ] **Step 1 — Survey:** Count total events, errors, error rate, unique agents,
  and p95 latency in the time window. Present as a one-line summary. If no issues,
  tell the user and stop.
- [ ] **Step 2 — Filter:** Isolate the top 3 contributors. Read
  [references/ctes.md](references/ctes.md) and use the appropriate CTE
  (`llm_responses` for token/latency, `tool_calls` for tools, `errors` for
  failures). Present as a markdown table, max 3 rows.
- [ ] **Step 3 — Deep Dive:** Extract the full trace for one representative
  failure from the top offender. Present chronologically with a plain-english
  walkthrough.
- [ ] **Diagnose:** Read [references/failure-patterns.md](references/failure-patterns.md)
  and map results to a known pattern. State: "This matches pattern: [X].
  Recommended next step: [Y]."

## CTE Rule

BQAA JSON paths are deeply nested. **Never write raw `JSON_VALUE()` or
`JSON_EXTRACT()` from scratch.** Always start queries with a base CTE from
[references/ctes.md](references/ctes.md). Use the default `llm_responses`
CTE unless the question is specifically about tools or delegation.

## Output

- **Survey** — single summary line
- **Filter** — markdown table, max 3 rows, sorted by problem metric
- **Deep Dive** — chronological code block + plain-english walkthrough
- **Delegation queries** — render as Mermaid `sequenceDiagram`
  (see [assets/mermaid-template.md](assets/mermaid-template.md))
- **Model comparison** — markdown table sorted by `avg_latency_ms` descending
- Always end with the matched failure pattern + recommended next action

## References (load on demand)

| File | When to load |
|------|-------------|
| [references/schema.md](references/schema.md) | When you need column types or nested field paths |
| [references/ctes.md](references/ctes.md) | When writing any query (pick the right CTE) |
| [references/queries.md](references/queries.md) | When a ready-made query matches the user's question |
| [references/failure-patterns.md](references/failure-patterns.md) | After Step 3, to diagnose results |
| [references/examples.md](references/examples.md) | If unsure how to structure the end-to-end flow |
