#!/usr/bin/env python3
"""Compile skill.md + all CTEs + all queries into a single self-contained file.

Usage:
    python scripts/compile.py                     # writes to compiled_skill.md
    python scripts/compile.py -o my_output.md     # custom output path

Why: An LLM reading skill.md would otherwise waste tokens and steps invoking
file-read commands (e.g., `cat ctes/base_errors.sql`) to fetch the SQL it
needs. This script inlines everything into one file so the LLM gets full
context in a single read.
"""
import argparse
import os
import glob


REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read().strip()


def collect_sql_files(directory: str) -> list[tuple[str, str]]:
    """Return sorted list of (filename, content) for all .sql files in a dir."""
    pattern = os.path.join(REPO_ROOT, directory, "*.sql")
    files = sorted(glob.glob(pattern))
    return [(os.path.basename(f), read_file(f)) for f in files]


def compile_skill(output_path: str):
    # Read the base skill.md
    skill_path = os.path.join(REPO_ROOT, "skill.md")
    skill_content = read_file(skill_path)

    # Collect CTEs and queries
    ctes = collect_sql_files("ctes")
    queries = collect_sql_files("queries")

    # Build the compiled output
    parts = [
        skill_content,
        "",
        "---",
        "",
        "## Appendix A: Full CTE Source Files",
        "",
        "The following are the complete CTE source files inlined for reference.",
        "These are the same CTEs described in Section 3 above.",
        "",
    ]

    for filename, content in ctes:
        parts.append(f"### {filename}")
        parts.append("")
        parts.append("```sql")
        parts.append(content)
        parts.append("```")
        parts.append("")

    parts.append("---")
    parts.append("")
    parts.append("## Appendix B: Full Query Source Files")
    parts.append("")
    parts.append("The following are complete, ready-to-run queries from the queries/ directory.")
    parts.append("")

    for filename, content in queries:
        parts.append(f"### {filename}")
        parts.append("")
        parts.append("```sql")
        parts.append(content)
        parts.append("```")
        parts.append("")

    compiled = "\n".join(parts)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(compiled)

    # Stats
    cte_count = len(ctes)
    query_count = len(queries)
    line_count = compiled.count("\n") + 1
    print(f"Compiled skill.md + {cte_count} CTEs + {query_count} queries")
    print(f"Output: {output_path} ({line_count} lines)")


def main():
    parser = argparse.ArgumentParser(description="Compile skill into a single self-contained file")
    parser.add_argument("-o", "--output", default=os.path.join(REPO_ROOT, "compiled_skill.md"),
                        help="Output file path (default: compiled_skill.md)")
    args = parser.parse_args()
    compile_skill(args.output)


if __name__ == "__main__":
    main()
