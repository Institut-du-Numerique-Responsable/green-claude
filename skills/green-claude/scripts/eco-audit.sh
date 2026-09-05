#!/bin/bash
# Audit éco-conception déterministe : grep les patterns de rules/ecoconception.json
# sur les fichiers passés en argument. Zéro appel modèle — sortie brute pour Claude.
#
# Usage : eco-audit.sh <fichier> [fichier...]
#         eco-audit.sh --list-rules          (checklist des règles sans pattern grep-able)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_FILE="$SCRIPT_DIR/../rules/ecoconception.json"
USAGE_FILE="$SCRIPT_DIR/../rules/usage.json"
LANG_DIR="$SCRIPT_DIR/../rules/langages"

# Extension d'un fichier, en minuscules. Deux pieges : "${f##*.}" travaille sur
# le chemin complet, donc un fichier sans point renvoie tout le chemin ; et les
# fichiers de build utiles ici n'ont pas d'extension du tout. On raisonne donc
# sur le nom seul, et un nom sans point est sa propre extension : Dockerfile ->
# dockerfile, Makefile -> makefile.
ext_of() {
    local base="${1##*/}"
    case "$base" in
        *.*) printf '%s' "${base##*.}" | tr '[:upper:]' '[:lower:]' ;;
        *)   printf '%s' "$base"       | tr '[:upper:]' '[:lower:]' ;;
    esac
}

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
    ext="$(ext_of "$1")"

    case "$ext" in
        py|rb|sh|bash|zsh|dockerfile|yml|yaml)  line_comment='^[[:space:]]*#' ;;
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
        # Une balise par ligne. Les exclusions de motif (exclude_patterns)
        # portent sur la ligne, donc deux balises voisines se couvraient
        # mutuellement : <img src="photo.jpg"><img src="ok.webp"> faisait taire
        # la regle sur le JPG parce que le WebP occupait la meme ligne, alors
        # que ce sont deux images distinctes dont une seule pose probleme.
        # (Sans apostrophe ni accent : ce bloc awk vit entre quotes simples.)
        out = ""
        n = length(line)
        for (i = 1; i <= n; i++) {
            c = substr(line, i, 1)
            if (c == "<") intag = 1
            if (intag) out = out c
            if (c == ">") { intag = 0; print out; out = "" }
        }
        if (out != "") print out
    }' "$1"
}

# Fichiers de règles correspondant à une extension, un par ligne, vide si non
# couverte. Plusieurs sont possibles : un .tsx est du TypeScript ET du React,
# et les deux jeux ont des choses distinctes à dire. Les motifs des frameworks
# nomment leurs propres API (useEffect, createSignal, @Component), donc charger
# react.json sur un .tsx qui n'est pas du React ne produit rien.
lang_file_for_ext() {
    local ext langs lang
    ext="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$ext" in
        py)                      langs="python" ;;
        js|mjs|cjs)              langs="javascript" ;;
        jsx)                     langs="javascript react solid" ;;
        ts)                      langs="javascript angular" ;;
        tsx)                     langs="javascript react solid angular" ;;
        vue)                     langs="javascript vue" ;;
        svelte)                  langs="javascript svelte" ;;
        astro)                   langs="javascript astro" ;;
        sql|pks|pkb|prc|fnc|trg) langs="sql" ;;
        java)                    langs="java" ;;
        cs)                      langs="csharp" ;;
        php)                     langs="php" ;;
        rb)                      langs="ruby" ;;
        rs)                      langs="rust" ;;
        c|h)                     langs="c" ;;
        cpp|cc|cxx|hpp|hh)       langs="cpp" ;;
        go)                      langs="go" ;;
        kt|kts)                  langs="kotlin" ;;
        swift)                   langs="swift" ;;
        sh|bash|zsh)             langs="shell" ;;
        scala|sc)                langs="scala" ;;
        jl)                      langs="julia" ;;
        nim)                     langs="nim" ;;
        zig)                     langs="zig" ;;
        *)                       return 0 ;;
    esac
    for lang in $langs; do
        [ -f "$LANG_DIR/$lang.json" ] && printf '%s\n' "$LANG_DIR/$lang.json"
    done
    return 0
}

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for the audit (brew install jq / apt install jq)." >&2
    exit 1
fi

if [ "${1:-}" = "--list-langs" ]; then
    echo "=== Languages covered by rules/langages/ ==="
    for lang_json in "$LANG_DIR"/*.json; do
        [ -f "$lang_json" ] || continue
        jq -r '"\(.metadata.name)\n  globs : \(.metadata.globs)\n  rules : \(.metadata.count)\n"' "$lang_json"
    done
    exit 0
fi

if [ "${1:-}" = "--list-rules" ] && [ -n "${2:-}" ]; then
    # Checklist d'un seul langage : toutes ses règles, pattern ou non.
    lang_json="$LANG_DIR/$2.json"
    [ -f "$lang_json" ] || { echo "Unknown language: $2 (see --list-langs)." >&2; exit 1; }
    jq -r '"=== \(.metadata.name) (\(.metadata.globs)) ==="' "$lang_json"
    jq -r '
        [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
        | .[]
        | "[\(.impact)] \(.id) — \(.title)\n  \(.recommendation)\n"' "$lang_json"
    exit 0
fi

if [ "${1:-}" = "--list-rules" ]; then
    echo "=== Process rules (no detectable pattern - RGESN/GR491) ==="
    jq -r '
        [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
        | .[]
        | select(((.patterns // []) | length == 0) and ((.detector // "") == ""))
        | "[\(.impact)] \(.id) — \(.title)\n  \(.recommendation)\n"' "$RULES_FILE"
    echo "=== Language rules with no detectable pattern (rules/langages/) ==="
    for lang_json in "$LANG_DIR"/*.json; do
        [ -f "$lang_json" ] || continue
        jq -r '
            .metadata.name as $lang
            | [.categories[] as $c | $c.rules[]]
            | .[]
            | select((.patterns // []) | length == 0)
            | "[\(.impact)] \(.id) — \(.title) (\($lang))\n  \(.recommendation)\n"' "$lang_json"
    done
    echo "=== Responsible use practices (context, brief, memory, verification, compute) ==="
    jq -r '
        [.categories[] as $c | $c.rules[] | . + {category: $c.name}]
        | .[]
        | "[\(.impact)] \(.id) — \(.title)\n  \(.how)\n"' "$USAGE_FILE"
    echo "Checklist for one language: eco-audit.sh --list-rules <language> (see --list-langs)."
    exit 0
fi

if [ $# -eq 0 ]; then
    echo "Usage: eco-audit.sh <file> [file...]" >&2
    echo "        eco-audit.sh --list-rules [language]" >&2
    echo "        eco-audit.sh --list-langs" >&2
    exit 1
fi

issues_found=0
suppressed=0

# Registre de décisions : ce que l'équipe a déjà tranché ne doit pas être
# resignalé. Un candidat qu'on écarte six fois de suite finit par apprendre à
# tout le monde à ignorer l'audit ; le noter une fois clôt la question.
#
# Format, une décision par ligne, le reste du fichier étant de la prose libre :
#   ECO-CONT-01  docs/index.html  ACCEPTED  logo.jpg gardé en repli og:image
#   ECO-SH-05    install.sh       TODO      mktemp sans trap
# Seul ACCEPTED fait taire la règle, et seulement pour ce fichier. TODO reste
# visible : c'est une dette assumée, pas une exemption.
# Fichiers hors périmètre : fixtures de test, catalogues d'exemples, corpus de
# règles. Ils CONTIENNENT du code fautif sans jamais l'exécuter, et les signaler
# est un faux positif par construction — celui qui a coûté le plus de bruit
# pendant l'écriture de ce dépôt. Un motif par ligne, chemin ou fragment.
IGNORE_FILE="${GREEN_CLAUDE_IGNORE:-.green-claude/ignore}"
IGNORE_PATTERNS=""
if [ -f "$IGNORE_FILE" ]; then
    IGNORE_PATTERNS="$(grep -vE '^[[:space:]]*(#|$)' "$IGNORE_FILE" 2>/dev/null | paste -sd'|' - || true)"
fi
is_ignored() {
    [ -n "$IGNORE_PATTERNS" ] || return 1
    printf '%s' "$1" | grep -qE "$IGNORE_PATTERNS"
}

DECISIONS_FILE="${GREEN_CLAUDE_DECISIONS:-.green-claude/decisions.md}"
DECISIONS=""
if [ -f "$DECISIONS_FILE" ]; then
    DECISIONS="$(grep -E '^[[:space:]]*ECO-[A-Z]+-[0-9]+[[:space:]]+[^[:space:]]+[[:space:]]+ACCEPTED' \
                   "$DECISIONS_FILE" 2>/dev/null || true)"
fi

# Vrai quand la règle $1 a été acceptée pour le fichier $2. La comparaison porte
# sur le nom de base autant que sur le chemin : un audit lancé depuis un autre
# répertoire doit retrouver la même décision.
is_accepted() {
    [ -n "$DECISIONS" ] || return 1
    local rid="$1" f="$2" base="${2##*/}"
    printf '%s\n' "$DECISIONS" | awk -v r="$rid" -v f="$f" -v b="$base" '
        $1 == r && ($2 == f || $2 == b) { found = 1 }
        END { exit found ? 0 : 1 }'
}

# Version nettoyée de chaque fichier, calculée une fois pour toutes plutôt qu'à
# chaque règle. Pas de tableau associatif pour la retrouver : bash 3.2, livré
# avec macOS, ne les connaît pas.
CLEAN_DIR="$(mktemp -d)"
trap 'rm -rf "$CLEAN_DIR"' EXIT
select_sha256_tool() {
    local requested="${GREEN_CLAUDE_SHA256_TOOL:-}"
    if [ -n "$requested" ]; then
        case "$requested" in
            shasum|sha256sum) ;;
            *) echo "Outil SHA-256 inconnu : $requested (attendu : shasum ou sha256sum)." >&2; return 1 ;;
        esac
        command -v "$requested" >/dev/null 2>&1 \
            || { echo "Outil SHA-256 introuvable : $requested." >&2; return 1; }
        printf '%s' "$requested"
    elif command -v shasum >/dev/null 2>&1; then
        printf '%s' "shasum"
    elif command -v sha256sum >/dev/null 2>&1; then
        printf '%s' "sha256sum"
    else
        echo "Aucun outil SHA-256 disponible : installe shasum ou sha256sum." >&2
        return 1
    fi
}
SHA256_TOOL="$(select_sha256_tool)" || { rm -rf "$CLEAN_DIR"; exit 1; }
cleaned_name() {
    case "$SHA256_TOOL" in
        shasum)    printf '%s' "$1" | shasum -a 256 | cut -d' ' -f1 ;;
        sha256sum) printf '%s' "$1" | sha256sum | cut -d' ' -f1 ;;
    esac
}
CLEANED_NAMES=()
clean_index=0
for arg in "$@"; do
    CLEANED_NAMES[clean_index]=""
    if [ -f "$arg" ]; then
        CLEANED_NAMES[clean_index]="$(cleaned_name "$arg")"
        clean_source "$arg" > "$CLEAN_DIR/${CLEANED_NAMES[clean_index]}"
    fi
    clean_index=$((clean_index + 1))
done

# Règles propres aux langages réellement présents parmi les fichiers audités :
# inutile de charger les dix fichiers pour auditer un seul script Python. Chaque
# règle porte alors la liste des extensions auxquelles elle s'applique, et n'est
# testée que sur ces fichiers — un motif Python signalerait n'importe quoi sur un
# fichier Java (`.all()`, `save()`, `+=` existent partout).
lang_rules="$(mktemp)"
trap 'rm -rf "$lang_rules" "$lang_rules.seen" "$CLEAN_DIR"' EXIT
for arg in "$@"; do
    [ -f "$arg" ] || continue
    while IFS= read -r lang_json; do
        [ -n "$lang_json" ] || continue
        grep -q "^$lang_json\$" "$lang_rules.seen" 2>/dev/null && continue
        echo "$lang_json" >> "$lang_rules.seen"
        jq -c '
            .metadata.extensions as $exts
            | [.categories[] as $c | $c.rules[] | . + {category: $c.name, exts: $exts}]
            | .[]
            | select((.patterns // []) | length > 0)' "$lang_json" >> "$lang_rules"
    done <<EOF
$(lang_file_for_ext "$(ext_of "$arg")")
EOF
done

# Une ligne JSON compacte par règle (jq -c) : pas de délimiteur maison à
# échapper (l'ancien découpage TSV cassait les patterns contenant des
# backslashes, ex. \., \(, \b), chaque champ est relu depuis la ligne.
# Une seule passe jq pour toutes les règles, au lieu d'une douzaine d'appels par
# règle. Avec 210 règles, l'ancienne boucle lançait plus de 750 processus jq
# pour auditer un fichier : le coût dominait très largement la détection
# elle-même, et il augmentait à chaque règle ajoutée. Un outil de sobriété qui
# se met à coûter cher perd son argument.
#
# Les champs sont séparés par US (0x1f) et les enregistrements par RS (0x1e) :
# deux caractères de contrôle qui n'apparaissent dans aucun texte de règle, là
# où une tabulation ou un pipe se heurteraient aux motifs eux-mêmes. `read -d`
# lit un enregistrement, IFS découpe les champs, et rien n'est reparsé.
#
# Ordre des champs, à garder synchronisé avec le `read` ci-dessous :
#   id, category, title, impact, patterns, excludes, file_excludes, detector,
#   enrich, recommendation, rgesn_ref, note, example_bad, example_good, exts,
#   enrich_is_verdict
RULE_FIELDS='
  [ .id, .category, .title, .impact,
    (.patterns | join("|")),
    ((.exclude_patterns // []) | join("|")),
    ((.exclude_file_patterns // []) | join("|")),
    (.detector // ""), (.enrich // ""),
    .recommendation, .rgesn_ref,
    (.note // .detector_note // .enrich_note // ""),
    (.example.bad // ""), (.example.good // ""),
    (((.exts // []) + (.extensions // [])) | join(" ")),
    ((.enrich_is_verdict // false) | tostring)
  ] | join("\u001f")'

while IFS=$'\x1f' read -r -d $'\x1e' \
      id category title impact patterns excludes file_excludes detector enrich \
      recommendation rgesn_ref note example_bad example_good exts enrich_verdict; do

    file_index=0
    for file in "$@"; do
        cleaned="${CLEANED_NAMES[file_index]}"
        file_index=$((file_index + 1))
        [ -f "$file" ] || continue
        # Règle propre à un langage : ne s'applique qu'aux fichiers de ce langage.
        if [ -n "$exts" ]; then
            file_ext="$(ext_of "$file")"
            case " $exts " in
                *" $file_ext "*) ;;
                *) continue ;;
            esac
        fi
        # Si l'un des motifs d'exclusion fichier apparaît quelque part dans le
        # fichier, la règle se tait : la bonne pratique y est déjà appliquée.
        if [ -n "$file_excludes" ]; then
            fscan="$CLEAN_DIR/$cleaned"
            [ -f "$fscan" ] || fscan="$file"
            grep -qiE -- "$file_excludes" "$fscan" 2>/dev/null && continue
        fi
        matches=""
        if [ -n "$detector" ]; then
            # Détecteur dédié multi-lignes (grep ligne-par-ligne ne sait pas
            # voir une imbrication répartie sur plusieurs lignes).
            detector_script="$SCRIPT_DIR/detect-$(echo "$detector" | tr '_' '-').awk"
            [ -f "$detector_script" ] || continue
            # basedir : répertoire à partir duquel résoudre les chemins
            # relatifs rencontrés dans le fichier. Identique à celui du fichier
            # dans le cas courant, différent quand l'appelant audite une copie
            # (hook PostToolUse). Les détecteurs qui ne résolvent aucun chemin
            # ignorent simplement la variable.
            matches=$(awk -v basedir="${GREEN_CLAUDE_BASE_DIR:-}" -f "$detector_script" "$file" 2>/dev/null || true)
        elif [ -n "$patterns" ]; then
            # `--` avant le motif : une regle peut commencer par un tiret
            # (--prefer-offline, -Xmx...), que grep prendrait pour une option.
            # Sans lui, la regle echouait en silence, ce qui ressemble a un
            # fichier propre.
            # Motifs cherchés sur la version nettoyée (sans prose ni commentaires).
            scanned="$CLEAN_DIR/$cleaned"
            [ -f "$scanned" ] || scanned="$file"
            if [ -n "$excludes" ]; then
                # `grep -q` en aval sort dès la première ligne retenue, ce qui
                # envoie un SIGPIPE au grep amont. Avec `set -o pipefail`, le
                # pipeline renvoie alors 141 et la règle se taisait — un faux
                # négatif qui n'apparaissait que sur les fichiers assez gros
                # pour que le tube se remplisse, donc là où il y a le plus à
                # trouver. `head -1` remplace le `-q` et pipefail est neutralisé
                # le temps du pipeline.
                matches=$(set +o pipefail; grep -iE -- "$patterns" "$scanned" 2>/dev/null | grep -vE -- "$excludes" | head -1)
                if [ -n "$matches" ]; then matches="match"; fi
            else
                matches=$(grep -qiE -- "$patterns" "$scanned" 2>/dev/null && echo "match" || true)
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
        if [ -n "$matches" ] && [ "$enrich_verdict" = "true" ] && [ -z "$enrich_out" ]; then
            matches=""
        fi
        if [ -n "$matches" ] && is_ignored "$file"; then
            matches=""
        fi
        if [ -n "$matches" ] && is_accepted "$id" "$file"; then
            suppressed=$((suppressed + 1))
            matches=""
        fi
        if [ -n "$matches" ]; then
            echo "[$impact] $id — $title"
            echo "  File           : $file"
            if [ "$matches" != "match" ]; then
                echo "$matches" | head -5 | sed 's/^/  Line           : /'
            fi
            [ -n "$enrich_out" ] && echo "$enrich_out" | sed 's/^/  Detail         : /'
            echo "  Category       : $category"
            echo "  RGESN          : $rgesn_ref"
            echo "  Recommendation : $recommendation"
            # Un exemple corrigé vaut mieux qu'une phrase qui le décrit : il
            # évite de reconstruire la forme attendue à chaque signalement.
            # Les exemples tiennent parfois sur deux lignes : les suivantes
            # sont réindentées sous le libellé, sinon le bloc se disloque.
            if [ -n "$example_good" ]; then
                printf '%s\n' "$example_bad"  | sed '1s/^/  Instead of     : /; 2,$s/^/                   /'
                printf '%s\n' "$example_good" | sed '1s/^/  Write          : /; 2,$s/^/                   /'
            fi
            # Candidat, pas preuve : un hit ici est ce que le pattern/détecteur
            # peut voir, pas un verdict. Cette mise en garde vit dans la règle
            # elle-même (note/detector_note/enrich_note du JSON) plutôt que
            # dans une liste séparée que Claude devrait se rappeler par cœur.
            [ -n "$note" ] && echo "  Note           : $note"
            echo ""
            issues_found=$((issues_found + 1))
        fi
    done
done < <(jq -j --arg rs $'\x1e' "
    [.categories[] as \$c | \$c.rules[] | . + {category: \$c.name}]
    | .[]
    | select(((.patterns // []) | length > 0) or ((.detector // \"\") != \"\"))
    | $RULE_FIELDS + \$rs" "$RULES_FILE"
    [ -s "$lang_rules" ] && jq -j --arg rs $'\x1e' "$RULE_FIELDS + \$rs" "$lang_rules"
    true)

if [ "$issues_found" -eq 0 ]; then
    echo "No ecodesign issue found in the files analysed."
else
    echo "$issues_found ecodesign issue(s) found."
fi
# Dire ce qui a été tu : une suppression silencieuse est un trou dans le
# rapport, et le lecteur doit pouvoir remonter au registre.
if [ "$suppressed" -gt 0 ]; then
    echo "$suppressed finding(s) hidden by decisions recorded in $DECISIONS_FILE."
fi
