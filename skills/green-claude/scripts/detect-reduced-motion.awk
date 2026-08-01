# Détecteur d'animations sans respect de prefers-reduced-motion
# (ECO-FRONT-14). Le WSG (W3C Web Sustainability Guidelines) demande de
# rendre les animations proportionnées et faciles à contrôler : forcer une
# animation à un visiteur qui a explicitement demandé d'en avoir moins
# (réglage système, souvent lié à une contrainte matérielle ou de
# consommation) gaspille du CPU/GPU pour un rendu que personne ne veut voir.
#
# Heuristique sur tout le fichier (pas ligne par ligne) : présence de
# @keyframes ou d'une déclaration animation: SANS présence, n'importe où
# dans le même fichier, d'une media query prefers-reduced-motion. Un
# faux négatif est possible si la media query vit dans un autre fichier CSS
# du même projet — l'audit ne voit qu'un fichier à la fois.
#
# Sortie : un message unique si le fichier a des animations mais aucun
# prefers-reduced-motion détecté, sinon rien.

BEGIN { has_animation = 0; has_reduced_motion_query = 0 }

{
    if ($0 ~ /@keyframes/ || $0 ~ /animation[ \t]*:/) has_animation = 1
    if ($0 ~ /prefers-reduced-motion/) has_reduced_motion_query = 1
}

END {
    if (has_animation && !has_reduced_motion_query) {
        print "animation(s) détectée(s) sans @media (prefers-reduced-motion: reduce) dans ce fichier"
    }
}
