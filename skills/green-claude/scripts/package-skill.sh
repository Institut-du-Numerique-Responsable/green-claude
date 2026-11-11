#!/bin/bash
# Fabrique l'archive installable du skill, pour les canaux qui attendent un zip
# plutôt qu'un dépôt git : l'API Skills et l'upload dans Claude.ai.
#
# Claude Code, lui, n'a besoin de rien de tout ça : le dépôt est un marketplace
# de plugins, installable par /plugin marketplace add.
#
# Usage : package-skill.sh [dossier-de-sortie]   (défaut : dist/)
#
# Les deux cibles n'ont pas les mêmes limites de description (1024 caractères
# pour l'API, 200 pour l'upload Claude.ai). Le dépôt garde la description
# longue, qui sert au déclenchement dans Claude Code ; l'archive Claude.ai
# reçoit une version courte, déclarée ici plutôt que tronquée au caractère près
# — une phrase coupée en plein milieu déclenche mal.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="${1:-$(cd "$SKILL_DIR/../.." && pwd)/dist}"

# L'API Skills et Claude.ai refusent un nom de skill contenant « claude » ou
# « anthropic » (mots réservés). Le plugin Claude Code garde green-claude ; les
# archives portent ce nom-ci, dans le champ name comme pour le dossier racine.
NOM_ARCHIVE="green-coding"

DESCRIPTION_COURTE="Eco-design rules (RGESN 2024, GR491) applied while writing or reviewing code, plus a deterministic sobriety audit. Ask for an \"eco-design audit\" or \"audit éco-conception\"."

command -v zip >/dev/null 2>&1 || { echo "zip est requis." >&2; exit 1; }

mkdir -p "$OUT_DIR"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

# Le dossier à la racine de l'archive doit porter le nom du skill : c'est ce
# que vérifient l'API comme l'upload Claude.ai.
cp -r "$SKILL_DIR" "$BUILD/$NOM_ARCHIVE"
rm -rf "$BUILD/$NOM_ARCHIVE/scripts/test-eco-audit.sh" "$BUILD/$NOM_ARCHIVE/scripts/package-skill.sh"
# Résidus macOS et éditeurs : inutiles à l'exécution, mais embarqués dans
# l'archive téléchargée par chaque utilisateur si on ne les retire pas ici.
find "$BUILD/$NOM_ARCHIVE" \( -name '.DS_Store' -o -name 'Thumbs.db' -o -name '*~' \) -delete

# Renomme le skill dans SKILL.md. Les chemins de repli « skills/green-claude »
# suivent, pour que la recherche du dossier du skill trouve le dossier renommé.
python3 - "$BUILD/$NOM_ARCHIVE/SKILL.md" "$NOM_ARCHIVE" <<'PY'
import re, sys, pathlib
chemin, nom = pathlib.Path(sys.argv[1]), sys.argv[2]
texte = chemin.read_text()
texte, n = re.subn(r"^name: .*$", f"name: {nom}", texte, count=1, flags=re.M)
if n != 1:
    sys.exit("champ name introuvable dans SKILL.md")
texte = texte.replace("skills/green-claude", f"skills/{nom}")
chemin.write_text(texte)
PY

verifie_nom() { # $1 = fichier SKILL.md
    local nom
    nom=$(awk -F': ' '/^name: /{print $2; exit}' "$1")
    if ! printf '%s' "$nom" | grep -Eq '^[a-z0-9-]{1,64}$'; then
        echo "  nom « $nom » : minuscules, chiffres et tirets, 64 caractères au plus" >&2
        return 1
    fi
    if printf '%s' "$nom" | grep -Eq 'claude|anthropic'; then
        echo "  nom « $nom » : contient un mot réservé (claude, anthropic)" >&2
        return 1
    fi
    echo "  nom : $nom"
}

verifie_limites() { # $1 = fichier SKILL.md, $2 = limite de description
    local fichier="$1" limite="$2" desc n
    desc=$(awk '/^description: \|/{flag=1; next} /^[a-z_-]+:/{flag=0} flag' "$fichier" \
           || true)
    [ -n "$desc" ] || desc=$(awk -F'description: ' '/^description: /{print $2}' "$fichier")
    n=$(printf '%s' "$desc" | tr -d '\n ' | wc -c | tr -d ' ')
    if [ "$n" -gt "$limite" ]; then
        echo "  description : $n caractères, au-delà de la limite de $limite" >&2
        return 1
    fi
    echo "  description : $n caractères (limite $limite)"
}

echo "Archive API Skills (limite de description : 1024)"
verifie_nom "$BUILD/$NOM_ARCHIVE/SKILL.md"
verifie_limites "$BUILD/$NOM_ARCHIVE/SKILL.md" 1024
rm -f "$OUT_DIR/green-claude-api.zip"
(cd "$BUILD" && zip -qr "$OUT_DIR/green-claude-api.zip" "$NOM_ARCHIVE")
echo "  -> $OUT_DIR/green-claude-api.zip"

# Variante Claude.ai : même contenu, description courte.
python3 - "$BUILD/$NOM_ARCHIVE/SKILL.md" "$DESCRIPTION_COURTE" <<'PY'
import re, sys, pathlib
chemin, courte = pathlib.Path(sys.argv[1]), sys.argv[2]
texte = chemin.read_text()
texte = re.sub(r"^description: \|\n(?:  .*\n)+", f"description: {courte}\n", texte, count=1, flags=re.M)
chemin.write_text(texte)
PY

echo "Archive Claude.ai (limite de description : 200)"
verifie_nom "$BUILD/$NOM_ARCHIVE/SKILL.md"
verifie_limites "$BUILD/$NOM_ARCHIVE/SKILL.md" 200
rm -f "$OUT_DIR/green-claude-claude-ai.zip"
(cd "$BUILD" && zip -qr "$OUT_DIR/green-claude-claude-ai.zip" "$NOM_ARCHIVE")
echo "  -> $OUT_DIR/green-claude-claude-ai.zip"
