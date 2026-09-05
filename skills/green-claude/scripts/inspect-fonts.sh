#!/bin/bash
# Enrichissement pour ECO-UX-05 (polices) — un pattern texte détecte qu'une
# police est chargée, pas si elle respecte les seuils RGESN 4.8 : au maximum
# 2 polices et 4 variantes au total (ou 400 Ko de polices téléchargées au
# total), avec vérification de la compression/du format.
#
# Best-effort, comme inspect-image.sh : mesure ce qui est vérifiable
# localement (police auto-hébergée résolvable sur disque), signale sans
# mesurer ce qui ne l'est pas (CDN tiers — poids réel inaccessible sans
# requête réseau).
#
# Usage : inspect-fonts.sh <fichier-audité>

set -euo pipefail

FILE="$1"
# Base de résolution des chemins relatifs. Vaut le répertoire du fichier
# dans le cas courant ; l'appelant peut la forcer quand il audite une copie
# du contenu plutôt que le fichier lui-même (hook PostToolUse), sans quoi
# « assets/logo.webp » serait cherché dans /tmp et jamais trouvé.
DIR="${GREEN_CLAUDE_BASE_DIR:-$(dirname "$FILE")}"
SEUIL_EXCES_OCTETS=$((40 * 1024))   # au-delà, police probablement mal optimisée
SEUIL_TOTAL_OCTETS=$((400 * 1024))  # RGESN 4.8

# --- Polices tierces (CDN) : détectées, mais ni poids ni nombre réels ne
# sont mesurables sans requête réseau vers le CDN.
if grep -qiE 'fonts\.googleapis\.com|fonts\.gstatic\.com|use\.typekit\.net' "$FILE" 2>/dev/null; then
    echo "third-party font(s) detected (CDN): real weight and count not measurable without a network request - check manually (RGESN 4.8: at most 2 fonts, 4 variants in total, or 400 KB)"
fi

# --- Polices auto-hébergées : parcourt les blocs @font-face { ... } pour en
# extraire famille et src, sans dépendre d'un vrai parseur CSS (heuristique
# ligne à ligne, suffisante pour du CSS formaté normalement).
families=""
families_autres=""
pending_family=""
variants=0
total_bytes=0
family=""
in_block=0

while IFS= read -r line; do
    if [[ "$line" == *"@font-face"* ]]; then
        in_block=1
        family=""
        script="latin"
        continue
    fi
    if [ "$in_block" -eq 1 ]; then
        if [[ "$line" =~ font-family[[:space:]]*:[[:space:]]*[\'\"]?([^\'\";]+) ]]; then
            family="${BASH_REMATCH[1]}"
        fi
        # Une famille restreinte par unicode-range à une écriture non latine
        # (arabe, cyrillique, CJK...) n'est pas téléchargée en même temps que les
        # latines : le navigateur ne va chercher le fichier que si la page affiche
        # un glyphe de sa plage. La compter dans le même budget ferait échouer
        # tout site multilingue qui fait pourtant exactement ce qu'il faut.
        if [[ "$line" =~ unicode-range ]]; then
            case "$line" in
                *U+0600*|*U+0750*|*U+FB50*|*U+FE70*) script="non-latin" ;;  # arabe
                *U+0400*|*U+0500*)                   script="non-latin" ;;  # cyrillique
                *U+0370*|*U+1F00*)                   script="non-latin" ;;  # grec
                *U+4E00*|*U+3040*|*U+AC00*)          script="non-latin" ;;  # CJK
                *U+0590*|*U+FB1D*)                   script="non-latin" ;;  # hébreu
                *U+0900*|*U+0E00*)                   script="non-latin" ;;  # devanagari, thaï
            esac
        fi
        if [[ "$line" =~ url\([\'\"]?([^\'\"\)]+)[\'\"]?\) ]]; then
            ref="${BASH_REMATCH[1]}"
            variants=$((variants + 1))
            pending_family="$family"

            if [[ ! "$ref" =~ ^https?:// ]]; then
                candidate="$ref"
                [ -f "$candidate" ] || candidate="$DIR/$ref"
                if [ -f "$candidate" ]; then
                    size=$(wc -c < "$candidate" 2>/dev/null | tr -d ' ')
                    total_bytes=$((total_bytes + size))
                    excess=$((size - SEUIL_EXCES_OCTETS))
                    if [ "$excess" -gt 0 ]; then
                        echo "$(basename "$candidate"): $((size / 1024)) KB, over the 40 KB threshold by $((excess / 1024)) KB - compression, surplus glyphs or complex outlines probably worth revisiting"
                    fi
                    case "$candidate" in
                        *.woff2) ;; # déjà le format le plus compressé
                        *.woff)  echo "$(basename "$candidate"): WOFF (v1) format - WOFF2 compresses better" ;;
                        *.ttf|*.otf) echo "$(basename "$candidate"): uncompressed format (TTF/OTF) - prefer WOFF2" ;;
                        *.eot)   echo "$(basename "$candidate"): EOT format (legacy IE) - obsolete, prefer WOFF2" ;;
                    esac
                fi
            fi
        fi
        if [[ "$line" == *"}"* ]]; then
            in_block=0
            # Classement à la fermeture du bloc : dans un @font-face,
            # `unicode-range` est déclaré après `src`, l'écriture n'est connue
            # qu'ici.
            if [ -n "${pending_family:-}" ]; then
                if [ "${script:-latin}" = "non-latin" ]; then
                    families_autres="$families_autres
$pending_family"
                else
                    families="$families
$pending_family"
                fi
            fi
            pending_family=""
        fi
    fi
# Le parcours est ligne à ligne, et l'entrée dans un @font-face consomme le
# reste de sa ligne. Un bloc écrit d'un seul tenant — `@font-face { font-family:
# "A"; src: url("a.woff2"); }`, ce que produit tout minifieur CSS — passait donc
# entièrement inaperçu. On découpe d'abord sur les accolades et les
# points-virgules pour retomber sur la forme multi-lignes que la boucle sait
# lire, sans rien changer à sa logique.
done < <(sed -e 's/{/{\
/g' -e 's/;/;\
/g' -e 's/}/\
}\
/g' "$FILE")

nb_familles=$(printf '%s\n' "$families" | sort -u | grep -c . || true)
nb_autres=$(printf '%s\n' "$families_autres" | sort -u | grep -c . || true)
# Ne signaler que le dépassement. Rester sous le seuil n'est pas une remarque à
# faire : émettre le décompte dans tous les cas rendait la règle impossible à
# satisfaire pour tout site chargeant la moindre police.
if [ "$nb_familles" -gt 2 ] || [ "$variants" -gt 4 ]; then
    echo "$nb_familles self-hosted Latin family/families, $variants variant(s) in total - over the RGESN 4.8 threshold (at most 2 / 4)"
fi
if [ "$nb_autres" -gt 0 ] && { [ "$nb_familles" -gt 2 ] || [ "$variants" -gt 4 ]; }; then
    echo "note: $nb_autres family/families restricted by unicode-range to a non-Latin script, outside the Latin budget (downloaded only when the page displays that script)"
fi
if [ "$total_bytes" -gt "$SEUIL_TOTAL_OCTETS" ]; then
    echo "total weight of resolvable self-hosted fonts: $((total_bytes / 1024)) KB - over the RGESN 4.8 threshold of 400 KB"
fi
