# Détecteur de doublons CSS (ECO-FRONT-11) : sélecteurs redéfinis plusieurs
# fois, et propriétés répétées dans un même bloc (la dernière écrase les
# précédentes, celles d'avant sont du poids mort). Seuils repris de
# YellowLabTools (policies.js, isBadThreshold) : 100 pour chaque.
#
# Les deux vérifications utilisent des heuristiques différentes, sans vrai
# parseur CSS :
# - sélecteurs : tout texte immédiatement avant un "{" est un candidat,
#   que la règle soit étalée sur plusieurs lignes ou tenue sur une seule
#   ("sel { ... }") — fonctionne dans les deux styles.
# - propriétés : suit le style étalé (une déclaration par ligne, jusqu'au
#   "}" qui referme le bloc). Un bloc tenu entièrement sur une seule ligne
#   n'est pas vérifié pour les propriétés dupliquées — limite assumée, le
#   cas le plus courant en pratique reste le style étalé.

BEGIN { in_block = 0 }

{
    line = $0

    # --- Sélecteurs dupliqués ---
    rest = line
    while (match(rest, /[^{}]*\{/)) {
        sel = substr(rest, RSTART, RLENGTH - 1)
        gsub(/^[ \t]+/, "", sel); gsub(/[ \t]+$/, "", sel)
        rest = substr(rest, RSTART + RLENGTH)
        if (sel != "" && sel !~ /^@/) {
            selector_count[sel]++
        }
    }

    # --- Propriétés dupliquées dans un même bloc (style étalé) ---
    trimmed = line
    gsub(/^[ \t]+/, "", trimmed); gsub(/[ \t]+$/, "", trimmed)

    if (!in_block && trimmed ~ /\{[ \t]*$/) {
        in_block = 1
        delete seen_props
    } else if (in_block && trimmed ~ /^\}/) {
        in_block = 0
    } else if (in_block && match(trimmed, /^[a-zA-Z-]+[ \t]*:/)) {
        prop = substr(trimmed, 1, RLENGTH - 1)
        gsub(/[ \t]+$/, "", prop)
        if (prop in seen_props) {
            dup_props++
        } else {
            seen_props[prop] = 1
        }
    }
}

END {
    dup_selectors = 0
    for (s in selector_count) {
        if (selector_count[s] > 1) dup_selectors += (selector_count[s] - 1)
    }
    if (dup_selectors > 100) {
        printf "%d sélecteurs redéfinis en double ou plus (seuil YellowLabTools : 100)\n", dup_selectors
    }
    if (dup_props > 100) {
        printf "%d propriétés répétées dans un même bloc (seuil YellowLabTools : 100)\n", dup_props
    }
}
