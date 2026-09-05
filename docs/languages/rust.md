# Ecodesign for Rust

**Version:** 1.0.0 | **Rules:** 7 | **Extensions:** rs

Ecodesign rules for Rust code: allocations under control, iterators without materialisation, non-blocking async, sober dependencies.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/rust.json` |
| **Globs** | `**/*.rs` |
| **Extensions** | `rs` |
| **Rule Count** | 7 |

## Rules by Category

### Rust — allocations and copies

Rust is sober by design; the point is not to squander that advantage (RGESN Algorithms, GR491_Backend_4).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-RS-01 | Medium | Convenience clone() | Borrow (&) when ownership is not required; Cow<str> for the sometimes-owned cases; expose &str and &[T] in signatures. |
| ECO-RS-02 | Medium | Intermediate collect() in an iterator chain | Chain the iterators without an intermediate collect; materialise only the final result, with with_capacity when the size is known. |
| ECO-RS-03 | Low | Vec with no pre-reserved capacity | Vec::with_capacity(n) when the size is predictable; reuse buffers in hot loops (clear() keeps the capacity). |

### Rust — async and I/O

Do not block the executor, reuse clients, bound the queues (RGESN Backend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-RS-04 | High | Blocking call inside an async task | spawn_blocking or a dedicated thread for long CPU work; tokio::time::sleep on the async side; buffered I/O (BufReader/BufWriter) and streaming for large volumes. |
| ECO-RS-05 | Medium | Network client created per request | Create the client once and clone it (the pool is shared); bounded channels and caches to avoid uncontrolled memory growth. |

<details>
<summary>Example for ECO-RS-04</summary>

**Before:**
```
async fn run() { std::thread::sleep(d); }
```

**After:**
```
async fn run() { tokio::time::sleep(d).await; }
```

</details>

### Rust — dependencies and build

Lighten the dependency graph and avoid needless restarts (RGESN Architecture/Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-RS-06 | Medium | unwrap() on an expected error path | Handle the error (Result, ?) on expected paths; keep unwrap for invariants that are genuinely guaranteed. |
| ECO-RS-07 | Low | Unjustified dependency graph | Justify each crate, disable unused features (default-features = false), check with cargo tree; build production with --release. |

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)