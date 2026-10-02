# Détecteur de variables globales implicites en JS/TS (ECO-FRONT-06) : une
# déclaration var/let/const, ou une affectation sans mot-clé, au niveau
# racine d'un fichier <script> classique (profondeur d'accolades 0) reste en
# vie pour toute la durée de vie de la page et est visible par tout autre
# script partageant ce contexte. Suit la profondeur des accolades : rien
# n'est signalé à l'intérieur d'une fonction, d'une IIFE ou d'un bloc.
#
# Un module ES n'a pas cette sémantique : son premier niveau est isolé au
# module. Deux preuves sont reconnues, et font taire le bloc concerné :
#   - une instruction import ou export statique au niveau racine, interdite
#     dans un script classique (l'import() dynamique, lui, y est permis et ne
#     prouve rien) ;
#   - l'attribut type="module" de la balise <script> dans une page.
# Dans une page (html, htm, vue, svelte), chaque bloc <script> est jugé
# séparément ; un fichier de script forme un seul bloc, même s'il cite une
# balise <script> dans une chaîne. Les candidats sont donc retenus jusqu'à la
# fin du bloc.
#
# Limites assumées : un module qui n'importe ni n'exporte rien, chargé par une
# balise située dans un autre fichier, reste indiscernable d'un script
# classique et est donc signalé. À l'inverse, une ligne de gabarit multi-ligne
# commençant par « import » ou « export » au niveau racine d'un script
# classique le fait passer pour un module. Un hit reste un candidat à vérifier,
# pas une preuve.
#
# Sortie : "numéro_de_ligne:ligne" pour chaque déclaration/affectation
# candidate au niveau racine.

function flush_block(    i) {
    if (!is_module) {
        for (i = 1; i <= pending; i++) print held[i]
    }
    pending = 0
    is_module = 0
}

BEGIN { depth = 0; pending = 0; is_module = 0 }

{
    line = $0
    if (FNR == 1) markup = (tolower(FILENAME) ~ /\.(html|htm|vue|svelte)$/)
    low = markup ? tolower(line) : ""
    if (markup && low ~ /<script[ \t>]/) {
        flush_block()
        if (low ~ /<script[^>]*[ \t]type[ \t]*=[ \t]*["']?module["' \t>]/) is_module = 1
    }
    trimmed = line
    gsub(/^[ \t]+/, "", trimmed)
    gsub(/[ \t]+$/, "", trimmed)

    is_comment_only = (trimmed ~ /^(\/\/|\*|\/\*)/)
    is_declaration  = (trimmed ~ /^(var|let|const)[ \t]+[a-zA-Z_$]/)
    # Affectation nue en tout début de ligne (pas de mot-clé, pas de point
    # avant le nom -> exclut "foo.bar = " qui n'est pas une déclaration).
    is_bare_assign  = (trimmed ~ /^[a-zA-Z_$][a-zA-Z0-9_$]*[ \t]*=[^=]/)

    # import x from, import { x }, import * as, import "x" ; export const,
    # export { x }, export * from. Le mot doit être suivi d'un espace ou d'un
    # de ces signes : « imports = [] » et « import("x") » n'en sont pas.
    is_esm_statement = (trimmed ~ /^(import|export)[ \t]+[a-zA-Z_$]/ || \
                        trimmed ~ /^import[ \t]*["'{*]/ || trimmed ~ /^export[ \t]*[{*]/)

    if (depth == 0 && !is_comment_only && is_esm_statement) {
        is_module = 1
    } else if (depth == 0 && !is_comment_only && (is_declaration || is_bare_assign)) {
        held[++pending] = sprintf("%d:%s", NR, line)
    }

    n = length(line)
    for (i = 1; i <= n; i++) {
        c = substr(line, i, 1)
        if (c == "{") depth++
        else if (c == "}") depth--
    }

    if (markup && low ~ /<\/script>/) flush_block()
}

END { flush_block() }
