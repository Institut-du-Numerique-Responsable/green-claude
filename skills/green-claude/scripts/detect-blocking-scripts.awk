# Détecteur de scripts bloquants (ECO-FRONT-13) : un <script src="..."> sans
# async ni defer arrête le parsing HTML le temps de télécharger et exécuter
# le script, retardant l'affichage de tout ce qui suit. Les scripts de type
# "module" sont exclus : ils sont différés par défaut selon la spécification
# HTML, pas besoin d'async/defer explicite.
#
# Heuristique : reconnaît la balise <script ...> sur une seule ligne (le cas
# quasi systématique en pratique). Une balise <script> étalée sur plusieurs
# lignes (attributs sur des lignes séparées) n'est pas suivie — limite
# assumée, un détecteur de candidats, pas une preuve.
#
# Sortie : "numéro_de_ligne:ligne" pour chaque script candidat.

{
    line = $0
    if (match(line, /<script[^>]*src=[^>]*>/)) {
        tag = substr(line, RSTART, RLENGTH)
        # Pas de \b : POSIX ERE (awk) ne le supporte pas, contrairement à
        # grep/sed. Simple sous-chaîne ici : le risque qu'"async"/"defer"
        # apparaisse par coïncidence ailleurs dans une balise <script> est
        # négligeable.
        if (tag !~ /async/ && tag !~ /defer/ && tag !~ /type=["\047]module["\047]/) {
            printf "%d:%s\n", NR, line
        }
    }
}
