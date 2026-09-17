# Axes d'amélioration : réduire le coût du contrôle

**Statut :** proposition, non implémenté
**Périmètre :** `hooks/`, `scripts/`, configuration Claude Code
**Objectif :** obtenir le même niveau de conformité pour un nombre d'appels de modèle
et un volume de contexte inférieurs

---

## Contexte

Le dispositif actuel place l'intégralité du contrôle après l'écriture. Le hook
`green-claude-audit.sh` est câblé en `PostToolUse` sur `Write|Edit|MultiEdit` :
Claude rédige le contenu, l'outil écrit le fichier, le hook lance l'audit, le
rapport remonte dans le contexte, Claude relit et applique une correction.

Ce fonctionnement est fiable, puisqu'il ne dépend pas de la décision du modèle,
mais il coûte deux écritures, une sortie d'audit et un cycle de raisonnement
supplémentaire par fichier. Du code non conforme atteint par ailleurs le disque
avant correction, ce qui interfère avec un pre-commit ou un observateur de
fichiers exécuté en parallèle.

Les deux axes ci-dessous visent le même résultat de conformité en déplaçant une
partie du travail vers un moment ou un modèle moins coûteux. Ils sont
indépendants et peuvent être menés séparément.

---

## Axe 1 : déplacer une partie du contrôle en `PreToolUse`

### Principe

Le hook `PreToolUse` s'exécute avant l'appel de l'outil. Il reçoit sur son entrée
standard l'objet `tool_input`, donc `file_path` et `content`. Il répond par un
`permissionDecision` valant `allow`, `deny` ou `ask`, accompagné d'un
`permissionDecisionReason`. Les versions récentes de Claude Code acceptent en
outre `updatedInput`, qui réécrit les arguments avant exécution, et
`additionalContext`, qui transmet une note au modèle.

Trois usages complémentaires en découlent.

#### 1.1 Refus ciblé

Le hook applique les expressions `grep -E` sur `tool_input.content`, en ne
chargeant que le fichier de règles correspondant à l'extension de `file_path`.
Lorsqu'il détecte une violation de niveau `High` dont le motif ne souffre aucune
ambiguïté, il renvoie `deny` en précisant la règle et sa recommandation.

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "ECO-BACK-01 — Optimiser les requêtes SQL. Sélectionner uniquement les colonnes nécessaires plutôt que SELECT *."
  }
}
```

L'écriture n'a pas lieu et Claude reformule aussitôt. La séquence « écrire,
auditer, corriger » se ramène à « refuser, réécrire », soit un appel d'outil et
une lecture de moins par fichier.

Un refus émis en `PreToolUse` est évalué avant le mode de permission. Il
s'applique donc même en `bypassPermissions`, ce qui en fait l'emplacement
naturel du mode strict `GREEN_CLAUDE_STRICT=1`.

#### 1.2 Correction mécanique sans modèle

Certaines des règles admettent une réécriture déterministe : ajout de
`loading="lazy"` sur une balise `img` qui en est dépourvue, ajout de `defer` sur
un script bloquant, remplacement d'un `import * as _ from 'lodash'` par l'import
nommé. Pour celles-ci, `updatedInput` corrige le contenu avant écriture, sans
que le modèle produise le moindre token.

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": { "content": "<contenu corrigé>" }
  }
}
```

C'est le gain le plus net du dispositif, et il reste transparent pour
l'utilisateur. Il suppose d'ajouter aux règles concernées un champ décrivant la
transformation, sur le modèle des champs `detector` et `enrich` existants.

#### 1.3 Amorçage par langage

À la première écriture vers un fichier d'une extension donnée, le hook injecte
une seule fois par session la liste condensée des règles du langage concerné, au
moyen d'`additionalContext`. Seuls les identifiants, les intitulés et les
recommandations sont transmis, jamais les expressions régulières.

Les fichiers suivants sont alors rédigés par un modèle déjà informé, ce qui
réduit le nombre de refus. Le filtrage par extension prend ici tout son sens :
le contexte relatif à Python n'est chargé que dans les sessions qui manipulent
du Python.

### Gain attendu

| Poste | Situation actuelle | Après |
| --- | --- | --- |
| Appels d'outil par fichier non conforme | 2 (`Write` puis `Edit`) | 1 |
| Sortie d'audit dans le contexte | systématique | uniquement en filet |
| Code non conforme sur le disque | oui, avant correction | non |
| Règles à réécriture déterministe | corrigées par le modèle | corrigées sans modèle |

### Risques et garde-fous

**Boucle de refus.** Si le modèle ne parvient pas à satisfaire une règle, il peut
réessayer indéfiniment. Un compteur par couple `session_id` et `file_path`, tenu
dans un fichier temporaire, permet de basculer en `allow` accompagné d'un
`additionalContext` au-delà de deux refus sur un même fichier : la règle est
alors signalée sans bloquer.

**Portée limitée sur `Edit`.** Le `tool_input` d'un `Edit` ne contient que
`old_string` et `new_string`, pas le fichier entier. Les règles portant sur
l'ensemble du fichier (taille du DOM, identifiants dupliqués, code mort,
feuilles de style redondantes) restent invérifiables à ce stade. `PostToolUse`
doit donc être conservé comme filet de sécurité, restreint aux seules règles que
`PreToolUse` ne peut structurellement pas voir, plutôt que de rejouer deux fois
l'audit complet.

**Dépendance à la version.** La prise en charge d'`updatedInput` et
d'`additionalContext` en `PreToolUse` dépend de la version de Claude Code
installée. Une dégradation vers `deny` assorti d'un `permissionDecisionReason`
est nécessaire pour les versions anciennes, faute de quoi le contrôle
disparaîtrait sans avertissement.

### Critères d'acceptation

- [ ] Le hook ne charge que le fichier de règles correspondant à l'extension traitée
- [ ] Un refus cite l'identifiant de règle et sa recommandation
- [ ] Deux refus consécutifs sur un même fichier déclenchent le repli en `allow`
- [ ] Les règles à réécriture déterministe sont identifiées explicitement dans le JSON
- [ ] `PostToolUse` ne conserve que les règles portant sur le fichier complet
- [ ] Le comportement est vérifié sur une version dépourvue d'`updatedInput`

---

## Axe 2 : sortir l'audit de la session principale

### Principe

Une passe d'audit se résume à lancer un script, lire la liste des motifs
détectés et la mettre en forme. Elle ne mobilise ni jugement architectural ni
raisonnement long. La session principale la traite pourtant avec le modèle
qu'elle emploie pour tout le reste, et absorbe au passage la sortie brute de
l'audit ainsi que le contenu des règles consultées.

Un sous-agent traite les deux points, puisqu'il s'exécute dans une fenêtre de
contexte distincte et ne restitue à la session parente que son résultat final.

```yaml
---
name: nr-review
description: >
  Audit écoconception et accessibilité d'un ensemble de fichiers.
  À utiliser après une série de modifications ou avant une PR.
  Ne modifie aucun fichier, renvoie un rapport structuré.
tools: Read, Grep, Glob, Bash
model: haiku
maxTurns: 8
---
```

Le corps du fichier tient lieu de prompt système et prescrit trois consignes :
exécuter le script d'audit sur les chemins fournis, n'ouvrir aucun fichier que
l'audit n'a pas signalé, répondre selon un format fixe à raison d'une ligne par
constat (fichier, ligne, identifiant de règle, impact, remplacement suggéré),
sans commentaire libre.

Le produit fournit le précédent : le sous-agent intégré `Explore` fonctionne en
lecture seule et repose sur Haiku par défaut, l'exploration d'un dépôt ne
requérant pas le modèle le plus puissant. La passe d'audit relève de la même
catégorie. L'écart de coût par token atteint un ordre de grandeur, sans écart de
qualité mesurable sur ce type de tâche.

### Point déterminant : le format de sortie

Le sous-agent n'a aucun accès à la conversation parente. La liste des fichiers
doit lui être transmise explicitement, et la session principale ne verra rien
d'autre que son rapport.

Si ce rapport indique le remplacement à appliquer, la correction s'effectue sans
rouvrir les fichiers. S'il reste vague, la session relit l'ensemble et l'économie
disparaît. L'escalade vers le modèle principal se limite alors aux constats qui
engagent un choix de conception : requête à réécrire, dépendance à remplacer,
composant à restructurer.

### Limites

**Seuil de rentabilité.** La délégation représente elle-même un aller-retour.
Elle ne devient intéressante qu'au-delà d'un certain volume, typiquement une
revue de PR ou une passe sur un répertoire, et non un fichier de trente lignes
pour lequel le script déterministe suffit.

**Chargement du skill.** Le champ `skills` du frontmatter ne convient pas pour
charger green-claude dans le sous-agent : il injecte l'intégralité du skill au
démarrage, ce qui annulerait l'économie. Le sous-agent n'a besoin que du script
et des fichiers de règles qu'il lit lui-même.

### Critères d'acceptation

- [ ] Le sous-agent est en lecture seule (`tools` sans `Write` ni `Edit`)
- [ ] Le rapport suit un format fixe exploitable sans relecture des fichiers
- [ ] Le contenu des règles n'apparaît jamais dans le contexte de la session parente
- [ ] Un seuil documenté indique à partir de quel volume la délégation est pertinente

---

## Mesure

Ces deux axes visent une réduction de coût. Ils ne peuvent être validés que par
comparaison, sur un jeu de tâches identique exécuté avant et après. Trois
indicateurs suffisent : nombre d'appels d'outil par tâche, tokens consommés sur
la session, densité de motifs restants dans le code produit. La conformité doit
rester constante ou s'améliorer, sans quoi le gain n'en est pas un.

La variable `CLAUDE_CODE_SUBAGENT_MODEL` impose le même modèle à tous les
sous-agents d'une session et permet de rendre les deux branches comparables à
modèle constant.

## Hors périmètre

Ces axes portent sur le coût du contrôle, pas sur son étendue. Ils n'ajoutent
aucune règle et ne modifient pas le référentiel couvert. L'extension du
périmètre aux critères d'accessibilité et d'inclusion relève d'une note
distincte.
