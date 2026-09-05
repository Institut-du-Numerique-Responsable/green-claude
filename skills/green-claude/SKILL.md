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

**What this skill is for.** Deliver code that consumes as little as possible:
the fewest tokens during the session, the least CPU time and memory at runtime,
the fewest bytes over the network, the least storage, and therefore the least
energy. That is what digital sobriety means in practice, and it is the reason
every rule below exists. A rule that does not eventually reduce a resource
someone pays for is not worth the context it takes.

The consumption comes in two waves, and the second is the larger one. During the
session, the context you transmit and the output you produce are processed by a
model, which costs computation and the energy behind it. After the session, the
code you leave behind runs on every user's machine, on every request, for years.
Both matter; only one of them stops when the conversation does.

Three rule sets: `rules/ecoconception.json` (83 rules, RGESN 2024 / GR491 /
Green Software Foundation / W3C WSG) while you write or modify code,
`rules/langages/*.json` (127 rules across 24 languages and frameworks) for the language you're
working in, and `rules/usage.json` (15 responsible-use practices) during the
conversation itself. Using Claude Code efficiently is also using it soberly.

## Quick reference

| Mode | Trigger | Action |
|---|---|---|
| Proactive (default) | Always, as soon as you write or modify code | Apply the relevant families from `ecoconception.json`, unprompted |
| Audit | "eco-design audit", "check the sobriety", `--eco-check` | `bash "$SKILL_DIR/scripts/eco-audit.sh" file1 file2 ...` (see *Finding the scripts*) |
| Browse | `/green-claude` | Full checklist of the 9 RGESN families + 15 responsible-use practices |

## Before you write anything

Three rules decide what gets written at all, which makes them worth more than
every optimisation that follows. A function tuned to perfection still costs
everything it cost if it had no reason to exist.

**Ask when the answer changes the work** (`USAGE-BRIEF-03`). Name the assumption
that would reshape the task if it were wrong. If it is genuinely ambiguous, ask
that one question and wait. If it is not, state the assumption in a line and
build. One blocking question beats four that the repository could have answered.

**Write the least code that solves the problem** (`ECO-ARCH-07`). Volume is the
easiest thing to mistake for progress, and an assistant produces it faster than
anyone can read it. Every line is compiled, shipped, loaded, executed, reviewed
and carried through every future migration. When you are about to generalise,
ask which second caller justifies it; with no answer, write the specific
version.

**Challenge the request and the model behind it** (`ECO-ALGO-08`). When a
request names a model or an AI approach, check whether the task needs a model at
all, whether this is the smallest one that clears the quality bar, and whether
the approach is the fitting one or merely the first one to mind. Say what you
would do differently in a sentence or two, give the reason, then build what the
user decides. Someone who has heard the argument and still wants the large model
is making a decision, not a mistake.

That last one is the rule most likely to collide with a direct instruction, so
the order matters: raise it once, take the answer, deliver.

## Proactive mode

Keep the 9 families of `ecoconception.json` in mind (strategy, specifications,
architecture, UX, content, frontend, backend, hosting, algorithms), and read the
rules file for the language you are about to write (see *Language-specific
rules*). Concretely, without being asked:

- Prefer open, lightweight formats (JSON/CSV/Markdown over docx/xlsx).
- Limit network requests and payloads (pagination, selected fields, no `SELECT *`).
- Avoid redundant loops and processing, cache what is stable.
- Load and import only what is used (no whole library for one function).
- Compress and correctly size images and assets.

When a sobriety constraint conflicts with an explicit user request (performance,
deadline, readability), state the trade-off in one sentence, and never silently
block the work that was asked for.

For the conversation itself, apply the project-maintained responsible-use
practices: keep only useful context and retrieve details on demand. Present them
as Green Claude recommendations, not as quotations or personal advice. Verify
client-specific commands against the official documentation for the version in
use.

On the link between tokens and energy: state the direction, refuse the ratio.
Fewer tokens processed means less computation, and less computation means less
energy. That much holds and is worth acting on. Turning a token count into
watts, joules or grams of CO2 does not hold, because prompt caching, model size,
batching, hardware and the grid mix each move the result more than the token
count does. Reduce because the computation is real; measure before you put a
number on it.

## Finding the scripts

Every command below starts from this skill's own directory, the one whose path
was given to you when the skill loaded ("Base directory for this skill: ..."").
Set it once and reuse it, so no command ever contains a guessed path:

```bash
SKILL_DIR="<the base directory given when this skill loaded>"
```

If that path was not given to you, resolve it before running anything, in this
order, and stop at the first hit:

```bash
SKILL_DIR="$(ls -d "$HOME"/.claude/skills/green-claude \
                    "$HOME"/.claude/plugins/*/skills/green-claude \
                    ./skills/green-claude 2>/dev/null | head -1)"
[ -x "$SKILL_DIR/scripts/eco-audit.sh" ] || echo "Green Claude: scripts not found"
```

A path that does not resolve is worth saying out loud. Inventing one produces a
"command not found" that reads like the audit found nothing, which is the one
outcome the user must never be handed.

## Audit mode

`bash "$SKILL_DIR/scripts/eco-audit.sh" file1 file2 ...` is a deterministic
script (grep/awk) with no reasoning cost for detection. Run it rather than
grepping by hand: it carries 225 rules, their thresholds, their per-language
scoping and their known false positives, none of which a hand-written grep
reproduces. Interpret and prioritize its output (High impact first), and read
*Common mistakes* below before relaying a result as-is.

Rules with no detectable pattern ("measure before optimizing", "environmental
criteria in user stories"...) are process rules, listed via
`bash "$SKILL_DIR/scripts/eco-audit.sh" --list-rules` rather than searched by grep.

## Language-specific rules

`rules/langages/` holds one file per language: the idioms cross-cutting rules
cannot name, such as ORM N+1 queries, cursor-based pagination,
`parallelStream()` or a convenience `clone()`. A generic "avoid redundant
queries" never tells you to use `select_related`; the Python file does.

**Read the file for the language you are about to write, before writing it.**
Map the extension, then read that one file:

| Extension | File to read |
|---|---|
| `.py` | `rules/langages/python.json` |
| `.js` `.jsx` `.ts` `.tsx` `.mjs` `.cjs` | `rules/langages/javascript.json` |
| `.sql` `.pks` `.pkb` `.prc` `.fnc` `.trg` | `rules/langages/sql.json` |
| `.java` | `rules/langages/java.json` |
| `.cs` | `rules/langages/csharp.json` |
| `.php` | `rules/langages/php.json` |
| `.rb` | `rules/langages/ruby.json` |
| `.rs` | `rules/langages/rust.json` |
| `.c` `.h` | `rules/langages/c.json` |
| `.cpp` `.cc` `.cxx` `.hpp` `.hh` | `rules/langages/cpp.json` |
| `.go` | `rules/langages/go.json` |
| `.kt` `.kts` | `rules/langages/kotlin.json` |
| `.swift` | `rules/langages/swift.json` |
| `.sh` `.bash` `.zsh` | `rules/langages/shell.json` |
| `.scala` `.sc` | `rules/langages/scala.json` |
| `.jl` | `rules/langages/julia.json` |
| `.nim` | `rules/langages/nim.json` |
| `.zig` | `rules/langages/zig.json` |
| `.jsx` `.tsx` | `javascript.json` + `react.json` + `solid.json` |
| `.ts` | `javascript.json` + `angular.json` |
| `.vue` | `javascript.json` + `vue.json` |
| `.svelte` | `javascript.json` + `svelte.json` |
| `.astro` | `javascript.json` + `astro.json` |

```bash
cat "$SKILL_DIR/rules/langages/python.json"     # or the Read tool, same file
```

Read the file or files for the language actually in play, once per session.
Reading all 24 costs context for the ones you are not writing, and a Python
pattern says nothing useful about Java. Some extensions map to more than one
file, because a `.tsx` is TypeScript and React at once. An extension absent from the table has no
language file: the cross-cutting rules still apply. A `Dockerfile` has no
extension at all and is routed by its name.

`eco-audit.sh --list-langs` lists the covered languages, `--list-rules <language>`
prints the full checklist for one of them.

## Reporting what you find

An audit result is a list of candidates, not a verdict. Deciding which ones hold
is your job, and the user needs to see that decision rather than the raw list.
Give every finding you report one of three verdicts:

| Verdict | Meaning |
|---|---|
| `FAIL` | Confirmed in context. You read the code around it and the defect is real. |
| `REVIEW` | The pattern matched but the context does not settle it. Say what would settle it. |
| `PASS` | Checked and correct. Only worth stating for a rule the user asked about. |

```
FAIL   ECO-BACK-01  views.py:12  N+1: c.client.nom inside the loop over Commande.objects.all()
                    Fix: select_related("client"). Verify: assertNumQueries.
REVIEW ECO-CONT-01  index.html:116  logo.jpg is 1024x529 for a 192x99 display slot
                    Settles it: whether a 2x screen needs the extra resolution.
```

Two things make this worth the keystrokes. A `REVIEW` you cannot resolve is
useful information, whereas a candidate relayed as a defect costs the user time
and costs the audit its credibility. And naming what would settle a `REVIEW`
turns it into a task someone can pick up.

When a rule carries an `example`, the audit prints the corrected form under
`Write`. Use it: it says what the fix looks like rather than describing it, and
it saves rebuilding that shape from the recommendation every time.

## Recording a decision

A candidate you dismiss once will come back on the next run, and the run after
that. Dismissed six times, it teaches everyone to skim past the audit, which
costs more than the rule ever saved.

`.green-claude/decisions.md` at the repository root closes the question:

```
ECO-CONT-01  docs/index.html  ACCEPTED  logo.jpg kept as the og:image fallback
ECO-SH-05    install.sh       TODO      two mktemp with no trap
```

`ACCEPTED` silences that rule for that file, and only there. `TODO` stays
visible, because a debt taken on deliberately is not an exemption. The audit
says how many findings it hid and where the file lives, so nothing disappears
without a trace.

Propose an entry when you and the user settle a trade-off, and read the file
before relaying a finding the team has already answered. Suggest it, and let the
user write it: a decision recorded on their behalf is a decision they never made.

While writing code, stay quiet: apply the rules and mention only what the user
would otherwise be surprised by. One line at the end, naming the rule id, beats
a running commentary on every rule you honoured.

When a rule conflicts with what the user explicitly asked for, state the
trade-off in one sentence, propose the lighter option, and **deliver what was
asked**. A user who requested two-second polling with their eyes open is making
a decision, not a mistake.

## Browse mode (`/green-claude`)

Checklist of the 9 RGESN families and the 15 responsible-use practices, with each rule's
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
