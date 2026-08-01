#!/bin/bash
# Enrichissement pour ECO-CONT-01 : un pattern grep sait dire qu'une image
# .png/.jpg est référencée, pas si elle est déjà compressée ou correctement
# dimensionnée — ça suppose de lire le fichier binaire réel. Ce script
# résout les chemins référencés dans le fichier audité et, quand ils
# existent sur disque, en lit le format/dimensions/poids réels via `file`.
#
# Best-effort : une image distante (URL) ou un chemin construit
# dynamiquement (variable, template) n'est pas résolvable ici — on ne dit
# rien plutôt que de se tromper. Usage : inspect-image.sh <fichier-audité>

set -euo pipefail

FILE="$1"
DIR="$(dirname "$FILE")"

command -v file >/dev/null 2>&1 || exit 0

grep -oiE '[^"'"'"'() >]+\.(png|jpe?g)' "$FILE" 2>/dev/null | sort -u | while read -r ref; do
    # URL distante : rien à inspecter localement.
    [[ "$ref" =~ ^https?:// ]] && continue

    candidate="$ref"
    [ -f "$candidate" ] || candidate="$DIR/$ref"
    [ -f "$candidate" ] || continue

    size_bytes=$(wc -c < "$candidate" 2>/dev/null | tr -d ' ')
    [ -n "$size_bytes" ] || continue
    size_ko=$(( (size_bytes + 512) / 1024 ))

    # `file` mentionne parfois une densité DPI avant les vraies dimensions
    # (ex. JPEG : "density 1x1, ... 1024x529, components 3") : la dernière
    # occurrence WxH est la bonne, pas la première. Espaces optionnels autour
    # du x car le format varie selon le type d'image (PNG : "200 x 100").
    dims=$(file -b "$candidate" 2>/dev/null | grep -oE '[0-9]+ ?x ?[0-9]+' | tail -1 | tr -d ' ')

    if [ -n "$dims" ]; then
        echo "$ref : ${dims}px, ${size_ko} Ko réels — vérifie que ça correspond à la taille affichée"
    else
        echo "$ref : ${size_ko} Ko réels"
    fi
done
