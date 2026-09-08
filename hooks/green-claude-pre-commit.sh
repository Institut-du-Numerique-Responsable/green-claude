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

source "$(dirname "$AUDIT")/audit-common.sh" || exit 1
load_audit_extensions || exit 1
cd "$(git rev-parse --show-toplevel)" || exit 1
TMP_DIR="$(mktemp -d)" || exit 1
trap 'rm -rf "$TMP_DIR"' EXIT
FOUND=0
ERRORS=0
# NUL-delimited names preserve spaces and newlines. Include renames, whose
# destination can contain new code even when Git classifies the change as R.
git diff --cached --name-only -z --diff-filter=ACMR > "$TMP_DIR/files" || exit 1
while IFS= read -r -d '' file; do
    is_auditable_file "$file" || continue
    # Audit the staged blob, even if the working copy was edited or deleted.
    TARGET="$TMP_DIR/${file##*/}"
    if ! git show ":$file" > "$TARGET"; then
        ERRORS=1
        continue
    fi
    if ! REPORT=$(GREEN_CLAUDE_SOURCE_FILE="$file" \
        GREEN_CLAUDE_BASE_DIR="$PWD/$(dirname "$file")" bash "$AUDIT" "$TARGET"); then
        ERRORS=1
        continue
    fi
    grep -q '^\[' <<<"$REPORT" || continue
    if [ "$FOUND" -eq 0 ]; then
        echo "[Green Claude] Motifs d'éco-conception dans le contenu indexé :"
    fi
    FOUND=1
    echo "$REPORT"
done < "$TMP_DIR/files"
if [ "$ERRORS" -ne 0 ]; then
    echo "[Green Claude] Audit incomplet : au moins un fichier n'a pas pu être analysé." >&2
fi
[ "$FOUND" -ne 0 ] || [ "$ERRORS" -ne 0 ] || exit 0

if [ "${GREEN_CLAUDE_STRICT:-0}" = "1" ]; then
    echo "GREEN_CLAUDE_STRICT=1 : commit interrompu."
    exit 1
fi
exit 0
