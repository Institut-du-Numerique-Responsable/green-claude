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
LANG_DIR="$SCRIPT_DIR/../rules/langages"

# Fichier de règles du langage correspondant à une extension, vide si non couvert.
lang_file_for_ext() {
    local ext lang
    ext="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$ext" in
        py)                      lang="python" ;;
        js|jsx|ts|tsx|mjs|cjs)   lang="javascript" ;;
        sql|pks|pkb|prc|fnc|trg) lang="sql" ;;
        java)                    lang="java" ;;
        cs)                      lang="csharp" ;;
        php)                     lang="php" ;;
        rb)                      lang="ruby" ;;
        rs)                      lang="rust" ;;
        c|h)                     lang="c" ;;
        cpp|cc|cxx|hpp|hh)       lang="cpp" ;;
        *)                       return 0 ;;
    esac
    [ -f "$LANG_DIR/$lang.json" ] && printf '%s' "$LANG_DIR/$lang.json"
}

if ! command -v jq >/dev/null 2>&1; then
    echo "jq est requis pour l'audit avancé (brew install jq / apt install jq)." >&2
    exit 1
fi

if [ "${1:-}" = "--list-langs" ]; then
    echo "=== Langages couverts par rules/langages/ ==="
    for lang_json in "$LANG_DIR"/*.json; do
        [ -f "$lang_json" ] || continue
        jq -r '"\(.metadata.name)\n  globs  : \(.metadata.globs)\n  règles : \(.metadata.count)\n"' "$lang_json"
    done
    exit 0
fi

if [ "${1:-}" = "--list-rules" ] && [ -n "${2:-}" ]; then
    # Checklist d'un seul langage : toutes ses règles, pattern ou non.
    lang_json="$LANG_DIR/$2.json"
    [ -f "$lang_json" ] || { echo "Langage inconnu : $2 (voir --list-langs)." >&2; exit 1; }
    jq -r '"=== \(.metadata.name) (\(.metadata.globs)) ==="' "$lang_json"
    jq -r '
        [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
        | .[]
        | "[\(.impact)] \(.id) — \(.title)\n  \(.recommendation)\n"' "$lang_json"
    exit 0
fi

if [ "${1:-}" = "--list-rules" ]; then
    echo "=== Règles de démarche (sans pattern détectable — RGESN/GR491) ==="
    jq -r '
        [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
        | .[]
        | select(((.patterns // []) | length == 0) and ((.detector // "") == ""))
        | "[\(.impact)] \(.id) — \(.title)\n  \(.recommendation)\n"' "$RULES_FILE"
    echo "=== Règles langage sans pattern détectable (rules/langages/) ==="
    for lang_json in "$LANG_DIR"/*.json; do
        [ -f "$lang_json" ] || continue
        jq -r '
            .metadata.name as $lang
            | [.categories[] as $c | $c.rules[]]
            | .[]
            | select((.patterns // []) | length == 0)
            | "[\(.impact)] \(.id) — \(.title) (\($lang))\n  \(.recommendation)\n"' "$lang_json"
    done
    echo "=== Pratiques d'usage Boris Cherny (contexte, brief, mémoire, vérification, compute) ==="
    jq -r '
        [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
        | .[]
        | "[\(.impact)] \(.id) — \(.title)\n  \(.how)\n"' "$BORIS_FILE"
    echo "Checklist d'un langage précis : eco-audit.sh --list-rules <langage> (voir --list-langs)."
    exit 0
fi

if [ $# -eq 0 ]; then
    echo "Usage : eco-audit.sh <fichier> [fichier...]" >&2
    echo "        eco-audit.sh --list-rules [langage]" >&2
    echo "        eco-audit.sh --list-langs" >&2
    exit 1
fi

issues_found=0

# Règles propres aux langages réellement présents parmi les fichiers audités :
# inutile de charger les dix fichiers pour auditer un seul script Python. Chaque
# règle porte alors la liste des extensions auxquelles elle s'applique, et n'est
# testée que sur ces fichiers — un motif Python signalerait n'importe quoi sur un
# fichier Java (`.all()`, `save()`, `+=` existent partout).
lang_rules="$(mktemp)"
trap 'rm -f "$lang_rules"' EXIT
for arg in "$@"; do
    [ -f "$arg" ] || continue
    lang_json="$(lang_file_for_ext "${arg##*.}")" || true
    [ -n "$lang_json" ] || continue
    grep -q "^$lang_json\$" "$lang_rules.seen" 2>/dev/null && continue
    echo "$lang_json" >> "$lang_rules.seen"
    jq -c '
        .metadata.extensions as $exts
        | [.categories[] as $c | $c.rules[] | . + {category: $c.name, exts: $exts}]
        | .[]
        | select((.patterns // []) | length > 0)' "$lang_json" >> "$lang_rules"
done
trap 'rm -f "$lang_rules" "$lang_rules.seen"' EXIT

# Une ligne JSON compacte par règle (jq -c) : pas de délimiteur maison à
# échapper (l'ancien découpage TSV cassait les patterns contenant des
# backslashes, ex. \., \(, \b), chaque champ est relu depuis la ligne.
while IFS= read -r rule_json; do
    id=$(jq -r '.id' <<<"$rule_json")
    category=$(jq -r '.category' <<<"$rule_json")
    title=$(jq -r '.title' <<<"$rule_json")
    impact=$(jq -r '.impact' <<<"$rule_json")
    patterns=$(jq -r '.patterns | join("|")' <<<"$rule_json")
    # exclude_patterns (facultatif) : lignes qui matchent le motif tout en
    # appliquant déjà la bonne pratique. La règle ne se déclenche que s'il reste
    # une ligne non exclue — Rails.cache.fetch pose problème sans expires_in,
    # pas avec.
    excludes=$(jq -r '(.exclude_patterns // []) | join("|")' <<<"$rule_json")
    detector=$(jq -r '.detector // ""' <<<"$rule_json")
    enrich=$(jq -r '.enrich // ""' <<<"$rule_json")
    recommendation=$(jq -r '.recommendation' <<<"$rule_json")
    rgesn_ref=$(jq -r '.rgesn_ref' <<<"$rule_json")
    note=$(jq -r '.note // .detector_note // .enrich_note // ""' <<<"$rule_json")

    exts=$(jq -r '(.exts // []) | join(" ")' <<<"$rule_json")

    for file in "$@"; do
        [ -f "$file" ] || continue
        # Règle propre à un langage : ne s'applique qu'aux fichiers de ce langage.
        if [ -n "$exts" ]; then
            file_ext="$(printf '%s' "${file##*.}" | tr '[:upper:]' '[:lower:]')"
            case " $exts " in
                *" $file_ext "*) ;;
                *) continue ;;
            esac
        fi
        matches=""
        if [ -n "$detector" ]; then
            # Détecteur dédié multi-lignes (grep ligne-par-ligne ne sait pas
            # voir une imbrication répartie sur plusieurs lignes).
            detector_script="$SCRIPT_DIR/detect-$(echo "$detector" | tr '_' '-').awk"
            [ -f "$detector_script" ] || continue
            matches=$(awk -f "$detector_script" "$file" 2>/dev/null || true)
        elif [ -n "$patterns" ] && [ -n "$excludes" ]; then
            matches=$(grep -iE "$patterns" "$file" 2>/dev/null | grep -qvE "$excludes" && echo "match" || true)
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
                    [ -n "$enrich_out" ] && echo "$enrich_out" | sed 's/^/  Détail         : /'
                fi
            fi
            echo "  Catégorie      : $category"
            echo "  RGESN          : $rgesn_ref"
            echo "  Recommandation : $recommendation"
            # Candidat, pas preuve : un hit ici est ce que le pattern/détecteur
            # peut voir, pas un verdict. Cette mise en garde vit dans la règle
            # elle-même (note/detector_note/enrich_note du JSON) plutôt que
            # dans une liste séparée que Claude devrait se rappeler par cœur.
            [ -n "$note" ] && echo "  Note           : $note"
            echo ""
            issues_found=$((issues_found + 1))
        fi
    done
done < <(jq -c '
    [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
    | .[]
    | select(((.patterns // []) | length > 0) or ((.detector // "") != ""))' "$RULES_FILE"
    cat "$lang_rules")

if [ "$issues_found" -eq 0 ]; then
    echo "Aucune issue d'éco-conception détectée sur les fichiers analysés."
else
    echo "$issues_found issue(s) d'éco-conception détectée(s)."
fi
