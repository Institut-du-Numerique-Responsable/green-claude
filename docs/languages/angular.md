# Ecodesign for Angular

**Version:** 1.0.0 | **Rules:** 3 | **Extensions:** ts, tsx

Ecodesign rules for Angular: OnPush change detection, lazy routes, subscriptions torn down.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/angular.json` |
| **Globs** | `**/*.ts` |
| **Extensions** | `ts, tsx` |
| **Rule Count** | 3 |

## Rules by Category

### Angular — change detection

Default change detection re-checks every binding on every event (RGESN Frontend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-NG-01 | Medium | Component without OnPush | Set changeDetection: ChangeDetectionStrategy.OnPush and drive updates through immutable inputs or signals. Verify the check frequency with the profiler. |
| ECO-NG-02 | Medium | Method called from a template | Precompute the value in the component, or expose it as a pipe with pure: true so the result is cached. |
| ECO-NG-03 | High | Subscription never torn down | Prefer the async pipe, which unsubscribes for you. Otherwise take until a destroy subject and complete it in ngOnDestroy. |

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)