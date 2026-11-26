# Privacy

Green Claude collects no data. The plugin has no telemetry, no account and no server of its own.

- **Skill and rules**: text files that Claude Code loads into the session. Your code reaches Claude the same way it does in any Claude Code session, under Anthropic's terms.
- **Audit scripts** (`eco-audit.sh`, `eco-score.sh`): Bash, awk and jq that run on your machine. They make no network call and send nothing anywhere.
- **Hooks**: they run the audit locally. The `[cache]` hook stores replies in `~/.cache/green-claude` (or `GREEN_CLAUDE_CACHE_DIR`) on your machine and deletes them after one hour.
- **Website** (institut-du-numerique-responsable.github.io/green-claude): self-hosted Matomo audience measurement, with cookies disabled and no third-party tracker. The plugin itself never contacts this site.

Questions: open an issue on [GitHub](https://github.com/Institut-du-Numerique-Responsable/green-claude/issues) or see [SUPPORT.md](SUPPORT.md).

## Confidentialité

Green Claude ne collecte aucune donnée. Le plugin n'a ni télémétrie, ni compte, ni serveur. Les scripts d'audit tournent sur votre machine sans appel réseau, et le cache `[cache]` reste dans `~/.cache/green-claude`, purgé après une heure. Le site de présentation mesure son audience avec un Matomo auto-hébergé, sans cookie ni traceur tiers.
