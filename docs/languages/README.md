# Language-Specific Eco-Design Rules

This directory contains detailed documentation for each supported language.
Each page lists all rules specific to that language, grouped by category.

## Available Languages

| Language | Rules | File |
|---|---|---|
| [angular](./angular.md) | 3 | `angular.json` |
| [astro](./astro.md) | 2 | `astro.json` |
| [c](./c.md) | 6 | `c.json` |
| [cpp](./cpp.md) | 6 | `cpp.json` |
| [csharp](./csharp.md) | 8 | `csharp.json` |
| [go](./go.md) | 6 | `go.json` |
| [java](./java.md) | 8 | `java.json` |
| [javascript](./javascript.md) | 9 | `javascript.json` |
| [julia](./julia.md) | 3 | `julia.json` |
| [kotlin](./kotlin.md) | 5 | `kotlin.json` |
| [nim](./nim.md) | 3 | `nim.json` |
| [php](./php.md) | 7 | `php.json` |
| [python](./python.md) | 11 | `python.json` |
| [react](./react.md) | 3 | `react.json` |
| [ruby](./ruby.md) | 7 | `ruby.json` |
| [rust](./rust.md) | 7 | `rust.json` |
| [scala](./scala.md) | 3 | `scala.json` |
| [shell](./shell.md) | 6 | `shell.json` |
| [solid](./solid.md) | 2 | `solid.json` |
| [sql](./sql.md) | 11 | `sql.json` |
| [svelte](./svelte.md) | 2 | `svelte.json` |
| [swift](./swift.md) | 5 | `swift.json` |
| [vue](./vue.md) | 2 | `vue.json` |
| [zig](./zig.md) | 2 | `zig.json` |

## How to Use

These pages are automatically generated from the rule files in `skills/green-claude/rules/langages/`.
To regenerate them, run:

```bash
scripts/generate-language-docs.py
```