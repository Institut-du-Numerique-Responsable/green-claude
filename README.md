# 🌱 Green Claude — Sobriété numérique pour Claude Code

**Green Claude** est un wrapper éco-responsable pour [Claude Code](https://claude.com/claude-code) : il réduit l'empreinte environnementale de vos requêtes IA (choix du modèle, limitation des données envoyées, cache, heures creuses) et audite votre code avec des règles d'**éco-conception** issues des référentiels **RGESN**, **GR491** et **Green Software Foundation**.

Un projet de l'[Institut du Numérique Responsable](https://github.com/Institut-du-Numerique-Responsable), sous licence MIT.

> **Moins de tokens = moins de calcul = moins d'énergie = moins de CO₂.**

---

## Sommaire

- [Pourquoi ce projet](#-pourquoi-ce-projet)
- [Installation](#-installation)
- [Utilisation](#-utilisation)
- [Les quatre leviers de sobriété](#-les-quatre-leviers-de-sobriété)
- [Les règles d'éco-conception](#-les-règles-déco-conception)
- [Les 12 pratiques de sobriété Claude Code (Boris Cherny)](#-les-12-pratiques-de-sobriété-claude-code-boris-cherny)
- [Écrire ses propres règles](#-écrire-ses-propres-règles)
- [Configuration](#-configuration)
- [Contribuer](#-contribuer)

---

## 🎯 Pourquoi ce projet

L'IA générative consomme de l'énergie à chaque requête, et cette consommation croît avec :

- **la taille du modèle** utilisé (un grand modèle pour une question triviale = gaspillage),
- **la quantité de tokens** traités (contexte, fichiers joints, allers-retours),
- **le moment** de la requête (le mix électrique varie selon l'heure),
- **la répétition** (la même question posée deux fois = deux fois le coût).

Green Claude agit sur ces quatre leviers, et ajoute un **audit d'éco-conception** de votre code pour que le logiciel produit soit lui aussi sobre.

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

# Audit avec le référentiel complet RGESN/GR491/GSF
green-claude --file src/app.js --rules rules/ecoconception.json --eco-check

# Consulter toutes les règles et pratiques disponibles
green-claude --list-rules

# Voir les modèles recommandés par niveau de complexité
green-claude --list-models
```

Toutes les options : `green-claude --help`.

---

## 🍃 Les quatre leviers de sobriété

### 1. Le bon modèle pour la bonne tâche

Le wrapper choisit le plus petit modèle qui fait bien le travail :

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

---

## 📚 Les règles d'éco-conception

Trois jeux de règles sont fournis dans `rules/`. Deux types de règles cohabitent :

- **Règles d'audit** : elles ont des `patterns` (expressions régulières) et sont détectées automatiquement dans votre code par `--eco-check` ;
- **Pratiques** (marquées `[pratique]` dans `--list-rules`) : des habitudes de conception ou d'usage, non détectables par une regex — elles servent de checklist.

### `rules/basic.json` — 15 règles de base

Le kit de démarrage : les erreurs les plus courantes et les plus coûteuses.

| Exemples | Impact |
|---|---|
| `SELECT *` au lieu de colonnes explicites | Élevé |
| Boucles imbriquées O(n²) sur de gros volumes | Élevé |
| lodash/moment importés pour trois fonctions | Élevé |
| Scripts de tracking superflus | Élevé |
| Images non optimisées, animations permanentes | Moyen |

### `rules/ecoconception.json` — 21 règles RGESN / GR491 / GSF

Le référentiel complet, organisé selon le cycle de vie du service :

| Catégorie | Contenu |
|---|---|
| **Stratégie & Gouvernance** | Mesurer avant d'optimiser, critères environnementaux dans les user stories |
| **Conception** | Low-tech d'abord, fonctionnalités limitées au nécessaire, formats ouverts, durabilité |
| **Développement** | SQL optimisé, pools de connexions, complexité algorithmique, dépendances, lazy loading |
| **Exploitation** | Hébergement sobre, compression HTTP, cache HTTP |
| **Contenus & Interface** | Images, vidéos sans autoplay, polices système, tracking minimal, SVG, HTML/CSS avant JS |

Sources : [RGESN](https://ecologie.numerique.gouv.fr/rg-esn/) (référentiel officiel français), [GR491](https://gr491.isit-europe.org/) (guide de l'ISIT), [Green Software Foundation](https://greensoftware.foundation/).

### `rules/boris.json` — 12 pratiques de sobriété Claude Code

Voir la section suivante.

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

Les contributions les plus utiles : nouvelles règles d'audit sourcées (RGESN, GR491, GSF), corrections de patterns (faux positifs), traductions.

---

## 🙏 Références

- [RGESN](https://ecologie.numerique.gouv.fr/rg-esn/) — Référentiel Général d'Écoconception de Services Numériques
- [GR491](https://gr491.isit-europe.org/) — Guide de référence de conception responsable de services numériques (ISIT)
- [Green Software Foundation](https://greensoftware.foundation/) — Patterns d'éco-conception logicielle
- [How Boris uses Claude Code](https://howborisusesclaudecode.com/) — Les pratiques de Boris Cherny, créateur de Claude Code
- [Anthropic](https://www.anthropic.com/) — Claude et Claude Code

## 📄 Licence

[MIT](LICENSE) — © 2026 Institut du Numérique Responsable
