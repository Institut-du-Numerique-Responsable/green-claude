# Ecodesign for C++

**Version:** 1.0.0 | **Rules:** 6 | **Extensions:** cpp, cc, cxx, hpp, hh

Ecodesign rules for C++ code: copies avoided, suitable containers, RAII, buffered I/O, no busy waiting.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/cpp.json` |
| **Globs** | `**/*.{cpp,cc,cxx,hpp,hh}` |
| **Extensions** | `cpp, cc, cxx, hpp, hh` |
| **Rule Count** | 6 |

## Rules by Category

### C++ — copies and allocations

Copy only what must be copied (RGESN Algorithms, GR491_Backend_4).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-CPP-01 | Medium | Non-trivial object passed by value | Pass by const&; std::move to transfer ownership; non-owning views (std::string_view, std::span) to read without copying. |
| ECO-CPP-02 | Low | vector without reserve() or emplace | reserve() when the size is predictable, emplace_back rather than push_back of a temporary; reuse buffers (clear() keeps the capacity). |
| ECO-CPP-03 | Low | shared_ptr by default | unique_ptr by default, shared_ptr only when ownership is genuinely shared; RAII throughout. |

### C++ — containers and algorithms

Choose the structure that fits the actual access pattern (RGESN 9.1).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-CPP-04 | Medium | Repeated linear search | unordered_map/unordered_set for frequent lookups; STL and ranges algorithms rather than successive copies. |

### C++ — I/O and waiting

Stream, never busy wait (RGESN Backend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-CPP-05 | Medium | File loaded entirely into memory | Buffered, block-based I/O, and streaming for large volumes. |
| ECO-CPP-06 | High | Busy waiting | condition_variable, poll/epoll or async primitives; build production with optimisations and profile before any manual optimisation. |

<details>
<summary>Example for ECO-CPP-06</summary>

**Before:**
```
while (!ready) { std::this_thread::sleep_for(1ms); }
```

**After:**
```
cv.wait(lock, [&]{ return ready; });
```

</details>

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)