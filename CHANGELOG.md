# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et les
nouvelles versions suivent [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

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
- Références obsolètes au CLI, liens de documentation et décompte des pratiques Boris.

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
