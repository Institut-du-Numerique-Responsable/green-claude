# Ecodesign for Python

**Version:** 1.0.0 | **Rules:** 11 | **Extensions:** py

Ecodesign rules specific to Python code: sober ORM (Django/SQLAlchemy), generators, vectorisation, bounded caches, reused connections.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/python.json` |
| **Globs** | `**/*.py` |
| **Extensions** | `py` |
| **Rule Count** | 11 |

## Rules by Category

### Python — data access

Django ORM / SQLAlchemy: transfer and materialise only what is needed (RGESN Backend, GR491_Backend_2/3).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-PY-01 | High | N+1 query on a walked queryset | Load the associations you walk with select_related/prefetch_related (Django) or joinedload/selectinload (SQLAlchemy). |
| ECO-PY-02 | High | Unbounded queryset materialised | Paginate every exposed list; stream large volumes with iterator() (Django) or yield_per() (SQLAlchemy). |
| ECO-PY-03 | Medium | Project the fields you need | Use only()/defer()/values()/values_list() (Django) or load_only() (SQLAlchemy) to fetch just the columns you use. |
| ECO-PY-04 | Medium | Group bulk writes | bulk_create/bulk_update (Django), executemany or batched insert() (SQLAlchemy); bound the batch size. |

<details>
<summary>Example for ECO-PY-01</summary>

**Before:**
```
for c in Commande.objects.all():
    print(c.client.nom)
```

**After:**
```
for c in Commande.objects.select_related('client'):
    print(c.client.nom)
```

</details>

<details>
<summary>Example for ECO-PY-02</summary>

**Before:**
```
rows = list(Article.objects.all())
```

**After:**
```
for row in Article.objects.iterator(chunk_size=500): ...
```

</details>

### Python — memory and streams

Do not materialise in memory what can be streamed (RGESN Algorithms, GR491_Backend_4).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-PY-05 | Medium | File read entirely into memory | Iterate the file line by line, or read in blocks (read(size), iter_content) for large volumes. |
| ECO-PY-06 | High | pandas: row-by-row loop instead of vectorising | Vectorise with numpy and pandas operations; cut memory with suitable dtypes (category, short integers). |
| ECO-PY-07 | Low | String concatenation in a loop | Accumulate in a list then ''.join(...), or write straight to a stream. |
| ECO-PY-08 | Medium | Membership test on a large list | Index into a set or a dict before the loop (constant-time lookup). |

<details>
<summary>Example for ECO-PY-06</summary>

**Before:**
```
df.apply(lambda r: r.a * r.b, axis=1)
```

**After:**
```
df['a'] * df['b']
```

</details>

### Python — I/O, network and cache

Reuse connections, bound caches, do not poll in a loop (RGESN Backend/Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-PY-09 | Medium | Unbounded cache | Bound and expire every cache: lru_cache(maxsize=N), a TTL on the Redis or Memcached side. |
| ECO-PY-10 | Medium | HTTP connections not reused | Reuse a requests.Session (or a shared httpx client); go async for concurrent I/O. |
| ECO-PY-11 | Medium | Polling loop | Prefer event-driven triggering (webhook, message, notification); failing that, widen the interval substantially. |

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)