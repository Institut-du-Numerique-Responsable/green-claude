# Détecteur de variables globales implicites en JS/TS (ECO-FRONT-06) : une
# déclaration var/let/const, ou une affectation sans mot-clé, au niveau
# racine d'un fichier <script> classique (profondeur d'accolades 0) reste en
# vie pour toute la durée de vie de la page et est visible par tout autre
# script partageant ce contexte. Suit la profondeur des accolades : rien
# n'est signalé à l'intérieur d'une fonction, d'une IIFE ou d'un bloc.
#
# Limite assumée : un module ES (<script type="module">) n'a pas cette
# sémantique (le top-level y est déjà isolé au module) — ce détecteur ne
# reçoit que le contenu du script, pas son attribut type, et ne peut donc
# pas faire la différence. Un hit reste un candidat à vérifier, pas une
# preuve.
#
# Sortie : "numéro_de_ligne:ligne" pour chaque déclaration/affectation
# candidate au niveau racine.

BEGIN { depth = 0 }

{
    line = $0
    trimmed = line
    gsub(/^[ \t]+/, "", trimmed)
    gsub(/[ \t]+$/, "", trimmed)

    is_comment_only = (trimmed ~ /^(\/\/|\*|\/\*)/)
    is_declaration  = (trimmed ~ /^(var|let|const)[ \t]+[a-zA-Z_$]/)
    # Affectation nue en tout début de ligne (pas de mot-clé, pas de point
    # avant le nom -> exclut "foo.bar = " qui n'est pas une déclaration).
    is_bare_assign  = (trimmed ~ /^[a-zA-Z_$][a-zA-Z0-9_$]*[ \t]*=[^=]/)

    if (depth == 0 && !is_comment_only && (is_declaration || is_bare_assign)) {
        printf "%d:%s\n", NR, line
    }

    n = length(line)
    for (i = 1; i <= n; i++) {
        c = substr(line, i, 1)
        if (c == "{") depth++
        else if (c == "}") depth--
    }
}
