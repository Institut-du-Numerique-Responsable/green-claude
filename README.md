<p align="center"><img src="docs/assets/logo.jpg" alt="Green Claude" width="300"></p>

# Green Claude : sobriété numérique pour Claude Code

[![Licence MIT](https://img.shields.io/badge/licence-MIT-green.svg)](LICENSE)
[![RGESN 2024](https://img.shields.io/badge/RGESN-2024-1b7a4a.svg)](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/)
[![Release](https://img.shields.io/github/v/release/Institut-du-Numerique-Responsable/green-claude)](https://github.com/Institut-du-Numerique-Responsable/green-claude/releases)
[![Site](https://img.shields.io/badge/site-green--claude-blue)](https://institut-du-numerique-responsable.github.io/green-claude/)

**Green Claude** est un skill pour [Claude Code](https://claude.com/claude-code) qui guide Claude vers un code éco-conçu, de façon automatique, sans commande à retenir.

Un projet de l'[Institut du Numérique Responsable](https://github.com/Institut-du-Numerique-Responsable), sous licence MIT.

> Un code éco-conçu = moins de ressources consommées chez chaque utilisateur, à chaque exécution, pendant toute la vie du logiciel.

---

## En une phrase

Tu installes le skill une fois. Ensuite, quand Claude Code écrit ou revoit du code dans tes projets, il applique de lui-même les règles d'éco-conception (**RGESN 2024**, **GR491**, **Green Software Foundation**), sans que tu aies à le lui demander à chaque fois.

## Installation

```bash
git clone https://github.com/Institut-du-Numerique-Responsable/green-claude.git
cd green-claude
./install.sh
```

Ça installe le skill dans `~/.claude/skills/green-claude`. Rien d'autre à faire : Claude Code le charge automatiquement dans tes sessions suivantes.

Prérequis : `jq`, pour le script d'audit (`brew install jq` / `sudo apt install jq`).

## Utilisation

Rien à taper. Trois façons de s'en servir :

| Tu veux... | Ce que tu fais |
|---|---|
| Que Claude code sobrement par défaut | Rien : c'est automatique dès que le skill est installé |
| Auditer un fichier existant | Demande simplement : *« audit éco-conception de ce fichier »* |
| Voir la checklist complète | Tape `/green-claude` |

L'audit (`skill/green-claude/scripts/eco-audit.sh`) est un script déterministe (grep sur les règles) : il ne coûte pas de raisonnement au modèle, juste la lecture du résultat.

---

## Les règles : 35 règles alignées sur les 9 familles du RGESN 2024

[`skill/green-claude/rules/ecoconception.json`](skill/green-claude/rules/ecoconception.json) couvre les **9 familles** du [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) (78 critères officiels). Chaque règle référence le critère RGESN correspondant (`rgesn_ref`) et la famille [GR491](https://gr491.isit-europe.org/) (`gr491_famille`) :

| Famille RGESN | Règles | Exemples |
|---|---|---|
| 1. Stratégie | 3 | Mesurer avant d'optimiser, données raisonnées, formats ouverts |
| 2. Spécifications | 5 | Compatibilité anciens terminaux, bas débit, impact des services tiers |
| 3. Architecture | 4 | Low-tech d'abord, ressources adaptées à la charge, environnements de test sobres |
| 4. UX/UI | 5 | Pas d'autoplay ni de scroll infini, composants natifs, polices limitées |
| 5. Contenus | 3 | Images optimisées, média le plus sobre, SVG |
| 6. Frontend | 4 | Pas de bibliothèque lourde, lazy loading, minification, dépendances |
| 7. Backend | 4 | SQL optimisé, pools de connexions, complexité, pagination + cache |
| 8. Hébergement | 3 | Hébergeur sobre, compression HTTP, cache HTTP |
| 9. **Algorithmie (dont IA)** | 4 | **Justifier l'IA, dimensionner le modèle, mesurer, alternatives sobres** |

Les règles sans motif détectable (démarche, gouvernance) sont ignorées par l'audit et servent de checklist dans `/green-claude`.

---

## Les pratiques Boris : utiliser Claude sobrement, pas seulement en produire

Coder avec l'IA a aussi un coût pendant la session elle-même : chaque requête consomme de l'énergie. [Boris Cherny](https://howborisusesclaudecode.com/), créateur de Claude Code, documente des pratiques d'usage efficace. Un usage efficace est aussi un usage sobre : chaque aller-retour évité économise des tokens, chaque contexte allégé aussi.

[`skill/green-claude/rules/boris.json`](skill/green-claude/rules/boris.json) en reprend 14, dont deux ajoutées avec des exemples d'outils open source vérifiés :

| Pratique | Le geste |
|---|---|
| Minimalisme de contexte | Prompt minimal, laisser Claude aller chercher le contexte lui-même |
| Rembobiner plutôt que corriger | `/rewind` (double Échap) au lieu d'empiler des corrections dans le contexte |
| `/clear` vs `/compact` | Nouvelle tâche → `/clear`. Tâche liée → `/compact <consigne>` |
| Cartographier le code | Un index du dépôt (CODEMAP.md, ou un outil comme [graphify](https://github.com/Graphify-Labs/graphify)) évite de relire les mêmes fichiers en entier à chaque session |
| Réponses denses | Aller droit au résultat plutôt que reformuler (l'esprit derrière des outils comme [caveman](https://github.com/juliusbrussee/caveman)) |
| Écrire la règle, pas re-corriger | « Ajoute ça à CLAUDE.md » répare une fois pour toutes |
| Une skill pour ce qui se répète | Un workflow quotidien devient une slash command |
| Donner un moyen de vérifier | Tests, commande, navigateur : moins de cycles de correction |
| Adapter le niveau d'effort | `/effort low/high/max` selon la tâche, jamais par défaut au maximum |
| `--bare` pour les scripts | Démarrage sans contexte projet, pour l'automatisation |

Détail complet : [`skill/green-claude/rules/boris.json`](skill/green-claude/rules/boris.json).

> Les outils tiers cités (graphify, caveman) sont des exemples illustratifs vérifiés (open source, licence MIT). Le projet ne les audite pas et n'en dépend pas.

---

## Ce qu'un skill ne peut pas faire (et comment on le couvre quand même)

Un skill s'exécute *pendant* une session déjà lancée. Il ne peut donc pas décider avec quel modèle démarrer, ni empêcher un appel au modèle avant qu'il n'ait lieu. Deux leviers restent donc hors du skill, dans [`hooks/`](hooks/), optionnels et proposés à l'installation :

- **Cache local** (`hooks/green-claude-cache.sh`) : une question déjà posée est resservie sans réappeler le modèle, zéro token consommé.
- **Avertissement heures creuses** (même hook) : signale les heures de pointe (hors 22h-6h UTC) sans bloquer.

Ces hooks se câblent dans `~/.claude/settings.json`. `install.sh` te guide, mais vérifie la doc hooks de ta version de Claude Code avant de coller la config.

---

## Écrire ses propres règles

Ajoute un fichier JSON dans `skill/green-claude/rules/`, structuré comme `ecoconception.json` (catégories → règles) :

```json
{
  "id": "CUSTOM-001",
  "title": "Ma règle",
  "impact": "Élevé",
  "patterns": ["mon_motif_regex"],
  "recommendation": "Quoi faire à la place."
}
```

- `patterns` : expressions régulières `grep -E` détectant le problème. **Liste vide = pratique** (checklist, ignorée par l'audit).
- `impact` : `Élevé`, `Moyen` ou `Faible`.
- `rgesn_ref` / `gr491_famille` (optionnels) : renvoi vers les référentiels officiels.

Relance ensuite `./install.sh` pour republier le skill mis à jour.

---

## 🤝 Contribuer

1. **Fork** ce dépôt
2. Créez une branche (`git checkout -b feature/ma-regle`)
3. Ajoutez vos règles ou améliorations (`jq empty skill/green-claude/rules/*.json` pour valider le JSON)
4. Ouvrez une **Pull Request**

Les contributions les plus utiles : nouvelles règles d'audit sourcées (RGESN, GR491, GSF) avec leur `rgesn_ref`, corrections de patterns (faux positifs), traductions.

Détail complet du format des règles et du processus de PR : [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 🙏 Références

- [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) : Référentiel Général d'Écoconception de Services Numériques (78 critères, 9 familles)
- [GR491](https://gr491.isit-europe.org/) : Guide de référence de conception responsable de services numériques (61 recommandations, 516 critères)
- [Green Software Foundation](https://greensoftware.foundation/) : patterns d'éco-conception logicielle
- [How Boris uses Claude Code](https://howborisusesclaudecode.com/) : les pratiques de Boris Cherny, créateur de Claude Code
- [Anthropic](https://www.anthropic.com/) : Claude et Claude Code

## 📄 Licence

[MIT](LICENSE), © 2026 Institut du Numérique Responsable
