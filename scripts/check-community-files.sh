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
    grep -Eq '^\*[[:space:]]+@gridboy[[:space:]]+@robintra[[:space:]]*$' "$ROOT_DIR/.github/CODEOWNERS" \
        || error "CODEOWNERS doit attribuer * à @gridboy et @robintra"
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

for form in bug.yml false-positive.yml new-rule.yml; do
    path="$ROOT_DIR/.github/ISSUE_TEMPLATE/$form"
    [ -s "$path" ] || continue
    grep -Eq '^name:[[:space:]]+.+' "$path" || error "$form n'a pas de nom"
    grep -Eq '^description:[[:space:]]+.+' "$path" || error "$form n'a pas de description"
    grep -Eq '^body:' "$path" || error "$form n'a pas de formulaire body"
    grep -Eq 'required:[[:space:]]+true' "$path" || error "$form ne contient aucun champ obligatoire"
done

if command -v ruby >/dev/null 2>&1; then
    for yaml in "$ROOT_DIR"/.github/ISSUE_TEMPLATE/*.yml; do
        [ -f "$yaml" ] || continue
        ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0))' "$yaml" >/dev/null \
            || error "$yaml n'est pas un YAML valide"
    done
fi

[ "$ERRORS" -eq 0 ] || exit 1
echo "OK - fichiers communautaires valides"
