# Ecodesign for Nim

**Version:** 1.0.0 | **Rules:** 3 | **Extensions:** nim

Ecodesign rules for Nim code: bounded compile-time work, no needless sequence copies, deterministic cleanup.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/nim.json` |
| **Globs** | `**/*.nim` |
| **Extensions** | `nim` |
| **Rule Count** | 3 |

## Rules by Category

### Nim — memory and build

Keep copies and generated code under control (RGESN Algorithms/Architecture).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-NIM-01 | Medium | Sequence copied instead of borrowed | Take openArray[T] or a var/lent parameter so the caller's memory is used in place, and reserve with newSeqOfCap when the size is known. |
| ECO-NIM-02 | Medium | Resource closed only on the happy path | Wrap the acquisition in a defer or a try/finally so the close runs on every exit path. |
| ECO-NIM-03 | Low | Unbounded compile-time generation | Keep generated code bounded and inspect it when it affects build time or binary size. A template is often enough where a macro was reached for. |

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)