# Ecodesign for Ruby / Rails

**Version:** 1.0.0 | **Rules:** 7 | **Extensions:** rb

Ecodesign rules for Ruby and Rails code: sober ActiveRecord, batched traversal, lazy enumerators, expiring caches.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/ruby.json` |
| **Globs** | `**/*.rb` |
| **Extensions** | `rb` |
| **Rule Count** | 7 |

## Rules by Category

### Ruby — data access (ActiveRecord)

Load only the columns and rows actually used (RGESN Backend, GR491_Backend_2/3).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-RB-01 | High | Whole table walked in memory | find_each/in_batches for large volumes; paginate every exposed list (pagy, kaminari). |
| ECO-RB-02 | Medium | Full objects loaded for a single column | pluck(:col) or select(:col1, :col2); includes/preload/eager_load on the associations you walk, to avoid the N+1. |
| ECO-RB-03 | Low | Counting where an existence test is enough | exists? for an existence test; update_all/insert_all for bulk writes, never save inside a loop. |

<details>
<summary>Example for ECO-RB-01</summary>

**Before:**
```
Order.all.each { |o| process(o) }
```

**After:**
```
Order.find_each(batch_size: 500) { |o| process(o) }
```

</details>

### Ruby — memory and CPU

Avoid intermediate arrays and linear searches (RGESN Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-RB-04 | Medium | Linear search on a large array | Index into a Set or a Hash before the loop. |
| ECO-RB-05 | Low | String concatenation in a loop | Build with << (mutation); lazy enumerators (.lazy) and each_slice for long transformation chains. |

### Ruby — cache, jobs and I/O

Bound caches, do not poll, reuse connections (RGESN Backend/Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-RB-06 | Medium | Cache entry with no expiry | Always pass expires_in; never a constant or class variable that accumulates without limit. |
| ECO-RB-07 | Medium | High-frequency scheduled job | Idempotent, batched jobs; event-driven triggering rather than polling; outbound HTTP connections and the database pool reused. |

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)