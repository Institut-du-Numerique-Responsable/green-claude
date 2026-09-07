# Ecodesign for Vue

**Version:** 1.0.0 | **Rules:** 2 | **Extensions:** vue

Ecodesign rules for Vue: computed over watchers, lazy routes, shallow state for large data.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/vue.json` |
| **Globs** | `**/*.vue` |
| **Extensions** | `vue` |
| **Rule Count** | 2 |

## Rules by Category

### Vue — reactivity

Deep reactivity on a large object costs on every read and every write (RGESN Frontend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-VUE-01 | Medium | Deep watcher on a large object | Watch the specific property that matters, or derive the value with computed. Use shallowRef for large immutable payloads. |
| ECO-VUE-02 | High | Route loaded eagerly | Load routes with a dynamic import so each page arrives when someone navigates to it. |

<details>
<summary>Example for ECO-VUE-02</summary>

**Before:**
```
import Dashboard from '../views/Dashboard.vue'
```

**After:**
```
const Dashboard = () => import('../views/Dashboard.vue')
```

</details>

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)