#!/bin/bash
# Audit éco-conception déterministe : grep les patterns de rules/ecoconception.json
# sur les fichiers passés en argument. Zéro appel modèle — sortie brute pour Claude.
#
# Usage : eco-audit.sh <fichier> [fichier...]
#         eco-audit.sh --list-rules          (checklist des règles sans pattern grep-able)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_FILE="$SCRIPT_DIR/../rules/ecoconception.json"
BORIS_FILE="$SCRIPT_DIR/../rules/boris.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "jq est requis pour l'audit avancé (brew install jq / apt install jq)." >&2
    exit 1
fi

if [ "${1:-}" = "--list-rules" ]; then
    echo "=== Règles de démarche (sans pattern détectable — RGESN/GR491) ==="
    jq -r '
        [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
        | .[]
        | select(((.patterns // []) | length == 0) and ((.detector // "") == ""))
        | "[\(.impact)] \(.id) — \(.title)\n  \(.recommendation)\n"' "$RULES_FILE"
    echo "=== Pratiques d'usage Boris Cherny (contexte, brief, mémoire, vérification, compute) ==="
    jq -r '
        [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
        | .[]
        | "[\(.impact)] \(.id) — \(.title)\n  \(.how)\n"' "$BORIS_FILE"
    exit 0
fi

if [ $# -eq 0 ]; then
    echo "Usage : eco-audit.sh <fichier> [fichier...]" >&2
    echo "        eco-audit.sh --list-rules" >&2
    exit 1
fi

issues_found=0

# Une ligne JSON compacte par règle (jq -c) : pas de délimiteur maison à
# échapper (l'ancien découpage TSV cassait les patterns contenant des
# backslashes, ex. \., \(, \b), chaque champ est relu depuis la ligne.
while IFS= read -r rule_json; do
    id=$(jq -r '.id' <<<"$rule_json")
    category=$(jq -r '.category' <<<"$rule_json")
    title=$(jq -r '.title' <<<"$rule_json")
    impact=$(jq -r '.impact' <<<"$rule_json")
    patterns=$(jq -r '.patterns | join("|")' <<<"$rule_json")
    detector=$(jq -r '.detector // ""' <<<"$rule_json")
    enrich=$(jq -r '.enrich // ""' <<<"$rule_json")
    recommendation=$(jq -r '.recommendation' <<<"$rule_json")
    rgesn_ref=$(jq -r '.rgesn_ref' <<<"$rule_json")

    for file in "$@"; do
        [ -f "$file" ] || continue
        matches=""
        if [ -n "$detector" ]; then
            # Détecteur dédié multi-lignes (grep ligne-par-ligne ne sait pas
            # voir une imbrication répartie sur plusieurs lignes).
            detector_script="$SCRIPT_DIR/detect-$(echo "$detector" | tr '_' '-').awk"
            [ -f "$detector_script" ] || continue
            matches=$(awk -f "$detector_script" "$file" 2>/dev/null || true)
        elif [ -n "$patterns" ]; then
            matches=$(grep -qiE "$patterns" "$file" 2>/dev/null && echo "match" || true)
        fi
        if [ -n "$matches" ]; then
            echo "[$impact] $id — $title"
            echo "  Fichier        : $file"
            if [ "$matches" != "match" ]; then
                echo "$matches" | head -5 | sed 's/^/  Ligne          : /'
            fi
            if [ -n "$enrich" ]; then
                # Best-effort : inspecte les fichiers réels référencés (image,
                # etc.) quand c'est possible. Un pattern seul ne peut pas dire
                # si une image est déjà compressée ou correctement dimensionnée
                # — ceci ajoute l'info réelle quand le fichier est résolvable
                # sur disque, sans rien affirmer quand il ne l'est pas (URL
                # distante, chemin construit dynamiquement...).
                enrich_script="$SCRIPT_DIR/inspect-$(echo "$enrich" | tr '_' '-').sh"
                if [ -f "$enrich_script" ]; then
                    enrich_out=$(bash "$enrich_script" "$file" 2>/dev/null || true)
                    [ -n "$enrich_out" ] && echo "$enrich_out" | sed 's/^/  Image          : /'
                fi
            fi
            echo "  Catégorie      : $category"
            echo "  RGESN          : $rgesn_ref"
            echo "  Recommandation : $recommendation"
            echo ""
            issues_found=$((issues_found + 1))
        fi
    done
done < <(jq -c '
    [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
    | .[]
    | select(((.patterns // []) | length > 0) or ((.detector // "") != ""))' "$RULES_FILE")

if [ "$issues_found" -eq 0 ]; then
    echo "Aucune issue d'éco-conception détectée sur les fichiers analysés."
else
    echo "$issues_found issue(s) d'éco-conception détectée(s)."
fi
