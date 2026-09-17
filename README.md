# Green Claude: digital sobriety for Claude Code

🇫🇷 [Lire en français](README.fr.md)

[![Licenses](https://img.shields.io/badge/licenses-Apache--2.0%20%2B%20CC%20BY%204.0-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Institut-du-Numerique-Responsable/green-claude)](https://github.com/Institut-du-Numerique-Responsable/green-claude/releases)
[![Site](https://img.shields.io/badge/site-green--claude-blue)](https://institut-du-numerique-responsable.github.io/green-claude/)

**Green Claude** helps [Claude Code](https://claude.com/claude-code) write code that uses fewer resources, with eco-design rules and a local audit tool.

A project by the [Institut du Numérique Responsable](https://institutnr.org): **107 general rules, 127 rules for 24 languages and frameworks, and 16 responsible-use practices**.

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
| Claude API | `dist/green-claude-api.zip` | `client.beta.skills.create(files=files_from_dir("green-claude"))` |

The archives contain the same skill, with a description adapted to each channel. Running the audit requires `bash` and `jq` in the execution environment.

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

## Language rules: 127 rules loaded on demand

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

[`skills/green-claude/rules/usage.json`](skills/green-claude/rules/usage.json) contains 16 project-authored recommendations, including two illustrated with verified open-source tools:

| Practice | The move |
|---|---|
| Context minimalism | Minimal prompt, let Claude fetch its own context |
| Rewind instead of correcting | `/rewind` (double Esc) instead of stacking corrections into the context |
| `/clear` vs `/compact` | New task → `/clear`. Related task → `/compact <instruction>` |
| Map the codebase | A repo index (CODEMAP.md, or a tool like [graphify](https://github.com/Graphify-Labs/graphify)) avoids re-reading the same files whole every session |
| Dense answers | Get straight to the result instead of rephrasing (the spirit behind tools like [caveman](https://github.com/juliusbrussee/caveman)) |
| Write the rule, don't re-correct | "Add this to CLAUDE.md" fixes it once and for all |
| A skill for anything repeated | A daily workflow becomes a slash command |
| Give it a way to verify | Tests, a command, a browser: fewer correction cycles |
| Match effort to the task | Use the controls available in the client and verify their effect through evaluations |
| Minimal mode for scripts | Avoid loading customizations an automation does not need |

Full detail: [`skills/green-claude/rules/usage.json`](skills/green-claude/rules/usage.json).

> The third-party tools cited (graphify, caveman) are verified illustrative examples (open source, MIT license). The project doesn't audit them and doesn't depend on them.

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

## License

Code: **Apache-2.0**. Rules and documentation: **CC BY 4.0**. Reuse, adaptation and commercial use are permitted under these licenses, with the required notices and attribution.

© 2026 Institut du Numérique Responsable. Principal author: Guillaume Gallon; other contributions: Git history. See the [license scope](LICENSE) and [credits](skills/green-claude/NOTICE). Third-party sources retain their own terms.
