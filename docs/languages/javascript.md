# Ecodesign for JavaScript / TypeScript

**Version:** 1.0.0 | **Rules:** 9 | **Extensions:** js, jsx, ts, tsx, mjs, cjs

Ecodesign rules for JS/TS, in the browser as much as in Node.js: dependencies, main thread, streams, bounded caches.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/javascript.json` |
| **Globs** | `**/*.{js,jsx,ts,tsx,mjs,cjs}` |
| **Extensions** | `js, jsx, ts, tsx, mjs, cjs` |
| **Rule Count** | 9 |

## Rules by Category

### JS/TS — dependencies and weight

Every kilobyte shipped is downloaded, parsed and executed on every device (RGESN Frontend, GR491_Frontend_9/10).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-JS-01 | High | Whole-library import | Targeted imports (import { x } from 'lib/x'); native APIs first (fetch, Intl, URL, structuredClone, Date/Temporal) before adding a dependency. |

<details>
<summary>Example for ECO-JS-01</summary>

**Before:**
```
import * as _ from 'lodash'
```

**After:**
```
import debounce from 'lodash/debounce'
```

</details>

### JS/TS — execution

Do not block the main thread or the event loop, and do not burn CPU for nothing (RGESN Frontend/Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-JS-02 | High | Blocking synchronous API | Use the asynchronous variants; move heavy computation off (worker_threads, Web Worker). |
| ECO-JS-03 | High | Periodic polling | SSE or WebSocket when the refresh is genuinely needed, otherwise refresh on user action; suspend when the document is hidden. |
| ECO-JS-04 | Medium | High-frequency event without debouncing | Debounce or throttle the handler, or use IntersectionObserver / ResizeObserver as appropriate. |
| ECO-JS-05 | Medium | Repeated linear search inside a loop | Index into a Map or a Set before the loop. |

<details>
<summary>Example for ECO-JS-02</summary>

**Before:**
```
const data = fs.readFileSync(path)
```

**After:**
```
const data = await fs.promises.readFile(path)
```

</details>

<details>
<summary>Example for ECO-JS-03</summary>

**Before:**
```
setInterval(() => fetch('/api/stats'), 2000)
```

**After:**
```
const es = new EventSource('/api/stats/stream')
document.addEventListener('visibilitychange', () => document.hidden && es.close())
```

</details>

### JS/TS — data, streams and memory

Stream, paginate, cache with an explicit policy, avoid leaks (RGESN Backend/Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-JS-06 | Medium | File or payload loaded entirely into memory | stream/pipeline on Node, ReadableStream in the browser; process in chunks. |
| ECO-JS-07 | Medium | HTTP client instantiated per call | A shared HTTP client with a keep-alive agent; a reused database connection pool. |
| ECO-JS-08 | Medium | Listener never detached | Detach the listener on unmount (effect cleanup, AbortController through the signal option); WeakMap for associations to objects. |
| ECO-JS-09 | Medium | Cache with no bound and no policy | Bound (maximum size) and expire (TTL) every cache; state the invalidation strategy; paginate API responses. |

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)