#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER="$SCRIPT_DIR/check-release-version.sh"

fail() {
    echo "ECHEC - $1" >&2
    exit 1
}

[ -f "$CHECKER" ] || fail "scripts/check-release-version.sh est absent"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

make_fixture() {
    local target="$1"
    mkdir -p "$target/scripts" "$target/.claude-plugin" "$target/skills/green-claude"
    cp "$CHECKER" "$target/scripts/check-release-version.sh"
    chmod +x "$target/scripts/check-release-version.sh"
    printf '{"version":"1.4.0"}\n' > "$target/.claude-plugin/plugin.json"
    cat > "$target/skills/green-claude/SKILL.md" <<'EOF'
---
name: green-claude
version: 1.4.0
---
EOF
    cat > "$target/CHANGELOG.md" <<'EOF'
# Changelog

## [1.4.0] - 2026-08-27
EOF
}

expect_success() {
    local fixture="$1" version="$2"
    "$fixture/scripts/check-release-version.sh" "$version" >/dev/null 2>&1 \
        || fail "la version valide $version a été refusée"
}

expect_failure() {
    local fixture="$1" version="$2" expected="$3" output
    if output="$("$fixture/scripts/check-release-version.sh" "$version" 2>&1)"; then
        fail "la version invalide $version a été acceptée"
    fi
    printf '%s' "$output" | grep -Fq "$expected" \
        || fail "diagnostic absent pour $version : $expected"
}

make_fixture "$TMP_DIR/valid"
expect_success "$TMP_DIR/valid" "1.4.0"
expect_success "$TMP_DIR/valid" "v1.4.0"
expect_failure "$TMP_DIR/valid" "1.4" "format SemVer invalide"

make_fixture "$TMP_DIR/plugin-mismatch"
printf '{"version":"1.3.0"}\n' > "$TMP_DIR/plugin-mismatch/.claude-plugin/plugin.json"
expect_failure "$TMP_DIR/plugin-mismatch" "v1.4.0" ".claude-plugin/plugin.json déclare 1.3.0"

make_fixture "$TMP_DIR/skill-mismatch"
sed 's/version: 1.4.0/version: 1.3.0/' \
    "$TMP_DIR/skill-mismatch/skills/green-claude/SKILL.md" \
    > "$TMP_DIR/skill-mismatch/skills/green-claude/SKILL.md.tmp"
mv "$TMP_DIR/skill-mismatch/skills/green-claude/SKILL.md.tmp" \
    "$TMP_DIR/skill-mismatch/skills/green-claude/SKILL.md"
expect_failure "$TMP_DIR/skill-mismatch" "v1.4.0" "SKILL.md déclare 1.3.0"

make_fixture "$TMP_DIR/changelog-mismatch"
printf '# Changelog\n' > "$TMP_DIR/changelog-mismatch/CHANGELOG.md"
expect_failure "$TMP_DIR/changelog-mismatch" "v1.4.0" "CHANGELOG.md ne contient pas de section [1.4.0]"

echo "OK - cohérence des versions vérifiée"
