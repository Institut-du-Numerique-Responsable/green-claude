#!/usr/bin/env bash
# Hook UserPromptSubmit — rappelle les trois règles qui décident de ce qui sera
# écrit, au moment où c'est encore décidable.
#
# ECO-ARCH-07 (le moins de code qui résout le problème), ECO-ALGO-08 (challenger
# la demande et le modèle) et USAGE-BRIEF-03 (poser la question avant de coder)
# s'appliquent AVANT la première ligne. Le skill les porte, mais il est lu au
# chargement de la session : trois tours plus tard le contexte s'est rempli et
# elles ne pèsent plus rien. Un hook, lui, s'exécute à chaque demande.
#
# Le même raisonnement que pour le hook d'audit : ce qui dépend de la mémoire du
# modèle s'applique souvent, ce qui dépend du harnais s'applique toujours.
#
# À déclarer dans ~/.claude/settings.json (voir install.sh) :
#   "hooks": { "UserPromptSubmit": [{"hooks": [{"type": "command",
#     "command": "~/.claude/hooks/green-claude-brief.sh"}]}] }

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
PROMPT="$(printf '%s' "$INPUT" | jq -r '.prompt // empty')"
[ -n "$PROMPT" ] || exit 0

# Ne se déclencher que sur une demande de production de code. Sur une question,
# une explication ou une recherche, ces trois règles n'ont rien à dire, et un
# rappel hors sujet à chaque tour est la meilleure façon de le faire ignorer.
VERBS='write|create|implement|build|add|refactor|generate|code|develop|design'
VERBS="$VERBS"'|écris|écrire|crée|créer|implémente|implémenter|ajoute|ajouter'
VERBS="$VERBS"'|développe|développer|refactor|génère|générer|code|conçois|fais-moi'
SUBJECTS='function|component|endpoint|api|service|script|class|module|feature|test|page|query'
SUBJECTS="$SUBJECTS"'|fonction|composant|service|script|classe|module|fonctionnalité|page|requête|écran'

printf '%s' "$PROMPT" | grep -qiE "($VERBS)" || exit 0
printf '%s' "$PROMPT" | grep -qiE "($SUBJECTS)" || exit 0

# Volontairement court. Un rappel qui prend dix lignes à chaque demande coûte
# plus de contexte qu'il n'en fait économiser, ce qui contredirait la règle
# qu'il rappelle.
cat <<'EOF'
[Green Claude] Avant d'écrire, trois questions (ECO-ARCH-07, ECO-ALGO-08, USAGE-BRIEF-03) :
1. Une hypothèse changerait-elle la forme du travail si elle était fausse ? Si oui, pose la question ; sinon, énonce-la en une ligne et avance.
2. Quel est le moins de code qui résout ce problème ? Une généralisation sans second appelant se réduit à sa version spécifique.
3. Si la demande nomme un modèle ou une approche IA : la tâche en a-t-elle besoin, et est-ce la plus petite qui passe la barre ? Dis ce que tu ferais autrement en une phrase, puis livre ce que l'utilisateur décide.
EOF
exit 0
