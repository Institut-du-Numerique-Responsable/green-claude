# Détecteur de complexité DOM (ECO-FRONT-08) : nombre d'éléments et
# profondeur d'imbrication. Seuils repris de YellowLabTools (policies.js,
# isBadThreshold) : >3000 éléments ou >25 niveaux de profondeur.
#
# Heuristique : compte les balises ouvrantes/fermantes ligne par ligne, sans
# vrai parseur HTML. Les éléments vides (void elements : img, br, input...)
# et les balises auto-fermantes (<tag/>) sont comptés comme un élément sans
# changer la profondeur. Imprécis sur du HTML généré dynamiquement ou du
# JSX complexe : un résultat proche du seuil mérite une vérification, pas
# une confiance aveugle.
#
# Sortie : une ligne récapitulative si un des deux seuils est dépassé.

BEGIN {
    depth = 0
    max_depth = 0
    count = 0
    void_elements = "area base br col embed hr img input link meta param source track wbr"
}

{
    line = $0
    n = length(line)
    i = 1
    while (i <= n) {
        if (substr(line, i, 1) == "<") {
            # Cherche la fin de la balise sur cette ligne (limite : une
            # balise coupée sur plusieurs lignes n'est pas reconnue).
            close_at = index(substr(line, i), ">")
            if (close_at == 0) { i++; continue }
            tag = substr(line, i, close_at)
            i += close_at

            if (tag ~ /^<!--/ || tag ~ /^<!/) continue  # commentaire/doctype

            if (tag ~ /^<\//) {
                depth--
                continue
            }

            count++
            is_self_closing = (tag ~ /\/>$/)

            match(tag, /^<([a-zA-Z][a-zA-Z0-9]*)/)
            tagname = tolower(substr(tag, RSTART + 1, RLENGTH - 1))

            if (!is_self_closing && index(" " void_elements " ", " " tagname " ") == 0) {
                depth++
                if (depth > max_depth) max_depth = depth
            }
        } else {
            i++
        }
    }
}

END {
    if (count > 3000) {
        printf "%d éléments HTML au total (seuil YellowLabTools : 3000)\n", count
    }
    if (max_depth > 25) {
        printf "profondeur d'imbrication max : %d niveaux (seuil YellowLabTools : 25)\n", max_depth
    }
}
