# Détecteur de code mort JS/TS (ECO-FRONT-05) : instructions inatteignables
# après un return/throw/break/continue, dans le même bloc. Suit la
# profondeur des accolades pour savoir quand ce bloc se referme (le code
# mort ne l'est que jusqu'à la fin de SON bloc, pas au-delà) et reconnaît les
# limites de case/default (le fallthrough syntaxique d'un switch n'est pas
# du code mort).
#
# Piège géré explicitement : la fermeture du bloc surveillé peut partager sa
# ligne avec la suite du code ("} catch (e) {", "} else {" — un style très
# courant). Le scan caractère par caractère repère le point exact où la
# profondeur retombe sous le seuil surveillé ; tout ce qui suit ce point,
# même sur la même ligne, n'est plus considéré comme mort.
#
# Sortie : "numéro_de_ligne:ligne" pour la première ligne inatteignable de
# chaque zone morte. Heuristique assumée : un détecteur de CANDIDATS, pas
# une preuve (un return dans un bloc jamais exécuté à l'exécution, un code
# de débogage volontairement laissé après un early-return temporaire...).

BEGIN { depth = 0; dead_depth = -1; flagged_this_zone = 0 }

# Vide le contenu des chaînes littérales en gardant les guillemets, pour que ni
# les accolades ni les mots-clés qu'elles contiennent ne soient lus comme du
# code. Sans ça, un dictionnaire de traductions contenant "Formation continue
# du personnel" ouvre une zone morte sur le `continue` d'une phrase française.
function count_char(s, c,   n, i) {
    n = 0
    for (i = 1; i <= length(s); i++) if (substr(s, i, 1) == c) n++
    return n
}

function blank_strings(s,   out, i, n, c, q, esc) {
    out = ""; n = length(s); q = ""; esc = 0
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q != "") {
            if (esc) { esc = 0; continue }
            if (c == "\\") { esc = 1; continue }
            if (c == q) { q = ""; out = out c }
            continue
        }
        if (c == "\"" || c == "'" || c == "`") { q = c; out = out c; continue }
        out = out c
    }
    return out
}

{
    orig = $0
    line = blank_strings($0)
    # Les commentaires ne sont pas du code : leurs accolades ne doivent pas
    # décaler la profondeur. `let x = null; // [{ node, original }]` refermait
    # un bloc qui n'avait jamais été ouvert.
    if (inblockcomment) {
        if (match(line, /\*\//)) { line = substr(line, RSTART + 2); inblockcomment = 0 }
        else { line = "" }
    }
    while (match(line, /\/\*.*\*\//)) {
        line = substr(line, 1, RSTART - 1) " " substr(line, RSTART + RLENGTH)
    }
    if (match(line, /\/\*/)) { line = substr(line, 1, RSTART - 1); inblockcomment = 1 }
    if (match(line, /\/\//)) { line = substr(line, 1, RSTART - 1) }
    trimmed = line
    gsub(/^[ \t]+/, "", trimmed)
    gsub(/[ \t]+$/, "", trimmed)

    # Une seule passe caractère par caractère : met à jour la profondeur
    # réelle et repère au passage, si une zone morte est surveillée, le
    # premier point où elle se referme sur cette ligne.
    close_pos = 0
    n = length(line)
    for (i = 1; i <= n; i++) {
        c = substr(line, i, 1)
        if (c == "{") {
            depth++
        } else if (c == "}") {
            depth--
            if (dead_depth >= 0 && depth < dead_depth && close_pos == 0) close_pos = i
        }
    }

    if (dead_depth >= 0) {
        if (close_pos > 0) {
            before = substr(line, 1, close_pos - 1)
            gsub(/^[ \t]+/, "", before); gsub(/[ \t]+$/, "", before)
            if (before != "" && !flagged_this_zone) {
                printf "%d:%s\n", NR, orig
                flagged_this_zone = 1
            }
            dead_depth = -1  # bloc refermé : fin de la zone surveillée
        } else if (trimmed ~ /^(case[ \t(]|default[ \t]*:)/) {
            dead_depth = -1  # nouveau case : pas mort, juste une autre entrée
        } else if (trimmed !~ /^(\/\/|\*|\/\*)/ && trimmed != "" && !flagged_this_zone) {
            printf "%d:%s\n", NR, orig
            flagged_this_zone = 1  # une seule ligne signalée par zone morte
        }
    }

    # Un return/throw/break/continue (mot entier, pour ne pas matcher un
    # identifiant du genre "returnValue") ouvre une nouvelle zone surveillée,
    # à la profondeur constatée après cette ligne.
    # `if (cond) return;` sur une seule ligne, sans accolade : le return est
    # conditionnel, la suite du bloc reste atteignable. C'est la forme la plus
    # répandue de garde en début de fonction — la signaler discrédite le
    # détecteur sur presque tout code réel.
    guarded = (trimmed ~ /(^|[^[:alnum:]_.])(if|else)[ \t]*\(/ && trimmed !~ /\{[ \t]*$/)
    # Bloc refermé après le return, sur la ligne même : `function f() { return x; }`.
    # Il ne reste aucun bloc où du code pourrait devenir inatteignable.
    # On compare les accolades ouvertes et fermées après le mot-clé plutôt que
    # de chercher une fermante : `return { a: 1 };` en contient une sans rien
    # refermer, et l'objet littéral est l'une des formes de retour les plus
    # courantes en JS. Seul un excédent de fermantes referme vraiment le bloc.
    closed_here = 0
    if (match(line, /(^|[^[:alnum:]_.])(return|throw|break|continue)([ \t;()]|$)/)) {
        apres = substr(line, RSTART + RLENGTH)
        if (count_char(apres, "}") > count_char(apres, "{")) closed_here = 1
    }
    if (dead_depth < 0 && !guarded && !closed_here && trimmed ~ /(^|[^[:alnum:]_.])(return|throw|break|continue)([ \t;()]|$)/) {
        dead_depth = depth
        flagged_this_zone = 0
    }
}
