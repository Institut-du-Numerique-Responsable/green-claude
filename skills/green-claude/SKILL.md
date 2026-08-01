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
version: 1.2.1
license: MIT
user-invocable: true
---

# Green Claude

Deux jeux de règles : `rules/ecoconception.json` (38 règles, RGESN 2024 / GR491 /
Green Software Foundation) pendant que tu écris ou modifies du code, et
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

## Mode browse (`/green-claude`)

Checklist des 9 familles RGESN et des 14 pratiques Boris, avec titre et
recommandation de chaque règle. Utile pour une revue de conception en amont du code.

## Erreurs courantes

Un hit du script d'audit est un **candidat**, pas une violation confirmée : vérifie
le contexte avant de le signaler.

- ECO-UX-05 (polices) déclenche sur toute mention de police, y compris déjà
  conforme : si le rapport n'a pas de ligne `Détail`, les polices auto-hébergées
  résolvables respectent déjà les seuils RGESN 4.8 (2 familles, 4 variantes, 400 Ko,
  format WOFF2) — inutile de resignaler. Une police tierce (CDN) est toujours
  signalée sans pouvoir être mesurée : à vérifier manuellement.
- `deprecated` en commentaire (ECO-ARCH-03) signale souvent une dépréciation
  documentée — une bonne pratique, pas un défaut.
- ECO-ARCH-01 (react/vue/angular/next) vise le choix initial d'architecture ; ne le
  resignale pas à chaque audit d'un projet déjà construit dessus.
- Un hit ECO-BACK-03 (`nested_loops`) est une boucle imbriquée candidate à O(n²),
  pas une preuve : confirme qu'elle dépend de la taille des données avant de
  recommander un refactor.
- Un hit ECO-FRONT-05 (`dead_code`) signale du code après un
  return/throw/break/continue non conditionnel dans le même bloc — pas un code
  mort à l'exécution runtime en général (un bloc jamais atteint par ailleurs
  n'est pas détectable statiquement).
- Un hit ECO-FRONT-06 (`implicit_globals`) signale une déclaration/affectation
  au niveau racine d'un script — un candidat à vérifier, pas forcément une
  erreur : une globale imposée par un script tiers (Matomo, etc.) en est un
  exemple légitime, à confirmer plutôt qu'à corriger d'office.
- Un hit ECO-CONT-01 signale la simple mention d'un `.png`/`.jpg` dans le code, pas
  un défaut de compression ou de dimension : le pattern seul ne peut pas lire le
  fichier binaire réel. Quand le chemin référencé est résolvable sur disque (pas
  une URL distante), le rapport ajoute son poids et ses dimensions réels
  (`scripts/inspect-image.sh`) — vérifie ces chiffres avant de conclure, et ne dis
  rien de plus que ce que le rapport donne quand le fichier n'est pas résolvable.

## Ce que ce skill ne fait PAS

Le cache de réponses « zéro token » ne peut pas être géré par un skill : il doit
être câblé via des hooks `UserPromptSubmit`/`Stop`, qui interceptent la requête
*avant* qu'elle n'atteigne le modèle (voir `hooks/` à la racine du dépôt). Le
choix du modèle (Haiku/Sonnet/Opus), lui, peut être changé en cours de session
via `/model` : ce skill ne le fait pas à ta place, mais rien n'empêche de
suggérer un modèle plus léger si une tâche y est manifestement disproportionnée.
