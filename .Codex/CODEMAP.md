# Green Claude — code map

`README.md` — English project overview, installation, usage, rule inventory, packaging and contribution entry point.
`README.fr.md` — French counterpart of the project overview.
`CONTRIBUTING.md` — contribution rules for adding and testing audit rules and detectors.
`CITATION.cff` — software citation metadata and authorship.
`install.sh` — interactive installer for the skill and optional Claude Code hooks.
`.claude-plugin/plugin.json` — Claude Code plugin metadata and current public version.
`.claude-plugin/marketplace.json` — local marketplace descriptor for the plugin.
`.github/workflows/eco-audit.yml` — CI for JSON validation, audit tests and repository eco-score.
`hooks/green-claude-audit.sh` — PostToolUse hook auditing newly written code.
`hooks/green-claude-cache.sh` — UserPromptSubmit hook serving short-lived cached responses.
`hooks/green-claude-cache-save.sh` — Stop hook extracting and storing the final response.
`hooks/green-claude-pre-commit.sh` — optional staged-file eco-audit.
`hooks/test-cache.sh` — deterministic cache-hook regression tests.
`skills/green-claude/SKILL.md` — skill trigger description and operating instructions; declares the current version.
`skills/green-claude/rules/ecoconception.json` — 52 cross-language eco-design rules.
`skills/green-claude/rules/boris.json` — sober Claude usage practices.
`skills/green-claude/rules/langages/*.json` — 80 language-specific rules across ten languages.
`skills/green-claude/scripts/eco-audit.sh` — deterministic rule engine over source files.
`skills/green-claude/scripts/eco-score.sh` — weighted issue-density measurement for repositories.
`skills/green-claude/scripts/test-eco-audit.sh` — end-to-end audit and packaging regression suite.
`skills/green-claude/scripts/package-skill.sh` — builds Claude.ai and Claude API zip archives.
`skills/green-claude/scripts/detect-*.awk` — structural detectors for patterns that grep cannot assess reliably.
`skills/green-claude/scripts/inspect-*.sh` — best-effort enrichment using referenced local assets.
`docs/index.html` — GitHub Pages landing page.
`docs/assets/logo.jpg` — public project logo.
`docs/robots.txt` — crawler policy for the public site.
`docs/sitemap.xml` — public-site sitemap.
`docs/llms.txt` — concise machine-readable project description.

