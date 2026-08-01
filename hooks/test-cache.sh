#!/bin/bash
# Vérifie le cycle complet du cache : miss -> sauvegarde -> hit, l'isolation
# par projet, et la sortie propre quand il n'y a rien à sauvegarder.
# Lancer : bash hooks/test-cache.sh
set -euo pipefail
cd "$(dirname "$0")"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"          # isole ~/.cache/green-claude

TRANSCRIPT="$TMP/t.jsonl"
cat > "$TRANSCRIPT" <<'EOF'
{"type":"assistant","message":{"content":[{"type":"thinking","thinking":"a exclure"}]}}
{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"x","content":"a exclure"}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{}}]}}
{"type":"assistant","message":{"content":[{"type":"text","text":"Paris.\nSur deux lignes."}]}}
EOF

prompt_payload() {  # session, cwd, prompt
    jq -nc --arg s "$1" --arg t "$TRANSCRIPT" --arg c "$2" --arg p "$3" \
      '{session_id:$s, transcript_path:$t, cwd:$c, hook_event_name:"UserPromptSubmit", prompt:$p}'
}
stop_payload() {    # session, cwd
    jq -nc --arg s "$1" --arg t "$TRANSCRIPT" --arg c "$2" \
      '{session_id:$s, transcript_path:$t, cwd:$c, hook_event_name:"Stop", stop_hook_active:false}'
}
fail() { echo "ECHEC: $1"; exit 1; }
CACHE="$HOME/.cache/green-claude"

# 1. Premier passage : rien en cache, aucun blocage, clé déposée pour Stop.
OUT="$(prompt_payload sess1 /proj/a "capitale de la France" | bash green-claude-cache.sh 2>/dev/null)"
[ -z "$OUT" ] || fail "1er passage: blocage inattendu -> $OUT"
[ -f "$CACHE/pending/sess1" ] || fail "1er passage: cle pending non deposee"

# 2. Stop : la réponse du transcript atterrit en cache, le pending est purgé.
stop_payload sess1 /proj/a | bash green-claude-cache-save.sh
N="$(find "$CACHE" -maxdepth 1 -type f | wc -l | tr -d ' ')"
[ "$N" -eq 1 ] || fail "sauvegarde: attendu 1 entree en cache, trouve $N"
if [ -f "$CACHE/pending/sess1" ]; then fail "sauvegarde: pending non nettoye"; fi

# 3. Même prompt, même projet, autre session : hit franc.
OUT="$(prompt_payload sess2 /proj/a "capitale de la France" | bash green-claude-cache.sh 2>/dev/null)"
printf '%s' "$OUT" | jq -e '.decision == "block"' >/dev/null \
    || fail "2e passage: pas de blocage (stdout doit etre du JSON seul) -> $OUT"
printf '%s' "$OUT" | jq -e '.reason | startswith("Paris.\nSur deux lignes.")' >/dev/null \
    || fail "2e passage: reponse multi-lignes tronquee ou polluee"

# 4. Même prompt, autre projet : pas de partage entre cwd.
OUT="$(prompt_payload sess3 /proj/b "capitale de la France" | bash green-claude-cache.sh 2>/dev/null)"
[ -z "$OUT" ] || fail "isolation cwd: cache partage entre deux projets"

# 5. Stop sans clé en attente : sortie propre, pas d'erreur.
stop_payload sessX /proj/a | bash green-claude-cache-save.sh \
    || fail "Stop sans pending doit sortir proprement"

# 6. Purge : une entrée et un pending plus vieux que le TTL disparaissent, les
# récents survivent. Une session tuée avant son Stop laisse un pending orphelin
# qu'aucun autre passage ne viendra nettoyer.
touch -t 200001010000 "$CACHE/pending/vieux-orphelin" "$CACHE"/[0-9a-f]*
touch "$CACHE/pending/recent"
prompt_payload sess4 /proj/c "declenche la purge" | bash green-claude-cache.sh 2>/dev/null >/dev/null
if [ -f "$CACHE/pending/vieux-orphelin" ]; then fail "purge: pending orphelin non supprime"; fi
[ -f "$CACHE/pending/recent" ] || fail "purge: pending recent supprime a tort"
N="$(find "$CACHE" -maxdepth 1 -type f | wc -l | tr -d ' ')"
[ "$N" -eq 0 ] || fail "purge: entree perimee conservee ($N restante(s))"

# 7. Le dépôt bouge sous la réponse : même prompt, même projet, mais HEAD
# différent -> miss. C'est le cas observé en vrai, une réponse decrivant l'état
# du dépôt resservie après des commits qui la rendaient fausse.
REPO="$TMP/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
gitc() { git -C "$REPO" -c user.email=t@t -c user.name=t "$@"; }
gitc commit -q --allow-empty -m un

prompt_payload sess5 "$REPO" "etat du depot" | bash green-claude-cache.sh >/dev/null 2>&1
stop_payload sess5 "$REPO" | bash green-claude-cache-save.sh
OUT="$(prompt_payload sess6 "$REPO" "etat du depot" | bash green-claude-cache.sh 2>/dev/null)"
printf '%s' "$OUT" | jq -e '.decision == "block"' >/dev/null \
    || fail "depot inchange: le hit attendu n a pas eu lieu"

gitc commit -q --allow-empty -m deux
OUT="$(prompt_payload sess7 "$REPO" "etat du depot" | bash green-claude-cache.sh 2>/dev/null)"
[ -z "$OUT" ] || fail "apres commit: la reponse perimee a ete resservie"

echo "OK - 7 verifications passees"
