#!/bin/bash
# Hook Stop — complète green-claude-cache.sh : sauvegarde la réponse finale
# dans le cache, indexée par le hash du prompt qui l'a déclenchée.
#
# À déclarer dans ~/.claude/settings.json (voir install.sh) :
#   "hooks": { "Stop": [{"hooks": [{"type": "command", "command": "~/.claude/hooks/green-claude-cache-save.sh"}]}] }

#
# NOTE : les noms de champs (.prompt / .response) du payload JSON du hook Stop
# dépendent de la version de Claude Code — vérifie la doc officielle avant
# usage réel et ajuste les clés jq ci-dessous en conséquence.

set -euo pipefail

CACHE_DIR="$HOME/.cache/green-claude"
mkdir -p "$CACHE_DIR"

INPUT="$(cat)"
PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty')"
RESPONSE="$(echo "$INPUT" | jq -r '.response // empty')"

[ -n "$PROMPT" ] && [ -n "$RESPONSE" ] || exit 0

KEY="$(echo -n "$PROMPT" | shasum -a 256 | cut -d' ' -f1)"
echo "$RESPONSE" > "$CACHE_DIR/$KEY"
