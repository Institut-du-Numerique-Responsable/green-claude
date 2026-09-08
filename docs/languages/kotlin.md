# Ecodesign for Kotlin

**Version:** 1.0.0 | **Rules:** 5 | **Extensions:** kt, kts

Ecodesign rules for Kotlin code, on Android as much as on the server: scoped coroutines, no blocking on a thread, bounded channels and collections.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/kotlin.json` |
| **Globs** | `**/*.{kt,kts}` |
| **Extensions** | `kt, kts` |
| **Rule Count** | 5 |

## Rules by Category

### Kotlin — coroutines and threads

Give every coroutine a lifetime, never block a thread waiting (RGESN Algorithms, GR491_Backend_4).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-KT-01 | High | GlobalScope coroutine | Launch from a scope with a lifetime: viewModelScope, lifecycleScope, or a CoroutineScope you cancel yourself. Cancellation then propagates to the children. |
| ECO-KT-02 | High | Blocking call inside a coroutine | Use delay() in suspending code, and move genuinely blocking work to Dispatchers.IO with withContext. Keep runBlocking for main() and tests. |
| ECO-KT-03 | Medium | Unbounded channel | Size the channel to what the consumer can absorb, and choose the overflow behaviour deliberately (SUSPEND, DROP_OLDEST). |

<details>
<summary>Example for ECO-KT-01</summary>

**Before:**
```
GlobalScope.launch { fetch() }
```

**After:**
```
viewModelScope.launch { fetch() }
```

</details>

<details>
<summary>Example for ECO-KT-02</summary>

**Before:**
```
runBlocking { api.load() }
```

**After:**
```
withContext(Dispatchers.IO) { api.load() }
```

</details>

### Kotlin — collections and allocations

Do not materialise a collection you only walk once (RGESN Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-KT-04 | Medium | Intermediate collection in a chain | Switch the chain to asSequence() when the collection is large, and materialise only the final result. On small collections the plain list stays clearer and cheaper. |
| ECO-KT-05 | Medium | Linear search inside a loop | Index into a Set or a Map before the loop, and look up in constant time. |

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)