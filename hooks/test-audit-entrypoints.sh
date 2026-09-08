#!/bin/bash
# Integration tests: real audit, hook payloads and Git index in a temporary repo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUDIT="$ROOT/skills/green-claude/scripts/eco-audit.sh"
SCORE="$ROOT/skills/green-claude/scripts/eco-score.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

# Resolve the installed audit location to this checkout; keep hook logic intact.
for name in audit pre-commit; do
    sed "s|^AUDIT=.*|AUDIT=\"$AUDIT\"|" "$ROOT/hooks/green-claude-$name.sh" > "$TMP/$name.sh"
done
mkdir "$TMP/repo"
cd "$TMP/repo"
git init -q
mkdir -p .green-claude
printf 'SELECT * FROM users;\n' > 'query file.sql'
git add 'query file.sql'
printf 'SELECT id FROM users;\n' > 'query file.sql'
if GREEN_CLAUDE_STRICT=1 bash "$TMP/pre-commit.sh" > "$TMP/out" 2>&1; then
    fail 'strict pre-commit accepted bad staged SQL hidden by an unstaged fix'
fi
grep -q ECO-SQL-01 "$TMP/out" || fail 'staged SQL finding missing'
git add 'query file.sql'
printf 'SELECT * FROM users;\n' > 'query file.sql'
if ! GREEN_CLAUDE_STRICT=1 bash "$TMP/pre-commit.sh" > "$TMP/out" 2>&1; then
    fail 'strict pre-commit rejected clean index because worktree is bad'
fi

printf 'SELECT * FROM users;\n' > query.sql
payload() {
    jq -nc --arg f "$PWD/$1" --rawfile c "$1" \
        '{tool_name:"Write",tool_input:{file_path:$f,content:$c}}'
}
printf 'ECO-SQL-01 query.sql ACCEPTED fixture\nECO-BACK-01 query.sql ACCEPTED fixture\n' > .green-claude/decisions.md
if ! payload query.sql | bash "$TMP/audit.sh" > "$TMP/out" 2>&1; then
    fail 'PostToolUse lost ACCEPTED decisions'
fi
printf 'query.sql\n' > .green-claude/ignore
: > .green-claude/decisions.md
if ! payload query.sql | bash "$TMP/audit.sh" > "$TMP/out" 2>&1; then
    fail 'PostToolUse lost file exclusion'
fi
: > .green-claude/ignore
: > .green-claude/decisions.md

# Languages added to the rule catalog must reach every entry point.
for file in sample.sh sample.zsh sample.jl sample.nim sample.zig sample.astro sample.kts sample.sc Dockerfile; do
    printf '\n' > "$file"
    if ! bash "$SCORE" --json "$file" > "$TMP/out" 2>&1; then
        fail "score omitted $file"
    fi
done
printf 'sleep 1\n' > sample.zsh
if payload sample.zsh | bash "$TMP/audit.sh" > "$TMP/out" 2>&1; then
    fail 'PostToolUse omitted Zsh rule'
fi
grep -q ECO-SH-04 "$TMP/out" || fail 'Zsh finding missing'
printf 'sleep 1\n' > sample.sh
git add sample.sh
if GREEN_CLAUDE_STRICT=1 bash "$TMP/pre-commit.sh" > "$TMP/out" 2>&1; then
    fail 'pre-commit omitted Shell rule'
fi
grep -q ECO-SH-04 "$TMP/out" || fail 'staged Shell finding missing'

if GREEN_CLAUDE_SHA256_TOOL=invalid GREEN_CLAUDE_STRICT=1 bash "$TMP/pre-commit.sh" > "$TMP/out" 2> "$TMP/err"; then
    fail 'strict pre-commit accepted an incomplete audit'
fi

if GREEN_CLAUDE_SHA256_TOOL=invalid bash "$SCORE" --json query.sql > "$TMP/out" 2> "$TMP/err"; then
    fail 'score reported success after audit failure'
fi
[ ! -s "$TMP/out" ] || fail 'score emitted a result after audit failure'
[ -s "$TMP/err" ] || fail 'score hid audit failure diagnostics'

[ "$FAILURES" -eq 0 ] || exit 1
echo 'OK - audit entry points verified'
