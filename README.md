# Green Claude: digital sobriety for Claude Code

🇫🇷 [Lire en français](README.fr.md)

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![RGESN 2024](https://img.shields.io/badge/RGESN-2024-1b7a4a.svg)](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/)
[![GR491](https://img.shields.io/badge/GR491-reference-1b7a4a.svg)](https://gr491.isit-europe.org/)
[![Release](https://img.shields.io/github/v/release/Institut-du-Numerique-Responsable/green-claude)](https://github.com/Institut-du-Numerique-Responsable/green-claude/releases)
[![Site](https://img.shields.io/badge/site-green--claude-blue)](https://institut-du-numerique-responsable.github.io/green-claude/)
[![Last commit](https://img.shields.io/github/last-commit/Institut-du-Numerique-Responsable/green-claude)](https://github.com/Institut-du-Numerique-Responsable/green-claude/commits/main)
[![GitHub Stars](https://img.shields.io/github/stars/Institut-du-Numerique-Responsable/green-claude?style=flat)](https://github.com/Institut-du-Numerique-Responsable/green-claude/stargazers)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

**Green Claude** is a skill for [Claude Code](https://claude.com/claude-code) that guides Claude toward eco-designed code, automatically, with no command to remember.

Built by the [Institut du Numérique Responsable](https://institutnr.org) (French non-profit on responsible digital practices), 2026, MIT licensed.

> Eco-designed code = fewer resources consumed by every user, on every run, for the software's entire lifetime.

This repository is specific to Claude Code. A standalone, portable version of the rules — usable with other AI assistants and other languages — is in development here: [regles-ecoconception-ia](https://github.com/Institut-du-Numerique-Responsable/regles-ecoconception-ia).

---

## In one sentence

Install the skill once. From then on, whenever Claude Code writes or reviews code in your projects, it applies eco-design rules on its own (**RGESN 2024**, **GR491**, **Green Software Foundation**, **W3C Web Sustainability Guidelines**, plus thresholds drawn from **YellowLabTools**), without you having to ask each time.

## Why a skill instead of a plain rule list

An RGESN checklist in a PDF or wiki depends on someone remembering to reopen it. Nobody reads it again before every line of code, and how well it's followed varies from person to person, and from day to day.

A Claude Code skill makes three concrete differences:

- **Loads automatically every session.** The skill loads itself — no need to mention it at the start of a conversation.
- **Contextual rule selection.** Claude applies whichever families are relevant to what it's writing right now: a backend file triggers the SQL and connection-pool rules, not the UX/UI rules about autoplay.
- **Built-in after-the-fact verification.** The audit script (`eco-audit.sh`) runs on demand against code already written, at zero reasoning cost for the model, to catch what proactive application missed.

A checklist stays a document you consult. The skill runs at the moment the code is written, inside the working session itself.

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

This installs the skill into `~/.claude/skills/green-claude`. Nothing else to do: Claude Code loads it automatically in your next sessions. This method is still worth using if you also want the optional cache hooks (see below), which the plugin manager doesn't wire up on its own.

Prerequisite: `jq`, needed by the audit script and the hooks (`brew install jq` / `sudo apt install jq`).

## Usage

Nothing to type. Three ways to use it:

| You want to... | What you do |
|---|---|
| Have Claude write sober code by default | Nothing: it's automatic once the skill is installed |
| Audit an existing file | Just ask: *"eco-design audit of this file"* |
| See the full checklist | Type `/green-claude` |

The audit (`skills/green-claude/scripts/eco-audit.sh`) is a deterministic script (grep against the rules): it costs the model no reasoning, only the reading of the result.

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

`eco-audit.sh api.js` (real, unedited output):

```
[High] ECO-FRONT-01 — Avoid heavy libraries for minor needs
  Recommendation: Prefer native language functions or lightweight alternatives (date-fns, Alpine.js).

[High] ECO-BACK-01 — Optimize SQL queries
  Recommendation: Select only the columns you need, index filtered columns, avoid functions in WHERE clauses and N+1 queries.

2 eco-design issue(s) detected.
```

In practice, you don't need to run the audit yourself on code like this: in proactive mode, Claude avoids `lodash` for a single function and `SELECT *` right when writing the code, before any audit even happens.

---

## Installing natively in Claude

Three channels, three formats. Claude Code needs nothing more than the repository:

```bash
/plugin marketplace add Institut-du-Numerique-Responsable/green-claude
/plugin install green-claude
```

The other two want a zip archive, which `package-skill.sh` builds:

```bash
bash skills/green-claude/scripts/package-skill.sh    # writes into dist/
```

| Channel | Archive | How to install |
|---|---|---|
| Claude Code | none | `/plugin marketplace add …` above, or `npx skills add Institut-du-Numerique-Responsable/green-claude` |
| Claude.ai | `dist/green-claude-claude-ai.zip` | Settings → Capabilities → Skills → Upload skill (code execution must be enabled) |
| Claude API | `dist/green-claude-api.zip` | `client.beta.skills.create(files=files_from_dir("green-claude"))` |

The two archives hold the same skill and differ only by the description: Claude.ai caps it at 200 characters where the API allows 1024. The repository keeps the long one, which is what makes Claude Code load the skill at the right moment; the packaging script substitutes a short version rather than truncating mid-sentence, since a sentence cut in half triggers badly.

The audit script needs `bash` and `jq`. Where `jq` is missing, the rules still apply while Claude writes code — only `eco-audit.sh` stops working.

---

## The rules: 52 rules aligned with the 9 RGESN 2024 families

[`skills/green-claude/rules/ecoconception.json`](skills/green-claude/rules/ecoconception.json) covers all **9 families** of [RGESN 2024](https://www.arcep.fr/mes-demarches-et-services/entreprises/fiches-pratiques/referentiel-general-ecoconception-services-numeriques.html) (78 official criteria). Each rule references the matching RGESN criterion (`rgesn_ref`) and [GR491](https://gr491.isit-europe.org/) family (`gr491_famille`):

| RGESN family | Rules | Examples |
|---|---|---|
| 1. Strategy | 6 | Measure before optimizing, reasoned data collection, open formats, sustainability advocate, awareness training, user transparency |
| 2. Specifications | 5 | Compatibility with old devices, low bandwidth, third-party services impact |
| 3. Architecture | 5 | Low-tech first, resources matched to load, sober test environments, tested and maintainable code |
| 4. UX/UI | 7 | No autoplay or infinite scroll, native components, limited fonts, most sober medium, prefers-reduced-motion |
| 5. Content | 2 | Optimized images, SVG |
| 6. Frontend | 13 | No heavy libraries, lazy loading, minification, dependencies, no dead code, no implicit globals, no synchronous XHR, lean DOM, no duplicate IDs, limited `!important`, no duplicate CSS, no legacy IE hacks, deferred scripts |
| 7. Backend | 4 | Optimized SQL, connection pools, complexity, pagination + cache |
| 8. Hosting | 6 | Sober hosting, HTTP compression, HTTP cache, HTTPS/TLS, broken links |
| 9. **Algorithms (incl. AI)** | 4 | **Justify AI use, right-size the model, measure, sober alternatives** |

Rules with no detectable pattern (process, governance) are skipped by the audit and serve as a checklist in `/green-claude`.

---

## Language rules: 80 rules loaded on demand

The 52 rules above hold whatever the language. They set the goal without saying how to reach it in Python or in Java: "avoid N+1 queries" doesn't choose between `select_related`, `JOIN FETCH`, `Include` and `with()`.

[`skills/green-claude/rules/langages/`](skills/green-claude/rules/langages/) goes one level down, with one file per language, applied **only to files of that language**:

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
eco-audit.sh --list-langs           # covered languages and their globs
eco-audit.sh --list-rules python    # full checklist for one language
```

---

## Measure, don't assume

`eco-score.sh` counts the patterns found in a repository, weights them by impact and reports them against code volume:

```bash
skills/green-claude/scripts/eco-score.sh          # human-readable
skills/green-claude/scripts/eco-score.sh --json   # one line per measurement, to keep over time
```

This score counts known patterns, not joules. A falling density says the code holds fewer recognizable patterns, not that it draws less power. Compare it to last month's rather than to zero, and check it against a real runtime measurement (query count, bytes transferred, CPU time, EcoIndex on a page): that's what settles it.

Two more checkpoints, both optional:

- `hooks/green-claude-pre-commit.sh` audits staged files. Where the Claude Code hook only sees what Claude writes, this one also sees what you write. It reports without blocking, unless you pass `GREEN_CLAUDE_STRICT=1`.
- `.github/workflows/eco-audit.yml` runs the rule test suite on every PR and publishes the repository's density in the job summary.

## Boris's practices: using Claude soberly and sensibly

Coding with AI also has a cost during the session itself: every request consumes energy. [Boris Cherny](https://howborisusesclaudecode.com/), Claude Code's creator, documents efficient usage practices. Efficient use is also sober use: every avoided back-and-forth saves tokens, every trimmed context does too.

[`skills/green-claude/rules/boris.json`](skills/green-claude/rules/boris.json) picks up 14 of them, including two added with verified open-source tool examples:

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
| Match effort to the task | `/effort low/high/max` depending on the task, never maxed out by default |
| `--bare` for scripts | Startup with no project context, for automation |

Full detail: [`skills/green-claude/rules/boris.json`](skills/green-claude/rules/boris.json).

> The third-party tools cited (graphify, caveman) are verified illustrative examples (open source, MIT license). The project doesn't audit them and doesn't depend on them.

---

## What a skill can't do (and how it's covered anyway)

A skill runs *during* a session that's already started, and the model decides whether to apply it. So it can't pick the starting model, can't intercept a call before it leaves, and can't guarantee a rule gets checked every single time. Three levers therefore live outside the skill, in [`hooks/`](hooks/), optional and offered at install time:

- **Systematic audit** (`hooks/green-claude-audit.sh`): wired as `PostToolUse` on `Write|Edit|MultiEdit`. Claude Code runs it after every code file written, without asking the model. It audits what was just added and hands the findings back to Claude, who fixes them before moving on.
- **Local cache** (`hooks/green-claude-cache.sh`): a question already asked gets served again without calling the model — zero tokens spent.
- **Off-peak warning** (same hook): flags peak hours (outside 22:00-06:00 UTC) without ever blocking.

These hooks wire into `~/.claude/settings.json`. If you answer "y", `install.sh` adds them there (other settings are preserved, and a backup of the original file is left at `settings.json.green-claude.bak`). Without `jq`, it prints the config to paste in by hand. To remove them: delete the `green-claude-*` entries from the file.

---

## Writing your own rules

Add a JSON file under `skills/green-claude/rules/`, structured like `ecoconception.json` (categories → rules):

```json
{
  "id": "CUSTOM-001",
  "title": "My rule",
  "impact": "High",
  "patterns": ["my_regex_pattern"],
  "recommendation": "What to do instead."
}
```

- `patterns`: `grep -E` regular expressions detecting the problem. **Empty list = a practice** (checklist item, skipped by the audit).
- `impact`: `High`, `Medium`, or `Low`.
- `rgesn_ref` / `gr491_famille` (optional): pointer back to the official standards.
- `detector` / `enrich` (optional): for cases a pattern alone can't see (multi-line nesting, counting, the real weight of a referenced file...), a dedicated script under `scripts/`. Full detail in [CONTRIBUTING.md](CONTRIBUTING.md).
- `note` (optional): a caveat shown in the audit's own output (known false positive, threshold, limited scope) — this is where to document a rule's interpretation pitfalls, not in the skill itself.

Then re-run `./install.sh` to republish the updated skill.

---

## 🤝 Contributing

1. **Fork** this repository
2. Create a branch (`git checkout -b feature/my-rule`)
3. Add your rules or improvements (`jq empty skills/green-claude/rules/*.json` to validate the JSON)
4. Open a **Pull Request**

Most useful contributions: new audit rules sourced from RGESN, GR491, GSF, WSG, or another recognized public reference, with their `rgesn_ref`; pattern fixes (false positives); translations.

Full detail on the rule format and PR process: [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 🙏 References

- [RGESN 2024](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/): Référentiel Général d'Écoconception de Services Numériques (78 criteria, 9 families)
- [GR491](https://gr491.isit-europe.org/): reference guide for responsible digital service design (61 recommendations, 516 criteria)
- [Green Software Foundation](https://greensoftware.foundation/): software eco-design patterns
- [W3C Web Sustainability Guidelines](https://w3c.github.io/sustainableweb-wsg/): web sustainability guidelines (UX, development, hosting, strategy)
- [YellowLabTools](https://github.com/YellowLabTools/YellowLabTools): open-source front-end quality audit tool, source of several thresholds (DOM, CSS, fonts)
- [How Boris uses Claude Code](https://howborisusesclaudecode.com/): Boris Cherny's practices, Claude Code's creator
- [Anthropic](https://www.anthropic.com/): Claude and Claude Code

## Maintainers

- [Guillaume Gallon](https://github.com/gridboy) ([LinkedIn](https://www.linkedin.com/in/ggallon/)) — [Institut du Numérique Responsable](https://institutnr.org)

## 📄 License

[MIT](LICENSE), © 2026 Institut du Numérique Responsable
