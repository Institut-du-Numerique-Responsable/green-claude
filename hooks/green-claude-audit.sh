#!/bin/bash
# Hook PostToolUse (Write|Edit|MultiEdit) — ce qu'un skill ne peut pas garantir :
# le skill est déclenché par le modèle, donc de façon probabiliste. Ce hook est
# exécuté par le harnais après CHAQUE écriture de fichier : l'audit passe, que
# Claude y ait pensé ou non.
#
# N'audite que le contenu introduit par l'écriture (new_string / content), pas
# tout le fichier : sinon chaque édition d'un fichier existant re-signale des
# motifs préexistants que la tâche en cours n'a pas introduits.
#
# Sortie code 2 = le rapport est réinjecté à Claude, qui corrige avant de
# poursuivre. Aucune issue = silence complet.
#
# À déclarer dans ~/.claude/settings.json (voir install.sh) :
#   "hooks": { "PostToolUse": [{"matcher": "Write|Edit|MultiEdit",
#     "hooks": [{"type": "command", "command": "~/.claude/hooks/green-claude-audit.sh"}]}] }

set -uo pipefail

AUDIT="$HOME/.claude/skills/green-claude/scripts/eco-audit.sh"
[ -x "$AUDIT" ] || exit 0            # skill absent : le hook ne casse rien
command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
FILE="$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")"
[ -n "$FILE" ] || exit 0

EXT="$(printf '%s' "${FILE##*.}" | tr '[:upper:]' '[:lower:]')"
[ "$EXT" != "$(printf '%s' "$FILE" | tr '[:upper:]' '[:lower:]')" ] || exit 0

# Uniquement du code : sur un .md ou un .json, les patterns des règles décrivent
# le sujet du document, pas un défaut à corriger (« penser à éviter SELECT * »).
case "$EXT" in
    py|js|jsx|ts|tsx|mjs|cjs|sql|pks|pkb|prc|fnc|trg|java|cs|php|rb|rs|c|h|cpp|cc|cxx|hpp|hh|go|kt|swift|scala|html|htm|css|scss|sass|vue|svelte|sh|bash) ;;
    *) exit 0 ;;
esac

# Contenu écrit : Write -> .content, Edit -> .new_string, MultiEdit -> tous les
# .edits[].new_string. Repli sur le fichier complet si rien n'est exploitable.
ADDED="$(jq -r '
    .tool_input
    | (.content // .new_string // ([.edits[]?.new_string] | join("\n")) // empty)' <<<"$INPUT")"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TARGET="$TMP_DIR/ajout.$EXT"

if [ -n "$ADDED" ]; then
    printf '%s\n' "$ADDED" > "$TARGET"
elif [ -f "$FILE" ]; then
    cp "$FILE" "$TARGET"
else
    exit 0
fi

REPORT="$("$AUDIT" "$TARGET" 2>/dev/null)" || exit 0
grep -q '^\[' <<<"$REPORT" || exit 0  # aucune issue : silence

# Le chemin temporaire n'a aucun sens pour Claude : on remet le vrai fichier.
REPORT="${REPORT//$TARGET/$FILE}"

cat >&2 <<EOF
[Green Claude] Éco-conception — motifs détectés dans ce que tu viens d'écrire ($FILE) :

$REPORT
Corrige ce qui est pertinent (impact Élevé en priorité). Si un signalement ne
s'applique pas au contexte, dis-le en une phrase et poursuis : ces règles ne
doivent jamais bloquer une demande légitime.
EOF
exit 2
