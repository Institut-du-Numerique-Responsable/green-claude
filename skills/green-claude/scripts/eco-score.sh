#!/bin/bash
# Densité d'issues d'éco-conception d'un dépôt, pour suivre l'évolution dans le
# temps plutôt que de constater un chiffre isolé.
#
# Ce que ce score est : un compte de motifs détectables, pondéré par impact et
# rapporté au volume de code. Ce qu'il n'est pas : une mesure d'énergie. Un
# score qui baisse dit que le code contient moins de motifs connus, pas qu'il
# consomme moins. Pour ça, il faut mesurer l'exécution réelle (requêtes SQL,
# octets transférés, temps CPU, EcoIndex sur une page).
#
# Usage : eco-score.sh [chemin...]        (défaut : dépôt courant)
#         eco-score.sh --json [chemin...] (une ligne JSON, pour l'historiser)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT="$SCRIPT_DIR/eco-audit.sh"

FORMAT="texte"
if [ "${1:-}" = "--json" ]; then FORMAT="json"; shift; fi

# Extensions auditables : celles que les règles savent lire. Inutile de compter
# les Markdown et les JSON dans le volume, aucune règle ne s'y applique.
EXTS='\.(py|js|jsx|ts|tsx|mjs|cjs|sql|pks|pkb|prc|fnc|trg|java|cs|php|rb|rs|c|h|cpp|cc|cxx|hpp|hh|go|kt|swift|scala|html|htm|css|scss|sass|vue|svelte)$'

collect_files() {
    if [ $# -eq 0 ]; then
        # Dans un dépôt git : les fichiers suivis, donc ni node_modules ni
        # artefacts de build, sans avoir à maintenir une liste d'exclusions.
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            git ls-files | grep -iE "$EXTS" || true
        else
            find . -type f | grep -iE "$EXTS" || true
        fi
    else
        for path in "$@"; do
            if [ -d "$path" ]; then
                find "$path" -type f | grep -iE "$EXTS" || true
            elif [ -f "$path" ]; then
                printf '%s\n' "$path" | grep -iE "$EXTS" || true
            fi
        done
    fi
}

FILES="$(collect_files "$@")"
if [ -z "$FILES" ]; then
    echo "Aucun fichier auditable trouvé." >&2
    exit 1
fi

nb_files=$(printf '%s\n' "$FILES" | wc -l | tr -d ' ')
nb_lines=$(printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 cat 2>/dev/null | wc -l | tr -d ' ')

REPORT="$(printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 bash "$AUDIT" 2>/dev/null || true)"
eleve=$(printf '%s\n' "$REPORT" | grep -c '^\[Élevé\]' || true)
moyen=$(printf '%s\n' "$REPORT" | grep -c '^\[Moyen\]' || true)
faible=$(printf '%s\n' "$REPORT" | grep -c '^\[Faible\]' || true)

# Pondération : un défaut à impact élevé pèse trois fois un défaut faible. Les
# poids sont arbitraires et assumés comme tels ; ce qui compte est de garder
# les mêmes d'une mesure à l'autre pour que la comparaison ait un sens.
poids=$(( eleve * 3 + moyen * 2 + faible ))
if [ "$nb_lines" -gt 0 ]; then
    densite=$(LC_ALL=C awk -v p="$poids" -v l="$nb_lines" 'BEGIN { printf "%.2f", p * 1000 / l }')
else
    densite="0.00"
fi

if [ "$FORMAT" = "json" ]; then
    printf '{"date":"%s","fichiers":%d,"lignes":%d,"eleve":%d,"moyen":%d,"faible":%d,"poids":%d,"densite_pour_1000_lignes":%s}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$nb_files" "$nb_lines" "$eleve" "$moyen" "$faible" "$poids" "$densite"
    exit 0
fi

echo "Score d'éco-conception"
echo "  Fichiers audités : $nb_files ($nb_lines lignes)"
echo "  Impact Élevé     : $eleve"
echo "  Impact Moyen     : $moyen"
echo "  Impact Faible    : $faible"
echo "  Poids total      : $poids (Élevé×3 + Moyen×2 + Faible×1)"
echo "  Densité          : $densite pour 1000 lignes"
echo ""
echo "Comparez cette densité à celle d'hier, pas à zéro : c'est la tendance qui"
echo "renseigne. Et confrontez-la à une mesure d'exécution réelle (requêtes,"
echo "octets transférés, EcoIndex), seule capable de dire si la consommation baisse."
