# GitHub Governance and Audit Path Safety Design

## Goal

Eliminate cleaned-file collisions in multi-file audits, provide a complete and approachable GitHub contribution surface, and enforce review-based changes to `main` without granting broader permissions than necessary.

## Audit temporary-file identity

`eco-audit.sh` currently maps source paths to temporary names by replacing `/` and spaces with underscores. Distinct paths such as `src/a_b.js` and `src/a/b.js` therefore collide and the later cleaned file can replace the earlier one.

Replace this mapping with a deterministic SHA-256 identifier of the exact path string. Prefer `shasum -a 256`, available on supported macOS installations, and fall back to `sha256sum` on Linux environments where `shasum` is absent. If neither command exists, stop with an actionable error rather than silently using a collision-prone mapping. Preserve Bash 3.2 compatibility.

Regression coverage must create two files whose old normalized names collide, give them observably different audit outcomes, and demonstrate that each file is scanned against its own cleaned content. Tests must also cover the hash-command fallback and missing-command diagnostic without mocking audit behavior.

## Community health files

Add the following repository-level interfaces:

- `SECURITY.md`: supported release policy, private reporting through GitHub Security Advisories, expected acknowledgement, coordinated-disclosure guidance, and a warning not to open public vulnerability issues.
- `CODE_OF_CONDUCT.md`: Contributor Covenant 2.1, with enforcement contact routed through the Institut du Numérique Responsable rather than a personal address.
- `.github/CODEOWNERS`: `@gridboy` and `@robintra` own the repository globally.
- `.github/ISSUE_TEMPLATE/bug.yml`: reproducible product or installation defect.
- `.github/ISSUE_TEMPLATE/false-positive.yml`: rule ID, minimal source sample, observed/expected result, tool versions and environment.
- `.github/ISSUE_TEMPLATE/new-rule.yml`: source/reference, target language or RGESN family, examples that should and should not match, impact rationale.
- `.github/ISSUE_TEMPLATE/config.yml`: disable blank issues and direct security reports to the private channel.
- `.github/pull_request_template.md`: scope, evidence/source, tests, false-positive analysis, documentation and changelog checklist.
- `SUPPORT.md`: route usage questions, bugs and vulnerabilities to the correct channels.
- `GOVERNANCE.md`: maintainer responsibilities, consensus-first decisions, CODEOWNERS review, release authority and inactivity handling.

Keep the documents concise and bilingual where a single file is practical. Link the policy surface from both READMEs and `CONTRIBUTING.md`. Update `.Codex/CODEMAP.md` for structural additions.

## GitHub repository governance

Inspect the current repository settings and branch/ruleset configuration before writing remote state. Apply the smallest configuration that achieves:

- changes to `main` arrive through pull requests;
- at least one approval is required;
- stale approvals are dismissed when new commits are pushed;
- all review conversations must be resolved;
- required CI checks must pass before merge, using the actual check names observed on the PR;
- force pushes and branch deletion remain forbidden;
- administrators and bypass actors do not routinely bypass the rules;
- merged branches are deleted automatically;
- GitHub Actions workflow permissions default to read-only, with PR approval required for workflows from first-time external contributors where supported.

Do not guess organization actor IDs, change repository visibility, enable paid-only features, or weaken an existing rule. If GitHub rejects a setting because of plan or organization policy, preserve the stronger current state and report the exact limitation.

## Delivery sequence

Work on `chore/github-professionalization`, not directly on `main`. Implement and test the collision fix first, then add community files and local validation, then audit and adjust remote settings. Push the branch, open a pull request, observe the actual CI check names, and only then finalize the required-status-check configuration. Do not self-merge the pull request merely to finish the task; leave the final review decision to the named owners.

## Verification

Completion requires:

- red/green regression proof for colliding audit paths;
- full audit and cache suites passing;
- Bash syntax and ShellCheck passing with only documented pre-existing exclusions;
- JSON, YAML and issue-form validation;
- all community links resolving locally;
- an independent code review with Important findings resolved;
- a GitHub pull request showing the expected CI checks;
- read-back of repository and branch/ruleset settings proving the requested protections, or an explicit report of any GitHub-enforced limitation.
