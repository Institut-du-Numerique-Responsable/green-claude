# Ecodesign for SQL and PL/SQL

**Version:** 1.0.0 | **Rules:** 11 | **Extensions:** sql, pks, pkb, prc, fnc, trg

Ecodesign rules for SQL and PL/SQL: sober reads, indexes and sargability, set-based processing, data lifecycle.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/sql.json` |
| **Globs** | `**/*.{sql,pks,pkb,prc,fnc,trg}` |
| **Extensions** | `sql, pks, pkb, prc, fnc, trg` |
| **Rule Count** | 11 |

## Rules by Category

### SQL — sober reads

Read and transfer only the rows and columns you need (RGESN Backend, GR491_Backend_1).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SQL-01 | High | SELECT * exposed | List explicitly the columns the need requires. |
| ECO-SQL-02 | Medium | OFFSET pagination | Cursor or keyset pagination: WHERE id > :last_id ORDER BY id LIMIT n. |
| ECO-SQL-03 | High | Non-sargable predicate | Rewrite the predicate against the raw column (a date range, a direct comparison) or create a dedicated functional index. |
| ECO-SQL-04 | Medium | SELECT DISTINCT hiding a join | Check the cardinality of the joins; prefer EXISTS over IN (subquery) on large volumes. |
| ECO-SQL-05 | High | Missing index on filtered columns | Check the execution plan; index the frequently filtered columns, without duplicating an existing index (each one costs on every write). |

<details>
<summary>Example for ECO-SQL-01</summary>

**Before:**
```
SELECT * FROM commandes;
```

**After:**
```
SELECT id, client_id, total FROM commandes;
```

</details>

<details>
<summary>Example for ECO-SQL-03</summary>

**Before:**
```
WHERE DATE(created_at) = '2026-09-05'
```

**After:**
```
WHERE created_at >= '2026-09-05' AND created_at < '2026-09-06'
```

</details>

### SQL — writes and processing

Work set-based and in slices rather than row by row (RGESN Backend/Architecture).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SQL-06 | High | Row-by-row processing (cursor or loop) | UPDATE ... WHERE, INSERT ... SELECT or MERGE in one statement; failing that, BULK COLLECT (with LIMIT) and FORALL in PL/SQL. |
| ECO-SQL-07 | Medium | COMMIT per row | COMMIT in sized batches (a few thousand rows), with bounded transactions. |
| ECO-SQL-08 | Medium | Mass delete or purge in a single statement | Purge in chunks with pauses; consider TRUNCATE or partitioning where the semantics allow. |
| ECO-SQL-09 | Low | Row-by-row logging in production | Log in batches or at the end of the job; keep production levels sober. |

<details>
<summary>Example for ECO-SQL-06</summary>

**Before:**
```
FOR r IN (SELECT id FROM t) LOOP
  UPDATE t SET x = 1 WHERE id = r.id;
END LOOP;
```

**After:**
```
UPDATE t SET x = 1 WHERE id IN (SELECT id FROM t);
```

</details>

### SQL — data lifecycle

Store less, and plan the end of life from the moment you create it (RGESN 7.3, GR491_Architecture_3/5).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SQL-10 | Low | Oversized types by default | Size the types to the real need (no BIGINT when INT is enough, no TEXT by default). |
| ECO-SQL-11 | High | No retention policy | Define retention and purge at creation time; plan partitioning or archiving for fast-growing tables. |

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)