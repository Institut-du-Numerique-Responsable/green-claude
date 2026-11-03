# Détecteur d'attente active en shell (ECO-SH-04) : un `sleep N` n'est signalé
# que s'il se trouve dans le corps d'une boucle (entre `do` et `done`). Un
# `sleep` isolé, par exemple une pause avant de lire un journal, n'est pas une
# boucle d'attente : le signaler apprenait à ignorer la règle.
#
# Sortie : "numéro_de_ligne:ligne" pour chaque sleep dans une boucle.
# Heuristique : les mots dans les chaînes et les commentaires sont ignorés ;
# `do` et `done` sont lus comme des mots du shell, y compris sur une même ligne
# (`while true; do sleep 5; done`).

BEGIN { depth = 0 }

function blank_strings(s,   out, i, n, c, q, esc) {
    out = ""; n = length(s); q = ""; esc = 0
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q != "") {
            if (esc) { esc = 0; continue }
            if (c == "\\" && q == "\"") { esc = 1; continue }
            if (c == q) { q = ""; out = out c }
            continue
        }
        if (c == "\"" || c == "'") { q = c; out = out c; continue }
        if (c == "#" && (i == 1 || substr(s, i - 1, 1) ~ /[ \t;]/)) break
        out = out c
    }
    return out
}

{
    line = blank_strings($0)
    gsub(/;/, " ; ", line)
    gsub(/[()]/, " ", line)
    n = split(line, w, /[ \t]+/)
    flagged = 0
    for (i = 1; i <= n; i++) {
        if (w[i] == "do") depth++
        else if (w[i] == "done" && depth > 0) depth--
        else if (w[i] == "sleep" && w[i + 1] ~ /^[0-9]/ && depth > 0 && !flagged) {
            printf "%d:%s\n", NR, $0
            flagged = 1
        }
    }
}
