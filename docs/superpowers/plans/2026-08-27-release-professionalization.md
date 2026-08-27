# Release Professionalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a verified `v1.4.0` release and leave a reproducible, secure release process for future versions.

**Architecture:** A small Bash checker owns release-version consistency and is exercised by a self-contained regression suite. Hardened GitHub Actions reuse that checker: ordinary CI validates changes, while a tag-only workflow validates, packages, and publishes release assets.

**Tech Stack:** Bash 3.2, jq, GitHub Actions, GitHub CLI, zip/unzip, Markdown.

**Spec:** `docs/superpowers/specs/2026-08-27-release-professionalization-design.md`

## Global Constraints

- All new release tags use exactly `vMAJOR.MINOR.PATCH`.
- Existing tags are never renamed or deleted.
- `.claude-plugin/plugin.json`, `skills/green-claude/SKILL.md`, `CHANGELOG.md`, and the release tag must agree.
- Validation remains read-only; only the release publication job receives `contents: write`.
- Scripts remain compatible with Bash 3.2 and require no new runtime dependency beyond jq.
- The release must not be published until all local verification succeeds.

---

### Task 1: Version consistency contract

**Files:**
- Create: `scripts/test-release-version.sh`
- Create: `scripts/check-release-version.sh`
- Create: `CHANGELOG.md`

**Interfaces:**
- Consumes: a version argument in `1.4.0` or `v1.4.0` form and repository metadata.
- Produces: `scripts/check-release-version.sh <version>`, exit 0 on complete agreement and a diagnostic non-zero exit otherwise.

- [ ] **Step 1: Write the failing regression test**

Create a temporary repository fixture containing minimal plugin metadata, skill frontmatter and changelog. Assert that the missing checker fails the test initially, then cover: `1.4.0`, `v1.4.0`, malformed `1.4`, plugin mismatch, skill mismatch, and missing changelog heading.

- [ ] **Step 2: Run the test and verify RED**

Run: `bash scripts/test-release-version.sh`

Expected: non-zero with the checker missing.

- [ ] **Step 3: Implement the minimal checker**

Normalize one optional leading `v`, validate `^[0-9]+\.[0-9]+\.[0-9]+$`, locate the repository from the script directory, extract the plugin version with jq, extract the first skill-frontmatter `version:` value with awk, and search for `## [<version>]` in `CHANGELOG.md`. Accumulate actionable mismatch messages and exit non-zero if any check fails.

- [ ] **Step 4: Add the historical changelog**

Use Keep a Changelog structure with `Unreleased`, `1.4.0`, `1.3.0`, `1.2.0`, `1.0.1`, and `1.0.0`. Derive entries from the corresponding Git history and existing release notes; do not invent product claims.

- [ ] **Step 5: Run GREEN and syntax checks**

Run:

```bash
bash scripts/test-release-version.sh
bash scripts/check-release-version.sh v1.4.0
bash -n scripts/check-release-version.sh scripts/test-release-version.sh
shellcheck scripts/check-release-version.sh scripts/test-release-version.sh
```

Expected: all commands exit 0 without warnings.

- [ ] **Step 6: Commit the contract**

```bash
git add CHANGELOG.md scripts/check-release-version.sh scripts/test-release-version.sh
git commit -m "feat: enforce release version consistency"
```

### Task 2: Harden continuous integration

**Files:**
- Modify: `.github/workflows/eco-audit.yml`

**Interfaces:**
- Consumes: repository contents and the version checker from Task 1.
- Produces: read-only CI with bounded runtime, cancellation of obsolete runs, immutable action references and release-consistency coverage.

- [ ] **Step 1: Record the expected workflow invariants**

Extend `scripts/test-release-version.sh` with repository-workflow assertions for top-level `permissions: contents: read`, `concurrency`, explicit `timeout-minutes`, immutable 40-character checkout SHA and execution of the release-version test.

- [ ] **Step 2: Run the test and verify RED**

Run: `bash scripts/test-release-version.sh`

Expected: failure naming the first missing workflow invariant.

- [ ] **Step 3: Harden the workflow minimally**

Add the required permission, concurrency group and timeouts; replace `actions/checkout@v4` with its current immutable SHA plus a version comment; add release-version tests to the test job.

- [ ] **Step 4: Run GREEN**

Run:

```bash
bash scripts/test-release-version.sh
bash skills/green-claude/scripts/test-eco-audit.sh
bash hooks/test-cache.sh
```

Expected: every suite reports success.

- [ ] **Step 5: Commit hardened CI**

```bash
git add .github/workflows/eco-audit.yml scripts/test-release-version.sh
git commit -m "ci: harden validation workflow"
```

### Task 3: Automated tagged releases

**Files:**
- Create: `.github/workflows/release.yml`
- Modify: `scripts/test-release-version.sh`

**Interfaces:**
- Consumes: a pushed `v*.*.*` tag on a consistent commit.
- Produces: one GitHub Release with generated notes, `green-claude-claude-ai.zip`, and `green-claude-api.zip`.

- [ ] **Step 1: Add failing release-workflow assertions**

Assert exact tag trigger, read-only default permissions, a validation job with timeout, a publication job depending on validation, job-scoped `contents: write`, version checking from `GITHUB_REF_NAME`, package generation, and publication of exactly the two expected archives.

- [ ] **Step 2: Run the test and verify RED**

Run: `bash scripts/test-release-version.sh`

Expected: failure because `.github/workflows/release.yml` is absent.

- [ ] **Step 3: Implement the release workflow**

Use pinned official GitHub actions. The validation job runs version, JSON, audit, cache and packaging checks, then uploads the two archives as an internal workflow artifact. The publication job downloads that artifact and creates the GitHub Release for the existing tag with generated notes.

- [ ] **Step 4: Run GREEN and inspect YAML**

Run:

```bash
bash scripts/test-release-version.sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/eco-audit.yml"); YAML.load_file(".github/workflows/release.yml")'
```

Expected: tests pass and both YAML files parse.

- [ ] **Step 5: Commit release automation**

```bash
git add .github/workflows/release.yml scripts/test-release-version.sh
git commit -m "ci: publish verified tagged releases"
```

### Task 4: Document the release policy

**Files:**
- Modify: `README.md`
- Modify: `README.fr.md`
- Modify: `CONTRIBUTING.md`
- Modify: `.Codex/CODEMAP.md`

**Interfaces:**
- Consumes: the workflow and checker implemented above.
- Produces: contributor-facing release instructions in English and French plus an updated repository map.

- [ ] **Step 1: Add documentation assertions**

Extend the regression script to require a `CHANGELOG.md` link and `vMAJOR.MINOR.PATCH` in both READMEs, plus the exact local checker command in `CONTRIBUTING.md`.

- [ ] **Step 2: Run the test and verify RED**

Run: `bash scripts/test-release-version.sh`

Expected: failure naming missing documentation.

- [ ] **Step 3: Add concise release documentation**

Document the changelog and tag convention in both READMEs. Add maintainer steps to `CONTRIBUTING.md`: update both version declarations and changelog, run the checker, merge, create an annotated `vX.Y.Z` tag, and push it. Add the new scripts/workflows/changelog to `CODEMAP.md`.

- [ ] **Step 4: Run GREEN and link checks**

Run:

```bash
bash scripts/test-release-version.sh
git diff --check
```

Expected: exit 0.

- [ ] **Step 5: Commit documentation**

```bash
git add README.md README.fr.md CONTRIBUTING.md .Codex/CODEMAP.md scripts/test-release-version.sh
git commit -m "docs: define the release policy"
```

### Task 5: Verify and publish v1.4.0

**Files:**
- Verify only: all changed files and generated `dist/*.zip` archives.
- External state: `origin/main`, tag `v1.4.0`, GitHub Actions and GitHub Releases.

**Interfaces:**
- Consumes: reviewed commits from Tasks 1–4.
- Produces: synchronized main branch, annotated remote tag and published release with two assets.

- [ ] **Step 1: Run the complete local verification**

```bash
bash scripts/test-release-version.sh
bash scripts/check-release-version.sh v1.4.0
bash skills/green-claude/scripts/test-eco-audit.sh
bash hooks/test-cache.sh
bash skills/green-claude/scripts/package-skill.sh
bash -n install.sh hooks/*.sh scripts/*.sh skills/green-claude/scripts/*.sh
shellcheck install.sh hooks/*.sh scripts/*.sh skills/green-claude/scripts/*.sh
jq -e . .claude-plugin/*.json skills/green-claude/rules/*.json skills/green-claude/rules/langages/*.json >/dev/null
unzip -t dist/green-claude-claude-ai.zip
unzip -t dist/green-claude-api.zip
git diff --check
```

Expected: every command exits 0; archives contain one `green-claude/` root.

- [ ] **Step 2: Review repository state**

Run: `git status --short --branch && git log --oneline origin/main..HEAD`

Expected: only intended release commits are ahead of `origin/main`, with no uncommitted files except ignored generated archives.

- [ ] **Step 3: Push main**

Run: `git push origin main`

Expected: remote main advances to the verified commit.

- [ ] **Step 4: Create and push the release tag**

```bash
git tag -a v1.4.0 -m "Green Claude v1.4.0"
git push origin v1.4.0
```

Expected: the tag targets the verified main commit and triggers the release workflow.

- [ ] **Step 5: Verify the published release**

Use GitHub CLI to wait for the triggered workflow, confirm success, and inspect `gh release view v1.4.0 --json tagName,isDraft,isPrerelease,assets,url`. Expected: published, non-draft, non-prerelease, with exactly the two named zip assets.
