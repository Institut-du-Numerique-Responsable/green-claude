# Green Claude : sobriété numérique pour Claude Code

🇬🇧 [Read in English](README.md)

[![Licence MIT](https://img.shields.io/badge/licence-MIT-green.svg)](LICENSE)
[![RGESN 2024](https://img.shields.io/badge/RGESN-2024-1b7a4a.svg)](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/)
[![GR491](https://img.shields.io/badge/GR491-r%C3%A9f%C3%A9rentiel-1b7a4a.svg)](https://gr491.isit-europe.org/)
[![Release](https://img.shields.io/github/v/release/Institut-du-Numerique-Responsable/green-claude)](https://github.com/Institut-du-Numerique-Responsable/green-claude/releases)
[![Site](https://img.shields.io/badge/site-green--claude-blue)](https://institut-du-numerique-responsable.github.io/green-claude/)
[![Dernier commit](https://img.shields.io/github/last-commit/Institut-du-Numerique-Responsable/green-claude)](https://github.com/Institut-du-Numerique-Responsable/green-claude/commits/main)
[![Stars GitHub](https://img.shields.io/github/stars/Institut-du-Numerique-Responsable/green-claude?style=flat)](https://github.com/Institut-du-Numerique-Responsable/green-claude/stargazers)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

**Green Claude** est un skill pour [Claude Code](https://claude.com/claude-code) qui guide Claude vers un code éco-conçu, de façon automatique, sans commande à retenir.

Une production de l'[Institut du Numérique Responsable](https://institutnr.org), 2026, sous licence MIT.

> Un code éco-conçu = moins de ressources consommées chez chaque utilisateur, à chaque exécution, pendant toute la vie du logiciel.

Ce dépôt est spécifique à Claude Code. Une version indépendante des règles,
portable vers d'autres assistants IA et d'autres langages, est en cours de
développement ici : [regles-ecoconception-ia](https://github.com/Institut-du-Numerique-Responsable/regles-ecoconception-ia).

---

## En une phrase

Tu installes le skill une fois. Ensuite, quand Claude Code écrit ou revoit du code dans tes projets, il applique de lui-même les règles d'éco-conception (**RGESN 2024**, **GR491**, **Green Software Foundation**, **W3C Web Sustainability Guidelines**, plus des seuils repris de **YellowLabTools**), sans que tu aies à le lui demander à chaque fois.

## Pourquoi un skill plutôt qu'une simple liste de règles

Une checklist RGESN en PDF ou en wiki dépend de la mémoire de qui l'a lue une fois. Personne ne la rouvre avant chaque ligne de code, et son application varie d'une personne à l'autre selon qui s'en souvient ce jour-là.

Un skill Claude Code apporte trois différences concrètes :

- **Chargement automatique à chaque session.** Le skill se charge tout seul, sans qu'on ait à le mentionner en tête de conversation.
- **Sélection contextuelle des règles.** Claude applique les familles pertinentes pour ce qu'il écrit à l'instant : un backend déclenche les règles SQL et pools de connexions, pas les règles UX/UI sur l'autoplay.
- **Vérification a posteriori intégrée.** Le script d'audit (`eco-audit.sh`) tourne à la demande sur le code déjà écrit, sans coût de raisonnement pour le modèle, pour attraper ce que l'application proactive a raté.

La checklist reste un document qu'on consulte. Le skill s'exécute au moment où le code s'écrit, dans la session de travail elle-même.

## Installation

### Via le gestionnaire de plugins de Claude Code (recommandé)

```
/plugin marketplace add Institut-du-Numerique-Responsable/green-claude
/plugin install green-claude@green-claude
```

Claude Code gère alors les mises à jour (`/plugin update green-claude`) sans repasser par un `git pull` manuel.

### Via install.sh

```bash
git clone https://github.com/Institut-du-Numerique-Responsable/green-claude.git
cd green-claude
./install.sh
```

Ça installe le skill dans `~/.claude/skills/green-claude`. Rien d'autre à faire : Claude Code le charge automatiquement dans tes sessions suivantes. Cette méthode reste utile pour câbler en plus les hooks de cache (voir plus bas), que le gestionnaire de plugins ne pose pas automatiquement.

Prérequis : `jq`, pour le script d'audit et les hooks (`brew install jq` / `sudo apt install jq`).

## Utilisation

Rien à taper. Trois façons de s'en servir :

| Tu veux... | Ce que tu fais |
|---|---|
| Que Claude code sobrement par défaut | Rien : c'est automatique dès que le skill est installé |
| Auditer un fichier existant | Demande simplement : *« audit éco-conception de ce fichier »* |
| Voir la checklist complète | Tape `/green-claude` |

L'audit (`skills/green-claude/scripts/eco-audit.sh`) est un script déterministe (grep sur les règles) : il ne coûte pas de raisonnement au modèle, juste la lecture du résultat.

## Exemple concret

Ce code, tout à fait banal :

```js
import _ from 'lodash';

app.get('/api/users', (req, res) => {
  db.query('SELECT * FROM users', (err, rows) => {
    res.json(rows);
  });
});
```

`eco-audit.sh api.js` (sortie réelle, non retouchée) :

```
[Élevé] ECO-FRONT-01 — Pas de bibliothèque lourde pour un besoin mineur
  Recommandation : Préférer les fonctions natives du langage ou des alternatives légères (date-fns, Alpine.js).

[Élevé] ECO-BACK-01 — Optimiser les requêtes SQL
  Recommandation : Sélectionner uniquement les colonnes nécessaires, indexer les colonnes filtrées, éviter les fonctions dans les clauses WHERE et les requêtes N+1.

2 issue(s) d'éco-conception détectée(s).
```

En pratique, tu n'as pas besoin de lancer l'audit toi-même sur ce genre de code : en mode proactif, Claude évite `lodash` pour une seule fonction et `SELECT *` dès l'écriture, avant même qu'un audit ait lieu.

---

## Les règles : 52 règles alignées sur les 9 familles du RGESN 2024

[`skills/green-claude/rules/ecoconception.json`](skills/green-claude/rules/ecoconception.json) couvre les **9 familles** du [RGESN 2024](https://www.arcep.fr/mes-demarches-et-services/entreprises/fiches-pratiques/referentiel-general-ecoconception-services-numeriques.html) (78 critères officiels). Chaque règle référence le critère RGESN correspondant (`rgesn_ref`) et la famille [GR491](https://gr491.isit-europe.org/) (`gr491_famille`) :

| Famille RGESN | Règles | Exemples |
|---|---|---|
| 1. Stratégie | 6 | Mesurer avant d'optimiser, données raisonnées, formats ouverts, référent sobriété, sensibilisation, transparence utilisateur |
| 2. Spécifications | 5 | Compatibilité anciens terminaux, bas débit, impact des services tiers |
| 3. Architecture | 5 | Low-tech d'abord, ressources adaptées à la charge, environnements de test sobres, code testé et maintenable |
| 4. UX/UI | 7 | Pas d'autoplay ni de scroll infini, composants natifs, polices limitées, média le plus sobre, prefers-reduced-motion |
| 5. Contenus | 2 | Images optimisées, SVG |
| 6. Frontend | 13 | Pas de bibliothèque lourde, lazy loading, minification, dépendances, pas de code mort, pas de globales implicites, pas de XHR synchrone, DOM sobre, pas d'IDs dupliqués, !important limité, pas de CSS dupliqué, pas de hacks IE legacy, scripts différés |
| 7. Backend | 4 | SQL optimisé, pools de connexions, complexité, pagination + cache |
| 8. Hébergement | 6 | Hébergeur sobre, compression HTTP, cache HTTP, HTTPS/TLS, liens cassés |
| 9. **Algorithmie (dont IA)** | 4 | **Justifier l'IA, dimensionner le modèle, mesurer, alternatives sobres** |

Les règles sans motif détectable (démarche, gouvernance) sont ignorées par l'audit et servent de checklist dans `/green-claude`.

---

## Les pratiques Boris : utiliser Claude sobrement et avec bon sens

Coder avec l'IA a aussi un coût pendant la session elle-même : chaque requête consomme de l'énergie. [Boris Cherny](https://howborisusesclaudecode.com/), créateur de Claude Code, documente des pratiques d'usage efficace. Un usage efficace est aussi un usage sobre : chaque aller-retour évité économise des tokens, chaque contexte allégé aussi.

[`skills/green-claude/rules/boris.json`](skills/green-claude/rules/boris.json) en reprend 14, dont deux ajoutées avec des exemples d'outils open source vérifiés :

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

Détail complet : [`skills/green-claude/rules/boris.json`](skills/green-claude/rules/boris.json).

> Les outils tiers cités (graphify, caveman) sont des exemples illustratifs vérifiés (open source, licence MIT). Le projet ne les audite pas et n'en dépend pas.

---

## Ce qu'un skill ne peut pas faire (et comment on le couvre quand même)

Un skill s'exécute *pendant* une session déjà lancée, et c'est le modèle qui décide de l'appliquer. Il ne choisit donc pas le modèle de démarrage, n'intercepte pas un appel avant qu'il parte, et ne garantit pas qu'une règle soit vérifiée à tous les coups. Trois leviers restent hors du skill, dans [`hooks/`](hooks/), optionnels et proposés à l'installation :

- **Audit systématique** (`hooks/green-claude-audit.sh`) : câblé en `PostToolUse` sur `Write|Edit|MultiEdit`. Claude Code l'exécute après chaque écriture de fichier de code, sans demander son avis au modèle. Le hook audite ce qui vient d'être ajouté et renvoie les motifs trouvés à Claude, qui corrige avant de continuer.
- **Cache local** (`hooks/green-claude-cache.sh`) : une question déjà posée est resservie sans réappeler le modèle, zéro token consommé.
- **Avertissement heures creuses** (même hook) : signale les heures de pointe (hors 22h-6h UTC) sans bloquer.

Ces hooks se câblent dans `~/.claude/settings.json`. Si on répond « o », `install.sh` les y ajoute (les autres réglages sont préservés et une sauvegarde du fichier d'origine est laissée en `settings.json.green-claude.bak`). Sans `jq` il affiche la config à coller à la main. Pour les retirer : supprimer les entrées `green-claude-*` du fichier.

---

## Écrire ses propres règles

Ajoute un fichier JSON dans `skills/green-claude/rules/`, structuré comme `ecoconception.json` (catégories → règles) :

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
- `detector` / `enrich` (optionnels) : pour les cas qu'un pattern seul ne peut pas voir (imbrication multi-lignes, comptage, poids réel d'un fichier référencé...), un script dédié dans `scripts/`. Détail complet dans [CONTRIBUTING.md](CONTRIBUTING.md).
- `note` (optionnel) : mise en garde affichée dans le résultat de l'audit (faux positif connu, seuil, portée limitée) — l'endroit où documenter les pièges d'interprétation d'une règle, pas dans le skill lui-même.

Relance ensuite `./install.sh` pour republier le skill mis à jour.

---

## 🤝 Contribuer

1. **Fork** ce dépôt
2. Créez une branche (`git checkout -b feature/ma-regle`)
3. Ajoutez vos règles ou améliorations (`jq empty skills/green-claude/rules/*.json` pour valider le JSON)
4. Ouvrez une **Pull Request**

Les contributions les plus utiles : nouvelles règles d'audit sourcées (RGESN, GR491, GSF, WSG, ou une autre référence publique reconnue) avec leur `rgesn_ref`, corrections de patterns (faux positifs), traductions.

Détail complet du format des règles et du processus de PR : [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 🙏 Références

- [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) : Référentiel Général d'Écoconception de Services Numériques (78 critères, 9 familles)
- [GR491](https://gr491.isit-europe.org/) : Guide de référence de conception responsable de services numériques (61 recommandations, 516 critères)
- [Green Software Foundation](https://greensoftware.foundation/) : patterns d'éco-conception logicielle
- [W3C Web Sustainability Guidelines](https://w3c.github.io/sustainableweb-wsg/) : recommandations de durabilité web (UX, développement, hébergement, stratégie)
- [YellowLabTools](https://github.com/YellowLabTools/YellowLabTools) : outil open source d'audit de qualité front-end, source de plusieurs seuils (DOM, CSS, polices)
- [How Boris uses Claude Code](https://howborisusesclaudecode.com/) : les pratiques de Boris Cherny, créateur de Claude Code
- [Anthropic](https://www.anthropic.com/) : Claude et Claude Code

## Mainteneurs

- [Guillaume Gallon](https://github.com/gridboy) ([LinkedIn](https://www.linkedin.com/in/ggallon/)) — [Institut du Numérique Responsable](https://institutnr.org)

## 📄 Licence

[MIT](LICENSE), © 2026 Institut du Numérique Responsable
