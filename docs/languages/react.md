# Ecodesign for React (and Preact)

**Version:** 1.0.0 | **Rules:** 3 | **Extensions:** jsx, tsx

Ecodesign rules for React and Preact: avoided re-renders, split routes, virtualised lists, cleaned-up effects.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/react.json` |
| **Globs** | `**/*.{jsx,tsx}` |
| **Extensions** | `jsx, tsx` |
| **Rule Count** | 3 |

## Rules by Category

### React — rendering

A re-render that changes nothing still costs a diff on every visitor's device (RGESN Frontend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-REACT-01 | High | Effect without a dependency array | Give every effect its dependency array, and return a cleanup that aborts the request or clears the timer. |
| ECO-REACT-02 | High | Long list rendered in full | Virtualise the list, or paginate it. Give the items stable keys so React can reuse nodes instead of rebuilding them. |
| ECO-REACT-03 | Medium | New object or function passed as a prop | Hoist the value out of the component, or wrap it in useMemo or useCallback when profiling shows the child actually re-renders. |

<details>
<summary>Example for ECO-REACT-01</summary>

**Before:**
```
useEffect(() => { fetchData() })
```

**After:**
```
useEffect(() => { const c = new AbortController(); fetchData(c.signal); return () => c.abort() }, [id])
```

</details>

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)