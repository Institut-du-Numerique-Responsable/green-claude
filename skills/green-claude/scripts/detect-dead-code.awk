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

{
    line = $0
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
                printf "%d:%s\n", NR, line
                flagged_this_zone = 1
            }
            dead_depth = -1  # bloc refermé : fin de la zone surveillée
        } else if (trimmed ~ /^(case[ \t(]|default[ \t]*:)/) {
            dead_depth = -1  # nouveau case : pas mort, juste une autre entrée
        } else if (trimmed !~ /^(\/\/|\*|\/\*)/ && trimmed != "" && !flagged_this_zone) {
            printf "%d:%s\n", NR, line
            flagged_this_zone = 1  # une seule ligne signalée par zone morte
        }
    }

    # Un return/throw/break/continue (mot entier, pour ne pas matcher un
    # identifiant du genre "returnValue") ouvre une nouvelle zone surveillée,
    # à la profondeur constatée après cette ligne.
    if (dead_depth < 0 && trimmed ~ /(^|[^[:alnum:]_.])(return|throw|break|continue)([ \t;()]|$)/) {
        dead_depth = depth
        flagged_this_zone = 0
    }
}
