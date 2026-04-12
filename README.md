# BigQuery Agent Analytics Skill

A lightweight, LLM-discoverable skill for analyzing [Google ADK BigQuery Agent Analytics](https://adk.dev/integrations/bigquery-agent-analytics/) data. No server, no MCP — just a prompt skill file with pre-built CTEs, query templates, and an analysis methodology that any AI coding assistant can use.

## What This Does

When loaded into an AI assistant (Claude Code, Cursor, AG, etc.), this skill teaches the LLM to:

- Query the BQAA table correctly, using pre-built CTEs that handle deeply nested JSON/proto structures
- Follow a structured analysis methodology: **Survey -> Filter -> Deep Dive**
- **Cost-check every query** via dry-run before execution
- Diagnose common failure patterns from known signal tables
- Visualize results appropriately (Mermaid diagrams for delegation flows, sorted tables for comparisons)
- Estimate costs, detect delegation loops, find HITL bottlenecks, and compare model performance

## Quick Start

### 1. Set up your environment

```bash
export GCP_PROJECT_ID="your-project-id"
export BQ_DATASET="your-dataset-id"
export BQ_TABLE="agent_events"          # optional, defaults to agent_events
pip install google-cloud-bigquery
```

The `run_bq.py` helper automatically injects `{PROJECT}`, `{DATASET}`, and `{TABLE}` placeholders in SQL from these environment variables. The LLM never needs to know your specific project or dataset name.

### 2. Compile the skill (optional, recommended)

```bash
python scripts/compile.py
```

This produces a single `compiled_skill.md` that inlines all CTEs and queries, so the LLM gets full context in one file read without needing to `cat` individual SQL files.

### 3. Install in your AI assistant

**Claude Code:**
Reference the compiled skill in your project's `CLAUDE.md`:
```markdown
For agent analytics, follow the skill at: path/to/agent-analytics-skill/compiled_skill.md
```
Or copy `compiled_skill.md` into `.claude/skills/`.

**Cursor:**
Reference in `.cursorrules` or project rules:
```
@agent-analytics-skill/compiled_skill.md
```

**Other agents:**
Include `compiled_skill.md` as system/project context.

### 4. Ask questions

```
"What's the error rate for my agents this week?"
"Which tool has the highest failure rate?"
"Compare latency across models for the last 30 days"
"Show me the most expensive sessions"
"Are there any agent delegation loops?"
"Show me the delegation flow for trace abc123"
```

## Repo Structure

```
agent-analytics-skill/
├── skill.md                # The complete skill (schema, CTEs, methodology, patterns, examples)
├── compiled_skill.md       # Auto-generated: skill.md + all SQL inlined (run compile.py)
├── ctes/                   # Base CTEs — never write raw JSON extraction
│   ├── base_llm_responses.sql
│   ├── base_tool_calls.sql
│   ├── base_errors.sql
│   ├── base_sessions.sql
│   └── base_agent_tree.sql
├── queries/                # Ready-to-run analytics queries
│   ├── trace_reconstruction.sql
│   ├── latency_analysis.sql
│   ├── token_usage_trends.sql
│   ├── tool_failure_rates.sql
│   ├── agent_delegation_map.sql
│   ├── hitl_bottlenecks.sql
│   ├── model_comparison.sql
│   └── session_cost_estimate.sql
├── scripts/
│   ├── run_bq.py           # Query executor: auto-injects env vars, dry-run, billing limits
│   └── compile.py          # Compiles skill.md + all SQL into a single file
└── README.md
```

## How It Works

```
User asks question
       |
       v
AI client loads compiled_skill.md as context
       |
       v
LLM uses pre-built CTEs (never writes raw JSON extraction)
       |
       v
LLM follows methodology: Survey -> Filter -> Deep Dive
       |
       v
CRITICAL: Dry-run first (python scripts/run_bq.py --dry-run "SQL")
       |
       v
If scan < 1GB: execute (python scripts/run_bq.py "SQL")
If scan > 1GB: refine query, re-check
       |
       v
run_bq.py auto-replaces {PROJECT}, {DATASET}, {TABLE} from env vars
       |                                              |
       v                                              v
LLM interprets results using              Google BigQuery
failure pattern table                     (actual execution)
       |
       v
LLM renders output using visualization rules
(Mermaid for delegation, sorted tables for comparisons)
       |
       v
User gets formatted analysis + recommended next action
```

## Configuration

| Environment Variable | Description | Required | Default |
|---------------------|-------------|----------|---------|
| `GCP_PROJECT_ID` | Your GCP project ID | Yes | — |
| `BQ_DATASET` | BigQuery dataset name | Yes | — |
| `BQ_TABLE` | Table name | No | `agent_events` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account JSON (if not using ADC) | No | — |

## Cost Safety

Every query goes through a mandatory dry-run check before execution. The `run_bq.py` script:

1. **`--dry-run`** — Queries the BigQuery API for `total_bytes_processed` without running the job
2. **`--max-gb`** — Sets a hard billing limit (default: 1 GB). BigQuery rejects queries exceeding this
3. The skill instructs the LLM to ALWAYS dry-run first and refuse to execute if the estimate exceeds the limit

## Schema

This skill targets the BQAA table created by the [ADK BigQuery Agent Analytics plugin](https://adk.dev/integrations/bigquery-agent-analytics/#schema-reference). The table name is configurable via `BQ_TABLE` (defaults to `agent_events`). See `skill.md` Section 2 for the full schema reference.

## License

MIT
