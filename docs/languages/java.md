# Ecodesign for Java

**Version:** 1.0.0 | **Rules:** 8 | **Extensions:** java

Ecodesign rules for Java code: sober JPA/Hibernate, memory, batching, serialisation, logging.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/java.json` |
| **Globs** | `**/*.java` |
| **Extensions** | `java` |
| **Rule Count** | 8 |

## Rules by Category

### Java — data access (JPA / Hibernate / JDBC)

Load only what is needed, in as few round trips as possible (RGESN Backend, GR491_Backend_2/3).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-JAVA-01 | High | findAll() on an unbounded table | Paginate as a matter of course (Pageable, setMaxResults); process large volumes in chunks. |
| ECO-JAVA-02 | High | Lazy association walked in a loop (N+1) | Load the associations you walk explicitly with JOIN FETCH or @EntityGraph; project into a DTO for read-only access. |
| ECO-JAVA-03 | Medium | Writes one entity at a time | JDBC batching (hibernate.jdbc.batch_size, saveAll in slices), Spring Batch for long jobs; size the HikariCP pool to the real need. |

<details>
<summary>Example for ECO-JAVA-01</summary>

**Before:**
```
List<Order> all = repo.findAll();
```

**After:**
```
Page<Order> page = repo.findAll(PageRequest.of(0, 100));
```

</details>

<details>
<summary>Example for ECO-JAVA-02</summary>

**Before:**
```
for (Order o : orders) { o.getCustomer().getName(); }
```

**After:**
```
@Query("select o from Order o join fetch o.customer")
```

</details>

### Java — memory and CPU

Limit allocations, unmeasured parallelism and unbounded caches (RGESN Algorithms, GR491_Backend_4).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-JAVA-04 | Medium | parallelStream() by default | Stay on a sequential stream by default; parallelise only after measurement, on a dedicated pool. |
| ECO-JAVA-05 | Low | String concatenation in a loop | StringBuilder for repeated concatenation; avoid boxing in pipelines (IntStream rather than Stream<Integer>). |
| ECO-JAVA-06 | Medium | Unbounded static cache | Caffeine with maximumSize plus expireAfterWrite, or an external cache with a TTL. |

### Java — APIs, logging and scheduled tasks

Serialise little, log soberly, do not poll (RGESN Backend/Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-JAVA-07 | Low | Concatenated log instead of a parameterised one | Parameterised logging (log.debug("x={}", x)); no logging inside tight loops; sober production levels. |
| ECO-JAVA-08 | Medium | High-frequency scheduled task | Event-driven triggering (listener, message) where possible; failing that, widen the interval and serialise the runs. |

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)