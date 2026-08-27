#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REQUESTED="${1:-}"
VERSION="${REQUESTED#v}"
ERRORS=0

error() {
    echo "ERREUR - $1" >&2
    ERRORS=$((ERRORS + 1))
}

if [ -z "$REQUESTED" ] || ! printf '%s' "$VERSION" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; then
    echo "ERREUR - format SemVer invalide : ${REQUESTED:-<vide>} (attendu : vMAJOR.MINOR.PATCH ou MAJOR.MINOR.PATCH)" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "ERREUR - jq est requis pour vérifier la version de release." >&2
    exit 1
fi

PLUGIN_VERSION="$(jq -r '.version // empty' "$ROOT_DIR/.claude-plugin/plugin.json" 2>/dev/null || true)"
SKILL_VERSION="$(awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && /^version:[[:space:]]*/ {
        sub(/^version:[[:space:]]*/, "")
        print
        exit
    }
' "$ROOT_DIR/skills/green-claude/SKILL.md")"

[ "$PLUGIN_VERSION" = "$VERSION" ] \
    || error ".claude-plugin/plugin.json déclare ${PLUGIN_VERSION:-<aucune version>}, attendu $VERSION"
[ "$SKILL_VERSION" = "$VERSION" ] \
    || error "SKILL.md déclare ${SKILL_VERSION:-<aucune version>}, attendu $VERSION"
ESCAPED_VERSION="${VERSION//./\.}"
grep -Eq "^## \\[$ESCAPED_VERSION\\]( - [0-9]{4}-[0-9]{2}-[0-9]{2})?$" "$ROOT_DIR/CHANGELOG.md" 2>/dev/null \
    || error "CHANGELOG.md ne contient pas de section [$VERSION]"

if [ "$ERRORS" -ne 0 ]; then
    exit 1
fi

echo "OK - release v$VERSION cohérente"
