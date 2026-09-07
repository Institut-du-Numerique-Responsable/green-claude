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

- Objectif du skill énoncé en tête de `SKILL.md` et dans les métadonnées des règles : livrer du code qui consomme le moins possible de tokens pendant la session, de temps CPU et de mémoire à l'exécution, d'octets sur le réseau, de stockage, et donc d'énergie.
- Lien tokens/énergie assumé dans sa direction et refusé dans son rapport : moins de tokens traités, c'est moins de calcul, et moins de calcul, c'est moins d'énergie ; convertir un nombre de tokens en watts ou en grammes de CO2 reste interdit sans mesure, le cache de prompt, la taille du modèle, le batching, le matériel et le mix électrique pesant chacun davantage. `USAGE-CTX-01` et `USAGE-CTX-03` portent désormais cette raison, et trois tests vérifient qu'elle ne disparaît pas.

- Règles et sortie de l’audit passées en anglais, pour ouvrir les contributions au-delà des francophones. `gr491_famille` garde son libellé français : c’est le nom officiel d’une famille du référentiel.
- Coût de l’audit divisé par dix-neuf : une passe `jq` unique remplace douze appels par règle, soit 3 processus au lieu de 753 sur un fichier. Suite de tests de 77 s à 19 s avec 79 règles de plus.
- Page de documentation : logo et favicon vectoriels servis par un seul fichier qui suit le thème système, 6,6 Ko transférés en deux requêtes contre 15,7 Ko en trois. Matomo sans cookie, chargé après le rendu.
- Intégration continue : deux jobs fusionnés en un, trois installations réseau de `jq` supprimées puisqu’il est préinstallé sur les runners.

### Corrigé

- Indexation : sitemap aligné sur les URL GitHub Pages, liens vers les pages de documentation, index `llms.txt` enrichi et métadonnées générées depuis la version et les règles ; suppression des notes d'avis non sourcées. Contrôles de synchronisation ajoutés à la CI.

- Cache local réservé aux questions autonomes explicitement préfixées `[cache]` : les demandes ordinaires ne sont plus bloquées par une ancienne réponse.
- Hook pre-commit : audit du contenu indexé, même si le fichier de travail diffère, avec prise en charge des renommages et des noms contenant des espaces.
- Hook Claude : conservation du chemin original pour les décisions acceptées et les exclusions lors de l'audit d'un extrait temporaire.
- Score : échec explicite lorsque l'audit échoue ; aucune densité n'est publiée dans ce cas.
- Extensions auditables communes aux hooks et au score, dérivées des règles de langage et des règles transverses ; tests d'intégration ajoutés à la CI et à la release.

- Règles IA ajoutées après coup : `ECO-ALGO-09`, `10` et `11` partageaient les mêmes motifs et signalaient trois fois en impact élevé tout fichier important PyTorch, sans décrire un seul défaut de son code. Une seule garde une détection, et elle détecte l'absence d'instrumentation de mesure.
- `batch_size = 1` attrapait `batch_size = 16`, `128` et `1024` : le motif n'était pas ancré.
- `ECO-ALGO-25` se déclenchait sur toute fonction nommée `train` ; les motifs nomment désormais les API de fine-tuning.
- `ECO-ALGO-12` recommandait de quantifier `gpt-4` et `claude-3-opus`, que personne consommant une API ne peut quantifier ; la règle est recadrée sur le chargement d'un modèle auto-hébergé.
- `ECO-HOST-07` et `08` se déclenchaient tous deux sur `A100` en disant presque la même chose.
- `ECO-HOST-09` affirmait sans source que `us-east-1` est carboné et une liste de régions européennes propre, et doublait `ECO-HEB-09`.
- Huit règles portaient `exclude_patterns` et `extensions` sans aucun motif : ces champs ne sont jamais lus.
- Vingt-et-un motifs utilisaient `\s`, hors ERE POSIX, là où le reste du dépôt utilise `[[:space:]]`.
- `ECO-HOST-07..10` renumérotées en `ECO-HOST-01..04` : deux règles numérotées `07` coexistaient avec `ECO-HEB`.
- Comptes de règles réalignés : `SKILL.md` annonçait 83 transverses et 225 au total pour 106 et 248 réelles, et c'est le fichier que le modèle charge. Un test compare désormais les chiffres annoncés aux règles présentes.
- Documentation : le hook de cadrage, le registre de décisions et le fichier d'exclusion n'étaient décrits nulle part hors du skill ; `CONTRIBUTING.md` ne documentait ni `example`, ni `three_u`, ni `source_note`, ni l'interdiction de `\s` et des lookaheads.


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
