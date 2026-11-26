# Green Claude: digital sobriety for Claude Code

🇫🇷 [Lire en français](README.fr.md)

[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-CC785C?logo=claude&logoColor=white)](https://github.com/Institut-du-Numerique-Responsable/green-claude)
[![Audit](https://img.shields.io/badge/audit-Bash%2FAWK-4EAA25?logo=gnubash&logoColor=white)](hooks/)
[![Python](https://img.shields.io/badge/Python-3-3776AB?logo=python&logoColor=white)](scripts/)
[![Licenses](https://img.shields.io/badge/licenses-Apache--2.0%20%2B%20CC%20BY%204.0-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Institut-du-Numerique-Responsable/green-claude)](https://github.com/Institut-du-Numerique-Responsable/green-claude/releases)
[![Site](https://img.shields.io/badge/site-green--claude-blue)](https://institut-du-numerique-responsable.github.io/green-claude/)

**Green Claude** helps [Claude Code](https://claude.com/claude-code) write code that uses fewer resources, with eco-design rules and a local audit tool.

A project by the [Institut du Numérique Responsable](https://institutnr.org): **107 general rules, 137 rules for 24 languages and frameworks, 13 responsible-use practices and 30 token sobriety rules**. The approach is presented on the INR website (in French): [Écoconcevoir avec un assistant de code](https://institutnr.org/ecoconcevoir-avec-un-assistant-de-code).

The skill guides the model when loaded; its application is not guaranteed on every response. The audit flags candidates for review, without certifying RGESN compliance or measuring energy savings. Optional hooks run the audit after supported code-writing operations.

The rules draw on RGESN 2024, GR491, the Green Software Foundation and the W3C Web Sustainability Guidelines. A version portable to other assistants is being developed in [regles-ecoconception-ia](https://github.com/Institut-du-Numerique-Responsable/regles-ecoconception-ia).

[Installation](#installation) · [Usage](#usage) · [Languages and frameworks](docs/languages/README.md) · [Limits and hooks](#limits-and-hooks) · [Contributing](CONTRIBUTING.md) · [License](#license)

## Installation

### Via the Claude Code plugin manager (recommended)

```
/plugin marketplace add Institut-du-Numerique-Responsable/green-claude
/plugin install green-claude@green-claude
```

Claude Code then handles updates (`/plugin update green-claude`) without a manual `git pull`.

### Via install.sh

```bash
git clone https://github.com/Institut-du-Numerique-Responsable/green-claude.git
cd green-claude
./install.sh
```

The script installs the skill into `~/.claude/skills/green-claude` and offers audit, cache and framing hooks separately. The plugin manager does not configure these hooks.

Prerequisite: `jq`, needed by the audit script and the hooks (`brew install jq` / `sudo apt install jq`).

### Claude.ai and Claude API

From a local clone, build the archives:

```bash
bash skills/green-claude/scripts/package-skill.sh    # writes into dist/
```

| Channel | Archive | How to install |
|---|---|---|
| Claude.ai | `dist/green-claude-claude-ai.zip` | Settings → Capabilities → Skills → Upload skill (code execution must be enabled) |
| Claude API | `dist/green-claude-api.zip` | `client.beta.skills.create(files=files_from_dir("green-coding"))` |

The archives contain the same skill, with a description adapted to each channel. There it is named `green-coding`: Claude.ai and the API reject a skill name that contains "claude". Running the audit requires `bash` and `jq` in the execution environment.

## Usage

Three ways to use it:

| You want to... | What you do |
|---|---|
| Have Claude write sober code by default | Install the skill; explicitly request its use when needed |
| Audit an existing file | Just ask: *"eco-design audit of this file"* |
| See the full checklist | Type `/green-claude` |

The audit uses local patterns and detectors, without calling a model for detection. Interpreting its results with Claude consumes tokens.

## Real example

This entirely ordinary piece of code:

```js
import _ from 'lodash';

app.get('/api/users', (req, res) => {
  db.query('SELECT * FROM users', (err, rows) => {
    res.json(rows);
  });
});
```

`bash skills/green-claude/scripts/eco-audit.sh api.js` (output excerpt):

```
[High] ECO-FRONT-01 — No heavy library for a minor need
  File           : api.js
  Category       : 6. Frontend
  RGESN          : 6.x
  Recommendation : Prefer the language's native functions or lighter alternatives (date-fns, Alpine.js).

[High] ECO-BACK-01 — Optimise SQL queries
  File           : api.js
  Category       : 7. Backend
  RGESN          : 7.x
  Recommendation : Select only the columns you need, index the filtered columns, and avoid functions in WHERE clauses and N+1 queries.

[High] ECO-JS-01 — Whole-library import
  File           : api.js
  Category       : JS/TS — dependencies and weight
  RGESN          : 6.1, 6.2
  Recommendation : Targeted imports (import { x } from 'lib/x'); native APIs first (fetch, Intl, URL, structuredClone, Date/Temporal) before adding a dependency.

3 ecodesign issue(s) found.
```

The skill can help Claude avoid these patterns while writing; use the audit to check the result.

---

## The rules: 107 rules aligned with the 9 RGESN 2024 families

[`skills/green-claude/rules/ecoconception.json`](skills/green-claude/rules/ecoconception.json) covers all **9 families** of [RGESN 2024](https://www.arcep.fr/mes-demarches-et-services/entreprises/fiches-pratiques/referentiel-general-ecoconception-services-numeriques.html) (78 official criteria) **plus a new "Hosting for AI" category**. Every rule carries an RGESN reference (`rgesn_ref`) and a [GR491](https://gr491.isit-europe.org/) family (`gr491_famille`).

How precise that reference currently is: **38 rules** point at specific criteria (e.g. `4.8`), **67 rules** only point at their family (`1.x` to `9.x`) because that mapping has not been done yet, and two rules follow the Green Software Foundation rather than the RGESN. Refining those family-level references is open work — the field states what it knows, never more.

| RGESN family | Rules | Examples |
|---|---|---|
| 1. Strategy | 9 | Measure before optimizing, reasoned data collection, open formats, sustainability advocate, awareness training, user transparency |
| 2. Specifications | 5 | Compatibility with old devices, low bandwidth, third-party services impact |
| 3. Architecture | 12 | Low-tech first, resources matched to load, sober test environments, tested and maintainable code |
| 4. UX/UI | 8 | No autoplay or infinite scroll, native components, limited fonts, most sober medium, prefers-reduced-motion |
| 5. Content | 3 | Optimized images, SVG, fonts |
| 6. Frontend | 14 | No heavy libraries, lazy loading, minification, dependencies, no dead code, no implicit globals, no synchronous XHR, lean DOM, no duplicate IDs, limited `!important`, no duplicate CSS, no legacy IE hacks, deferred scripts |
| 7. Backend | 13 | Optimized SQL, connection pools, complexity, pagination + cache, N+1 queries |
| 8. Hosting | 12 | Sober hosting, HTTP compression, HTTP cache, HTTPS/TLS, broken links |
| 9. **Algorithms (incl. AI)** | 27 | **Justify AI use, right-size the model, measure, sober alternatives, quantification, batching, streaming** |
| 10. **Hosting for AI** | 4 | **Inference-optimized GPUs, green datacenters, CPU inference, model sizing** |

Rules with no detectable pattern (process, governance) are skipped by the audit and serve as a checklist in `/green-claude`.

---

## Language rules: 137 rules loaded on demand

The 107 rules above hold whatever the language. They set the goal without saying how to reach it in Python or in Java: "avoid N+1 queries" doesn't choose between `select_related`, `JOIN FETCH`, `Include` and `with()`.

[`skills/green-claude/rules/langages/`](skills/green-claude/rules/langages/) goes one level down, with one file per language, applied **only to files of that language**:

Examples from the **24 languages and frameworks**. See the [complete list and detailed rules](docs/languages/README.md).

| File | Files covered | Rules | What it catches on its own |
|---|---|---|---|
| `python.json` | `**/*.py` | 11 | Django/SQLAlchemy N+1, `iterrows()`, unbounded `lru_cache()`, `requests.get` without a session |
| `sql.json` | `**/*.{sql,pks,pkb,prc,fnc,trg}` | 11 | `SELECT *`, `OFFSET` pagination, non-sargable predicates, PL/SQL cursors, retention |
| `javascript.json` | `**/*.{js,jsx,ts,tsx,mjs,cjs}` | 9 | `import * as`, `fs.*Sync`, `setInterval`, listeners never removed |
| `java.json` | `**/*.java` | 8 | `findAll()`, JPA N+1, `parallelStream()`, unbounded static cache |
| `csharp.json` | `**/*.cs` | 8 | Premature `ToList()`, `.Result`, `new HttpClient()` per request |
| `php.json` | `**/*.php` | 7 | Unbounded `->get()`, Eloquent/Doctrine N+1, `file_get_contents`, cache without purge |
| `ruby.json` | `**/*.rb` | 7 | `.all.each`, `map(&:col)`, `count > 0`, cache without `expires_in` |
| `rust.json` | `**/*.rs` | 7 | Convenience `clone()`, intermediate `collect()`, blocking an async executor |
| `c.json` | `**/*.{c,h}` | 6 | `strlen()` in a loop condition, repeated `strcat()`, byte-by-byte I/O, busy waiting |
| `cpp.json` | `**/*.{cpp,cc,cxx,hpp,hh}` | 6 | Pass by value, linear `std::find`, `shared_ptr` by default |

Without this filtering by extension, one language's patterns fire on the others: `.all()`, `save()` and `+=` exist everywhere and don't point at the same problem. The audit only loads the file for the languages actually present among its arguments.

```bash
bash skills/green-claude/scripts/eco-audit.sh --list-langs           # covered languages and their globs
bash skills/green-claude/scripts/eco-audit.sh --list-rules python    # full checklist for one language
bash skills/green-claude/scripts/eco-audit.sh --rules src/App.tsx    # compact rules for a file, a family or a language
```

---

## Measure, don't assume

`eco-score.sh` counts the patterns found in a repository, weights them by impact and reports them against code volume:

```bash
skills/green-claude/scripts/eco-score.sh          # human-readable
skills/green-claude/scripts/eco-score.sh --json   # one line per measurement, to keep over time
```

This score counts known patterns, not joules. A falling density says the code holds fewer recognizable patterns, not that it draws less power. Compare it to last month's rather than to zero, and check it against a real runtime measurement (query count, bytes transferred, CPU time, EcoIndex on a page): that's what settles it.

If the audit fails, the command exits with an error and produces no score. Hooks and the score derive their supported extensions from the rule catalog; automatic selection excludes Markdown and JSON.

Two more checkpoints, both optional:

- `hooks/green-claude-pre-commit.sh` audits the staged content, even when the working copy differs. Where the Claude Code hook only sees what Claude writes, this one also sees what you write. It reports without blocking, unless you pass `GREEN_CLAUDE_STRICT=1`.
- `.github/workflows/eco-audit.yml` runs the rule test suite on every PR and publishes the repository's density in the job summary.

## Responsible-use practices for Claude Code

Coding with AI also uses resources during the session. Green Claude therefore maintains its own recommendations for avoiding unnecessary context, output, retries, and compute. Token counts are an activity indicator, not a direct measurement of energy or emissions; environmental claims require measurements from the actual execution context.

[`skills/green-claude/rules/usage.json`](skills/green-claude/rules/usage.json) contains 13 project-authored recommendations. The table adds two practices now carried by the token sobriety rules (NR-TOK, next section):

| Practice | The move |
|---|---|
| Context minimalism | Minimal prompt, let Claude fetch its own context |
| Rewind instead of correcting | `/rewind` (double Esc) instead of stacking corrections into the context |
| `/clear` vs `/compact` | New task → `/clear`. Related task → `/compact <instruction>` |
| Map the codebase | A repo index (CODEMAP.md, or a tool like [graphify](https://github.com/Graphify-Labs/graphify)) avoids re-reading the same files whole every session |
| Dense answers | Get straight to the result instead of rephrasing (the spirit behind tools like [caveman](https://github.com/juliusbrussee/caveman)); plain style without AI writing tics, checked with [stop-slop](https://github.com/hardikpandya/stop-slop) when installed (NR-TOK-001 to 005) |
| Write the rule, don't re-correct | "Add this to CLAUDE.md" fixes it once and for all |
| A skill for anything repeated | A daily workflow becomes a slash command |
| Give it a way to verify | Tests, a command, a browser: fewer correction cycles |
| Match effort to the task | Use the controls available in the client and verify their effect through evaluations (NR-TOK-023, NR-TOK-024 for subagents) |
| Minimal mode for scripts | Avoid loading customizations an automation does not need |

Full detail: [`skills/green-claude/rules/usage.json`](skills/green-claude/rules/usage.json).

The skill applies these rules to its own replies: no em dash, no phrase that announces an idea instead of delivering it, no pseudo-cleft sentence, no emphatic presentative or detached fake subordinate clause, no epanorthosis, verbal anaphora or binary antithesis, no counted announcement or announced list. They hold in every language ([`references/style.md`](skills/green-claude/references/style.md)).

> The third-party tools cited are verified open source: graphify and stop-slop under the MIT license, caveman under the Apache License 2.0 (see [Attribution and third-party licenses](#attribution-and-third-party-licenses)). The project doesn't audit them and doesn't depend on them.

## Token sobriety for AI agents

[`skills/green-claude/rules/tokens.json`](skills/green-claude/rules/tokens.json) holds the 30 NR-TOK rules of the Institut du Numérique Responsable. They cut the tokens consumed, the model calls and the needless processing without degrading quality, security, maintainability or understanding of the code. They target development agents such as Claude Code, OpenAI Codex and Mistral Vibe.

| Family | Rules | Examples |
|---|---|---|
| A. Reply sobriety | NR-TOK-001 to 006 | answer directly, no redundant conclusion, few messages between tool calls |
| B. Context management | NR-TOK-007 to 014 | load what is needed, targeted search, compress logs while keeping errors, numbers and paths |
| C. Operation sobriety | NR-TOK-015 to 022 | investigate before changing, targeted changes, stop at the acceptance criteria |
| D. Model optimization | NR-TOK-023 to 026 | proportionate model, deterministic local processing, cache |
| E. Quality and measurement | NR-TOK-027 to 030 | no saving at the cost of quality, measure, session report |

Seven rules are mandatory: NR-TOK-007, 011, 015, 016, 022, 027 and 030. NR-TOK-023 to 026 and NR-TOK-028 depend on what the environment allows. The others apply by default. They absorb the former USAGE-CTX-06, USAGE-CPU-01 and USAGE-CPU-02 practices, and each rule's `related` field names the responsible-use practices they still overlap.

`eco-audit.sh --rules tokens` prints them in compact form, followed by the session report format required by NR-TOK-030. The report closes any task that ran tools or changed files, never a plain question. It lists the rules applied, the optimizations, the available measurements, the tests and the limits. It invents no metric and gives a saving percentage only against a comparable baseline. Cutting tokens, cutting costs and cutting environmental impact remain three separate goals.

### Lean mode

Green Claude adds text to the session: a session report at the end of each task (NR-TOK-030), a reminder of three questions before each code request, and the full detail of every finding after each file Claude writes. You need that text while you learn the rules. Once you know them, you pay for it in tokens on every task. Lean mode switches each of them off, one by one or all together, and leaves the detection as it is.

Ludovic NACHURY asked for lean mode.

#### Turning it on

Lean mode reads one environment variable, `GREEN_CLAUDE_LEAN`. Claude Code passes the `env` block of its settings to the hooks and to the commands Claude runs. Set the variable in that block.

For every project, in `~/.claude/settings.json`:

```json
{
  "env": { "GREEN_CLAUDE_LEAN": "all" }
}
```

For one project only, in `.claude/settings.json` at the root of the repository (commit it to share the choice with your team, or use `.claude/settings.local.json` to keep it to yourself):

```json
{
  "env": { "GREEN_CLAUDE_LEAN": "report,audit" }
}
```

Restart Claude Code after a change: it reads the settings at startup. To go back to the default, delete the line or set an empty value (`""`).

#### Values

Values combine with commas. Case and spaces do not matter: `report, Audit` works.

| Value | What it switches off | What stays |
|---|---|---|
| `report` | The NR-TOK-030 session report at the end of a task. | The other token sobriety rules. |
| `brief` | The reminder of three questions before a code request (`green-claude-brief.sh`, about 600 bytes on each matching request). | The same three rules in `SKILL.md`. |
| `audit` | The full blocks and the instructions printed by the `PostToolUse` audit hook. | One line per finding, with `file:line`. |
| `all` | All three. | Detection and findings. |

#### What changes, with examples

**`audit`.** After Claude writes this file:

```python
import requests
def report():
    out = ""
    for c in Commande.objects.all():
        out += c.client.nom
        requests.get("https://api.example.com/x")
    data = open("big.csv").read()
    return out
```

the default hook sends one block per finding, then instructions (4,470 bytes for these 6 findings):

```
[Green Claude] Éco-conception — motifs détectés dans ce que tu viens d'écrire (views.py) :

[High] ECO-BACK-06 — Timeout and retry cap on every remote call
  File           : views.py:6
  Category       : 7. Backend
  RGESN          : 7.2
  Recommendation : Set a timeout on every outbound call, cap the number of retries, …
  Instead of     : requests.get(url)
  Write          : session.get(url, timeout=5)
  Note           : The rule goes quiet as soon as the file mentions a timeout, …
… (5 more blocks)
Corrige ce qui est pertinent (impact Élevé en priorité). …
```

With `GREEN_CLAUDE_LEAN=audit`, the hook sends one line per finding (1,811 bytes):

```
[Green Claude] [High] ECO-BACK-06 Timeout and retry cap on every remote call — views.py:6 — Set a timeout on every outbound call, …
[Green Claude] [High] ECO-PY-01 N+1 query on a walked queryset — views.py:4 — Load the associations you walk with select_related/prefetch_related …
[Green Claude] [Medium] ECO-PY-05 File read entirely into memory — views.py:7 — Iterate the file line by line, …
[Green Claude] [Low] ECO-PY-07 String concatenation in a loop — views.py:5 — Accumulate in a list then ''.join(...), …
…
```

Claude gets the detail of a finding with `eco-audit.sh views.py`.

**`report`.** By default, a task that ran tools or changed files ends with this report:

```
### Token sobriety
- Rules: NR-TOK-007, NR-TOK-015, NR-TOK-016.
- Optimizations: targeted search, edit of the changed lines only.
- Measures: unavailable.
- Quality: test-eco-audit.sh passes.
- Limits: none.
```

With `report`, Claude ends the task without it. Claude learns this from `eco-audit.sh --rules tokens`, which `SKILL.md` has it run at the start of real work, and which prints:

```
## Session report (NR-TOK-030)
Off: GREEN_CLAUDE_LEAN disables it. Do not write the report.
```

If Claude has not run that command in the session, it does not know the report is off and may still write it.

**`brief`.** By default, a request such as « écris une fonction qui pagine les commandes » adds this reminder before Claude answers:

```
[Green Claude] Avant d'écrire, trois questions (ECO-ARCH-07, ECO-ALGO-08, USAGE-BRIEF-03) :
1. Une hypothèse changerait-elle la forme du travail si elle était fausse ? …
2. Quel est le moins de code qui résout ce problème ? …
3. Si la demande nomme un modèle ou une approche IA : …
```

With `brief`, the hook prints nothing.

#### Checking that it is on

```bash
# In a shell, for a one-off test without changing the settings:
GREEN_CLAUDE_LEAN=report bash skills/green-claude/scripts/eco-audit.sh --rules tokens | tail -2
# → Off: GREEN_CLAUDE_LEAN disables it. Do not write the report.
```

In a Claude Code session, ask Claude to run `echo "$GREEN_CLAUDE_LEAN"`: the value comes from the settings.

#### Which value to pick

- You are discovering the rules: leave lean mode off.
- You know the rules and want short sessions: `all`.
- You want to keep the reminder on design questions but drop the rest: `report,audit`.
- You review every finding in detail: `report,brief`.

The hooks installed by `install.sh` are copies: after an update of the repository, copy `hooks/green-claude-audit.sh` and `hooks/green-claude-brief.sh` to `~/.claude/hooks/` again, or the old copies keep ignoring lean mode.

---

## Limits and hooks

A skill runs *during* a session that's already started, and the model decides whether to apply it. So it can't pick the starting model, can't intercept a call before it leaves, and can't guarantee a rule gets checked every single time. Four levers therefore live outside the skill, in [`hooks/`](hooks/), optional and offered at install time:

- **Systematic audit** (`hooks/green-claude-audit.sh`): wired as `PostToolUse` on `Write|Edit|MultiEdit`. Claude Code runs it after every code file written, without asking the model. It audits what was just added and returns findings to Claude for review and possible correction.
- **Explicit local cache** (`hooks/green-claude-cache.sh`): prefix a self-contained factual question with `[cache] `, for example `[cache] What is the capital of France?`. Only these requests can reuse a response for one hour without calling the model. Ordinary requests always reach Claude. Do not use this prefix for code audits, actions, or questions that depend on files or previous messages: the cache does not track those changes. A cache hit is displayed as a hook message and is not added to Claude's conversation context.
- **Off-peak warning** (same hook): flags peak hours (outside 22:00-06:00 UTC) without ever blocking.
- **Framing before writing** (`hooks/green-claude-brief.sh`): wired as `UserPromptSubmit`. On a request to produce code, it recalls the three rules that decide what gets written at all — the least code that solves the problem, challenge the request and the model, ask before you build. On a question, it stays quiet. Those rules also live in the skill; the hook repeats them when the request is made.

## Two files that silence what should not speak

A candidate you dismiss once comes back on the next run, and the one after that. Dismissed six times, it teaches the whole team to skim past the audit, which costs more than the rule ever saved. Two versioned files close the question, at the repository root.

`.green-claude/decisions.md` holds what the team has settled:

```
ECO-CONT-01  docs/index.html  ACCEPTED  logo.jpg kept as the og:image fallback
ECO-SH-05    install.sh       TODO      two mktemp with no trap
```

`ACCEPTED` silences that rule for that file, and only there. `TODO` stays visible: a debt taken on deliberately is not an exemption. The audit reports how many findings it hid and where the file lives, so nothing vanishes without a trace. The rest of the file is free prose; only lines in the right shape are read.

`.green-claude/ignore` takes files out of scope, one pattern per line:

```
skills/green-claude/scripts/test-eco-audit.sh
skills/green-claude/rules/
```

A test suite and a rule corpus **contain** faulty code without ever running it. Flagging them is a false positive by construction, and it produced more noise than anything else while this repository was written.

Both locations can be overridden with `GREEN_CLAUDE_DECISIONS` and `GREEN_CLAUDE_IGNORE`.

These hooks wire into `~/.claude/settings.json`. If you answer "y", `install.sh` adds them there (other settings are preserved, and a backup of the original file is left at `settings.json.green-claude.bak`). Without `jq`, it prints the config to paste in by hand. To remove them: delete the `green-claude-*` entries from the file.

---

## Options and configuration

### `eco-audit.sh`

| Command | Effect |
|---|---|
| `eco-audit.sh <file>...` | Full audit: one block per finding with `file:line`, recommendation, corrected example and the rule's `Note`. |
| `eco-audit.sh --compact <file>...` | One line per finding: `[impact] ID title — file:line — recommendation`. The skill uses it first, then the full audit on the files it keeps. |
| `eco-audit.sh --rules [name...]` | Compact rules for a family (`backend`, `ux`…), a language (`python`), a file (`src/App.tsx`), `usage`, `tokens` or `all`. With no name, lists what exists. |
| `eco-audit.sh --list-rules [language]` | Process rules with no detectable pattern, or the full checklist of one language. |
| `eco-audit.sh --list-langs` | Covered languages and their globs. |
| `eco-audit.sh -h`, `--help` | Usage. |

Exit codes: `0` when the audit ran, with or without findings; `1` for a usage error, an unknown family or a missing `jq`; `2` when an argument is an unreadable file or an unknown option, and the script analyses nothing.

Examples, on the `views.py` file shown under *Lean mode*:

```console
$ bash skills/green-claude/scripts/eco-audit.sh --compact views.py
[High] ECO-BACK-06 Timeout and retry cap on every remote call — views.py:6 — Set a timeout on every outbound call, …
[High] ECO-PY-01 N+1 query on a walked queryset — views.py:4 — Load the associations you walk with select_related/prefetch_related …
[High] ECO-PY-02 Unbounded queryset materialised — views.py:4 — Paginate every exposed list; …
[Medium] ECO-PY-05 File read entirely into memory — views.py:7 — Iterate the file line by line, …
[Low] ECO-PY-07 String concatenation in a loop — views.py:5 — Accumulate in a list then ''.join(...), …
[Medium] ECO-PY-10 HTTP connections not reused — views.py:6 — Reuse a requests.Session (or a shared httpx client); …
6 ecodesign issue(s) found.

$ bash skills/green-claude/scripts/eco-audit.sh --rules python      # Python rules, one line each
$ bash skills/green-claude/scripts/eco-audit.sh --rules backend hosting
$ bash skills/green-claude/scripts/eco-audit.sh src/*.py templates/*.html   # full audit of several files

$ bash skills/green-claude/scripts/eco-audit.sh nope.py
File not found or unreadable: nope.py
Audit not run: nothing was analysed.
$ echo $?
2
```

### `eco-score.sh`

| Command | Effect |
|---|---|
| `eco-score.sh [path...]` | Density of findings weighted by impact, for the current repository by default. |
| `eco-score.sh --json [path...]` | The same score on one JSON line, to keep a history. |

### Environment variables

Set them in the `env` block of `~/.claude/settings.json` for the hooks and the commands Claude runs, or in your shell for `git commit` and manual audits.

| Variable | Read by | Effect | Default |
|---|---|---|---|
| `GREEN_CLAUDE_LEAN` | skill, audit and brief hooks | Lean mode: `report`, `brief`, `audit` or `all` (see *Lean mode*). | empty: everything on |
| `GREEN_CLAUDE_STRICT` | pre-commit hook | `1` stops the commit when the audit finds something in the staged content or cannot read it. | `0`: warns without blocking |
| `GREEN_CLAUDE_DECISIONS` | `eco-audit.sh` | Path of the decision register. | `.green-claude/decisions.md` |
| `GREEN_CLAUDE_IGNORE` | `eco-audit.sh` | Path of the list of files kept out of the audit. | `.green-claude/ignore` |
| `GREEN_CLAUDE_CACHE_DIR` | cache hooks | Directory of the `[cache]` replies. | `~/.cache/green-claude` |
| `GREEN_CLAUDE_SHA256_TOOL` | `eco-audit.sh` | Forces `shasum` or `sha256sum`. | the first one found |
| `GREEN_CLAUDE_SOURCE_FILE`, `GREEN_CLAUDE_BASE_DIR` | hooks, internal | Real path and base directory of a file audited from a temporary copy. The hooks set them. | set by the hooks |

Examples:

```bash
# Block the commit when the staged content has findings (the hook only warns by default):
GREEN_CLAUDE_STRICT=1 git commit -m "feat: pagination"

# Keep the decision register and the ignore list in a shared folder:
GREEN_CLAUDE_DECISIONS=docs/green/decisions.md GREEN_CLAUDE_IGNORE=docs/green/ignore \
    bash skills/green-claude/scripts/eco-audit.sh src/app.py
```

```json
{
  "env": {
    "GREEN_CLAUDE_LEAN": "report,audit",
    "GREEN_CLAUDE_CACHE_DIR": "/Users/me/.cache/green-claude"
  }
}
```

---

## Writing your own rules

The [contribution guide](CONTRIBUTING.md) covers the JSON format, source attribution, detectors and required tests. After local changes, rerun `./install.sh` to update the installed copy.

---

## 🤝 Contributing

1. **Fork** this repository
2. Create a branch (`git checkout -b feature/my-rule`)
3. Add your rules or improvements (`jq empty skills/green-claude/rules/*.json` to validate the JSON)
4. Open a **Pull Request**

Most useful contributions: new audit rules sourced from RGESN, GR491, GSF, WSG, or another recognized public reference, with their `rgesn_ref`; pattern fixes (false positives); translations.

Full detail on the rule format and PR process: [CONTRIBUTING.md](CONTRIBUTING.md).

Community participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md)
and [governance policy](GOVERNANCE.md). See [SUPPORT.md](SUPPORT.md) for the
right help channel and [SECURITY.md](SECURITY.md) for private vulnerability
reporting.

---

## Releases

Notable changes are recorded in the [changelog](CHANGELOG.md). New releases use
Semantic Versioning tags in the form `vMAJOR.MINOR.PATCH`; legacy tags retain
their original names so existing links keep working. A tagged release is
published automatically only after its version, tests, and packaged archives
have been verified.

---

## 🙏 References

- [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/): Référentiel Général d'Écoconception de Services Numériques (78 criteria, 9 families)
- [GR491](https://gr491.isit-europe.org/): reference guide for responsible digital service design (61 recommendations, 516 criteria)
- [Green Software Foundation](https://greensoftware.foundation/): software eco-design patterns
- [W3C Web Sustainability Guidelines](https://w3c.github.io/sustainableweb-wsg/): web sustainability guidelines (UX, development, hosting, strategy)
- [YellowLabTools](https://github.com/YellowLabTools/YellowLabTools): open-source front-end quality audit tool, source of several thresholds (DOM, CSS, fonts)
- [Anthropic](https://www.anthropic.com/): Claude and Claude Code

## Maintainers

- [Guillaume Gallon](https://github.com/gridboy) ([LinkedIn](https://www.linkedin.com/in/ggallon/)) — [Institut du Numérique Responsable](https://institutnr.org)

## Attribution and third-party licenses

### Caveman

A few ideas of the NR-TOK rules ([`rules/tokens.json`](skills/green-claude/rules/tokens.json)) come from the open source project [Caveman](https://github.com/JuliusBrussee/caveman) (Copyright 2026 Julius Brussee, Apache License 2.0). The INR reworked and rewrote those rules for the goals and reference frameworks of responsible digital practice.

This project is independent of Caveman and its author. Referring to Caveman implies no endorsement, affiliation or participation on their part.

## License

Code: **Apache-2.0**. Rules and documentation: **CC BY 4.0**. Reuse, adaptation and commercial use are permitted under these licenses, with the required notices and attribution.

© 2026 Institut du Numérique Responsable. Principal author: Guillaume Gallon; other contributions: Git history. See the [license scope](LICENSE) and [credits](skills/green-claude/NOTICE). Third-party sources retain their own terms.
