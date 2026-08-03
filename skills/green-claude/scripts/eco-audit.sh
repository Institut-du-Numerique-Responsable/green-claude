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

# Le texte rédigé n'est pas du code. Un fichier qui *parle* d'autoplay ou de
# SELECT * n'en contient pas pour autant, et le signaler use la crédibilité de
# l'audit. On retire donc, avant de chercher les motifs :
#   - le texte des pages de balisage, en ne gardant que l'intérieur des balises
#     (donc les attributs) et les blocs <script>/<style>, qui sont bien du code ;
#   - les commentaires, prose ou code désactivé. Du code commenté ne s'exécute
#     pas, donc ne consomme rien.
# Les détecteurs awk, eux, travaillent sur le fichier d'origine : ils ont besoin
# des numéros de ligne réels et de la structure complète des blocs.
clean_source() {
    local file="$1" ext line_comment="" block=0
    ext="$(printf '%s' "${1##*.}" | tr '[:upper:]' '[:lower:]')"

    case "$ext" in
        py|rb|sh|bash)                          line_comment='^[[:space:]]*#' ;;
        sql|pks|pkb|prc|fnc|trg)                line_comment='^[[:space:]]*--' ;;
        js|jsx|ts|tsx|mjs|cjs|java|cs|php|rs|go|kt|swift|scala|c|h|cpp|cc|cxx|hpp|hh)
                                                line_comment='^[[:space:]]*//'; block=1 ;;
        css|scss|sass)                          block=1 ;;
    esac

    case "$ext" in
        html|htm|vue|svelte) strip_markup_text "$file" ;;
        *)                   cat "$file" ;;
    esac | awk -v lc="$line_comment" -v block="$block" '
        block && inblock {
            if ($0 ~ /\*\//) { sub(/^.*\*\//, ""); inblock = 0 } else { next }
        }
        block {
            while (match($0, /\/\*.*\*\//)) {
                $0 = substr($0, 1, RSTART - 1) " " substr($0, RSTART + RLENGTH)
            }
            if (match($0, /\/\*/)) { $0 = substr($0, 1, RSTART - 1); inblock = 1 }
        }
        lc != "" && $0 ~ lc { next }
        { print }'
}

# Contenu textuel des pages de balisage : seuls l'intérieur des balises et les
# blocs <script>/<style> sont conservés. Les commentaires HTML disparaissent
# avec le reste du texte.
strip_markup_text() {
    awk '
    {
        line = $0
        low = tolower(line)
        if (!raw && low ~ /<(script|style)[ >]/) {
            print line
            if (low !~ /<\/(script|style)>/) raw = 1
            next
        }
        if (raw) {
            print line
            if (low ~ /<\/(script|style)>/) raw = 0
            next
        }
        if (incomment) {
            if (match(line, /-->/)) { line = substr(line, RSTART + 3); incomment = 0 }
            else next
        }
        while (match(line, /<!--.*-->/)) {
            line = substr(line, 1, RSTART - 1) " " substr(line, RSTART + RLENGTH)
        }
        if (match(line, /<!--/)) { line = substr(line, 1, RSTART - 1); incomment = 1 }
        out = ""
        n = length(line)
        for (i = 1; i <= n; i++) {
            c = substr(line, i, 1)
            if (c == "<") intag = 1
            if (intag) out = out c
            if (c == ">") { intag = 0; out = out " " }
        }
        print out
    }' "$1"
}

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

# Version nettoyée de chaque fichier, calculée une fois pour toutes plutôt qu'à
# chaque règle. Pas de tableau associatif pour la retrouver : bash 3.2, livré
# avec macOS, ne les connaît pas.
CLEAN_DIR="$(mktemp -d)"
cleaned_name() { printf '%s' "$1" | tr '/ ' '__'; }
for arg in "$@"; do
    [ -f "$arg" ] || continue
    clean_source "$arg" > "$CLEAN_DIR/$(cleaned_name "$arg")"
done

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
trap 'rm -rf "$lang_rules" "$lang_rules.seen" "$CLEAN_DIR"' EXIT

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
    # exclude_file_patterns (facultatif) : le remède ne vit pas sur la ligne
    # détectée mais ailleurs dans le fichier. Un setInterval suspendu par un
    # visibilitychange trente lignes plus bas applique déjà la recommandation,
    # et une exclusion ligne à ligne ne peut pas le voir.
    file_excludes=$(jq -r '(.exclude_file_patterns // []) | join("|")' <<<"$rule_json")
    detector=$(jq -r '.detector // ""' <<<"$rule_json")
    enrich=$(jq -r '.enrich // ""' <<<"$rule_json")
    recommendation=$(jq -r '.recommendation' <<<"$rule_json")
    rgesn_ref=$(jq -r '.rgesn_ref' <<<"$rule_json")
    note=$(jq -r '.note // .detector_note // .enrich_note // ""' <<<"$rule_json")

    # `exts` vient des règles de langage (rules/langages/), `extensions` du
    # périmètre déclaré par une règle transverse — un détecteur écrit pour du
    # JavaScript n'a rien à dire sur un script shell, où `esac` ressemble à du
    # code mort et `VAR=` à une globale implicite.
    exts=$(jq -r '((.exts // []) + (.extensions // [])) | join(" ")' <<<"$rule_json")

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
        # Si l'un des motifs d'exclusion fichier apparaît quelque part dans le
        # fichier, la règle se tait : la bonne pratique y est déjà appliquée.
        if [ -n "$file_excludes" ]; then
            fscan="$CLEAN_DIR/$(cleaned_name "$file")"
            [ -f "$fscan" ] || fscan="$file"
            grep -qiE "$file_excludes" "$fscan" 2>/dev/null && continue
        fi
        matches=""
        if [ -n "$detector" ]; then
            # Détecteur dédié multi-lignes (grep ligne-par-ligne ne sait pas
            # voir une imbrication répartie sur plusieurs lignes).
            detector_script="$SCRIPT_DIR/detect-$(echo "$detector" | tr '_' '-').awk"
            [ -f "$detector_script" ] || continue
            matches=$(awk -f "$detector_script" "$file" 2>/dev/null || true)
        elif [ -n "$patterns" ]; then
            # Motifs cherchés sur la version nettoyée (sans prose ni commentaires).
            scanned="$CLEAN_DIR/$(cleaned_name "$file")"
            [ -f "$scanned" ] || scanned="$file"
            if [ -n "$excludes" ]; then
                matches=$(grep -iE "$patterns" "$scanned" 2>/dev/null | grep -qvE "$excludes" && echo "match" || true)
            else
                matches=$(grep -qiE "$patterns" "$scanned" 2>/dev/null && echo "match" || true)
            fi
        fi
        # Enrichissement calculé avant l'affichage : certaines règles n'ont de
        # verdict que par la mesure.
        enrich_out=""
        if [ -n "$matches" ] && [ -n "$enrich" ]; then
            # Best-effort : inspecte les fichiers réels référencés (image,
            # police...) quand c'est possible. Un pattern seul ne peut pas dire
            # si une image est déjà compressée ou correctement dimensionnée — on
            # ajoute l'info réelle quand le fichier est résolvable sur disque,
            # sans rien affirmer quand il ne l'est pas (URL distante, chemin
            # construit dynamiquement...).
            enrich_script="$SCRIPT_DIR/inspect-$(echo "$enrich" | tr '_' '-').sh"
            [ -f "$enrich_script" ] && enrich_out=$(bash "$enrich_script" "$file" 2>/dev/null || true)
        fi
        # enrich_is_verdict : pour certaines règles, seule la mesure tranche.
        # Détecter un @font-face ne dit rien en soi — c'est le décompte des
        # familles et le poids réel qui décident. Sans mesure à rapporter, il
        # n'y a rien à signaler, sinon la règle ne peut jamais être satisfaite.
        if [ -n "$matches" ] && [ "$(jq -r '.enrich_is_verdict // false' <<<"$rule_json")" = "true" ] \
           && [ -z "$enrich_out" ]; then
            matches=""
        fi
        if [ -n "$matches" ]; then
            echo "[$impact] $id — $title"
            echo "  Fichier        : $file"
            if [ "$matches" != "match" ]; then
                echo "$matches" | head -5 | sed 's/^/  Ligne          : /'
            fi
            [ -n "$enrich_out" ] && echo "$enrich_out" | sed 's/^/  Détail         : /'
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
