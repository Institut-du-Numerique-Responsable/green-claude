#!/bin/bash
# Hook Stop — complète green-claude-cache.sh : sauvegarde la réponse finale
# dans le cache, sous la clé que cache.sh a déposée pour cette session.
#
# Le payload du hook Stop ne contient ni le prompt ni la réponse, seulement
# session_id / transcript_path / stop_hook_active / cwd. La clé vient donc du
# fichier pending, et la réponse est relue dans le transcript JSONL.
#
# Câblé automatiquement par install.sh dans ~/.claude/settings.json.

set -euo pipefail

CACHE_DIR="$HOME/.cache/green-claude"
INPUT="$(cat)"

SESSION="$(printf '%s' "$INPUT" | jq -r '.session_id // empty')"
TRANSCRIPT="$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')"
PENDING="$CACHE_DIR/pending/$SESSION"

# Pas de clé en attente (prompt servi depuis le cache, ou hook lancé seul) :
# rien à sauvegarder.
[ -n "$SESSION" ] || exit 0
[ -f "$PENDING" ] || exit 0
[ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ] || { rm -f "$PENDING"; exit 0; }

# Dernier bloc texte de l'assistant. -s puis last prend le bloc entier : un
# tail -1 ne garderait que sa dernière ligne. Les blocs thinking et tool_use
# sont écartés par le select.
RESPONSE="$(jq -rs '[ .[]
                      | select(.type == "assistant")
                      | .message.content[]?
                      | select(.type == "text")
                      | .text ] | last // empty' "$TRANSCRIPT" 2>/dev/null || true)"

if [ -n "$RESPONSE" ]; then
    printf '%s' "$RESPONSE" > "$CACHE_DIR/$(cat "$PENDING")"
fi
rm -f "$PENDING"
