# Détecteur de boucles imbriquées (ECO-BACK-03) — heuristique multi-lignes.
# grep ligne-par-ligne ne peut pas voir une imbrication répartie sur plusieurs
# lignes ; ici on suit la profondeur des accolades pour savoir si une boucle
# s'ouvre à l'intérieur du bloc d'une autre.
#
# Sortie : "numéro_de_ligne:ligne" pour chaque boucle interne candidate.
# Heuristique assumée (langages à accolades ; ignore chaînes/commentaires) :
# c'est un détecteur de CANDIDATS, à confirmer en contexte.

BEGIN { depth = 0; loops = 0; pending = 0; pending_age = 0 }

{
    line = $0
    is_loop = (line ~ /(^|[^[:alnum:]_.])(for|while)[[:space:]]*\(/ \
            || line ~ /\.(forEach|map|flatMap|filter)[[:space:]]*\(/)

    if (is_loop) {
        # Une boucle qui démarre alors qu'on est déjà dans le bloc d'une
        # autre boucle = imbrication.
        if (loops > 0) printf "%d:%s\n", NR, line
        pending++
        pending_age = 0
    }

    n = length(line)
    for (i = 1; i <= n; i++) {
        c = substr(line, i, 1)
        if (c == "{") {
            depth++
            if (pending > 0) { loops++; loop_depth[loops] = depth; pending-- }
        } else if (c == "}") {
            if (loops > 0 && loop_depth[loops] == depth) loops--
            depth--
        }
    }

    # Boucle sans accolade ouvrante sur sa ligne ni la suivante :
    # instruction unique (for (...) x++;) — on ne la suit pas.
    if (pending > 0) {
        pending_age++
        if (pending_age > 1) { pending = 0; pending_age = 0 }
    }
}
