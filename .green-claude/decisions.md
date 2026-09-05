# Décisions d'éco-conception

Ce que l'équipe a tranché, pour que l'audit ne le resignale pas. Une décision
par ligne, au format :

    <RÈGLE>  <fichier>  <ACCEPTED|TODO>  <raison>

`ACCEPTED` fait taire la règle pour ce fichier, et seulement pour lui. `TODO`
reste visible : c'est une dette assumée, pas une exemption. Le reste du fichier
est de la prose libre, l'audit ne lit que les lignes au bon format.

## Acceptées

    ECO-CONT-01  docs/index.html  ACCEPTED  logo.jpg conservé comme og:image et repli non-SVG ; le SVG sert l'affichage
    ECO-CONT-03  docs/index.html  ACCEPTED  favicon.png est le repli des navigateurs sans favicon SVG, le SVG existe

## À traiter

    ECO-SH-05    install.sh       TODO      deux mktemp sans trap : les temporaires survivent à une sortie anticipée
