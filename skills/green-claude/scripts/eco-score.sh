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

source "$SCRIPT_DIR/audit-common.sh"
load_audit_extensions

collect_files() {
    if [ $# -eq 0 ]; then
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            git ls-files -z
        else
            find . -type f -print0
        fi
    else
        for path in "$@"; do
            if [ -d "$path" ]; then
                find "$path" -type f -print0
            elif [ -f "$path" ]; then
                printf '%s\0' "$path"
            fi
        done
    fi
}

FILES=()
while IFS= read -r -d '' file; do
    is_auditable_file "$file" || continue
    FILES[${#FILES[@]}]="$file"
done < <(collect_files "$@")
if [ "${#FILES[@]}" -eq 0 ]; then
    echo "Aucun fichier auditable trouvé." >&2
    exit 1
fi

nb_files=${#FILES[@]}
nb_lines=$(printf '%s\0' "${FILES[@]}" | xargs -0 cat -- | wc -l | tr -d ' ')

# An unavailable audit is not a zero-issue result. Preserve stderr and fail
# before emitting any score, including when xargs splits a large file list.
REPORT="$(printf '%s\0' "${FILES[@]}" | xargs -0 bash "$AUDIT")" || {
    echo "Green Claude: audit failed; no score produced." >&2
    exit 1
}
eleve=$(printf '%s\n' "$REPORT" | grep -c '^\[High\]' || true)
moyen=$(printf '%s\n' "$REPORT" | grep -c '^\[Medium\]' || true)
faible=$(printf '%s\n' "$REPORT" | grep -c '^\[Low\]' || true)

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

echo "Ecodesign score"
echo "  Files audited    : $nb_files ($nb_lines lines)"
echo "  High impact      : $eleve"
echo "  Medium impact    : $moyen"
echo "  Low impact       : $faible"
echo "  Weighted total   : $poids (High x3 + Medium x2 + Low x1)"
echo "  Density          : $densite per 1000 lines"
echo ""
echo "Comparez cette densité à celle d'hier, pas à zéro : c'est la tendance qui"
echo "renseigne. Et confrontez-la à une mesure d'exécution réelle (requêtes,"
echo "octets transférés, EcoIndex), seule capable de dire si la consommation baisse."
