#!/bin/bash
# Hook UserPromptSubmit — ce qu'un skill ne peut pas faire car il s'exécute
# APRÈS que la requête ait déjà atteint le modèle :
#   1. Cache local : une question déjà posée est resservie sans appeler l'API.
#   2. Heures de pointe : avertit avant d'envoyer une requête lourde en journée.
#
# À déclarer dans ~/.claude/settings.json (voir install.sh) :
#   "hooks": { "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "~/.claude/hooks/green-claude-cache.sh"}]}] }

set -euo pipefail

CACHE_DIR="$HOME/.cache/green-claude"
OFFPEAK_START=22   # 22h UTC
OFFPEAK_END=6       # 6h UTC
mkdir -p "$CACHE_DIR"

# Hasher le prompt seul, pas l'enveloppe : session_id & co. varieraient la clé
# à chaque session et cache-save.sh n'en retrouverait aucune.
PROMPT="$(jq -r '.prompt // empty')"
[ -n "$PROMPT" ] || exit 0
KEY="$(echo -n "$PROMPT" | shasum -a 256 | cut -d' ' -f1)"
CACHE_FILE="$CACHE_DIR/$KEY"

# 1. Cache : réponse déjà connue pour ce prompt exact -> zéro appel modèle
if [ -f "$CACHE_FILE" ]; then
    # stdout doit être du JSON seul : la réponse passe par "reason", que
    # decision "block" affiche à la place de l'appel au modèle.
    jq -n --rawfile r "$CACHE_FILE" \
      '{decision: "block", reason: ($r + "\n[Green Claude] Réponse servie depuis le cache local (zéro appel modèle).")}'
    exit 0
fi

# 2. Heures de pointe : simple avertissement, ne bloque jamais
current_hour=$((10#$(date -u +%H)))
if [ "$current_hour" -lt "$OFFPEAK_START" ] && [ "$current_hour" -ge "$OFFPEAK_END" ]; then
    echo "[Green Claude] Heure de pointe (réseau électrique plus carboné). Les heures creuses sont 22h-6h UTC." >&2
fi

exit 0
