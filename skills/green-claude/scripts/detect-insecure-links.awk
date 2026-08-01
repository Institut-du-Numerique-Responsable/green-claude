# Détecteur de liens HTTP non sécurisés (ECO-HEB-04). Une requête en clair
# ne bénéficie pas de la compression et du multiplexage de HTTP/2 (qui
# exige TLS en pratique dans tous les navigateurs), et expose à une
# renégociation ou un homme du milieu qui peut forcer un retéléchargement.
#
# Exclut ce qui n'est pas une vraie requête réseau ou un cas de
# développement légitime : les espaces de noms XML/SVG (http://www.w3.org/,
# http://schema.org/) sont des identifiants, pas des adresses appelées ; et
# localhost/127.0.0.1 servent au développement local, où le TLS n'a pas la
# même pertinence.
#
# Sortie : "numéro_de_ligne:ligne" pour chaque URL http:// candidate
# (une seule fois par ligne, même si elle en contient plusieurs).

{
    line = $0
    rest = line
    while (match(rest, /http:\/\/[^"'"'"' )>]+/)) {
        url = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)

        if (url !~ /^http:\/\/(localhost|127\.0\.0\.1|www\.w3\.org|schema\.org)/) {
            printf "%d:%s\n", NR, line
            next
        }
    }
}
