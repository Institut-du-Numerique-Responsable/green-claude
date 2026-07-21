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
version: 1.1.0
license: MIT
user-invocable: true
---

# Green Claude

Deux jeux de règles, deux moments d'application :

1. **`rules/ecoconception.json`** (35 règles, RGESN 2024 / GR491 / Green Software Foundation),
   à appliquer **pendant que tu écris ou modifies du code**. C'est le code qui va
   tourner pendant des années chez les utilisateurs : la sobriété se joue là, pas
   après coup.
2. **`rules/boris.json`** (14 pratiques d'usage), à appliquer **pendant la conversation
   elle-même** : contexte minimal, rembobiner plutôt que corriger, éviter les
   allers-retours inutiles. Un usage efficace de Claude Code est aussi un usage sobre.

## Pourquoi un skill, et pas juste une liste de règles

Une liste de règles dans un fichier reste inerte : personne ne la relit avant
chaque ligne de code, elle vieillit sans que personne s'en aperçoive, et son
respect dépend de la mémoire de qui l'a écrite ou lue une fois. Un skill
change trois choses : Claude Code le charge et l'applique à chaque session
sans qu'on ait à le rappeler, il combine sélection automatique (les familles
pertinentes pour ce que tu écris, pas les 49 règles à chaque fois) et
vérification a posteriori via le script d'audit, et il vit dans le même flux
que le code plutôt que dans un document séparé qu'on consulte une fois puis
qu'on oublie.

## Mode proactif (par défaut)

Quand tu écris ou modifies du code, garde en tête les familles de `ecoconception.json` :
stratégie, spécifications, architecture, UX, contenus, frontend, backend, hébergement,
algorithmie. Concrètement, sans qu'on te le demande :

- Préfère les formats ouverts et légers (JSON/CSV/Markdown plutôt que docx/xlsx).
- Limite les requêtes réseau et les payloads (pagination, champs sélectionnés, pas de `SELECT *`).
- Évite les boucles ou traitements redondants, mets en cache ce qui est stable.
- Ne charge/n'importe que ce qui est utilisé (pas de librairie entière pour une fonction).
- Compresse et dimensionne correctement les images et assets.

Si une contrainte de sobriété entre en tension avec une demande explicite du user
(perf, deadline, lisibilité), signale le compromis en une phrase. Ne bloque jamais
silencieusement le travail demandé.

Pour la conversation elle-même, applique les réflexes Boris : prompt minimal, ne pas
préc-charger des fichiers entiers si tu peux les lire toi-même à la demande, préférer
rembobiner (double Échap) plutôt qu'empiler des corrections dans le contexte.

## Mode audit (sur demande)

Quand l'utilisateur demande explicitement un audit ("audit éco-conception",
"vérifie la sobriété", "--eco-check"), exécute :

```bash
bash <chemin-du-skill>/scripts/eco-audit.sh fichier1 fichier2 ...
```

C'est un script déterministe (grep sur les patterns des règles), sans coût de
raisonnement pour la détection : tu n'as qu'à interpréter et prioriser la sortie
pour l'utilisateur (impact Élevé d'abord).

Certaines règles n'ont pas de pattern détectable dans le code (ex. "mesurer avant
d'optimiser", "critères environnementaux dans les user stories") : ce sont des
règles de démarche, à rappeler en checklist plutôt qu'à chercher par grep. Le
script les ignore déjà lors de l'audit, mais les liste avec
`scripts/eco-audit.sh --list-rules` (règles ecoconception.json sans pattern +
pratiques boris.json).

## Mode browse (`/green-claude`)

Affiche les 9 familles RGESN de `rules/ecoconception.json` et les 14 pratiques de
`rules/boris.json` sous forme de checklist, avec le titre et la recommandation de
chaque règle. Utile pour une revue de conception en amont du code.

## Ce que ce skill ne fait PAS

Le choix du modèle (Haiku/Sonnet/Opus) et le cache de réponses "zéro token" ne
peuvent pas être gérés par un skill : ils doivent être décidés *avant* que la
session ne soit lancée ou la requête envoyée. Voir `hooks/` à la racine du dépôt
pour ce qui reste de ce périmètre, câblé via un hook `UserPromptSubmit`.
