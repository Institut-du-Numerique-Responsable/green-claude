# GitHub Governance and Audit Path Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent multi-file audit path collisions, add professional community interfaces, and enforce reviewed changes to `main` through verified GitHub settings.

**Architecture:** The audit engine hashes exact source paths before storing cleaned copies, with a portable SHA-256 adapter and regression coverage. Community-health files remain declarative and are validated structurally, while remote governance is applied only after read-only inspection and a real PR reveals the CI check names.

**Tech Stack:** Bash 3.2, jq, AWK, GitHub issue forms/YAML, GitHub CLI/API, Markdown.

**Spec:** `docs/superpowers/specs/2026-08-27-github-governance-and-audit-paths-design.md`

## Global Constraints

- Work only on `chore/github-professionalization`; do not push changes directly to `main`.
- Keep Bash 3.2 compatibility and introduce no new runtime dependency.
- `@gridboy` and `@robintra` are global code owners.
- Never publish security reports through public issues.
- Read remote settings before mutating them; preserve any stronger existing protection.
- Do not self-merge the final pull request.

---

### Task 1: Collision-safe cleaned-file storage

**Files:**
- Modify: `skills/green-claude/scripts/test-eco-audit.sh`
- Modify: `skills/green-claude/scripts/eco-audit.sh`

**Interfaces:**
- Consumes: an exact source path string.
- Produces: a stable SHA-256 filename through `cleaned_name`, using `shasum` or `sha256sum`.

- [ ] Add a regression fixture with `src/a_b.js` and `src/a/b.js` whose old normalized names collide and whose expected audit findings differ.
- [ ] Run `bash skills/green-claude/scripts/test-eco-audit.sh` and verify the new case fails for the collision.
- [ ] Add hash-command selection and an actionable failure when neither SHA-256 command exists.
- [ ] Replace underscore normalization with the exact-path digest.
- [ ] Add isolated fallback/absence coverage by controlling `PATH` with tiny executable command fixtures while exercising the real audit entry point.
- [ ] Run the audit suite, Bash syntax and ShellCheck; verify all pass.
- [ ] Commit as `fix(audit): prevent cleaned-path collisions`.

### Task 2: Community health surface

**Files:**
- Create: `SECURITY.md`
- Create: `CODE_OF_CONDUCT.md`
- Create: `SUPPORT.md`
- Create: `GOVERNANCE.md`
- Create: `.github/CODEOWNERS`
- Create: `.github/ISSUE_TEMPLATE/bug.yml`
- Create: `.github/ISSUE_TEMPLATE/false-positive.yml`
- Create: `.github/ISSUE_TEMPLATE/new-rule.yml`
- Create: `.github/ISSUE_TEMPLATE/config.yml`
- Create: `.github/pull_request_template.md`
- Create: `scripts/check-community-files.sh`
- Create: `scripts/test-community-files.sh`
- Modify: `README.md`
- Modify: `README.fr.md`
- Modify: `CONTRIBUTING.md`
- Modify: `.Codex/CODEMAP.md`
- Modify: `.github/workflows/eco-audit.yml`

**Interfaces:**
- Consumes: repository community files and issue-form YAML.
- Produces: `scripts/check-community-files.sh`, a deterministic structural validator used locally and in CI.

- [ ] Write a failing validator test against a fixture missing required files, invalid owners and unsafe public-security routing.
- [ ] Run the test and verify RED.
- [ ] Implement the minimal validator: required-file checks, exact global owners, private security URL, issue-form required fields, YAML parsing where available, and local Markdown link targets.
- [ ] Add the policy files and GitHub templates described by the spec, keeping prose concise and actionable.
- [ ] Link the policy surface from both READMEs and contribution guidance; update CODEMAP.
- [ ] Add community validation to ordinary CI.
- [ ] Run validator tests, the real validator, YAML parsing, link checks and `git diff --check`.
- [ ] Commit as `docs: add community health and governance files`.

### Task 3: Full local review and branch publication

**Files:**
- Verify: all files changed since `origin/main`.
- External state: remote branch and pull request.

- [ ] Run version tests, community tests, audit tests, cache tests, Bash syntax, ShellCheck, JSON/YAML validation and `git diff --check origin/main..HEAD`.
- [ ] Request an independent read-only code review; resolve all Important findings and rerun affected tests.
- [ ] Confirm a clean worktree and that only intended commits are ahead of `origin/main`.
- [ ] Push `chore/github-professionalization` and open a PR against `main` with summary, test evidence and governance implications.
- [ ] Wait for CI and record the exact successful status-check names.

### Task 4: Apply and verify GitHub governance

**Files:**
- External state only: repository settings, Actions permissions and ruleset/branch protection.

- [ ] Read repository metadata, Actions permissions, existing branch protection/rulesets and bypass actors through GitHub APIs.
- [ ] Compute the smallest patch that adds only missing protections and never weakens stronger settings.
- [ ] Enable automatic deletion of merged branches and read-only default workflow permissions with first-time-contributor approval where supported.
- [ ] Require PRs, one approval, stale-review dismissal, conversation resolution and the exact CI checks observed on the PR; prohibit force-push/deletion and remove routine bypass where API permissions allow.
- [ ] Read every setting back and compare it with the target state.
- [ ] Report the PR URL, verified protections and any organization/plan limitation. Leave the PR open for a named owner to review and merge.
