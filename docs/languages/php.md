# Ecodesign for PHP

**Version:** 1.0.0 | **Rules:** 7 | **Extensions:** php

Ecodesign rules for PHP code: sober ORM (Doctrine/Eloquent/PDO), generators, streams, OPcache, reused connections.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/php.json` |
| **Globs** | `**/*.php` |
| **Extensions** | `php` |
| **Rule Count** | 7 |

## Rules by Category

### PHP — data access

Doctrine / Eloquent / PDO: load only what is read (RGESN Backend, GR491_Backend_2/3).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-PHP-01 | High | Unbounded collection loaded | Paginate every exposed list; walk large volumes in batches with chunk()/cursor() (Eloquent) or toIterable() (Doctrine). |
| ECO-PHP-02 | High | Association walked in a loop (N+1) | Eager loading: with() (Eloquent) or a fetch join / DQL join (Doctrine); project the useful columns rather than full entities. |
| ECO-PHP-03 | Medium | Row-by-row writes | Multi-row insert(), upsert() or batches; exists() rather than count() > 0. |

<details>
<summary>Example for ECO-PHP-01</summary>

**Before:**
```
$rows = Order::all();
```

**After:**
```
Order::query()->select('id', 'total')->cursorPaginate(50);
```

</details>

<details>
<summary>Example for ECO-PHP-02</summary>

**Before:**
```
foreach ($orders as $o) { echo $o->customer->name; }
```

**After:**
```
$orders = Order::with('customer')->get();
```

</details>

### PHP — memory and streams

Stream rather than materialise everything (RGESN Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-PHP-04 | Medium | File loaded entirely into memory | Read as a stream (fopen plus block reads), fputcsv and streams for exports; generators (yield) to produce long sequences. |
| ECO-PHP-05 | Medium | Linear search in a large array | Index by key and test with isset($index[$k]) (constant time). |

### PHP — execution and infrastructure

Reuse connections, bound caches, lighten the dependency graph (RGESN Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-PHP-06 | Medium | One HTTP connection per call | A shared, injected HTTP client (Guzzle); persistent PDO connections or a pool, depending on the platform. |
| ECO-PHP-07 | Medium | File cache with no purge | A bounded, expiring cache (APCu, Redis with a TTL); OPcache enabled in production, optimised autoload (composer dump-autoload -o). |

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)