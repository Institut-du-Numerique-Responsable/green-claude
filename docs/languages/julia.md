# Ecodesign for Julia

**Version:** 1.0.0 | **Rules:** 3 | **Extensions:** jl

Ecodesign rules for Julia code: type stability, allocations under control, bounded threading.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/julia.json` |
| **Globs** | `**/*.jl` |
| **Extensions** | `jl` |
| **Rule Count** | 3 |

## Rules by Category

### Julia — allocations and types

Type instability and hidden allocations dominate the cost of a hot function (RGESN Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-JULIA-01 | High | Global variable read from a hot function | Pass the value as an argument, or declare it const when it genuinely never changes. Check with @code_warntype before optimising anything else. |
| ECO-JULIA-02 | Medium | Array grown by push! in a loop | Preallocate with sizehint! or Vector{T}(undef, n) when the size is known, and mutate in place. Reuse the buffer across iterations. |
| ECO-JULIA-03 | Medium | Threading without a bound | Measure the sequential version first, then size the parallelism to the work per item and to what the machine can spare. Compile and warm up before comparing steady-state timings. |

<details>
<summary>Example for ECO-JULIA-02</summary>

**Before:**
```
r = []
for x in xs; push!(r, f(x)); end
```

**After:**
```
r = Vector{Float64}(undef, length(xs))
@inbounds for i in eachindex(xs); r[i] = f(xs[i]); end
```

</details>

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)