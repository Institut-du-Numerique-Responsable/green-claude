# Ecodesign for Scala

**Version:** 1.0.0 | **Rules:** 3 | **Extensions:** scala, sc

Ecodesign rules for Scala code: lazy transformations, bounded parallelism, no needless materialisation.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/scala.json` |
| **Globs** | `**/*.{scala,sc}` |
| **Extensions** | `scala, sc` |
| **Rule Count** | 3 |

## Rules by Category

### Scala — collections and evaluation

Do not materialise what you only traverse once (RGESN Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SCALA-01 | Medium | Chained transformations materialised at each step | Use .iterator or .view for the chain and materialise only the final result. On a small collection the strict version stays clearer. |
| ECO-SCALA-02 | Medium | Parallel collection without measurement | Stay sequential by default. Parallelise only after a benchmark, on a pool you sized yourself. |
| ECO-SCALA-03 | High | Future built eagerly in a loop | Bound the concurrency explicitly, with a throttled traverse or a semaphore, so the number in flight stays a decision rather than a consequence of the list length. |

<details>
<summary>Example for ECO-SCALA-01</summary>

**Before:**
```
xs.map(_.id).filter(_ > 0).map(fetch)
```

**After:**
```
xs.iterator.map(_.id).filter(_ > 0).map(fetch).toList
```

</details>

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)