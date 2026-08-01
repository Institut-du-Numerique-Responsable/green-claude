#!/bin/bash
# Hook UserPromptSubmit — ce qu'un skill ne peut pas faire car il s'exécute
# APRÈS que la requête ait déjà atteint le modèle :
#   1. Cache local : une question déjà posée est resservie sans appeler l'API.
#   2. Heures de pointe : avertit avant d'envoyer une requête lourde en journée.
#
# Câblé automatiquement par install.sh dans ~/.claude/settings.json.

set -euo pipefail

CACHE_DIR="$HOME/.cache/green-claude"
OFFPEAK_START=22   # 22h UTC
OFFPEAK_END=6       # 6h UTC
TTL_MIN=60
mkdir -p "$CACHE_DIR/pending"

# Hasher le prompt seul, pas l'enveloppe : session_id & co. varieraient la clé
# à chaque session et cache-save.sh n'en retrouverait aucune.
INPUT="$(cat)"
PROMPT="$(printf '%s' "$INPUT" | jq -r '.prompt // empty')"
[ -n "$PROMPT" ] || exit 0

# Le cwd entre dans la clé : le même prompt posé dans deux projets différents
# n'attend pas la même réponse. Le HEAD git aussi : sans lui, une réponse
# décrivant le dépôt survit aux commits qui la rendent fausse. Hors dépôt git,
# la clé retombe sur cwd + prompt.
CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // empty')"
HEAD_SHA="$(git -C "${CWD:-.}" rev-parse HEAD 2>/dev/null || true)"
KEY="$(printf '%s\n%s\n%s' "$CWD" "$HEAD_SHA" "$PROMPT" | shasum -a 256 | cut -d' ' -f1)"
CACHE_FILE="$CACHE_DIR/$KEY"

# Purge par date de fichier, pas d'index de TTL : une heure, car une réponse
# vieillit vite quand le code qu'elle décrit bouge. La profondeur 2 couvre
# aussi pending/ : une session qui s'arrête sans passer par le hook Stop y
# laisse une clé que plus personne ne viendra consommer.
find "$CACHE_DIR" -mindepth 1 -maxdepth 2 -type f -mmin "+$TTL_MIN" -delete 2>/dev/null || true

# 1. Cache : réponse déjà connue pour ce prompt exact -> zéro appel modèle
if [ -f "$CACHE_FILE" ]; then
    # stdout doit être du JSON seul : la réponse passe par "reason", que
    # decision "block" affiche à la place de l'appel au modèle.
    jq -n --rawfile r "$CACHE_FILE" \
      '{decision: "block", reason: ($r + "\n[Green Claude] Réponse servie depuis le cache local (zéro appel modèle).")}'
    exit 0
fi

# Le payload du hook Stop ne porte ni le prompt ni la réponse : on lui laisse
# la clé ici, plutôt que de la lui faire recalculer depuis le transcript (tout
# écart de texte la ferait diverger et le cache ne se remplirait jamais).
SESSION="$(printf '%s' "$INPUT" | jq -r '.session_id // empty')"
if [ -n "$SESSION" ]; then
    printf '%s' "$KEY" > "$CACHE_DIR/pending/$SESSION"
fi

# 2. Heures de pointe : simple avertissement, ne bloque jamais
current_hour=$((10#$(date -u +%H)))
if [ "$current_hour" -lt "$OFFPEAK_START" ] && [ "$current_hour" -ge "$OFFPEAK_END" ]; then
    echo "[Green Claude] Heure de pointe (réseau électrique plus carboné). Les heures creuses sont 22h-6h UTC." >&2
fi

exit 0
