# 🌱 Green Claude — Sobriété numérique pour Claude Code

**Green Claude** est un wrapper éco-responsable pour [Claude Code](https://claude.com/claude-code) qui agit dans **les deux sens** :

1. **Réduire l'impact d'utiliser Claude** — chaque requête IA consomme de l'énergie ; le wrapper la rend aussi sobre que possible (modèle proportionné, données limitées, cache, heures creuses, pratiques de sobriété).
2. **Faire produire à Claude du code sobre** — le logiciel généré aura sa propre empreinte pendant des années ; les règles d'éco-conception (**RGESN 2024**, **GR491**, **Green Software Foundation**) servent à auditer le code et à guider Claude pour qu'il le conçoive sobre dès le départ.

Un projet de l'[Institut du Numérique Responsable](https://github.com/Institut-du-Numerique-Responsable), sous licence MIT.

> **Moins de tokens = moins de calcul = moins d'énergie = moins de CO₂.**
> **Et un code éco-conçu = des économies chez chaque utilisateur, à chaque exécution, pendant toute la vie du logiciel.**

---

## Sommaire

- [La double vocation](#-la-double-vocation)
- [Installation](#-installation)
- [Utilisation](#-utilisation)
- [Volet 1 — Utiliser Claude sobrement](#-volet-1--utiliser-claude-sobrement)
- [Volet 2 — Faire produire du code sobre](#-volet-2--faire-produire-du-code-sobre)
- [Les 12 pratiques de sobriété Claude Code (Boris Cherny)](#-les-12-pratiques-de-sobriété-claude-code-boris-cherny)
- [Écrire ses propres règles](#-écrire-ses-propres-règles)
- [Configuration](#-configuration)
- [Contribuer](#-contribuer)

---

## 🎭 La double vocation

L'impact environnemental de « coder avec l'IA » a deux faces, et optimiser une seule ne suffit pas :

| | Volet 1 — L'impact d'**utiliser** Claude | Volet 2 — L'impact du **code produit** par Claude |
|---|---|---|
| **Quand ?** | Pendant le développement | Pendant toute la vie du logiciel |
| **Qui consomme ?** | Le data center qui exécute le modèle | Chaque serveur et chaque terminal qui exécute le code |
| **Leviers** | Modèle proportionné, moins de tokens, cache, heures creuses, pratiques d'usage | Éco-conception : RGESN, GR491, GSF |
| **Outils Green Claude** | Le wrapper `green-claude` + `rules/boris.json` | L'audit `--eco-check` + `rules/ecoconception.json` |

Les deux volets se renforcent : les bonnes pratiques d'usage (volet 1) réduisent les allers-retours, et un Claude guidé par les règles d'éco-conception (volet 2) produit du premier coup un code qu'il ne faudra pas ré-optimiser — donc moins de requêtes aussi.

---

## 📥 Installation

### Installation automatique (recommandé)

```bash
git clone https://github.com/Institut-du-Numerique-Responsable/green-claude.git
cd green-claude
./install.sh
```

### Installation manuelle

```bash
# 1. Copier les fichiers
mkdir -p ~/green-claude
cp green-claude ~/green-claude/
cp -r rules ~/green-claude/
chmod +x ~/green-claude/green-claude

# 2. Ajouter au PATH
echo 'export PATH="$HOME/green-claude:$PATH"' >> ~/.zshrc   # ou ~/.bashrc
source ~/.zshrc
```

### Prérequis

| Outil | Rôle | Obligatoire |
|---|---|---|
| [Claude Code CLI](https://code.claude.com/docs) (`claude`) | Exécuter les requêtes IA | Oui (sauf audit seul) |
| `jq` | Audit avancé (fichiers de règles JSON) | Non — sans jq, l'audit basique fonctionne |

```bash
npm install -g @anthropic-ai/claude-code   # CLI Claude Code
brew install jq                            # macOS — ou : sudo apt install jq
```

---

## 🚀 Utilisation

```bash
# Question simple → modèle léger (Haiku)
green-claude --complexity simple "Explique cette regex"

# Analyse d'un fichier avec audit éco-conception intégré
green-claude --file src/app.js --eco-check "Analyse ce code"

# Audit seul, sans appel à l'IA (zéro token)
green-claude --file src/app.js --eco-check

# Audit avec le référentiel complet RGESN/GR491
green-claude --file src/app.js --rules rules/ecoconception.json --eco-check

# Consulter toutes les règles et pratiques disponibles
green-claude --list-rules

# Voir les modèles recommandés par niveau de complexité
green-claude --list-models
```

Toutes les options : `green-claude --help`.

---

## 🍃 Volet 1 — Utiliser Claude sobrement

Quatre leviers automatiques, appliqués par le wrapper avant chaque requête :

### 1. Le bon modèle pour la bonne tâche

| Complexité | Modèle | Usage type |
|---|---|---|
| `simple` | Claude Haiku | Questions simples, reformulations, corrections de syntaxe |
| `medium` (défaut) | Claude Sonnet | La plupart des tâches de code |
| `complex` | Claude Opus | Raisonnement profond, problèmes difficiles |

**Nuance importante** : la sobriété, c'est l'*adéquation*, pas le minimum systématique. Un petit modèle qui échoue et fait recommencer trois fois consomme plus qu'un grand modèle qui réussit du premier coup. En cas de doute sur une tâche complexe, montez en gamme.

### 2. Limiter les données envoyées

Chaque octet envoyé devient des tokens traités par le modèle. Par défaut : **10 Ko par fichier, 500 Ko au total, 5 fichiers maximum** (configurable). Cela incite aussi à ne joindre que le code pertinent plutôt que des répertoires entiers.

### 3. Heures creuses

Entre **22h et 6h UTC**, le réseau électrique est généralement moins carboné et les data centers moins sollicités. Le wrapper vous avertit en heure de pointe — libre à vous de continuer ou de planifier le travail lourd la nuit (`crontab` + `--ignore-offpeak`).

### 4. Cache local des réponses

Une question déjà posée est servie depuis le cache local : **zéro appel, zéro token**. Désactivable avec `--no-cache`.

À ces leviers automatiques s'ajoutent les **12 pratiques de sobriété** de `rules/boris.json` (voir [plus bas](#-les-12-pratiques-de-sobriété-claude-code-boris-cherny)) : des habitudes d'utilisation qui réduisent les tokens gaspillés en contexte pollué, en allers-retours et en re-explications.

---

## 🌍 Volet 2 — Faire produire du code sobre

Le code généré par Claude sera exécuté des millions de fois, chez des milliers d'utilisateurs, pendant des années : **c'est là que se joue l'essentiel de l'empreinte**. Green Claude fournit des règles d'éco-conception alignées sur les référentiels publics, utilisables de deux façons :

### a) Auditer le code (détection automatique)

```bash
green-claude --file src/app.js --rules rules/ecoconception.json --eco-check
```

L'audit détecte dans le code les motifs contraires à l'éco-conception (`SELECT *`, bibliothèques lourdes, autoplay, boucles imbriquées…) et affiche pour chaque problème le critère RGESN correspondant et la recommandation.

### b) Guider Claude en amont (prévention)

Injectez les règles dans le contexte de Claude pour qu'il produise directement du code éco-conçu — c'est plus sobre que corriger après coup :

```bash
# Ponctuellement : joindre les règles à la requête
green-claude --file rules/ecoconception.json "Applique ces règles d'éco-conception \
  en écrivant le composant de galerie d'images"
```

Ou durablement, dans le `CLAUDE.md` de votre projet :

```markdown
## Éco-conception
Applique les règles de ~/green-claude/rules/ecoconception.json à tout code produit :
privilégier la solution la plus simple, pas de bibliothèque lourde pour un besoin
mineur, requêtes SQL optimisées, images WebP/AVIF, pas d'autoplay, lazy loading.
Signale tout arbitrage contraire à ces règles.
```

Ainsi Claude **applique lui-même les bonnes pratiques** à chaque génération de code — la boucle est bouclée.

### Les règles : 35 règles alignées sur les 9 familles du RGESN 2024

`rules/ecoconception.json` couvre les **9 familles** du [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) (78 critères officiels). Chaque règle référence le ou les critères RGESN correspondants (`rgesn_ref`) et la famille [GR491](https://gr491.isit-europe.org/) (`gr491_famille`) :

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

La famille 9 (nouveauté RGESN 2024) est le pont entre les deux volets : ses critères sur l'IA frugale sont précisément ce que le wrapper applique (dimensionner le modèle = `--complexity`, mesurer = suivi des tokens, alternatives sobres = cache).

`rules/basic.json` (15 règles) est le sous-ensemble pédagogique de démarrage, sans dépendance à un référentiel.

---

## 🧠 Les 12 pratiques de sobriété Claude Code (Boris Cherny)

[Boris Cherny](https://howborisusesclaudecode.com/) est le créateur de Claude Code chez Anthropic. Ses conseils d'utilisation visent d'abord l'efficacité — mais **un usage efficace de l'IA est aussi un usage sobre** : chaque aller-retour évité, chaque contexte allégé, chaque re-prompt supprimé économise des tokens, donc du calcul, donc de l'énergie.

Nous avons sélectionné et reformulé 12 de ses pratiques sous l'angle sobriété. Chacune est documentée dans `rules/boris.json` avec le principe d'origine, l'explication « pourquoi c'est sobre » et le geste concret.

### Gérer le contexte

Le contexte est retraité (et facturé) **à chaque tour** de conversation : c'est le poste de gaspillage n°1.

| # | Pratique | Le geste |
|---|---|---|
| 1 | **Minimalisme de contexte** | Prompt minimal + un moyen pour Claude d'aller chercher le contexte lui-même. Ne pas coller des fichiers entiers qu'il peut lire au besoin. |
| 2 | **Rembobiner plutôt que corriger** | Une erreur ? `/rewind` (double Échap) puis re-prompt propre — la tentative ratée ne reste pas dans le contexte à être refacturée à chaque tour. |
| 3 | **`/clear` vs `/compact`** | Nouvelle tâche → `/clear` (repartir de zéro). Tâche liée → `/compact <consigne>` (résumé orienté : « garde le refactor d'auth, jette le débogage »). |
| 4 | **Compacter avant la dégradation** | Sur les longues sessions, la qualité chute vers 300-400k tokens. Compacter proactivement évite le double gaspillage contexte dégradé + reprises. |

### Préparer la tâche

| # | Pratique | Le geste |
|---|---|---|
| 5 | **Le brief complet dès le premier message** | Objectif + contraintes + critères d'acceptation. Un brief incomplet = clarifications, reprises, corrections — chacune refacture tout le contexte. |
| 6 | **Déléguer, pas micro-piloter** | Un brief net puis laisser travailler, plutôt que corriger étape par étape : moins d'interruptions = moins de tours = moins de tokens. |

### Capitaliser — ne jamais payer deux fois

| # | Pratique | Le geste |
|---|---|---|
| 7 | **Écrire la règle, pas re-corriger** | Après chaque erreur : « Ajoute une règle dans CLAUDE.md pour ne plus refaire ça. » La correction conversationnelle répare une fois ; la règle écrite répare pour toujours. |
| 8 | **Une skill pour tout ce qui se répète** | Un workflow utilisé plus d'une fois par jour devient une slash command ou une skill en git : écrite une fois, invoquée en quelques tokens. |

### Vérifier pour ne pas refaire

| # | Pratique | Le geste |
|---|---|---|
| 9 | **Donner à Claude un moyen de vérifier son travail** | Tests, commande bash, navigateur : « la chose la plus importante » selon Boris Cherny — qualité ×2-3, donc autant de cycles de correction en moins. |

### Proportionner la puissance

| # | Pratique | Le geste |
|---|---|---|
| 10 | **Adapter le niveau d'effort** | `/effort low` pour le simple, `high` pour le complexe, `max` en dernier recours. L'optimum écologique est l'adéquation, pas le minimum. |
| 11 | **Pas de panel d'agents pour une petite tâche** | « La plupart des tâches de code n'ont pas besoin d'un panel de 5 relecteurs. » Réserver les workflows multi-agents aux tâches larges, fixer des budgets de tokens, surveiller `/usage`. |
| 12 | **`--bare` pour les scripts** | Les appels scriptés (`claude -p --bare`) ne chargent pas le contexte projet : démarrage 10× plus rapide et tokens économisés à chaque exécution. |

Consultez le détail complet (principes sourcés, explications) : `green-claude --list-rules` ou directement [`rules/boris.json`](rules/boris.json).

---

## ✍️ Écrire ses propres règles

Ajoutez un fichier JSON dans `rules/`. Deux structures acceptées :

```json
{
  "metadata": { "name": "Mes règles", "count": 1 },
  "rules": [
    {
      "id": "CUSTOM-001",
      "title": "Ma règle",
      "impact": "Élevé",
      "patterns": ["mon_motif_regex"],
      "recommendation": "Quoi faire à la place."
    }
  ]
}
```

Ou la structure par catégories (voir `rules/ecoconception.json`). Règles du format :

- `patterns` : expressions régulières `grep -E` détectant le problème. **Liste vide = pratique** (checklist, ignorée par l'audit).
- `impact` : `Élevé`, `Moyen` ou `Faible` — colore la sortie de l'audit.
- `rgesn_ref` / `gr491_famille` (optionnels) : renvoi vers les référentiels officiels.

Puis : `green-claude --file src/ --rules rules/mes-regles.json --eco-check`

En mode basique (sans jq), ajoutez une ligne au tableau `BASIC_RULES` du script :

```bash
BASIC_RULES+=("mon_motif:Ma Catégorie:Ma recommandation")
```

---

## 🔧 Configuration

Les limites se modifient en tête du script `green-claude` :

```bash
MAX_FILE_SIZE=10240    # 10 Ko par fichier
MAX_TOTAL_SIZE=524288  # 500 Ko au total
MAX_FILES=5
OFFPEAK_START=22       # heures creuses (UTC)
OFFPEAK_END=6
```

---

## 🤝 Contribuer

1. **Fork** ce dépôt
2. Créez une branche (`git checkout -b feature/ma-regle`)
3. Ajoutez vos règles ou améliorations (avec `jq empty rules/*.json` pour valider le JSON)
4. Ouvrez une **Pull Request**

Les contributions les plus utiles : nouvelles règles d'audit sourcées (RGESN, GR491, GSF) avec leur `rgesn_ref`, corrections de patterns (faux positifs), traductions.

---

## 🙏 Références

- [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) — Référentiel Général d'Écoconception de Services Numériques (78 critères, 9 familles)
- [GR491](https://gr491.isit-europe.org/) — Guide de référence de conception responsable de services numériques (61 recommandations, 516 critères)
- [Green Software Foundation](https://greensoftware.foundation/) — Patterns d'éco-conception logicielle
- [How Boris uses Claude Code](https://howborisusesclaudecode.com/) — Les pratiques de Boris Cherny, créateur de Claude Code
- [Anthropic](https://www.anthropic.com/) — Claude et Claude Code

## 📄 Licence

[MIT](LICENSE) — © 2026 Institut du Numérique Responsable
