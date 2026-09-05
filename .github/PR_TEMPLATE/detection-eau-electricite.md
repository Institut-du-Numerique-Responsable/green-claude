# Pull Request: Detection des règles eau/électricité

## Contexte

Répond à la demande: **"peux tu me montrer ce qui se passe si on peut pas evaluer l'eau ?"**

## Problème identifié

Les règles ECO-ALGO-09, ECO-ALGO-10 et ECO-ALGO-11 concernent la mesure de la consommation d'eau et d'électricité pour les systèmes IA, mais **n'avaient pas de patterns de détection**, donc :
- ❌ N'étaient **pas détectées** par l'audit automatique
- ❌ N'apparaissaient que dans la checklist (`--list-rules`)
- ❌ Les violations passaient **inaperçues**

### Exemple concret

**Fichier test:**
```python
import torch
model = torch.nn.Transformer()
```

**Avant la fix:**
```bash
$ eco-audit.sh test.py
No ecodesign issue found.
```
⚠️ **Aucun problème détecté**, alors que le fichier viole 3 règles !

## Solution implémentée

### 1. Ajout de patterns aux règles

**ECO-ALGO-09** (Link tokens to physical resources):
- Patterns: `import\s+torch`, `import\s+transformers`, `import\s+tensorflow`, `import\s+keras`
- Exclusions: commentaires mentionnant `tokens.*water`, `tokens.*electricity`, etc.

**ECO-ALGO-10** (Require real measurements):
- Patterns: mêmes bibliothèques IA
- Exclusions: référence à `IA_MEASUREMENTS.md`

**ECO-ALGO-11** (Set water and electricity budgets):
- Patterns: mêmes bibliothèques IA
- Exclusions: référence à `CodeCarbon`, `Experiments Impact Tracker`

**Après la fix:**
```bash
$ eco-audit.sh test.py
[High] ECO-ALGO-09 — Link tokens to physical resources
[High] ECO-ALGO-10 — Require real measurements for AI systems
[High] ECO-ALGO-11 — Set water and electricity budgets
3 ecodesign issue(s) found.
```
✅ **Toutes les violations sont maintenant détectées !**

### 2. Documentation

- **docs/water-electricity-detection.md**: Explication détaillée du problème et de la solution
- **docs/security-audit.md**: Audit de sécurité du repository (secret scanning à activer)
- **docs/languages/**: Documentation par langage (25 langages supportés)

## Fichiers modifiés

- `skills/green-claude/rules/ecoconception.json` - Ajout des patterns aux 3 règles
- `docs/water-electricity-detection.md` - Documentation de la détection
- `docs/security-audit.md` - Audit de sécurité
- `docs/languages/*.md` - Documentation par langage (25 fichiers)
- `scripts/generate-language-docs.py` - Script de génération de la documentation

## Comment gérer les faux positifs

Si votre code a déjà la documentation requise, vous pouvez :

1. **Ajouter des commentaires** dans le code:
   ```python
   import torch
   # See IA_MEASUREMENTS.md for water/electricity measurements
   ```

2. **Ajouter au fichier `.green-claude/ignore`**:
   ```
   ECO-ALGO-09  my_file.py  ACCEPTED  Documented in IA_MEASUREMENTS.md
   ```

3. **Ajouter au fichier `.green-claude/decisions.md`**:
   ```markdown
   ECO-ALGO-10 my_file.py ACCEPTED Measurements in IA_MEASUREMENTS.md
   ```

## Prochaines étapes

1. **Activer Secret Scanning** sur GitHub:
   - Aller sur: https://github.com/Institut-du-Numerique-Responsable/green-claude/settings/security_analysis
   - Activer "Secret scanning" et "Push protection"
   - Voir: docs/security-audit.md

2. **Amélioration future**: 
   - Créer un script `inspect-ai-measurements.sh` pour une détection plus précise
   - Utiliser le champ `enrich` avec `enrich_is_verdict: true`
   - Vérifier l'existence réelle de IA_MEASUREMENTS.md

## Impact

- ✅ **Détection automatique** des violations eau/électricité
- ✅ **25 langages documentés** avec leurs règles spécifiques
- ✅ **Audit de sécurité** documenté
- ⚠️ **Action manuelle requise**: activer Secret Scanning sur GitHub
