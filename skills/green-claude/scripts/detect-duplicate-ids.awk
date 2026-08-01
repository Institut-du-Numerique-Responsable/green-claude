# Détecteur d'IDs HTML dupliqués (ECO-FRONT-09) : un id doit être unique
# dans tout le document. Un doublon casse getElementById/querySelector (qui
# ne renvoient que le premier), ce qui pousse à des contournements en
# JavaScript plus coûteux que nécessaire, et peut faire déclencher deux fois
# des scripts qui ciblent l'id.
#
# Heuristique : extrait chaque id="..."/id='...' ligne par ligne (pas de
# vrai parseur HTML), signale tout id vu plus d'une fois avec le numéro de
# sa première occurrence.

{
    # awk (POSIX ERE) n'a pas de \b : (^|[caractère non-identifiant]) le
    # remplace pour ne pas matcher "valid=" ou "grid=" comme "id=".
    line = $0
    rest = line
    while (match(rest, /(^|[^a-zA-Z0-9_-])id[ \t]*=[ \t]*["\047][^"\047]+["\047]/)) {
        token = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)

        # Isole la valeur entre guillemets, qu'ils soient simples ou doubles.
        q = index(token, "\"")
        if (q == 0) q = index(token, "\047")
        value = substr(token, q + 1)
        value = substr(value, 1, length(value) - 1)

        if (!(value in first_line)) {
            first_line[value] = NR
            count[value] = 1
        } else {
            count[value]++
        }
    }
}

END {
    for (id in count) {
        if (count[id] > 1) {
            printf "%d:id=\"%s\" apparaît %d fois (première occurrence ligne %d)\n", first_line[id], id, count[id], first_line[id]
        }
    }
}
