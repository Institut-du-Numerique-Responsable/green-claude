# Ecodesign for Astro

**Version:** 1.0.0 | **Rules:** 2 | **Extensions:** astro

Ecodesign rules for Astro: static by default, the smallest client directive, media optimised at build.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/astro.json` |
| **Globs** | `**/*.astro` |
| **Extensions** | `astro` |
| **Rule Count** | 2 |

## Rules by Category

### Astro — hydration

Every hydrated island ships a runtime the static page did not need (RGESN Frontend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-ASTRO-01 | High | Island hydrated on load | Pick the smallest directive that meets the interaction: client:idle, client:visible, or client:media. Keep client:load for what must be interactive immediately. |
| ECO-ASTRO-02 | Medium | Image used without the build-time pipeline | Use the Image component so the format, the sizes and the dimensions are produced at build time, and keep an accessible alt. |

<details>
<summary>Example for ECO-ASTRO-01</summary>

**Before:**
```
<Carousel client:load />
```

**After:**
```
<Carousel client:visible />
```

</details>

---

[Back to all languages](../README.md) | [Main documentation](../../README.md)