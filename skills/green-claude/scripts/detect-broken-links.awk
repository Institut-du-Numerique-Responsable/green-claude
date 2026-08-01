# Détecteur de liens locaux cassés (ECO-HEB-06) : un href/src qui pointe
# vers un fichier du projet lui-même mais que ce fichier n'existe pas sur
# disque devient un 404 dès la mise en ligne — un aller-retour réseau et un
# rendu de page dégradé pour rien.
#
# Portée assumée : seuls les chemins locaux/relatifs sont vérifiables sans
# requête réseau. Les URLs externes (http/https), les ancres (#section) et
# les liens mailto:/tel: sont ignorés — un vrai lien externe mort ne peut
# être détecté qu'en le requêtant réellement, hors de portée d'un audit
# statique sans réseau.
#
# Sortie : "numéro_de_ligne:ligne" pour chaque référence locale introuvable.

{
    # FILENAME n'est pas fiable dans BEGIN (pas encore défini à ce stade en
    # awk) : le répertoire est calculé ici, au premier enregistrement lu.
    if (!dir_computed) {
        dir = FILENAME
        slash = 0
        for (i = length(dir); i > 0; i--) {
            if (substr(dir, i, 1) == "/") { slash = i; break }
        }
        dir = (slash > 0) ? substr(dir, 1, slash - 1) : "."
        dir_computed = 1
    }

    line = $0
    rest = line
    while (match(rest, /(href|src)=["'][^"']+["']/)) {
        token = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)

        q = index(token, "\"")
        if (q == 0) q = index(token, "'")
        ref = substr(token, q + 1)
        ref = substr(ref, 1, length(ref) - 1)

        if (ref == "" || ref ~ /^(https?:|mailto:|tel:|#|data:|javascript:|\/\/)/) continue

        sub(/[?#].*$/, "", ref)  # ancre/paramètres : seul le chemin compte
        if (ref == "") continue

        candidate = (ref ~ /^\//) ? ref : dir "/" ref
        cmd = "test -e \"" candidate "\" && echo yes || echo no"
        cmd | getline exists
        close(cmd)

        if (exists == "no") {
            printf "%d:%s\n", NR, line
        }
    }
}
