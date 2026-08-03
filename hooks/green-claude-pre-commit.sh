#!/bin/bash
# Hook git pre-commit : audite les fichiers de code mis en index avant qu'ils
# n'entrent dans l'historique. Complète le hook PostToolUse de Claude Code, qui
# ne voit que ce que Claude écrit — celui-ci voit aussi ce que tu écris toi.
#
# Installation :
#   ln -s ../../hooks/green-claude-pre-commit.sh .git/hooks/pre-commit
#
# Ne bloque jamais le commit : il signale et laisse passer. Un audit qui empêche
# de committer finit désactivé dans la semaine, et on perd les deux.
# Pour bloquer volontairement : GREEN_CLAUDE_STRICT=1 git commit ...

set -uo pipefail

AUDIT="$HOME/.claude/skills/green-claude/scripts/eco-audit.sh"
[ -x "$AUDIT" ] || AUDIT="$(git rev-parse --show-toplevel)/skills/green-claude/scripts/eco-audit.sh"
[ -x "$AUDIT" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

FILES=$(git diff --cached --name-only --diff-filter=ACM \
        | grep -iE '\.(py|js|jsx|ts|tsx|mjs|cjs|sql|pks|pkb|prc|fnc|trg|java|cs|php|rb|rs|c|h|cpp|cc|cxx|hpp|hh|go|kt|swift|scala|html|htm|css|scss|sass|vue|svelte)$' || true)
[ -n "$FILES" ] || exit 0

REPORT=$(printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 bash "$AUDIT" 2>/dev/null || true)
grep -q '^\[' <<<"$REPORT" || exit 0

echo "[Green Claude] Motifs d'éco-conception dans les fichiers commités :"
echo ""
echo "$REPORT"

if [ "${GREEN_CLAUDE_STRICT:-0}" = "1" ]; then
    echo "GREEN_CLAUDE_STRICT=1 : commit interrompu."
    exit 1
fi
exit 0
