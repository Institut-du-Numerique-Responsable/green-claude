# Ecodesign for C

**Version:** 1.0.0 | **Rules:** 6 | **Extensions:** c, h

Ecodesign rules for C code: memory under control, no hidden quadratic pattern, buffered I/O, no busy waiting.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/c.json` |
| **Globs** | `**/*.{c,h}` |
| **Extensions** | `c, h` |
| **Rule Count** | 6 |

## Rules by Category

### C — memory

Allocate for the real need, free on every path (RGESN Algorithms, GR491_Backend_4).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-C-01 | Medium | Dynamic allocation to check | One identified free for every allocation, error paths included; reuse buffers inside loops instead of reallocating. |
| ECO-C-02 | Low | Large memory area copied | Pass a pointer or an index; keep structures compact (types sized to the need, watch padding on massively instantiated structs). |

### C — CPU and algorithms

Avoid hidden quadratic patterns (RGESN 9.1).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-C-03 | High | strlen() in a loop condition | Compute the length once before the loop. |
| ECO-C-04 | Medium | Repeated strcat() | Keep an end pointer or use memcpy with an offset; pick structures suited to the volume (hashing, binary search) rather than repeated linear scans. |

<details>
<summary>Example for ECO-C-03</summary>

**Before:**
```
for (i = 0; i < strlen(s); i++)
```

**After:**
```
size_t n = strlen(s);
for (i = 0; i < n; i++)
```

</details>

### C — I/O and waiting

Batch I/O, never busy wait (RGESN Backend/Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-C-05 | Medium | Byte-by-byte I/O | Use buffered, block-based I/O (fread/fwrite, writev); always close and release resources. |
| ECO-C-06 | High | Busy waiting | Block on poll/epoll/select or a condition variable; build production with -O2 and measure before hand-optimising. |

<details>
<summary>Example for ECO-C-06</summary>

**Before:**
```
while (!ready) { usleep(1000); }
```

**After:**
```
pthread_cond_wait(&cond, &mutex);
```

</details>

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)