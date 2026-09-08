# Ecodesign for Zig

**Version:** 1.0.0 | **Rules:** 2 | **Extensions:** zig

Ecodesign rules for Zig code: explicit allocator ownership, bounded buffers, tested failure paths.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/zig.json` |
| **Globs** | `**/*.zig` |
| **Extensions** | `zig` |
| **Rule Count** | 2 |

## Rules by Category

### Zig — allocators and buffers

Ownership is explicit in Zig; the cost is paying attention to it (RGESN Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-ZIG-01 | High | Allocation without a matching defer | Pair every alloc with a defer free on the next line, and test the failure path with a failing allocator. |
| ECO-ZIG-02 | High | Unbounded read from external input | Set a maximum sized to what the format actually requires, or read into a fixed buffer in a loop. |

<details>
<summary>Example for ECO-ZIG-01</summary>

**Before:**
```
const buf = try allocator.alloc(u8, n);
```

**After:**
```
const buf = try allocator.alloc(u8, n);
defer allocator.free(buf);
```

</details>

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)