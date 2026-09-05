# Detection of Water and Electricity Measurement Rules

## Problem Statement

The user asked: **"peux tu me montrer ce qui se passe si on peut pas evaluer l'eau ?"**

This document demonstrates what happens when the audit system cannot evaluate water and electricity consumption in AI systems.

## Current Behavior (Before Fix)

Rules ECO-ALGO-09, ECO-ALGO-10, and ECO-ALGO-11 address water and electricity measurement for AI systems:

- **ECO-ALGO-09**: Link tokens to physical resources (water, electricity, hardware)
- **ECO-ALGO-10**: Require real measurements for AI systems
- **ECO-ALGO-11**: Set water and electricity budgets

**Problem**: These rules had **no patterns**, so they were only visible in the checklist (`--list-rules`) but **NOT detected by the automatic audit**.

### Example: File with AI usage but no water/electricity measurement

```python
# test_eau.py
import torch
model = torch.nn.Transformer()
# No water/electricity measurement
```

**Before fix** - Running audit:
```bash
$ eco-audit.sh test_eau.py
No ecodesign issue found in the files analysed.
```

⚠️ **The audit found NOTHING**, even though the file violates all three water/electricity rules!

## Current Behavior (After Fix)

Patterns have been added to detect AI library usage (torch, transformers, tensorflow, keras) for these three rules.

**After fix** - Running audit:
```bash
$ eco-audit.sh test_eau.py
[High] ECO-ALGO-09 — Link tokens to physical resources
  File           : test_eau.py
  Category       : 9. Algorithms (including AI)
  RGESN          : 9.x
  Recommendation : State the direction and refuse the ratio. Fewer tokens processed means less computation, and less computation means less energy and water.

[High] ECO-ALGO-10 — Require real measurements for AI systems
  File           : test_eau.py
  Category       : 9. Algorithms (including AI)
  RGESN          : 9.x
  Recommendation : For every AI implementation, measure and document: (1) tokens processed, (2) CPU/GPU time, (3) electricity consumption, and (4) water usage. Store results in IA_MEASUREMENTS.md.

[High] ECO-ALGO-11 — Set water and electricity budgets
  File           : test_eau.py
  Category       : 9. Algorithms (including AI)
  RGESN          : 9.x
  Recommendation : Define maximum thresholds per project: e.g., < 10L of water/day, < 1kWh/day. Use tools like CodeCarbon or Experiments Impact Tracker.

3 ecodesign issue(s) found.
```

✅ **Now the audit detects all three issues!**

## How to Suppress False Positives

If you have documented your water/electricity measurements, you can:

1. **Add comments** in your code referencing the measurements:
   ```python
   import torch
   # See IA_MEASUREMENTS.md for water/electricity measurements
   # Using CodeCarbon for budget tracking
   ```

2. **Add to `.green-claude/ignore`** file:
   ```
   ECO-ALGO-09  my_ai_file.py  ACCEPTED  Water/electricity documented in IA_MEASUREMENTS.md
   ECO-ALGO-10  my_ai_file.py  ACCEPTED  Measurements stored in IA_MEASUREMENTS.md
   ECO-ALGO-11  my_ai_file.py  ACCEPTED  Budgets defined using CodeCarbon
   ```

3. **Add to `.green-claude/decisions.md`** file:
   ```markdown
   ECO-ALGO-09 my_ai_file.py ACCEPTED Water/electricity link documented
   ECO-ALGO-10 my_ai_file.py ACCEPTED Measurements in IA_MEASUREMENTS.md
   ECO-ALGO-11 my_ai_file.py ACCEPTED Budgets using CodeCarbon
   ```

## Summary

**Before**: Rules without patterns were invisible to the audit → water/electricity violations went undetected.

**After**: Patterns added → audit now detects AI usage without proper water/electricity documentation.

**Next steps**: Consider using `enrich` field with a dedicated inspection script for more precise detection (e.g., check if IA_MEASUREMENTS.md actually exists and contains valid measurements).
