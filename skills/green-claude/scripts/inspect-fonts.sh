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
DIR="$(dirname "$FILE")"
SEUIL_EXCES_OCTETS=$((40 * 1024))   # au-delà, police probablement mal optimisée
SEUIL_TOTAL_OCTETS=$((400 * 1024))  # RGESN 4.8

# --- Polices tierces (CDN) : détectées, mais ni poids ni nombre réels ne
# sont mesurables sans requête réseau vers le CDN.
if grep -qiE 'fonts\.googleapis\.com|fonts\.gstatic\.com|use\.typekit\.net' "$FILE" 2>/dev/null; then
    echo "police(s) tierce(s) détectée(s) (CDN) : poids/nombre réels non mesurables sans requête réseau — vérifie manuellement (RGESN 4.8 : max 2 polices, 4 variantes au total, ou 400 Ko)"
fi

# --- Polices auto-hébergées : parcourt les blocs @font-face { ... } pour en
# extraire famille et src, sans dépendre d'un vrai parseur CSS (heuristique
# ligne à ligne, suffisante pour du CSS formaté normalement).
families=""
variants=0
total_bytes=0
family=""
in_block=0

while IFS= read -r line; do
    if [[ "$line" == *"@font-face"* ]]; then
        in_block=1
        family=""
        continue
    fi
    if [ "$in_block" -eq 1 ]; then
        if [[ "$line" =~ font-family[[:space:]]*:[[:space:]]*[\'\"]?([^\'\";]+) ]]; then
            family="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ url\([\'\"]?([^\'\"\)]+)[\'\"]?\) ]]; then
            ref="${BASH_REMATCH[1]}"
            variants=$((variants + 1))
            [ -n "$family" ] && families="$families
$family"

            if [[ ! "$ref" =~ ^https?:// ]]; then
                candidate="$ref"
                [ -f "$candidate" ] || candidate="$DIR/$ref"
                if [ -f "$candidate" ]; then
                    size=$(wc -c < "$candidate" 2>/dev/null | tr -d ' ')
                    total_bytes=$((total_bytes + size))
                    excess=$((size - SEUIL_EXCES_OCTETS))
                    if [ "$excess" -gt 0 ]; then
                        echo "$(basename "$candidate") : $((size / 1024)) Ko, dépasse le seuil de 40 Ko de $((excess / 1024)) Ko — compression, glyphes surabondants ou formes complexes probablement à revoir"
                    fi
                    case "$candidate" in
                        *.woff2) ;; # déjà le format le plus compressé
                        *.woff)  echo "$(basename "$candidate") : format WOFF (v1) — WOFF2 compresse mieux" ;;
                        *.ttf|*.otf) echo "$(basename "$candidate") : format non compressé (TTF/OTF) — préférer WOFF2" ;;
                        *.eot)   echo "$(basename "$candidate") : format EOT (IE legacy) — obsolète, préférer WOFF2" ;;
                    esac
                fi
            fi
        fi
        [[ "$line" == *"}"* ]] && in_block=0
    fi
done < "$FILE"

nb_familles=$(printf '%s\n' "$families" | sort -u | grep -c . || true)
if [ "$nb_familles" -gt 0 ]; then
    echo "$nb_familles famille(s) auto-hébergée(s) distincte(s), $variants variante(s) au total — seuil RGESN 4.8 : max 2 / 4"
fi
if [ "$total_bytes" -gt "$SEUIL_TOTAL_OCTETS" ]; then
    echo "poids total des polices auto-hébergées résolvables : $((total_bytes / 1024)) Ko — dépasse le seuil RGESN 4.8 de 400 Ko"
fi
