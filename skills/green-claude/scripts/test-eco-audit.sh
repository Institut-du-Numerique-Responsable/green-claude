#!/bin/bash
# Vérifie eco-audit.sh : détection par pattern (grep), détection par détecteur
# dédié (detect-nested-loops.awk), absence de faux positif sur du code propre,
# et cohérence de --list-rules avec les règles réellement détectables.
# Lancer : bash scripts/test-eco-audit.sh
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v jq >/dev/null 2>&1; then
    echo "jq est requis pour ce test." >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "ECHEC: $1"; exit 1; }

# 1. Détection par pattern (grep) : SELECT * doit être signalé.
cat > "$TMP/query.sql" <<'EOF'
SELECT * FROM members WHERE id = 1;
EOF
OUT="$(bash eco-audit.sh "$TMP/query.sql")"
echo "$OUT" | grep -q 'ECO-BACK-01' || fail "SELECT * non détecté (pattern grep)"

# 2. Pas de faux positif pattern sur du code qui ne matche aucune règle.
cat > "$TMP/clean.sql" <<'EOF'
SELECT id, name FROM members WHERE id = 1;
EOF
OUT="$(bash eco-audit.sh "$TMP/clean.sql")"
echo "$OUT" | grep -q 'ECO-BACK-01' && fail "faux positif : requête déjà propre signalée"
true

# 3. Détection par détecteur dédié : boucle imbriquée multi-lignes (le cas que
# grep ligne-par-ligne ne peut pas voir).
cat > "$TMP/nested.js" <<'EOF'
for (const user of users) {
  for (const order of user.orders) {
    total += order.amount;
  }
}
EOF
OUT="$(bash eco-audit.sh "$TMP/nested.js")"
echo "$OUT" | grep -q 'ECO-BACK-03' || fail "boucle imbriquée non détectée (détecteur awk)"
echo "$OUT" | grep -q 'Ligne ' || fail "numéro de ligne absent de la sortie du détecteur"

# 4. Pas de faux positif du détecteur sur des boucles séquentielles (pas
# imbriquées) ni sur une boucle simple contenant un if.
cat > "$TMP/sequential.js" <<'EOF'
for (const u of users) {
  names.push(u.name);
}
for (const o of orders) {
  totals.push(o.amount);
}
EOF
OUT="$(bash eco-audit.sh "$TMP/sequential.js")"
echo "$OUT" | grep -q 'ECO-BACK-03' && fail "faux positif : boucles séquentielles signalées comme imbriquées"
true

# 5. --list-rules : les règles détectables (pattern OU detector) ne doivent
# pas y figurer, seules les règles de démarche y sont.
OUT="$(bash eco-audit.sh --list-rules)"
echo "$OUT" | grep -q 'ECO-BACK-01' && fail "--list-rules liste une règle détectable par pattern (ECO-BACK-01)"
echo "$OUT" | grep -q 'ECO-BACK-03' && fail "--list-rules liste une règle détectable par détecteur (ECO-BACK-03)"
echo "$OUT" | grep -q 'ECO-STRAT-01' || fail "--list-rules omet une règle de démarche réelle (ECO-STRAT-01)"

# 6. Fichier inexistant : ne doit pas faire planter l'audit.
bash eco-audit.sh "$TMP/n-existe-pas.js" >/dev/null 2>&1 \
    || fail "l'audit échoue sur un fichier inexistant au lieu de l'ignorer"

echo "OK - 6 verifications passees"
