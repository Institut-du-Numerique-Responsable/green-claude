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

DESCRIPTION_COURTE="Eco-design rules (RGESN 2024, GR491) applied while writing or reviewing code, plus a deterministic sobriety audit. Ask for an \"eco-design audit\" or \"audit éco-conception\"."

command -v zip >/dev/null 2>&1 || { echo "zip est requis." >&2; exit 1; }

mkdir -p "$OUT_DIR"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

# Le dossier à la racine de l'archive doit porter le nom du skill : c'est ce
# que vérifient l'API comme l'upload Claude.ai.
cp -r "$SKILL_DIR" "$BUILD/green-claude"
rm -rf "$BUILD/green-claude/scripts/test-eco-audit.sh" "$BUILD/green-claude/scripts/package-skill.sh"

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
verifie_limites "$BUILD/green-claude/SKILL.md" 1024
(cd "$BUILD" && zip -qr "$OUT_DIR/green-claude-api.zip" green-claude)
echo "  -> $OUT_DIR/green-claude-api.zip"

# Variante Claude.ai : même contenu, description courte.
python3 - "$BUILD/green-claude/SKILL.md" "$DESCRIPTION_COURTE" <<'PY'
import re, sys, pathlib
chemin, courte = pathlib.Path(sys.argv[1]), sys.argv[2]
texte = chemin.read_text()
texte = re.sub(r"^description: \|\n(?:  .*\n)+", f"description: {courte}\n", texte, count=1, flags=re.M)
chemin.write_text(texte)
PY

echo "Archive Claude.ai (limite de description : 200)"
verifie_limites "$BUILD/green-claude/SKILL.md" 200
(cd "$BUILD" && zip -qr "$OUT_DIR/green-claude-claude-ai.zip" green-claude)
echo "  -> $OUT_DIR/green-claude-claude-ai.zip"
