---
name: green-claude
description: |
  Use when Claude writes, modifies or reviews code (file formats, network
  requests, images/assets, loops, caching, pagination, dependencies, framework
  or AI model choice), when the user asks for a sobriety audit ("eco-design
  audit", "check this code for sobriety", "--eco-check", "RGESN", "GR491",
  "eco-design", "green IT", "audit éco-conception", "vérifie la sobriété de ce
  code", "écoconception"), or when invoked via /green-claude to walk through the
  rule checklist.
author: Institut du Numérique Responsable
version: 1.4.0
license: MIT
user-invocable: true
---

# Green Claude

Three rule sets: `rules/ecoconception.json` (52 rules, RGESN 2024 / GR491 /
Green Software Foundation) while you write or modify code,
`rules/langages/*.json` (80 rules) for the language you're working in, and
`rules/boris.json` (14 usage practices) during the conversation itself. Using
Claude Code efficiently is also using it soberly.

## Quick reference

| Mode | Trigger | Action |
|---|---|---|
| Proactive (default) | Always, as soon as you write or modify code | Apply the relevant families from `ecoconception.json`, unprompted |
| Audit | "eco-design audit", "check the sobriety", `--eco-check` | `bash <skill-path>/scripts/eco-audit.sh file1 file2 ...` |
| Browse | `/green-claude` | Full checklist of the 9 RGESN families + 14 Boris practices |

## Proactive mode

Keep the 9 families of `ecoconception.json` in mind (strategy, specifications,
architecture, UX, content, frontend, backend, hosting, algorithms). Concretely,
without being asked:

- Prefer open, lightweight formats (JSON/CSV/Markdown over docx/xlsx).
- Limit network requests and payloads (pagination, selected fields, no `SELECT *`).
- Avoid redundant loops and processing, cache what is stable.
- Load and import only what is used (no whole library for one function).
- Compress and correctly size images and assets.

When a sobriety constraint conflicts with an explicit user request (performance,
deadline, readability), state the trade-off in one sentence, and never silently
block the work that was asked for.

For the conversation itself, apply whatever is up to you among the Boris
reflexes: keep the context minimal, don't preload entire files when you can read
them yourself on demand. If a cascade of corrections is building up, suggest the
user rewind (double Esc) instead: it's their move, not yours, but raising it
avoids stacking failed attempts in the context.

## Audit mode

`bash <skill-path>/scripts/eco-audit.sh file1 file2 ...` is a deterministic
script (grep/awk) with no reasoning cost for detection. Interpret and prioritize
its output (High impact first), and read *Common mistakes* below before relaying
a result as-is.

Rules with no detectable pattern ("measure before optimizing", "environmental
criteria in user stories"...) are process rules, listed via
`<skill-path>/scripts/eco-audit.sh --list-rules` rather than searched by grep.

## Language-specific rules

`rules/langages/` holds one file per language (Python, JS/TS, SQL, Java, C#, PHP,
Ruby, Rust, C, C++): the idioms cross-cutting rules cannot name, such as ORM
N+1 queries, cursor-based pagination, `parallelStream()` or convenience
`clone()`. Only consult the file for the language you're working in, never all
ten: the audit already makes that selection from the file extension, and never
applies a Python pattern to Java.

`eco-audit.sh --list-langs` lists the covered languages, `--list-rules <language>`
prints the full checklist for one of them.

## Browse mode (`/green-claude`)

Checklist of the 9 RGESN families and the 14 Boris practices, with each rule's
title and recommendation. Useful for a design review before any code is written.

## Common mistakes

A hit from the audit script is a **candidate**, not a confirmed violation. When a
`Note` line comes with a result, read it before relaying anything to the user: it
explains the precise limit of that rule's pattern or detector (known false
positive, threshold, scope). It lives in the rule itself, so it stays current,
unlike a separate list here that would go stale with every new rule.

## Guaranteed application

Loading this skill remains the model's decision: it happens often, not every
time. For a check that depends on no one, the repository ships
`hooks/green-claude-audit.sh`, wired as `PostToolUse` on `Write|Edit|MultiEdit`.
Claude Code runs it after every code file written and hands you back the patterns
it found. It only audits what the write added, and stays silent when it finds
nothing.

## What this skill does NOT do

The "zero token" response cache cannot be handled by a skill: it has to be wired
through `UserPromptSubmit`/`Stop` hooks, which intercept the request *before* it
reaches the model (see `hooks/` at the repository root). The model choice
(Haiku/Sonnet/Opus) can be changed mid-session with `/model`: this skill won't do
it for you, but nothing stops you from suggesting a lighter model when a task is
plainly out of proportion with it.
