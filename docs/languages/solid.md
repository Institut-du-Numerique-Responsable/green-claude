# Ecodesign for Solid

**Version:** 1.0.0 | **Rules:** 2 | **Extensions:** jsx, tsx

Ecodesign rules for Solid: fine-grained signals, narrow effects, lazy routes.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/solid.json` |
| **Globs** | `**/*.{jsx,tsx}` |
| **Extensions** | `jsx, tsx` |
| **Rule Count** | 2 |

## Rules by Category

### Solid — reactivity

Solid updates the exact node that changed, as long as the dependencies stay narrow (RGESN Frontend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SOLID-01 | Medium | Effect broader than its dependencies | Read only the signals the effect needs, and use createMemo for a derived value several effects share. Verify that an update touches only the intended nodes. |
| ECO-SOLID-02 | Medium | List rendered with map instead of For | Use For for keyed lists and Index when the position is what identifies the row. |

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)