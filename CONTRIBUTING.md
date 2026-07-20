# Contribuer à Green Claude

Merci de l'intérêt porté à ce projet. Les contributions les plus utiles sont les nouvelles règles d'audit sourcées, les corrections de faux positifs et les traductions.

## Avant de commencer

1. Forkez ce dépôt.
2. Créez une branche : `git checkout -b feature/ma-regle`.
3. Installez `jq` si ce n'est pas déjà fait (`brew install jq` / `sudo apt install jq`), utilisé pour valider le JSON des règles et pour le script d'audit.

## Ajouter une règle d'éco-conception

Les règles vivent dans `skill/green-claude/rules/ecoconception.json`, organisées par catégorie (une des 9 familles du RGESN 2024). Chaque règle suit ce format :

```json
{
  "id": "ECO-CATEGORIE-01",
  "title": "Titre court de la règle",
  "description": "Ce que la règle vérifie et pourquoi ça compte.",
  "impact": "Élevé",
  "patterns": ["mon_motif_regex"],
  "recommendation": "Quoi faire à la place.",
  "rgesn_ref": "N.x",
  "gr491_famille": "Nom de la famille GR491",
  "tags": ["mots-clés"]
}
```

- `patterns` : expressions régulières `grep -E` qui détectent le problème dans le code. Une liste vide fait de la règle une checklist de démarche/gouvernance, ignorée par l'audit automatique.
- `impact` : `Élevé`, `Moyen` ou `Faible`.
- `rgesn_ref` renvoie au critère officiel du [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) ; utilisez le format `N.x` si la règle relève d'une famille sans correspondre à un critère unique.
- `gr491_famille` relie la règle au [GR491](https://gr491.isit-europe.org/).
- Sourcez toujours la règle : citez le RGESN, le GR491, le Green Software Foundation, ou une autre référence publique reconnue. Les règles maison sans source ne sont pas acceptées.

## Ajouter une pratique Boris

Les pratiques d'usage sobre de Claude Code vivent dans `skill/green-claude/rules/boris.json`, sur le même principe. Si vous citez un outil tiers en exemple, vérifiez qu'il est open source et sous une licence permissive avant de l'ajouter.

## Corriger un faux positif

Si un pattern regex déclenche l'audit à tort, ouvrez une PR qui resserre l'expression régulière et expliquez le cas limite rencontré dans la description de la PR.

## Vérifier son travail

Avant d'ouvrir une PR :

```bash
jq empty skill/green-claude/rules/*.json
```

Ça valide que le JSON reste bien formé. Testez aussi le script d'audit sur un fichier contenant le motif que vous ciblez :

```bash
./skill/green-claude/scripts/eco-audit.sh chemin/vers/un/fichier
```

## Ouvrir la Pull Request

Décrivez la source de la règle (lien vers le référentiel), l'impact attendu, et un exemple de code qui déclenche (ou corrige) le motif. Une PR par sujet plutôt qu'un gros lot de changements non liés.
