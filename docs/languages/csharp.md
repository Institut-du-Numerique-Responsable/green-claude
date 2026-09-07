# Ecodesign for C# / .NET

**Version:** 1.0.0 | **Rules:** 8 | **Extensions:** cs

Ecodesign rules for C#/.NET code: sober Entity Framework, async end to end, allocations, bounded caches, logging.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/csharp.json` |
| **Globs** | `**/*.cs` |
| **Extensions** | `cs` |
| **Rule Count** | 8 |

## Rules by Category

### C# — data access (EF Core / ADO.NET)

Keep the work in the database and materialise only what is needed (RGESN Backend, GR491_Backend_2/3).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-CS-01 | High | Premature materialisation of an IQueryable | Filter, project and aggregate on the IQueryable before any materialisation; paginate (Skip/Take, or keyset: Where(x => x.Id > lastId).Take(n)). |
| ECO-CS-02 | Medium | Read-only query without AsNoTracking or projection | AsNoTracking() as a matter of course on read-only queries, and a targeted Select(x => new Dto { ... }) rather than cascading Include. |
| ECO-CS-03 | Low | Count() where Any() is enough | Any() for an existence test; avoid enumerating the same IEnumerable several times (materialise once when reused). |

<details>
<summary>Example for ECO-CS-01</summary>

**Before:**
```
var users = db.Users.ToList().Where(u => u.Active);
```

**After:**
```
var users = db.Users.Where(u => u.Active).Select(u => u.Id).Take(100).ToList();
```

</details>

### C# — asynchrony and network

Do not block a thread, reuse connections (RGESN Backend/Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-CS-04 | High | Blocking wait on a task | async/await end to end for every I/O. |
| ECO-CS-05 | Medium | HttpClient instantiated per request | IHttpClientFactory (connections reused); enable response compression and cache headers (ResponseCache, ETag). |
| ECO-CS-06 | Medium | Background service that polls | Event-driven triggering (message, webhook); failing that, widen the interval substantially. |

<details>
<summary>Example for ECO-CS-04</summary>

**Before:**
```
var data = GetAsync().Result;
```

**After:**
```
var data = await GetAsync();
```

</details>

### C# — memory and logging

Limit allocations on hot paths and bound the caches (RGESN Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-CS-07 | Medium | Unbounded static cache | IMemoryCache with SizeLimit/AbsoluteExpiration, or a distributed cache with a TTL. |
| ECO-CS-08 | Low | String concatenation in a loop | StringBuilder for repeated concatenation; Span<T>/Memory<T> for heavy parsing; parameterised structured logging (_logger.LogDebug("x={X}", x)). |

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)