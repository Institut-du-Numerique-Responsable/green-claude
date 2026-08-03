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
# Le fichier contient aussi un lien mort (n-existe-pas.png) et une image
# distante, légitimement signalés par ECO-HEB-06 (liens cassés) : on vérifie
# ici que c'est bien ECO-CONT-01 (enrichissement image) qui ne dit rien sur
# ces deux-là, pas que la sortie entière les tait (une autre règle le fait).
CONT01_BLOCK="$(echo "$OUT" | awk '/ECO-CONT-01/{p=1} p&&/^$/{p=0} p')"
echo "$CONT01_BLOCK" | grep -q 'remote.png' && fail "enrichissement image : ne doit rien affirmer sur une URL distante"
echo "$CONT01_BLOCK" | grep -q 'n-existe-pas.png' && fail "enrichissement image : ne doit rien affirmer sur un fichier absent"
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
cat >> "$TMP/fonts.css" <<EOF
@font-face {
  font-family: "Extra";
  src: url("small.woff2") format("woff2");
}
EOF
OUT="$(bash eco-audit.sh "$TMP/fonts.css")"
echo "$OUT" | grep -q '3 famille(s)' || fail "polices : comptage des familles distinctes incorrect"
echo "$OUT" | grep -q '4 variante(s)' || fail "polices : comptage des variantes incorrect"
echo "$OUT" | grep -q 'big.woff2.*40 Ko' || fail "polices : excès au-delà de 40 Ko non détecté"
echo "$OUT" | grep -q 'legacy.ttf.*non compressé' || fail "polices : format TTF non signalé"
echo "$OUT" | grep -q 'small.woff2' && fail "polices : ne doit rien signaler sur une police déjà conforme (woff2, < 40 Ko)"
true

# Sous le seuil RGESN (2 familles, 2 variantes, woff2 légers) : rester conforme
# n'est pas une remarque à faire. Émettre le décompte dans tous les cas rendait
# la règle impossible à satisfaire.
cat > "$TMP/fonts-ok.css" <<EOF
@font-face {
  font-family: "Inter";
  src: url("small.woff2") format("woff2");
}
@font-face {
  font-family: "Serif";
  src: url("small.woff2") format("woff2");
}
EOF
OUT="$(bash eco-audit.sh "$TMP/fonts-ok.css")"
echo "$OUT" | grep -q 'ECO-UX-05' && fail "polices : ne doit rien signaler sous le seuil RGESN (2 familles / 2 variantes)"
true

# Une famille restreinte par unicode-range à une écriture non latine n'est
# téléchargée que si la page affiche cette écriture : elle ne pèse pas sur le
# budget latin, sinon tout site multilingue échoue en faisant ce qu'il faut.
cat > "$TMP/fonts-ar.css" <<EOF
@font-face {
  font-family: "Inter";
  src: url("small.woff2") format("woff2");
  unicode-range: U+0000-00FF;
}
@font-face {
  font-family: "Serif";
  src: url("small.woff2") format("woff2");
  unicode-range: U+0000-00FF;
}
@font-face {
  font-family: "Cairo";
  src: url("small.woff2") format("woff2");
  unicode-range: U+0600-06FF, U+FE70-FEFC;
}
EOF
OUT="$(bash eco-audit.sh "$TMP/fonts-ar.css")"
echo "$OUT" | grep -q 'dépasse le seuil RGESN 4.8' && fail "polices : une famille non latine scopée par unicode-range ne doit pas peser sur le budget latin"
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

# Le détecteur suit la profondeur des accolades : celles qui vivent dans une
# chaîne ou un commentaire n'en sont pas. Et une garde `if (x) return;` sur une
# seule ligne, ou un `return` dont le bloc se referme sur la même ligne, ne rend
# rien inatteignable. Ces trois formes sont omniprésentes en JS réel.
cat > "$TMP/dead-strings.js" <<'EOF'
const dict = { fr: "Formation continue du personnel technique" };
function guard(x) {
  if (!x) return;
  work(x);
}
function oneline() { return 2; }
const after = 3;
let nodes = null; // [{ node, original }]
const tpl = `un { accolade } dans un template`;
EOF
OUT="$(bash eco-audit.sh "$TMP/dead-strings.js")"
echo "$OUT" | grep -q 'ECO-FRONT-05' && fail "code mort : faux positif (mot-clé dans une chaîne, garde sur une ligne, ou bloc refermé sur la ligne du return)"
true

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

# 17. ECO-FRONT-13 (script bloquant) : détecte l'absence d'async/defer,
# silencieux avec async ou type="module".
cat > "$TMP/blocking.html" <<'EOF'
<script src="app.js"></script>
<script src="tracker.js" async></script>
<script src="mod.js" type="module"></script>
EOF
OUT="$(bash eco-audit.sh "$TMP/blocking.html")"
# Ces 3 fichiers .js n'existent pas non plus sur disque : ECO-HEB-06 (liens
# cassés) les signale aussi, légitimement, pour une autre raison. On scope
# la vérification au bloc ECO-FRONT-13 pour ne pas confondre les deux.
FRONT13_BLOCK="$(echo "$OUT" | awk '/ECO-FRONT-13/{p=1} p&&/^$/{p=0} p')"
echo "$FRONT13_BLOCK" | grep -q 'app.js' || fail "script bloquant non détecté"
echo "$FRONT13_BLOCK" | grep -q 'tracker.js' && fail "faux positif : script async signalé comme bloquant"
echo "$FRONT13_BLOCK" | grep -q 'mod.js' && fail "faux positif : script type=module signalé comme bloquant"

# 18. ECO-UX-07 (prefers-reduced-motion) : détecte une animation sans la
# media query, silencieux si elle est présente ou s'il n'y a pas d'animation.
cat > "$TMP/animnoquery.css" <<'EOF'
.spin { animation: spin 2s linear infinite; }
EOF
cat > "$TMP/animwithquery.css" <<'EOF'
.spin { animation: spin 2s linear infinite; }
@media (prefers-reduced-motion: reduce) { .spin { animation: none; } }
EOF
OUT="$(bash eco-audit.sh "$TMP/animnoquery.css")"
echo "$OUT" | grep -q 'ECO-UX-07' || fail "animation sans prefers-reduced-motion non détectée"
OUT="$(bash eco-audit.sh "$TMP/animwithquery.css")"
echo "$OUT" | grep -q 'ECO-UX-07' && fail "faux positif : prefers-reduced-motion déjà présent"
true

# 19. ECO-HEB-04 (HTTP non sécurisé) : détecte http://, silencieux sur
# https://, localhost et les espaces de noms XML (w3.org).
cat > "$TMP/insecure.js" <<'EOF'
fetch('http://api.example.com/data');
EOF
cat > "$TMP/secure.js" <<'EOF'
fetch('https://api.example.com/data');
fetch('http://localhost:3000/api');
EOF
cat > "$TMP/svgns.html" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg"></svg>
EOF
OUT="$(bash eco-audit.sh "$TMP/insecure.js")"
echo "$OUT" | grep -q 'ECO-HEB-04' || fail "lien http:// non détecté"
OUT="$(bash eco-audit.sh "$TMP/secure.js")"
echo "$OUT" | grep -q 'ECO-HEB-04' && fail "faux positif sur https:// ou localhost"
OUT="$(bash eco-audit.sh "$TMP/svgns.html")"
echo "$OUT" | grep -q 'ECO-HEB-04' && fail "faux positif sur l'espace de noms SVG w3.org"
true

# 20. ECO-HEB-05 (TLS/SSL obsolète) : détecte TLSv1/1.1 et les méthodes
# legacy, silencieux sur TLSv1.2/1.3 (le piège du \b qui matche un préfixe).
cat > "$TMP/oldtls.js" <<'EOF'
const o = { secureProtocol: 'TLSv1_method' };
EOF
cat > "$TMP/newtls.js" <<'EOF'
const o = { minVersion: 'TLSv1.2' };
EOF
OUT="$(bash eco-audit.sh "$TMP/oldtls.js")"
echo "$OUT" | grep -q 'ECO-HEB-05' || fail "protocole TLS obsolète non détecté"
OUT="$(bash eco-audit.sh "$TMP/newtls.js")"
echo "$OUT" | grep -q 'ECO-HEB-05' && fail "faux positif : TLSv1.2 pris pour TLSv1 obsolète"
true

# 21. ECO-HEB-06 (liens locaux cassés) : détecte un fichier référencé
# absent, silencieux sur un fichier présent, une URL externe ou une ancre.
# Test volontairement lancé alors que le cwd (scripts/) diffère du
# répertoire du fichier audité ($TMP) : c'est exactement le cas qui avait
# fait échouer la première version du détecteur (FILENAME non fiable dans
# BEGIN, "dir" retombait sur "." qui n'était correct que par coïncidence).
mkdir -p "$TMP/assets"
echo "ok" > "$TMP/assets/real.css"
cat > "$TMP/links.html" <<'EOF'
<link rel="stylesheet" href="assets/real.css">
<link rel="stylesheet" href="assets/ghost.css">
<a href="https://example.com/external">externe</a>
<a href="#section">ancre</a>
EOF
OUT="$(bash eco-audit.sh "$TMP/links.html")"
echo "$OUT" | grep -q 'ghost.css' || fail "lien local cassé non détecté"
echo "$OUT" | grep -q 'real.css' && fail "faux positif sur un fichier local qui existe bien"
echo "$OUT" | grep -q 'external' && fail "faux positif sur une URL externe (non vérifiable sans réseau)"
true

# 22. Règles propres à un langage : un motif Python se déclenche sur du Python.
cat > "$TMP/n_plus_un.py" <<'EOF'
for a in Article.objects.filter(actif=True):
    print(a.auteur.nom)
EOF
OUT="$(bash eco-audit.sh "$TMP/n_plus_un.py")"
echo "$OUT" | grep -q 'ECO-PY-01' || fail "règle Python non appliquée à un fichier .py"

# 23. Et sur lui seul : les motifs Python parlent d'ORM Django, ils n'ont aucun
# sens sur du Ruby ou du Java, où `.all()` et `save()` désignent autre chose.
cat > "$TMP/modele.rb" <<'EOF'
Article.all.each { |a| puts a.auteur.nom }
EOF
OUT="$(bash eco-audit.sh "$TMP/modele.rb")"
echo "$OUT" | grep -q 'ECO-RB-01' || fail "règle Ruby non appliquée à un fichier .rb"
echo "$OUT" | grep -q 'ECO-PY-' && fail "fuite : une règle Python signalée sur un fichier Ruby"
true

# 24. Code déjà sobre dans un langage couvert : aucune règle de ce langage.
cat > "$TMP/propre.py" <<'EOF'
def liste(session, url):
    return session.get(url).json()
EOF
OUT="$(bash eco-audit.sh "$TMP/propre.py")"
echo "$OUT" | grep -q 'ECO-PY-' && fail "faux positif : code Python déjà sobre signalé"
true

# 25. Les langages sont annonçables et consultables sans auditer de fichier.
OUT="$(bash eco-audit.sh --list-langs)"
echo "$OUT" | grep -q 'Éco-conception Python' || fail "--list-langs ne liste pas les langages"
OUT="$(bash eco-audit.sh --list-rules python)"
echo "$OUT" | grep -q 'ECO-PY-01' || fail "--list-rules python ne sort pas la checklist du langage"

# 26. exclude_patterns : une ligne qui matche le motif mais applique déjà la
# bonne pratique n'est pas signalée (ECO-RB-06 : Rails.cache.fetch a besoin
# d'un expires_in, la version qui en a un est correcte).
cat > "$TMP/cache_ko.rb" <<'EOF'
Rails.cache.fetch("k") { calcul }
EOF
cat > "$TMP/cache_ok.rb" <<'EOF'
Rails.cache.fetch("k", expires_in: 5.minutes) { calcul }
EOF
OUT="$(bash eco-audit.sh "$TMP/cache_ko.rb")"
echo "$OUT" | grep -q 'ECO-RB-06' || fail "cache sans expiration non détecté"
OUT="$(bash eco-audit.sh "$TMP/cache_ok.rb")"
echo "$OUT" | grep -q 'ECO-RB-06' && fail "exclude_patterns ignoré : cache avec expires_in signalé à tort"
true

# 27. Prose et commentaires : un fichier qui *parle* d'un motif n'en contient
# pas pour autant. Vaut pour le texte des pages de balisage comme pour les
# commentaires de code, y compris quand ils citent du code désactivé.
cat > "$TMP/prose.html" <<'EOF'
<!-- On évite autoplay et SELECT * dans ce projet -->
<p>L'audit détecte SELECT *, les bibliothèques lourdes et l'autoplay.</p>
EOF
OUT="$(bash eco-audit.sh "$TMP/prose.html")"
echo "$OUT" | grep -q 'ECO-BACK-01' && fail "faux positif : SELECT * cité dans du texte HTML"
echo "$OUT" | grep -q 'ECO-UX-01' && fail "faux positif : autoplay cité dans du texte HTML"

cat > "$TMP/commente.py" <<'EOF'
# Ce module évite SELECT * et n'utilise plus Article.objects.all()
def liste(session, url):
    return session.get(url).json()
EOF
OUT="$(bash eco-audit.sh "$TMP/commente.py")"
echo "$OUT" | grep -q 'ECO-BACK-01' && fail "faux positif : SELECT * cité dans un commentaire Python"
echo "$OUT" | grep -q 'ECO-PY-02' && fail "faux positif : queryset cité dans un commentaire Python"
true

# 28. Le vrai code, lui, reste détecté : attribut autoplay et bloc <script>.
cat > "$TMP/media.html" <<'EOF'
<video autoplay src="promo.mp4"></video>
EOF
OUT="$(bash eco-audit.sh "$TMP/media.html")"
echo "$OUT" | grep -q 'ECO-UX-01' || fail "attribut autoplay réel non détecté"

# 29. Noms de frameworks : cherchés comme simples mots, « vue » signale tout
# texte français et « next » toute boucle. Il faut un import ou une dépendance.
cat > "$TMP/appli.jsx" <<'EOF'
import React from "react";
EOF
cat > "$TMP/vue-francaise.js" <<'EOF'
const total = items.length;
EOF
OUT="$(bash eco-audit.sh "$TMP/appli.jsx")"
echo "$OUT" | grep -q 'ECO-ARCH-01' || fail "import React réel non détecté"
OUT="$(bash eco-audit.sh "$TMP/vue-francaise.js")"
echo "$OUT" | grep -q 'ECO-ARCH-01' && fail "faux positif : framework signalé sans import ni dépendance"
true

# 30. Périmètre des détecteurs : les awk sont écrits pour un langage donné et
# ne doivent pas parler des autres. Sur un script shell, `esac` ressemble à du
# code mort et `VAR=` à une variable globale implicite.
cat > "$TMP/script.sh" <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(dirname "$0")"
case "$1" in
    a) echo un ;;
esac
EOF
OUT="$(bash eco-audit.sh "$TMP/script.sh")"
echo "$OUT" | grep -q 'ECO-FRONT-05' && fail "faux positif : détecteur de code mort JS lancé sur du shell"
echo "$OUT" | grep -q 'ECO-FRONT-06' && fail "faux positif : détecteur de globales JS lancé sur du shell"
true

# Et le détecteur reste actif là où il a un sens.
cat > "$TMP/reel.js" <<'EOF'
var fuite = 1;
function f() {
  return 1;
  console.log("mort");
}
EOF
OUT="$(bash eco-audit.sh "$TMP/reel.js")"
echo "$OUT" | grep -q 'ECO-FRONT-05' || fail "code mort JS non détecté après ajout du périmètre"
echo "$OUT" | grep -q 'ECO-FRONT-06' || fail "globale implicite JS non détectée après ajout du périmètre"

# exclude_file_patterns : le remède vit ailleurs dans le fichier que la ligne
# détectée. Un timer suspendu quand l'onglet est caché, un handler de scroll
# étalé sur requestAnimationFrame, des listeners détachés via AbortController
# appliquent déjà la recommandation — une exclusion ligne à ligne ne le voit pas.
cat > "$TMP/sobre.js" <<'EOF'
let timer = null;
function start() { timer = setInterval(tick, 1000); }
document.addEventListener('visibilitychange', () => {
  if (document.hidden) { clearInterval(timer); timer = null; } else { start(); }
});
window.addEventListener('scroll', () => {
  if (queued) return;
  queued = true;
  requestAnimationFrame(paint);
}, { passive: true });
EOF
OUT="$(bash eco-audit.sh "$TMP/sobre.js")"
echo "$OUT" | grep -q 'ECO-JS-03' && fail "polling : timer suspendu sur visibilitychange ne doit pas être signalé"
echo "$OUT" | grep -q 'ECO-JS-04' && fail "handler haute fréquence : scroll calé sur requestAnimationFrame ne doit pas être signalé"
true

cat > "$TMP/pas-sobre.js" <<'EOF'
setInterval(() => fetch('/api/status'), 1000);
window.addEventListener('scroll', () => { paint(window.scrollY); });
EOF
OUT="$(bash eco-audit.sh "$TMP/pas-sobre.js")"
echo "$OUT" | grep -q 'ECO-JS-03' || fail "polling : setInterval sans garde de visibilité doit rester signalé"
echo "$OUT" | grep -q 'ECO-JS-04' || fail "handler haute fréquence : scroll non throttlé doit rester signalé"

# ECO-BACK-02 cherchait "new.*Connection", qui matche la prose : un fichier de
# traductions contenant "400 new connections" était signalé comme ouvrant une
# connexion base de données sans pool.
cat > "$TMP/i18n.js" <<'EOF'
window.I18N = { en: { "400 branchements neufs": "400 new connections" } };
EOF
OUT="$(bash eco-audit.sh "$TMP/i18n.js")"
echo "$OUT" | grep -q 'ECO-BACK-02' && fail "pool de connexions : faux positif sur une chaîne de traduction"
true

cat > "$TMP/db.js" <<'EOF'
const conn = createConnection({ host: process.env.DB_HOST });
EOF
OUT="$(bash eco-audit.sh "$TMP/db.js")"
echo "$OUT" | grep -q 'ECO-BACK-02' || fail "pool de connexions : createConnection doit rester détecté"

# ECO-CONT-01 : une balise servant déjà WebP/AVIF, un srcset ou du lazy-loading
# n'est pas le problème visé. Les métadonnées sociales et les favicons non plus :
# les scrapers et les favicons ne lisent pas WebP, le JPG/PNG y est obligatoire.
cat > "$TMP/images-ok.html" <<'EOF'
<meta property="og:image" content="https://exemple.org/apercu.jpg">
<link rel="icon" href="favicon.png" type="image/png">
<picture><source type="image/webp" srcset="photo.webp"><img src="photo.jpg" loading="lazy" width="600" height="450" alt=""></picture>
EOF
OUT="$(bash eco-audit.sh "$TMP/images-ok.html")"
echo "$OUT" | grep -q 'ECO-CONT-01' && fail "images : faux positif sur WebP + fallback, og:image et favicon"
true


# 31. Empaquetage : les deux canaux qui attendent un zip (API Skills, upload
# Claude.ai) exigent un dossier unique à la racine, nommé comme le skill, et
# une description sous leur limite respective — 1024 et 200 caractères.
if command -v zip >/dev/null 2>&1; then
    DIST="$TMP/dist"
    bash package-skill.sh "$DIST" >/dev/null 2>&1 || fail "package-skill.sh a échoué"
    [ -f "$DIST/green-claude-api.zip" ] || fail "archive API absente"
    [ -f "$DIST/green-claude-claude-ai.zip" ] || fail "archive Claude.ai absente"

    RACINES=$(unzip -l "$DIST/green-claude-api.zip" | awk 'NR>3 && $4 != "" {split($4,a,"/"); print a[1]}' | sort -u | grep -v '^-' || true)
    [ "$RACINES" = "green-claude" ] || fail "l'archive doit contenir un seul dossier racine nommé green-claude (trouvé : $RACINES)"

    DESC=$(unzip -p "$DIST/green-claude-claude-ai.zip" green-claude/SKILL.md | awk -F'description: ' '/^description: /{print $2}')
    N=$(printf '%s' "$DESC" | wc -c | tr -d ' ')
    [ "$N" -le 200 ] || fail "description de la variante Claude.ai : $N caractères, limite 200"
    [ "$N" -gt 0 ] || fail "description absente de la variante Claude.ai"

    unzip -p "$DIST/green-claude-api.zip" green-claude/rules/langages/python.json >/dev/null 2>&1 \
        || fail "les règles par langage manquent dans l'archive"
fi

# Retour d'objet littéral : l'accolade fermante de `return { a: 1 };` ne
# referme aucun bloc, la suite reste donc bien du code mort. Chercher une
# fermante quelconque après le mot-clé ratait ce cas, pourtant l'une des
# formes de retour les plus courantes en JS.
cat > "$TMP/retour-objet.js" <<'EOF'
function f() {
  return { a: 1 };
  console.log("vraiment mort");
}
function g() {
  return { a: { b: 1 } };
  console.log("mort aussi");
}
EOF
OUT="$(bash eco-audit.sh "$TMP/retour-objet.js")"
echo "$OUT" | grep -q 'ECO-FRONT-05' || fail "code mort après un return d'objet littéral non détecté"

# Et l'inverse : un bloc réellement refermé sur la ligne du return ne laisse
# aucune place à du code inatteignable.
cat > "$TMP/retour-inline.js" <<'EOF'
function g() { return 2; }
const x = g();
console.log(x);
EOF
OUT="$(bash eco-audit.sh "$TMP/retour-inline.js")"
echo "$OUT" | grep -q 'ECO-FRONT-05' && fail "faux positif : bloc refermé sur la ligne du return"
true

# Toute règle dotée d'exclude_file_patterns doit porter une note : l'exclusion
# vaut pour le fichier entier, donc un silence n'est pas une absence de
# problème. Sans note, Claude relaie ce silence comme un verdict.
MANQUANTES=$(jq -s -r '[.[].categories[].rules[] | select(.exclude_file_patterns) | select((.note // "") == "") | .id] | join(", ")' ../rules/langages/*.json)
[ -z "$MANQUANTES" ] || fail "règles avec exclude_file_patterns sans note : $MANQUANTES"

# Exclusions par balise : elles portent sur la ligne, or deux balises voisines
# partagent souvent la leur. Une image déjà optimisée ne doit pas couvrir celle
# qui ne l'est pas, même collée à elle dans le source.
cat > "$TMP/voisines.html" <<'EOF'
<img src="photo.jpg"><img src="ok.webp">
EOF
OUT="$(bash eco-audit.sh "$TMP/voisines.html")"
echo "$OUT" | grep -q 'ECO-CONT-01' || fail "image non optimisée masquée par une image WebP voisine sur la même ligne"

# L'inverse tient toujours : une balise réellement conforme reste silencieuse.
cat > "$TMP/conforme.html" <<'EOF'
<img src="ok.webp" srcset="ok.webp 1x" loading="lazy">
EOF
OUT="$(bash eco-audit.sh "$TMP/conforme.html")"
echo "$OUT" | grep -q 'ECO-CONT-01' && fail "faux positif : image déjà servie en WebP avec srcset"
true

# @font-face écrit d'un seul tenant, ce que produit tout minifieur CSS : le
# parcours ligne à ligne consommait le reste de la ligne en entrant dans le
# bloc, et le fichier entier passait inaperçu.
python3 -c "
import os
for n in 'abc': open(os.path.join('$TMP', n + '.woff2'), 'wb').write(b'\\0' * 20000)
"
cat > "$TMP/minifie.css" <<'EOF'
@font-face { font-family: "A"; src: url("a.woff2"); }
@font-face { font-family: "B"; src: url("b.woff2"); }
@font-face { font-family: "C"; src: url("c.woff2"); }
EOF
OUT="$(bash eco-audit.sh "$TMP/minifie.css")"
echo "$OUT" | grep -q 'ECO-UX-05' || fail "trois familles sur une seule ligne : dépassement de seuil non détecté"

# Et sous le seuil, toujours rien à dire, quel que soit le formatage.
cat > "$TMP/deux-familles.css" <<'EOF'
@font-face { font-family: "A"; src: url("a.woff2"); }
@font-face { font-family: "B"; src: url("b.woff2"); }
EOF
OUT="$(bash eco-audit.sh "$TMP/deux-familles.css")"
echo "$OUT" | grep -q 'ECO-UX-05' && fail "faux positif : deux familles restent sous le seuil RGESN 4.8"
true

echo "OK - suite complete"
