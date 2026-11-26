# Détecteur de concaténation de chaînes dans une boucle Python (ECO-PY-07).
# `s += ...` recopie toute la chaîne à chaque tour. Le motif grep d'origine ne
# voyait que `+= "littéral"`, n'importe où dans le fichier : il ratait
# `out += c.client.nom` dans une boucle et signalait un `msg += "x"` isolé.
#
# Une ligne est signalée quand, dans le corps d'une boucle for/while :
#   - la variable augmentée a reçu une chaîne plus haut (`out = ""`, `s: str = f""`) ;
#   - ou la partie droite est visiblement une chaîne (littéral, f-string, str(),
#     concaténation avec un littéral).
#
# Sortie : "numéro_de_ligne:ligne".
# Heuristique : le corps de boucle est lu à l'indentation ; les commentaires
# sont retirés hors chaînes ; une variable réaffectée à autre chose qu'une
# chaîne (`total = 0`) cesse d'être suivie.

function strip_comment(s,   out, i, n, c, q, esc) {
    out = ""; n = length(s); q = ""; esc = 0
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q != "") {
            out = out c
            if (esc) { esc = 0; continue }
            if (c == "\\") { esc = 1; continue }
            if (c == q) q = ""
            continue
        }
        if (c == "\"" || c == "'") q = c
        if (c == "#") break
        out = out c
    }
    return out
}

function indent_of(s) {
    match(s, /^[ \t]*/)
    return RLENGTH
}

function stringy(rhs) {
    return rhs ~ /^[ \t]*([rRbBuU]?[fF]?|[fF][rR]?)["']/ \
        || rhs ~ /^[ \t]*(str|repr|format)\(/ \
        || rhs ~ /\+[ \t]*[fF]?["']/ \
        || rhs ~ /["'][ \t]*\+/
}

function check(body, lineno, raw,   name, rhs) {
    if (match(body, /^[ \t]*[A-Za-z_][A-Za-z0-9_]*[ \t]*\+=/)) {
        name = body; sub(/^[ \t]*/, "", name); sub(/[ \t]*\+=.*/, "", name)
        rhs = body; sub(/^[^+]*\+=/, "", rhs)
        if ((name in strvars) || stringy(rhs)) { printf "%d:%s\n", lineno, raw; return 1 }
    }
    return 0
}

BEGIN { depth = 0 }

{
    line = strip_comment($0)
    if (line ~ /^[ \t]*$/) next
    ind = indent_of(line)

    # Sortie des boucles dont le corps est terminé.
    while (depth > 0 && ind <= loop_ind[depth]) depth--

    # Suivi des variables chaîne : `nom = ""`, `nom: str = f"..."`, `nom = str(...)`.
    if (match(line, /^[ \t]*[A-Za-z_][A-Za-z0-9_]*[ \t]*(:[ \t]*str[ \t]*)?=[^=]/)) {
        name = line; sub(/^[ \t]*/, "", name); sub(/[ \t]*(:[^=]*)?=.*/, "", name)
        rhs = line; sub(/^[^=]*=/, "", rhs)
        if (stringy(rhs) || rhs ~ /^[ \t]*str\(/) strvars[name] = 1
        else delete strvars[name]
    }

    if (line ~ /^[ \t]*(async[ \t]+)?(for|while)[ \t].*:/) {
        # Corps sur la même ligne : `for x in xs: s += x`. Un en-tête qui finit
        # par « : » ouvre un bloc, même s'il contient une tranche (`xs[1:3]`).
        if (line !~ /:[ \t]*$/) {
            body = line; sub(/^[^:]*:/, "", body)
            check(body, NR, $0)
            next
        }
        depth++
        loop_ind[depth] = ind
        next
    }

    if (depth > 0) check(line, NR, $0)
}
