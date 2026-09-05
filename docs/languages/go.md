# Ecodesign for Go

**Version:** 1.0.0 | **Rules:** 6 | **Extensions:** go

Ecodesign rules for Go code: bounded goroutines, released resources, streamed bodies, reused clients, no polling.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/go.json` |
| **Globs** | `**/*.go` |
| **Extensions** | `go` |
| **Rule Count** | 6 |

## Rules by Category

### Go — concurrency

Every goroutine needs a way to end, every pool a bound (RGESN Algorithms, GR491_Backend_4).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-GO-01 | High | Goroutine with no way to stop | Give every goroutine a termination path: a context you propagate, a bounded worker pool, or an errgroup you wait on. Bound the queue that feeds it as well. |
| ECO-GO-02 | Medium | Blocking sleep used as a scheduler | Drive the work from an event: a channel, a ticker you can stop, a webhook, a queue. Where polling is unavoidable, widen the interval and document the stop condition. |

<details>
<summary>Example for ECO-GO-01</summary>

**Before:**
```
go func() { work() }()
```

**After:**
```
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error { return work(ctx) })
```

</details>

### Go — resources and I/O

Release what you open, stream what is large, reuse what is costly to build (RGESN Backend/Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-GO-03 | High | Response body never closed | defer resp.Body.Close() right after checking the error, on every path including the ones that return early. |
| ECO-GO-04 | Medium | Whole body read into memory | Decode straight from the reader (json.NewDecoder(resp.Body)), copy with io.Copy, or bound the read with io.LimitReader. |
| ECO-GO-05 | Medium | HTTP client built per call | Build one client at package or service level, with timeouts and transport limits, and share it. It is safe for concurrent use. |
| ECO-GO-06 | Medium | Outbound request with no deadline | Use http.NewRequestWithContext with a context.WithTimeout, and set the client's own Timeout as a backstop. |

<details>
<summary>Example for ECO-GO-03</summary>

**Before:**
```
resp, _ := http.Get(url)
```

**After:**
```
resp, err := client.Do(req)
if err != nil { return err }
defer resp.Body.Close()
```

</details>

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)