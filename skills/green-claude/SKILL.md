---
name: green-claude
description: |
  Use when Claude écrit, modifie ou revoit du code (formats de fichiers, requêtes
  réseau, images/assets, boucles, cache, pagination, dépendances, choix de
  framework ou de modèle IA), quand l'utilisateur demande un audit de sobriété
  ("audit éco-conception", "vérifie la sobriété de ce code", "--eco-check",
  "RGESN", "GR491", "écoconception", "green IT"), ou quand invoqué via
  /green-claude pour parcourir la checklist des règles.
author: Institut du Numérique Responsable
version: 1.3.0
license: MIT
user-invocable: true
---

# Green Claude

Trois jeux de règles : `rules/ecoconception.json` (52 règles, RGESN 2024 / GR491 /
Green Software Foundation) pendant que tu écris ou modifies du code,
`rules/langages/*.json` (80 règles) pour le langage sur lequel tu travailles, et
`rules/boris.json` (14 pratiques d'usage) pendant la conversation elle-même. Un
usage efficace de Claude Code est aussi un usage sobre.

## Référence rapide

| Mode | Déclencheur | Action |
|---|---|---|
| Proactif (par défaut) | Toujours, dès que tu écris ou modifies du code | Applique les familles pertinentes de `ecoconception.json`, sans qu'on te le demande |
| Audit | « audit éco-conception », « vérifie la sobriété », `--eco-check` | `bash <chemin-du-skill>/scripts/eco-audit.sh fichier1 fichier2 ...` |
| Browse | `/green-claude` | Checklist complète des 9 familles RGESN + 14 pratiques Boris |

## Mode proactif

Garde en tête les 9 familles de `ecoconception.json` (stratégie, spécifications,
architecture, UX, contenus, frontend, backend, hébergement, algorithmie).
Concrètement, sans qu'on te le demande :

- Préfère les formats ouverts et légers (JSON/CSV/Markdown plutôt que docx/xlsx).
- Limite les requêtes réseau et les payloads (pagination, champs sélectionnés, pas de `SELECT *`).
- Évite les boucles ou traitements redondants, mets en cache ce qui est stable.
- Ne charge/n'importe que ce qui est utilisé (pas de librairie entière pour une fonction).
- Compresse et dimensionne correctement les images et assets.

Si une contrainte de sobriété entre en tension avec une demande explicite du user
(perf, deadline, lisibilité), signale le compromis en une phrase, sans jamais
bloquer silencieusement le travail demandé.

Pour la conversation, applique ce qui dépend de toi parmi les réflexes Boris :
garde le contexte minimal, ne précharge pas des fichiers entiers si tu peux les
lire toi-même à la demande. Si une correction en cascade s'annonce, suggère
plutôt à l'utilisateur de rembobiner (double Échap) : c'est son geste, pas le
tien, mais le lui rappeler évite d'empiler les tentatives ratées dans le contexte.

## Mode audit

`bash <chemin-du-skill>/scripts/eco-audit.sh fichier1 fichier2 ...` : un script déterministe
(grep/awk), sans coût de raisonnement pour la détection. Interprète et priorise
la sortie (impact Élevé d'abord) — voir *Erreurs courantes* avant de relayer un
résultat tel quel.

Les règles sans pattern détectable (« mesurer avant d'optimiser », « critères
environnementaux dans les user stories »...) sont des règles de démarche,
listées via `<chemin-du-skill>/scripts/eco-audit.sh --list-rules` plutôt que cherchées par grep.

## Règles propres à un langage

`rules/langages/` contient un fichier par langage (Python, JS/TS, SQL, Java, C#,
PHP, Ruby, Rust, C, C++) : les idiomes que les règles transverses ne peuvent pas
nommer, comme le N+1 d'un ORM, la pagination par curseur, `parallelStream()` ou
`clone()` de confort. Ne consulte que le fichier du langage sur lequel tu
travailles, jamais les dix : l'audit fait déjà cette sélection à partir de
l'extension du fichier, et n'applique jamais un motif Python à du Java.

`eco-audit.sh --list-langs` liste les langages couverts, `--list-rules <langage>`
sort la checklist complète d'un langage.

## Mode browse (`/green-claude`)

Checklist des 9 familles RGESN et des 14 pratiques Boris, avec titre et
recommandation de chaque règle. Utile pour une revue de conception en amont du code.

## Erreurs courantes

Un hit du script d'audit est un **candidat**, pas une violation confirmée. Quand
une ligne `Note` accompagne un résultat, lis-la avant de relayer quoi que ce
soit à l'utilisateur : elle explique la limite précise du pattern ou du
détecteur pour cette règle (faux positif connu, seuil, portée...) — c'est
l'information à jour, plutôt qu'une liste séparée ici qui se périmerait à
chaque nouvelle règle.

## Ce que ce skill ne fait PAS

Le cache de réponses « zéro token » ne peut pas être géré par un skill : il doit
être câblé via des hooks `UserPromptSubmit`/`Stop`, qui interceptent la requête
*avant* qu'elle n'atteigne le modèle (voir `hooks/` à la racine du dépôt). Le
choix du modèle (Haiku/Sonnet/Opus), lui, peut être changé en cours de session
via `/model` : ce skill ne le fait pas à ta place, mais rien n'empêche de
suggérer un modèle plus léger si une tâche y est manifestement disproportionnée.
