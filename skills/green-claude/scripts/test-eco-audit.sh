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

# 8. ECO-UX-05 (polices) : détection élargie aux CDN tiers, comptage des
# familles/variantes auto-hébergées et poids réel contre le seuil RGESN 4.8
# (40 Ko d'excès par police, 400 Ko au total), format non compressé signalé.
python3 -c "open('$TMP/small.woff2','wb').write(b'\x00' * 20000)"
python3 -c "open('$TMP/big.woff2','wb').write(b'\x00' * 60000)"
python3 -c "open('$TMP/legacy.ttf','wb').write(b'\x00' * 15000)"

cat > "$TMP/fonts.css" <<EOF
@font-face {
  font-family: "Inter";
  src: url("small.woff2") format("woff2");
}
@font-face {
  font-family: "Inter";
  src: url("big.woff2") format("woff2");
}
@font-face {
  font-family: "Legacy";
  src: url("legacy.ttf") format("truetype");
}
EOF
OUT="$(bash eco-audit.sh "$TMP/fonts.css")"
echo "$OUT" | grep -q '2 famille(s)' || fail "polices : comptage des familles distinctes incorrect"
echo "$OUT" | grep -q '3 variante(s)' || fail "polices : comptage des variantes incorrect"
echo "$OUT" | grep -q 'big.woff2.*40 Ko' || fail "polices : excès au-delà de 40 Ko non détecté"
echo "$OUT" | grep -q 'legacy.ttf.*non compressé' || fail "polices : format TTF non signalé"
echo "$OUT" | grep -q 'small.woff2' && fail "polices : ne doit rien signaler sur une police déjà conforme (woff2, < 40 Ko)"
true

cat > "$TMP/google-fonts.html" <<EOF
<link href="https://fonts.googleapis.com/css2?family=Roboto" rel="stylesheet">
EOF
OUT="$(bash eco-audit.sh "$TMP/google-fonts.html")"
echo "$OUT" | grep -q 'ECO-UX-05' || fail "polices : Google Fonts (CDN tiers) non détecté du tout"
echo "$OUT" | grep -q 'non mesurables sans requête réseau' || fail "polices : absence de la mise en garde sur le CDN tiers"

# 9. ECO-FRONT-05 (code mort) : détecte le vrai code inatteignable après un
# return/throw, sans se faire piéger par les cas très courants où le bloc
# surveillé se referme sur la même ligne que la suite du code (try/catch,
# if/else) ni par le fallthrough syntaxique d'un switch/case.
cat > "$TMP/dead.js" <<'EOF'
function foo() {
  return 42;
  console.log("mort");
}
function bar(x) {
  if (x) {
    return 1;
  }
  console.log("atteignable, hors du if");
}
function classify(x) {
  switch (x) {
    case 1:
      return "un";
    default:
      return "autre";
  }
}
function safe() {
  try {
    return risky();
  } catch (e) {
    console.log("gestion erreur, atteignable");
  }
}
EOF
OUT="$(bash eco-audit.sh "$TMP/dead.js")"
echo "$OUT" | grep -q 'mort");' || fail "code mort : vrai positif (après return) non détecté"
echo "$OUT" | grep -q 'hors du if' && fail "code mort : faux positif (code après un if contenant un return)"
echo "$OUT" | grep -q 'gestion erreur' && fail "code mort : faux positif (catch après un return dans le try)"
N=$(echo "$OUT" | grep -c 'ECO-FRONT-05')
[ "$N" -eq 1 ] || fail "code mort : attendu 1 seul hit sur ce fichier, trouvé $N"

# 10. ECO-FRONT-06 (globales implicites) : détecte var/affectation nue au
# niveau racine d'un script, silencieux dans une IIFE/fonction, et ne
# confond pas une affectation de propriété ("window.foo =", "obj.bar =")
# avec une nouvelle globale.
cat > "$TMP/globals.js" <<'EOF'
var leaked = 1;
foo = 2;
window.bar = 3;
(function() {
  var scoped = 1;
})();
function helper() {
  var localVar = 1;
}
obj.prop = 5;
EOF
OUT="$(bash eco-audit.sh "$TMP/globals.js")"
echo "$OUT" | grep -q 'var leaked' || fail "globales : var au niveau racine non détecté"
echo "$OUT" | grep -q 'foo = 2' || fail "globales : affectation nue au niveau racine non détectée"
echo "$OUT" | grep -q 'window.bar' && fail "globales : faux positif sur une affectation de propriété (window.bar)"
echo "$OUT" | grep -q 'var scoped' && fail "globales : faux positif sur une var dans une IIFE"
echo "$OUT" | grep -q 'localVar' && fail "globales : faux positif sur une var dans une fonction"
echo "$OUT" | grep -q 'obj.prop' && fail "globales : faux positif sur une affectation de propriété (obj.prop)"

# 11. ECO-FRONT-07 (XHR synchrone) : détecte le 3e argument false, pas true.
cat > "$TMP/sync.js" <<'EOF'
xhr.open('GET', '/api', false);
EOF
cat > "$TMP/async.js" <<'EOF'
xhr.open('GET', '/api', true);
EOF
OUT="$(bash eco-audit.sh "$TMP/sync.js")"
echo "$OUT" | grep -q 'ECO-FRONT-07' || fail "XHR synchrone non détecté"
OUT="$(bash eco-audit.sh "$TMP/async.js")"
echo "$OUT" | grep -q 'ECO-FRONT-07' && fail "faux positif : XHR asynchrone (true) signalé comme synchrone"
true

# 12. ECO-FRONT-08 (taille DOM) : seuils YellowLabTools (3000 éléments,
# 25 niveaux), silencieux sous les seuils, éléments vides (img) sans effet
# sur la profondeur.
python3 -c "
html = '<div>'
for i in range(30): html += '<div>'
html += 'x'
for i in range(30): html += '</div>'
html += '</div>'
open('$TMP/deep.html', 'w').write(html)
"
cat > "$TMP/shallow.html" <<'EOF'
<div><p>ok</p><img src="x.jpg"></div>
EOF
OUT="$(bash eco-audit.sh "$TMP/deep.html")"
echo "$OUT" | grep -q 'ECO-FRONT-08' || fail "profondeur DOM excessive non détectée"
OUT="$(bash eco-audit.sh "$TMP/shallow.html")"
echo "$OUT" | grep -q 'ECO-FRONT-08' && fail "faux positif sur un DOM simple"
true

# 13. ECO-FRONT-09 (IDs dupliqués) : détecte le doublon, pas de faux positif
# sur valid=/grid= qui contiennent "id" sans être des id.
cat > "$TMP/dupid.html" <<'EOF'
<div id="a">1</div>
<div id="a">2</div>
EOF
cat > "$TMP/novalidfp.html" <<'EOF'
<div valid="a">1</div>
<div grid="a">2</div>
EOF
OUT="$(bash eco-audit.sh "$TMP/dupid.html")"
echo "$OUT" | grep -q 'ECO-FRONT-09' || fail "id dupliqué non détecté"
OUT="$(bash eco-audit.sh "$TMP/novalidfp.html")"
echo "$OUT" | grep -q 'ECO-FRONT-09' && fail "faux positif : valid=/grid= pris pour un id"
true

# 14. ECO-FRONT-10 (!important) : seuil 200, silencieux en dessous.
python3 -c "
open('$TMP/manyimp.css', 'w').write('.a { color: red !important; }\n' * 250)
"
cat > "$TMP/fewimp.css" <<'EOF'
.a { color: red !important; }
EOF
OUT="$(bash eco-audit.sh "$TMP/manyimp.css")"
echo "$OUT" | grep -q 'ECO-FRONT-10' || fail "usage excessif de !important non détecté"
OUT="$(bash eco-audit.sh "$TMP/fewimp.css")"
echo "$OUT" | grep -q 'ECO-FRONT-10' && fail "faux positif sur un usage ponctuel de !important"
true

# 15. ECO-FRONT-11 (CSS dupliqué) : sélecteurs en un-liner ET propriétés en
# style étalé, seuil 100 pour chacun.
python3 -c "
open('$TMP/dupsel.css', 'w').write('.dup { color: red; }\n' * 105)
"
OUT="$(bash eco-audit.sh "$TMP/dupsel.css")"
echo "$OUT" | grep -q 'ECO-FRONT-11' || fail "sélecteurs CSS dupliqués non détectés"

# 16. ECO-FRONT-12 (hacks IE) : détecte, pas de faux positif sur du CSS propre.
cat > "$TMP/iehack.css" <<'EOF'
* html .foo { color: red; }
EOF
cat > "$TMP/cleanhack.css" <<'EOF'
.foo { color: red; }
EOF
OUT="$(bash eco-audit.sh "$TMP/iehack.css")"
echo "$OUT" | grep -q 'ECO-FRONT-12' || fail "hack IE (star html) non détecté"
OUT="$(bash eco-audit.sh "$TMP/cleanhack.css")"
echo "$OUT" | grep -q 'ECO-FRONT-12' && fail "faux positif hack IE sur CSS propre"
true

echo "OK - 16 verifications passees"
