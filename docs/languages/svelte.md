# Ecodesign for Svelte

**Version:** 1.0.0 | **Rules:** 2 | **Extensions:** svelte

Ecodesign rules for Svelte: narrow reactive statements, stores unsubscribed, static rendering where possible.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/svelte.json` |
| **Globs** | `**/*.svelte` |
| **Extensions** | `svelte` |
| **Rule Count** | 2 |

## Rules by Category

### Svelte — reactivity

A reactive statement re-runs whenever anything it touches changes (RGESN Frontend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SVELTE-01 | Medium | Store subscribed without teardown | Use the $store auto-subscription, or keep the returned function and call it in onDestroy. |
| ECO-SVELTE-02 | Low | Broad reactive statement | Keep the statement to the data it needs, and split a wide one into several narrow ones so each re-runs only for its own inputs. |

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)