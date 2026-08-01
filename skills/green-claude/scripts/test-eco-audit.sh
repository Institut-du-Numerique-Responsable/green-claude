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

# 7. Enrichissement image (ECO-CONT-01) : dimensions/poids réels si le
# fichier est résolvable sur disque, silence sur une URL distante ou un
# chemin invalide (rien à affirmer sans pouvoir vérifier).
python3 -c "
import struct, zlib
def chunk(tag, data):
    return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag+data))
sig = b'\x89PNG\r\n\x1a\n'
ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', 200, 100, 8, 2, 0, 0, 0))
raw = b''.join(b'\x00' + b'\xff\x00\x00' * 200 for _ in range(100))
idat = chunk(b'IDAT', zlib.compress(raw))
iend = chunk(b'IEND', b'')
open('$TMP/photo.png','wb').write(sig+ihdr+idat+iend)
" 2>/dev/null || fail "impossible de générer le PNG de test (python3 requis)"

cat > "$TMP/gallery.html" <<EOF
<img src="photo.png" alt="reel">
<img src="https://example.com/remote.png" alt="distant">
<img src="n-existe-pas.png" alt="invalide">
EOF
OUT="$(bash eco-audit.sh "$TMP/gallery.html")"
echo "$OUT" | grep -q '200x100px' || fail "enrichissement image : dimensions réelles non détectées"
echo "$OUT" | grep -q 'remote.png' && fail "enrichissement image : ne doit rien affirmer sur une URL distante"
echo "$OUT" | grep -q 'n-existe-pas.png' && fail "enrichissement image : ne doit rien affirmer sur un fichier absent"
true

echo "OK - 7 verifications passees"
