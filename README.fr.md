# Green Claude : sobriété numérique pour Claude Code

🇬🇧 [Read in English](README.md)

[![Licences](https://img.shields.io/badge/licences-Apache--2.0%20%2B%20CC%20BY%204.0-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Institut-du-Numerique-Responsable/green-claude)](https://github.com/Institut-du-Numerique-Responsable/green-claude/releases)
[![Site](https://img.shields.io/badge/site-green--claude-blue)](https://institut-du-numerique-responsable.github.io/green-claude/)

**Green Claude** aide [Claude Code](https://claude.com/claude-code) à proposer du code moins gourmand en ressources, grâce à des règles d’éco-conception et à un audit local.

Un projet de l’[Institut du Numérique Responsable](https://institutnr.org) : **107 règles générales, 127 règles pour 24 langages et frameworks, et 16 pratiques d’usage responsable**.

Le skill guide le modèle lorsqu’il est chargé ; son application n’est pas garantie à chaque réponse. L’audit détecte des problèmes potentiels à examiner, sans certifier la conformité RGESN ni mesurer une économie d’énergie. Les hooks optionnels permettent de lancer cet audit après les écritures de code prises en charge.

Les règles s’appuient sur le RGESN 2024, le GR491, la Green Software Foundation et les W3C Web Sustainability Guidelines. Une version portable vers d’autres assistants est développée dans [regles-ecoconception-ia](https://github.com/Institut-du-Numerique-Responsable/regles-ecoconception-ia).

[Installation](#installation) · [Utilisation](#utilisation) · [Langages et frameworks](docs/languages/README.md) · [Limites et hooks](#limites-et-hooks) · [Contribuer](CONTRIBUTING.md) · [Licence](#licence)

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

Le script installe le skill dans `~/.claude/skills/green-claude` et propose séparément les hooks d’audit, de cache et de cadrage. Le gestionnaire de plugins ne configure pas ces hooks.

Prérequis : `jq`, pour le script d'audit et les hooks (`brew install jq` / `sudo apt install jq`).

### Claude.ai et API Claude

Depuis un clone local, génère les archives :

```bash
bash skills/green-claude/scripts/package-skill.sh    # écrit dans dist/
```

| Canal | Archive | Installation |
|---|---|---|
| Claude.ai | `dist/green-claude-claude-ai.zip` | Réglages → Fonctionnalités → Skills → Téléverser (l'exécution de code doit être activée) |
| API Claude | `dist/green-claude-api.zip` | `client.beta.skills.create(files=files_from_dir("green-claude"))` |

Les archives contiennent le même skill, avec une description adaptée à chaque canal. L’audit nécessite `bash` et `jq` dans l’environnement d’exécution.

## Utilisation

Trois façons de s’en servir :

| Tu veux... | Ce que tu fais |
|---|---|
| Que Claude code sobrement par défaut | Installer le skill ; demander explicitement son application si nécessaire |
| Auditer un fichier existant | Demande simplement : *« audit éco-conception de ce fichier »* |
| Voir la checklist complète | Tape `/green-claude` |

L’audit utilise des motifs et des détecteurs locaux, sans appel à un modèle pour la détection. L’interprétation de ses résultats par Claude consomme des tokens.

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

`bash skills/green-claude/scripts/eco-audit.sh api.js` (extrait de sortie ; les règles sont en anglais) :

```
[High] ECO-FRONT-01 — No heavy library for a minor need
  File           : api.js
  Category       : 6. Frontend
  RGESN          : 6.x
  Recommendation : Prefer the language's native functions or lighter alternatives (date-fns, Alpine.js).

[High] ECO-BACK-01 — Optimise SQL queries
  File           : api.js
  Category       : 7. Backend
  RGESN          : 7.x
  Recommendation : Select only the columns you need, index the filtered columns, and avoid functions in WHERE clauses and N+1 queries.

[High] ECO-JS-01 — Whole-library import
  File           : api.js
  Category       : JS/TS — dependencies and weight
  RGESN          : 6.1, 6.2
  Recommendation : Targeted imports (import { x } from 'lib/x'); native APIs first (fetch, Intl, URL, structuredClone, Date/Temporal) before adding a dependency.

3 ecodesign issue(s) found.
```

Le skill peut aider Claude à éviter ces problèmes lors de l’écriture ; l’audit permet ensuite de contrôler le résultat.

---

## Les règles : 107 règles alignées sur les 9 familles du RGESN 2024

[`skills/green-claude/rules/ecoconception.json`](skills/green-claude/rules/ecoconception.json) couvre les **9 familles** du [RGESN 2024](https://www.arcep.fr/mes-demarches-et-services/entreprises/fiches-pratiques/referentiel-general-ecoconception-services-numeriques.html) (78 critères officiels) **et une nouvelle catégorie "Hébergement pour l'IA"**. Chaque règle porte un renvoi RGESN (`rgesn_ref`) et une famille [GR491](https://gr491.isit-europe.org/) (`gr491_famille`).

Précision du renvoi RGESN, en l'état : **38 règles** pointent des critères précis (ex. `4.8`), **67 règles** ne pointent que leur famille (`1.x` à `9.x`) faute d'un mappage encore fait, et deux règles relèvent de la Green Software Foundation plutôt que du RGESN. L'affinage de ces renvois à la famille est un chantier ouvert — le champ dit ce qu'il sait, jamais plus.

| Famille RGESN | Règles | Exemples |
|---|---|---|
| 1. Stratégie | 9 | Mesurer avant d'optimiser, données raisonnées, formats ouverts, référent sobriété, sensibilisation, transparence utilisateur |
| 2. Spécifications | 5 | Compatibilité anciens terminaux, bas débit, impact des services tiers |
| 3. Architecture | 12 | Low-tech d'abord, ressources adaptées à la charge, environnements de test sobres, code testé et maintenable |
| 4. UX/UI | 8 | Pas d'autoplay ni de scroll infini, composants natifs, polices limitées, média le plus sobre, prefers-reduced-motion |
| 5. Contenus | 3 | Images optimisées, SVG, polices |
| 6. Frontend | 14 | Pas de bibliothèque lourde, lazy loading, minification, dépendances, pas de code mort, pas de globales implicites, pas de XHR synchrone, DOM sobre, pas d'IDs dupliqués, !important limité, pas de CSS dupliqué, pas de hacks IE legacy, scripts différés |
| 7. Backend | 13 | SQL optimisé, pools de connexions, complexité, pagination + cache, requêtes N+1 |
| 8. Hébergement | 12 | Hébergeur sobre, compression HTTP, cache HTTP, HTTPS/TLS, liens cassés |
| 9. **Algorithmie (dont IA)** | 27 | **Justifier l'IA, dimensionner le modèle, mesurer, alternatives sobres, quantification, batching, streaming** |
| 10. **Hébergement pour l'IA** | 4 | **GPU optimisés inférence, datacenters verts, inférence CPU, dimensionnement modèle** |

Les règles sans motif détectable (démarche, gouvernance) sont ignorées par l'audit et servent de checklist dans `/green-claude`.

---

## Les règles par langage : 127 règles chargées à la demande

Les 107 règles ci-dessus valent quel que soit le langage. Elles fixent l'objectif sans dire comment l'atteindre en Python ou en Java : « éviter les requêtes N+1 » ne tranche pas entre `select_related`, `JOIN FETCH`, `Include` et `with()`.

[`skills/green-claude/rules/langages/`](skills/green-claude/rules/langages/) descend d'un cran, avec un fichier par langage appliqué **uniquement aux fichiers de ce langage** :

Exemples parmi les **24 langages et frameworks**. Voir la [liste complète et les règles détaillées](docs/languages/README.md).

| Fichier | Fichiers concernés | Règles | Ce qu'il attrape en propre |
|---|---|---|---|
| `python.json` | `**/*.py` | 11 | N+1 Django/SQLAlchemy, `iterrows()`, `lru_cache()` non borné, `requests.get` sans session |
| `sql.json` | `**/*.{sql,pks,pkb,prc,fnc,trg}` | 11 | `SELECT *`, pagination `OFFSET`, prédicats non sargables, curseurs PL/SQL, rétention |
| `javascript.json` | `**/*.{js,jsx,ts,tsx,mjs,cjs}` | 9 | `import * as`, `fs.*Sync`, `setInterval`, listeners jamais détachés |
| `java.json` | `**/*.java` | 8 | `findAll()`, N+1 JPA, `parallelStream()`, cache statique non borné |
| `csharp.json` | `**/*.cs` | 8 | `ToList()` prématuré, `.Result`, `new HttpClient()` par requête |
| `php.json` | `**/*.php` | 7 | `->get()` non borné, N+1 Eloquent/Doctrine, `file_get_contents`, cache sans purge |
| `ruby.json` | `**/*.rb` | 7 | `.all.each`, `map(&:col)`, `count > 0`, cache sans `expires_in` |
| `rust.json` | `**/*.rs` | 7 | `clone()` de confort, `collect()` intermédiaire, blocage d'exécuteur async |
| `c.json` | `**/*.{c,h}` | 6 | `strlen()` en condition de boucle, `strcat()` répété, I/O octet par octet, attente active |
| `cpp.json` | `**/*.{cpp,cc,cxx,hpp,hh}` | 6 | Passage par valeur, `std::find` linéaire, `shared_ptr` par défaut |

Sans ce filtrage par extension, les motifs d'un langage se déclenchent à tort sur les autres : `.all()`, `save()` et `+=` existent partout et n'y désignent pas le même problème. L'audit ne charge que le fichier des langages réellement présents parmi ses arguments.

```bash
bash skills/green-claude/scripts/eco-audit.sh --list-langs           # langages couverts et globs associés
bash skills/green-claude/scripts/eco-audit.sh --list-rules python    # checklist complète d'un langage
```

---

## Mesurer, plutôt que supposer

`eco-score.sh` compte les motifs détectés dans un dépôt, les pondère par impact et les rapporte au volume de code :

```bash
skills/green-claude/scripts/eco-score.sh          # lisible
skills/green-claude/scripts/eco-score.sh --json   # une ligne par mesure, à historiser
```

Ce score compte des motifs connus, pas des joules. Une densité qui baisse dit que le code contient moins de motifs repérables, pas qu'il consomme moins. Comparez-la à celle du mois dernier plutôt qu'à zéro, et confrontez-la à une mesure d'exécution réelle (nombre de requêtes, octets transférés, temps CPU, EcoIndex sur une page) : c'est elle qui tranche.

Si l'audit échoue, la commande retourne une erreur et ne produit aucun score. Les hooks et le score déduisent les extensions prises en charge du catalogue de règles ; la sélection automatique exclut Markdown et JSON.

Deux autres points de contrôle, tous deux optionnels :

- `hooks/green-claude-pre-commit.sh` audite le contenu indexé, même si la copie de travail diffère. Là où le hook Claude Code ne voit que ce que Claude écrit, celui-ci voit aussi ce que vous écrivez. Il signale sans bloquer, sauf si vous passez `GREEN_CLAUDE_STRICT=1`.
- `.github/workflows/eco-audit.yml` fait tourner la suite de tests des règles sur chaque PR, et publie la densité du dépôt dans le résumé du job.

## Pratiques d’usage responsable de Claude Code

Coder avec l’IA mobilise des ressources pendant la session. Green Claude maintient donc ses propres recommandations pour limiter les contextes, sorties, reprises et calculs inutiles. Le nombre de tokens reste un indicateur d’activité, pas une mesure directe de l’énergie ou des émissions : toute affirmation environnementale doit être mesurée dans son contexte d’exécution.

[`skills/green-claude/rules/usage.json`](skills/green-claude/rules/usage.json) contient 16 recommandations éditoriales du projet, dont deux illustrées par des outils open source vérifiés :

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
| Adapter le niveau d'effort | Utiliser les réglages disponibles et vérifier leur effet par des évaluations |
| Mode minimal pour les scripts | Éviter les personnalisations inutiles lorsque le client le permet |

Détail complet : [`skills/green-claude/rules/usage.json`](skills/green-claude/rules/usage.json).

> Les outils tiers cités (graphify, caveman) sont des exemples illustratifs vérifiés (open source, licence MIT). Le projet ne les audite pas et n'en dépend pas.

---

## Limites et hooks

Un skill s'exécute *pendant* une session déjà lancée, et c'est le modèle qui décide de l'appliquer. Il ne choisit donc pas le modèle de démarrage, n'intercepte pas un appel avant qu'il parte, et ne garantit pas qu'une règle soit vérifiée à tous les coups. Quatre leviers restent hors du skill, dans [`hooks/`](hooks/), optionnels et proposés à l'installation :

- **Audit systématique** (`hooks/green-claude-audit.sh`) : câblé en `PostToolUse` sur `Write|Edit|MultiEdit`. Claude Code l'exécute après chaque écriture de fichier de code, sans demander son avis au modèle. Le hook audite ce qui vient d'être ajouté et renvoie les motifs trouvés à Claude pour examen et correction éventuelle.
- **Cache local explicite** (`hooks/green-claude-cache.sh`) : préfixer une question factuelle autonome par `[cache] `, par exemple `[cache] Quelle est la capitale de la France ?`. Seules ces demandes peuvent réutiliser une réponse pendant une heure sans appeler le modèle. Les demandes ordinaires atteignent toujours Claude. Ne pas utiliser ce préfixe pour un audit de code, une action ou une question liée aux fichiers ou aux échanges précédents : le cache ne suit pas ces changements. Une réponse en cache est affichée comme message du hook et n'entre pas dans le contexte de conversation de Claude.
- **Avertissement heures creuses** (même hook) : signale les heures de pointe (hors 22h-6h UTC) sans bloquer.
- **Cadrage avant écriture** (`hooks/green-claude-brief.sh`) : câblé en `UserPromptSubmit`. Sur une demande de production de code, il rappelle les trois règles qui décident de ce qui sera écrit — le moins de code qui résout le problème, challenger la demande et le modèle, poser la question avant de coder. Sur une question, il se tait. Ces règles figurent aussi dans le skill ; le hook les rappelle au moment de la demande.

## Deux fichiers pour faire taire ce qui n'a pas à parler

Un candidat écarté une fois revient au tour suivant, et à celui d'après. Écarté six fois, il apprend à toute l'équipe à survoler l'audit, ce qui coûte plus cher que la règle ne rapporte. Deux fichiers versionnés règlent la question, à la racine du dépôt.

`.green-claude/decisions.md` porte ce que l'équipe a tranché :

```
ECO-CONT-01  docs/index.html  ACCEPTED  logo.jpg gardé comme repli og:image
ECO-SH-05    install.sh       TODO      deux mktemp sans trap
```

`ACCEPTED` fait taire cette règle pour ce fichier, et seulement pour lui. `TODO` reste visible : une dette assumée n'est pas une exemption. L'audit annonce combien de constats il a tus et où se trouve le fichier, donc rien ne disparaît sans trace. Le reste du fichier est de la prose libre, seules les lignes au bon format sont lues.

`.green-claude/ignore` sort des fichiers du périmètre, un motif par ligne :

```
skills/green-claude/scripts/test-eco-audit.sh
skills/green-claude/rules/
```

Une suite de tests et un corpus de règles **contiennent** du code fautif sans jamais l'exécuter. Les signaler est un faux positif par construction, et c'est celui qui a produit le plus de bruit pendant l'écriture de ce dépôt.

Les deux emplacements se surchargent par `GREEN_CLAUDE_DECISIONS` et `GREEN_CLAUDE_IGNORE`.

Ces hooks se câblent dans `~/.claude/settings.json`. Si on répond « o », `install.sh` les y ajoute (les autres réglages sont préservés et une sauvegarde du fichier d'origine est laissée en `settings.json.green-claude.bak`). Sans `jq` il affiche la config à coller à la main. Pour les retirer : supprimer les entrées `green-claude-*` du fichier.

---

## Écrire ses propres règles

Le [guide de contribution](CONTRIBUTING.md) décrit le format JSON, les sources à citer, les détecteurs et les tests à lancer. Après une modification locale, relance `./install.sh` pour mettre à jour la copie installée.

---

## 🤝 Contribuer

1. **Fork** ce dépôt
2. Créez une branche (`git checkout -b feature/ma-regle`)
3. Ajoutez vos règles ou améliorations (`jq empty skills/green-claude/rules/*.json` pour valider le JSON)
4. Ouvrez une **Pull Request**

Les contributions les plus utiles : nouvelles règles d'audit sourcées (RGESN, GR491, GSF, WSG, ou une autre référence publique reconnue) avec leur `rgesn_ref`, corrections de patterns (faux positifs), traductions.

Détail complet du format des règles et du processus de PR : [CONTRIBUTING.md](CONTRIBUTING.md).

La participation suit le [code de conduite](CODE_OF_CONDUCT.md) et la
[gouvernance](GOVERNANCE.md) du projet. Consultez [SUPPORT.md](SUPPORT.md) pour
choisir le bon canal et [SECURITY.md](SECURITY.md) pour signaler une
vulnérabilité en privé.

---

## Releases

Les changements notables sont consignés dans le [changelog](CHANGELOG.md). Les
nouvelles releases utilisent des tags Semantic Versioning au format
`vMAJOR.MINOR.PATCH` ; les anciens tags conservent leur nom afin de ne casser
aucun lien. Une release taguée n'est publiée automatiquement qu'après
vérification de sa version, des tests et des archives produites.

---

## 🙏 Références

- [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) : Référentiel Général d'Écoconception de Services Numériques (78 critères, 9 familles)
- [GR491](https://gr491.isit-europe.org/) : Guide de référence de conception responsable de services numériques (61 recommandations, 516 critères)
- [Green Software Foundation](https://greensoftware.foundation/) : patterns d'éco-conception logicielle
- [W3C Web Sustainability Guidelines](https://w3c.github.io/sustainableweb-wsg/) : recommandations de durabilité web (UX, développement, hébergement, stratégie)
- [YellowLabTools](https://github.com/YellowLabTools/YellowLabTools) : outil open source d'audit de qualité front-end, source de plusieurs seuils (DOM, CSS, polices)
- [Anthropic](https://www.anthropic.com/) : Claude et Claude Code

## Mainteneurs

- [Guillaume Gallon](https://github.com/gridboy) ([LinkedIn](https://www.linkedin.com/in/ggallon/)) — [Institut du Numérique Responsable](https://institutnr.org)

## Licence

Code : **Apache-2.0**. Règles et documentation : **CC BY 4.0**. Réutilisation, adaptation et usage commercial autorisés selon ces licences, avec conservation des mentions requises et attribution.

© 2026 Institut du Numérique Responsable. Auteur principal : Guillaume Gallon ; autres contributions : historique Git. Voir le [périmètre des licences](LICENSE) et les [crédits](skills/green-claude/NOTICE). Les sources tierces conservent leurs propres conditions.
