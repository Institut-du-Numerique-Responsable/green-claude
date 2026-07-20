#!/bin/bash
# Audit éco-conception déterministe : grep les patterns de rules/ecoconception.json
# sur les fichiers passés en argument. Zéro appel modèle — sortie brute pour Claude.
#
# Usage : eco-audit.sh <fichier> [fichier...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_FILE="$SCRIPT_DIR/../rules/ecoconception.json"

if [ $# -eq 0 ]; then
    echo "Usage : eco-audit.sh <fichier> [fichier...]" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq est requis pour l'audit avancé (brew install jq / apt install jq)." >&2
    exit 1
fi

issues_found=0

while IFS=$'\t' read -r id category title impact patterns recommendation rgesn_ref; do
    for file in "$@"; do
        [ -f "$file" ] || continue
        if grep -qE "$patterns" "$file" 2>/dev/null; then
            echo "[$impact] $id — $title"
            echo "  Fichier        : $file"
            echo "  Catégorie      : $category"
            echo "  RGESN          : $rgesn_ref"
            echo "  Recommandation : $recommendation"
            echo ""
            issues_found=$((issues_found + 1))
        fi
    done
done < <(jq -r '
    [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
    | .[]
    | select((.patterns // []) | length > 0)
    | [.id, .category, .title, .impact, (.patterns | join("|")), .recommendation, .rgesn_ref]
    | @tsv' "$RULES_FILE")

if [ "$issues_found" -eq 0 ]; then
    echo "Aucune issue d'éco-conception détectée sur les fichiers analysés."
else
    echo "$issues_found issue(s) d'éco-conception détectée(s)."
fi
