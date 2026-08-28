#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${COMMUNITY_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ERRORS=0

error() {
    echo "ERREUR - $1" >&2
    ERRORS=$((ERRORS + 1))
}

required_files='SECURITY.md
CODE_OF_CONDUCT.md
SUPPORT.md
GOVERNANCE.md
.github/CODEOWNERS
.github/pull_request_template.md
.github/ISSUE_TEMPLATE/bug.yml
.github/ISSUE_TEMPLATE/false-positive.yml
.github/ISSUE_TEMPLATE/new-rule.yml
.github/ISSUE_TEMPLATE/config.yml'

while IFS= read -r file; do
    [ -s "$ROOT_DIR/$file" ] || error "$file est absent ou vide"
done <<EOF
$required_files
EOF

if [ -s "$ROOT_DIR/.github/CODEOWNERS" ]; then
    owners_line=$(grep -E '^\*[[:space:]]+' "$ROOT_DIR/.github/CODEOWNERS" | head -n 1 || true)
    for owner in @gridboy @robintra @Guillaume-INR @vcourbou @vincentcourboulay; do
        printf '%s\n' "$owners_line" | grep -Eq "(^|[[:space:]])${owner}([[:space:]]|$)" \
            || error "CODEOWNERS doit attribuer * à $owner"
    done
fi

if [ -s "$ROOT_DIR/SECURITY.md" ]; then
    grep -Fq '/security/advisories/new' "$ROOT_DIR/SECURITY.md" \
        || error "SECURITY.md ne pointe pas vers le signalement privé GitHub"
fi

config="$ROOT_DIR/.github/ISSUE_TEMPLATE/config.yml"
if [ -s "$config" ]; then
    grep -Eq '^blank_issues_enabled:[[:space:]]+false$' "$config" \
        || error "les issues vierges doivent être désactivées"
    grep -Fq '/security/advisories/new' "$config" \
        || error "la configuration des issues ne route pas les vulnérabilités en privé"
fi

if ! command -v ruby >/dev/null 2>&1; then
    error "ruby est requis pour valider le schéma des formulaires GitHub"
elif ! COMMUNITY_ROOT="$ROOT_DIR" ruby "$SCRIPT_DIR/validate-issue-forms.rb" >/dev/null; then
    error "les formulaires GitHub ne respectent pas le schéma attendu"
fi

[ "$ERRORS" -eq 0 ] || exit 1
echo "OK - fichiers communautaires valides"
