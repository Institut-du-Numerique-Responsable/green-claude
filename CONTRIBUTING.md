# Contribuer à Green Claude

Merci de l'intérêt porté à ce projet. Les contributions les plus utiles sont les nouvelles règles d'audit sourcées, les corrections de faux positifs et les traductions.

## Avant de commencer

1. Forkez ce dépôt.
2. Créez une branche : `git checkout -b feature/ma-regle`.
3. Installez `jq` si ce n'est pas déjà fait (`brew install jq` / `sudo apt install jq`), utilisé pour valider le JSON des règles et pour le script d'audit.

## Ajouter une règle d'éco-conception

Les règles vivent dans `skills/green-claude/rules/ecoconception.json`, organisées par catégorie (une des 9 familles du RGESN 2024). Chaque règle suit ce format :

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

- `patterns` : expressions régulières `grep -E` qui détectent le problème dans le code. Une liste vide fait de la règle une checklist de démarche/gouvernance, ignorée par l'audit automatique — sauf si un `detector` est défini (voir ci-dessous).
- `detector` (optionnel) : nom d'un détecteur dédié dans `scripts/detect-<nom>.awk`, pour les cas que grep ne peut pas voir car répartis sur plusieurs lignes (ex. `nested_loops` pour les boucles imbriquées). N'utilisez ce mécanisme que si `patterns` ne peut vraiment pas suffire.
- `enrich` (optionnel) : nom d'un script `scripts/inspect-<nom>.sh`, exécuté en plus de `patterns` (pas à la place) quand la règle a matché, pour ajouter une information réelle qu'un pattern texte ne peut pas donner (ex. `image` pour lire le poids/dimensions réels d'un fichier référencé). Doit rester best-effort : ne rien afficher plutôt que d'affirmer quelque chose de non vérifiable (fichier non résolvable, URL distante).
- `note` (optionnel) : mise en garde affichée dans le résultat de l'audit quand la règle matche (ex. faux positif connu, seuil, portée limitée). `eco-audit.sh` affiche `note`, ou à défaut `detector_note`/`enrich_note`, sur une ligne `Note`. Si votre règle a un piège d'interprétation connu, documentez-le ici plutôt que dans `SKILL.md` : l'info doit voyager avec le résultat de l'audit, pas vivre dans une liste séparée à tenir à jour à la main.
- `exclude_patterns` (facultatif) : motifs qui annulent une détection sur la même ligne. La règle ne se déclenche que s'il reste au moins une ligne détectée non exclue. Sert quand le motif cherché apparaît aussi dans du code correct : `Rails.cache.fetch` pose problème sans `expires_in`, pas avec.
- `impact` : `Élevé`, `Moyen` ou `Faible`.
- `rgesn_ref` renvoie au critère officiel du [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) ; utilisez le format `N.x` si la règle relève d'une famille sans correspondre à un critère unique.
- `gr491_famille` relie la règle au [GR491](https://gr491.isit-europe.org/).
- Sourcez toujours la règle : citez le RGESN, le GR491, le Green Software Foundation, ou une autre référence publique reconnue. Les règles maison sans source ne sont pas acceptées.

## Ajouter une règle propre à un langage

Les règles qui ne valent que pour un langage vivent dans `skills/green-claude/rules/langages/`, un fichier par langage (`python.json`, `sql.json`, `java.json`…). Même format de règle que ci-dessus, avec un bloc `metadata` qui déclare le périmètre :

```json
{
  "metadata": {
    "name": "Éco-conception Go",
    "description": "Ce que couvre le fichier.",
    "version": "1.0.0",
    "globs": "**/*.go",
    "extensions": ["go"],
    "count": 6,
    "type": "code_audit"
  },
  "categories": { }
}
```

Pour un nouveau langage, associez aussi l'extension dans `lang_file_for_ext()` (`skills/green-claude/scripts/eco-audit.sh`), sinon l'audit ne chargera jamais le fichier.

Ces règles ne sont testées que sur les fichiers de leur langage, ce qui autorise des motifs précis (`\\.iterrows\\(\\)`, `\\.parallelStream\\(\\)`) sans risque pour les autres. Écrivez-les pour ce langage seulement.

## Ajouter une pratique Boris

Les pratiques d'usage sobre de Claude Code vivent dans `skills/green-claude/rules/boris.json`, sur le même principe. Si vous citez un outil tiers en exemple, vérifiez qu'il est open source et sous une licence permissive avant de l'ajouter.

## Corriger un faux positif

Si un pattern regex déclenche l'audit à tort, ouvrez une PR qui resserre l'expression régulière et expliquez le cas limite rencontré dans la description de la PR.

## Vérifier son travail

Avant d'ouvrir une PR :

```bash
jq empty skills/green-claude/rules/*.json skills/green-claude/rules/langages/*.json
```

Ça valide que le JSON reste bien formé. Testez aussi le script d'audit sur un fichier contenant le motif que vous ciblez :

```bash
./skills/green-claude/scripts/eco-audit.sh chemin/vers/un/fichier
```

Si vous touchez à `eco-audit.sh`, `detect-nested-loops.awk` ou aux règles avec pattern/detector, faites aussi tourner la suite de tests dédiée — elle vérifie les cas positifs, les faux positifs à éviter, et la cohérence de `--list-rules` :

```bash
bash skills/green-claude/scripts/test-eco-audit.sh
```

## Ouvrir la Pull Request

Décrivez la source de la règle (lien vers le référentiel), l'impact attendu, et un exemple de code qui déclenche (ou corrige) le motif. Une PR par sujet plutôt qu'un gros lot de changements non liés.

## Publier une release

Les tags suivent la convention `green-claude--v<version>`, posée via la commande officielle du CLI plutôt qu'à la main :

```bash
claude plugin tag --push
```

Elle valide que `version` dans `.claude-plugin/plugin.json` et l'entrée correspondante dans `.claude-plugin/marketplace.json` sont cohérentes avant de créer et pousser le tag. Les tags `v1.0.0`/`v1.0.1`, antérieurs à la restructuration en plugin, ne suivent pas cette convention — ne pas la reprendre pour les prochaines releases.
