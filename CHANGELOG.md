# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et les
nouvelles versions suivent [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

### Ajouté

- Passage du corpus de 146 à 225 règles : 83 transverses, 127 de langage sur 24 fichiers, 15 pratiques d’usage.
- Quatorze langages et frameworks supplémentaires : Go, Kotlin, Swift, Shell, Scala, Julia, Nim, Zig, React (Preact compris), Vue, Angular, Svelte, Astro, Solid.
- Cadre 3U de l’Institut du Numérique Responsable (utile, utilisable, utilisé) porté par un champ `three_u` sur 29 règles, avec accessibilité (`ECO-UX-08`) et fin de vie (`ECO-STRAT-07`) qui comblaient les deux volets les plus faibles.
- Trois règles en amont du code : le moins de code qui résout le problème (`ECO-ARCH-07`), challenger la demande et le modèle (`ECO-ALGO-08`), poser la question avant de coder (`USAGE-BRIEF-03`).
- Vingt-quatre règles adaptées de green-codex sous CC BY 4.0, chacune citant sa source.
- Exemples avant/après sur les 46 règles à impact élevé détectables, affichés par l’audit sous `Instead of` et `Write`.
- Registre de décisions `.green-claude/decisions.md` : ce que l’équipe a tranché n’est plus resignalé, et l’audit annonce ce qu’il a tu.
- Fichier d’exclusion `.green-claude/ignore` pour les fixtures et catalogues d’exemples, qui contiennent du code fautif sans jamais l’exécuter.
- Hook `UserPromptSubmit` de cadrage (`hooks/green-claude-brief.sh`), qui rappelle les trois règles amont sur une demande de production de code et se tait sur une question.

### Modifié

- Règles et sortie de l’audit passées en anglais, pour ouvrir les contributions au-delà des francophones. `gr491_famille` garde son libellé français : c’est le nom officiel d’une famille du référentiel.
- Coût de l’audit divisé par dix-neuf : une passe `jq` unique remplace douze appels par règle, soit 3 processus au lieu de 753 sur un fichier. Suite de tests de 77 s à 19 s avec 79 règles de plus.
- Page de documentation : logo et favicon vectoriels servis par un seul fichier qui suit le thème système, 6,6 Ko transférés en deux requêtes contre 15,7 Ko en trois. Matomo sans cookie, chargé après le rendu.
- Intégration continue : deux jobs fusionnés en un, trois installations réseau de `jq` supprimées puisqu’il est préinstallé sur les runners.

### Corrigé

- `grep` prenait un motif d’exclusion commençant par `--` pour une option : la règle échouait en silence, ce qui ressemble à un fichier propre.
- `set -o pipefail` combiné à `grep -q` produisait des faux négatifs sur les fichiers assez gros pour remplir le tube, donc précisément là où il y a le plus à trouver.
- Résolution d’extension d’un fichier sans point : `Dockerfile` n’était jamais routé vers ses règles.
- Le hook d’audit résout désormais les chemins relatifs depuis le fichier d’origine et non depuis `/tmp`, ce qui supprimait un faux positif systématique sur les règles de liens et d’images.
- `ECO-BACK-10` cherchait `%s` dans `execute()`, qui est la forme correcte : la règle était écrite à l’envers.
- Documentation : le renvoi RGESN est désormais annoncé pour ce qu’il est, précis au critère pour les familles 1 à 4 et à la famille pour les suivantes, au lieu d’un « renvoi aux critères officiels » faux pour 33 règles sur 52.
- Retrait de deux seuils chiffrés sans source dans `ECO-SPEC-05`.
- Suppression de l’attribution non vérifiée des pratiques d’usage à Boris Cherny ; ces recommandations sont désormais assumées par le projet, sans équivalence entre tokens et énergie ni chiffres universels non mesurés.

## [1.4.0] - 2026-08-27

### Ajouté

- 80 règles d'écoconception propres à dix langages, chargées selon l'extension des fichiers.
- Score de densité d'issues, hook pre-commit et workflow d'intégration continue.
- Hook PostToolUse pour auditer automatiquement le code nouvellement écrit.
- Archives natives pour Claude.ai et l'API Skills.
- Métadonnées de citation, `llms.txt`, sitemap et intégration IndexNow pour le site public.

### Modifié

- Skill principal traduit en anglais tout en conservant les déclencheurs français.
- Détecteurs bornés à leur langage et réduction des faux positifs dans la prose, les commentaires, les images et les polices.
- Documentation et site public alignés sur les 52 règles transversales et les 80 règles par langage.

## [1.3.0] - 2026-08-01

### Ajouté

- Détecteurs de code mort, variables globales implicites, images, polices, complexité DOM/CSS/JS, HTTPS/TLS et liens cassés.
- Règles issues des Web Sustainability Guidelines et seuils inspirés de YellowLabTools.
- Notes contextuelles accompagnant les résultats heuristiques.

### Modifié

- Extension de 38 à 52 règles transversales.
- Réduction et clarification des instructions du skill.

## [1.2.0] - 2026-08-01

### Ajouté

- Installation comme plugin Claude Code.
- Câblage automatique des hooks optionnels dans les réglages Claude Code.

### Corrigé

- Détection des boucles imbriquées.
- Invalidation et sauvegarde du cache local selon le dépôt courant.

## [1.0.1] - 2026-07-21

### Corrigé

- Lecture des règles par `eco-audit.sh`, auparavant neutralisée par le découpage jq/TSV.
- Références obsolètes au CLI, liens de documentation et décompte des pratiques d’usage alors désignées par une attribution personnelle désormais retirée.

### Modifié

- Remplacement du wrapper CLI initial par un skill Claude Code et un hook optionnel.
- Ajout du guide de contribution et amélioration du site public.

## [1.0.0] - 2026-07-19

### Ajouté

- Première version du skill Green Claude.
- Règles d'écoconception alignées sur le RGESN 2024 et le GR491.
- Site GitHub Pages et documentation initiale.

[Unreleased]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/green-claude--v1.3.0...v1.4.0
[1.3.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/green-claude--v1.2.0...green-claude--v1.3.0
[1.2.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/v1.0.1...green-claude--v1.2.0
[1.0.1]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/releases/tag/v1.0.0
