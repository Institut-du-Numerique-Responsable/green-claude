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

source "$(dirname "$AUDIT")/audit-common.sh"
load_audit_extensions || exit 0
is_auditable_file "$FILE" || exit 0

# Contenu écrit : Write -> .content, Edit -> .new_string, MultiEdit -> tous les
# .edits[].new_string. Repli sur le fichier complet si rien n'est exploitable.
ADDED="$(jq -r '
    .tool_input
    | (.content // .new_string // ([.edits[]?.new_string] | join("\n")) // empty)' <<<"$INPUT")"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TARGET="$TMP_DIR/${FILE##*/}"

if [ -n "$ADDED" ]; then
    printf '%s\n' "$ADDED" > "$TARGET"
elif [ -f "$FILE" ]; then
    cp "$FILE" "$TARGET"
else
    exit 0
fi

# Le contenu est audité depuis une copie temporaire, mais les chemins relatifs
# qu'il contient (« assets/logo.webp », « ./config.json ») se résolvent depuis
# le répertoire du fichier réel. Sans cette base, toute règle qui vérifie
# l'existence d'un fichier référencé — liens locaux cassés, poids réel d'une
# image — signale systématiquement un défaut inexistant, et un faux positif
# systématique est ce qui apprend à ignorer le hook.
GREEN_CLAUDE_BASE_DIR="$(dirname "$FILE")"
GREEN_CLAUDE_SOURCE_FILE="$FILE"
export GREEN_CLAUDE_BASE_DIR GREEN_CLAUDE_SOURCE_FILE

REPORT="$("$AUDIT" "$TARGET" 2>/dev/null)" || exit 0
grep -q '^\[' <<<"$REPORT" || exit 0  # aucune issue : silence

cat >&2 <<EOF
[Green Claude] Éco-conception — motifs détectés dans ce que tu viens d'écrire ($FILE) :

$REPORT
Corrige ce qui est pertinent (impact Élevé en priorité). Si un signalement ne
s'applique pas au contexte, dis-le en une phrase et poursuis : ces règles ne
doivent jamais bloquer une demande légitime.
EOF
exit 2
