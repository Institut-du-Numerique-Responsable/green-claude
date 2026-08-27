# Release Professionalization Design

## Goal

Make `v1.4.0` a reproducible, verifiable GitHub release and establish one durable release convention for subsequent versions.

## Version policy

All new releases use Semantic Versioning tags in the exact form `vMAJOR.MINOR.PATCH`. Existing historical tags remain untouched because renaming or deleting published tags would break references. The version declared in `.claude-plugin/plugin.json` and the `version` frontmatter in `skills/green-claude/SKILL.md` must equal the tag without its leading `v`.

The changelog uses Keep a Changelog headings and contains an entry for every published line from 1.0.0 through 1.4.0. Version 1.4.0 describes the repository state currently declared as 1.4.0; it is not used to introduce unrelated product changes.

## Consistency checker

A dependency-free shell script validates a supplied release version. It accepts either `1.4.0` or `v1.4.0`, rejects non-SemVer input, and confirms that:

- `.claude-plugin/plugin.json` contains the same version;
- `skills/green-claude/SKILL.md` contains the same frontmatter version;
- `CHANGELOG.md` contains a heading for that version.

The script must work with Bash 3.2 and `jq`, return a non-zero status with an actionable message on mismatch, and have regression coverage for valid, malformed and inconsistent versions.

## GitHub Actions

The existing CI runs the consistency test in addition to the current JSON and audit suites. Actions are pinned to immutable commit SHAs, workflow permissions default to read-only, jobs have explicit timeouts, and obsolete branch/PR runs are cancelled through concurrency controls.

A separate release workflow is triggered only by tags matching `v*.*.*`. It:

1. checks out the exact tagged commit;
2. validates that the tag and repository versions match;
3. runs the audit and cache test suites;
4. builds the Claude.ai and Claude API archives;
5. publishes a GitHub Release with generated notes and both archives.

Only the publication job receives `contents: write`; validation remains read-only. The workflow must fail before publication if the version is inconsistent or packaging/tests fail.

## Release 1.4.0

After local verification, create the annotated tag `v1.4.0` on the reviewed release commit and push it to `origin`. The workflow then creates the GitHub release. Verify the remote tag, workflow result, release page and attached archives. Do not modify the legacy `green-claude--v1.2.0` and `green-claude--v1.3.0` tags.

## Documentation

The English and French READMEs briefly document the `vMAJOR.MINOR.PATCH` convention and link to `CHANGELOG.md`. Contributor instructions state that release metadata must stay aligned and identify the local validation command.

## Verification

Completion requires fresh evidence from:

- consistency-check regression tests;
- the full eco-audit test suite;
- cache-hook tests;
- Bash syntax checks and ShellCheck;
- JSON validation;
- package generation and archive inspection;
- clean Git status after commit;
- remote confirmation that `v1.4.0` and its GitHub release exist with both assets.

