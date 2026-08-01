# Détecteur d'usage excessif de !important (ECO-FRONT-10). Seuil repris de
# YellowLabTools (policies.js, isBadThreshold) : au-delà de 200 occurrences,
# c'est le symptôme d'une spécificité CSS hors de contrôle — chaque
# !important supplémentaire force les suivants à en ajouter encore plus
# pour prendre le dessus, gonflant le fichier sans fin utile.
#
# Sortie : une ligne récapitulative si le seuil est dépassé, sinon rien (un
# usage ponctuel et déclaré est parfois légitime).

{
    n = gsub(/!important/, "!important", $0)
    total += n
}

END {
    if (total > 200) {
        printf "%d occurrences de !important (seuil YellowLabTools : 200)\n", total
    }
}
