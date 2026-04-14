#!/usr/bin/env python3
"""Lightweight BigQuery executor for agent analytics queries.

Usage:
    python scripts/run_bq.py "SELECT ..."
    python scripts/run_bq.py --dry-run "SELECT ..."
    python scripts/run_bq.py --max-gb 5 "SELECT ..."

Features:
- Auto-injects {PROJECT}, {DATASET}, {TABLE} from environment variables
  so the LLM never needs to know the user's specific project/dataset/table.
- --dry-run mode estimates bytes scanned WITHOUT executing the query.
- --max-gb sets the billing safety limit (default 1 GB).
"""
import sys
import json
import os
import argparse

from google.cloud import bigquery


def inject_placeholders(sql: str, project: str, dataset: str, table: str) -> str:
    """Replace {PROJECT}, {DATASET}, {TABLE} placeholders with env values."""
    return (
        sql.replace("{PROJECT}", project)
        .replace("{DATASET}", dataset)
        .replace("{TABLE}", table)
    )


def format_bytes(n: int) -> str:
    """Human-readable byte size."""
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(n) < 1024:
            return f"{n:.2f} {unit}"
        n /= 1024
    return f"{n:.2f} PB"


def main():
    parser = argparse.ArgumentParser(description="Run a BigQuery query with safety limits")
    parser.add_argument("query", help="SQL query string")
    parser.add_argument("--project", default=os.environ.get("GCP_PROJECT_ID", ""), help="GCP project ID")
    parser.add_argument("--dataset", default=os.environ.get("BQ_DATASET", ""), help="BigQuery dataset")
    parser.add_argument("--table", default=os.environ.get("BQ_TABLE", "agent_events"), help="Table name (default: agent_events)")
    parser.add_argument("--max-gb", type=int, default=1, help="Max bytes billed in GB (default: 1)")
    parser.add_argument("--dry-run", action="store_true", help="Estimate bytes scanned without executing")
    args = parser.parse_args()

    if not args.project:
        print("ERROR: Set GCP_PROJECT_ID env var or pass --project", file=sys.stderr)
        sys.exit(1)
    if not args.dataset:
        print("ERROR: Set BQ_DATASET env var or pass --dataset", file=sys.stderr)
        sys.exit(1)

    # Auto-inject placeholders from env/args
    sql = inject_placeholders(args.query, args.project, args.dataset, args.table)

    client = bigquery.Client(project=args.project)

    if args.dry_run:
        # Dry run: estimate bytes scanned without executing
        job_config = bigquery.QueryJobConfig(
            dry_run=True,
            use_query_cache=False,
            use_legacy_sql=False,
        )
        try:
            job = client.query(sql, job_config=job_config)
            bytes_processed = job.total_bytes_processed
            print(json.dumps({
                "dry_run": True,
                "total_bytes_processed": bytes_processed,
                "human_readable": format_bytes(bytes_processed),
                "exceeds_limit": bytes_processed > args.max_gb * (1 << 30),
                "limit_gb": args.max_gb,
            }))
        except Exception as e:
            print(f"ERROR (dry-run): {e}", file=sys.stderr)
            sys.exit(1)
    else:
        # Actual execution with billing limit
        job_config = bigquery.QueryJobConfig(
            maximum_bytes_billed=args.max_gb * (1 << 30),
            use_legacy_sql=False,
        )
        try:
            result = client.query(sql, job_config=job_config).result()
            for row in result:
                print(json.dumps(dict(row), default=str))
        except Exception as e:
            print(f"ERROR: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
