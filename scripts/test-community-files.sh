#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER="$SCRIPT_DIR/check-community-files.sh"

fail() {
    echo "ECHEC - $1" >&2
    exit 1
}

[ -f "$CHECKER" ] || fail "scripts/check-community-files.sh est absent"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/scripts"
cp "$CHECKER" "$TMP_DIR/scripts/check-community-files.sh"
cp "$SCRIPT_DIR/validate-issue-forms.rb" "$TMP_DIR/scripts/validate-issue-forms.rb"
chmod +x "$TMP_DIR/scripts/check-community-files.sh"

if COMMUNITY_ROOT="$TMP_DIR" "$TMP_DIR/scripts/check-community-files.sh" >/dev/null 2>&1; then
    fail "un dépôt sans fichiers communautaires a été accepté"
fi

mkdir -p "$TMP_DIR/.github/ISSUE_TEMPLATE"
for file in SECURITY.md CODE_OF_CONDUCT.md SUPPORT.md GOVERNANCE.md .github/pull_request_template.md; do
    mkdir -p "$TMP_DIR/$(dirname "$file")"
    printf '# Test\n' > "$TMP_DIR/$file"
done
printf '* @someone\n' > "$TMP_DIR/.github/CODEOWNERS"
for file in bug.yml false-positive.yml new-rule.yml config.yml; do
    printf 'name: Test\ndescription: Test\nbody: []\n' > "$TMP_DIR/.github/ISSUE_TEMPLATE/$file"
done

if COMMUNITY_ROOT="$TMP_DIR" "$TMP_DIR/scripts/check-community-files.sh" >/dev/null 2>&1; then
    fail "des propriétaires incorrects et un canal sécurité absent ont été acceptés"
fi

printf '* @gridboy @robintra @Guillaume-INR @vcourbou @vincentcourboulay\n' > "$TMP_DIR/.github/CODEOWNERS"
printf '# Security\nhttps://github.com/example/project/security/advisories/new\n' > "$TMP_DIR/SECURITY.md"
cat > "$TMP_DIR/.github/ISSUE_TEMPLATE/config.yml" <<'EOF'
blank_issues_enabled: false
contact_links:
  - name: Security
    url: https://github.com/example/project/security/advisories/new
    about: Private reports
EOF
for file in bug.yml false-positive.yml new-rule.yml; do
    cat > "$TMP_DIR/.github/ISSUE_TEMPLATE/$file" <<'EOF'
name: Test
description: Test form
body:
  - type: textarea
    id: details
    attributes:
      label: Details
    validations:
      required: true
EOF
done
COMMUNITY_ROOT="$TMP_DIR" "$TMP_DIR/scripts/check-community-files.sh" >/dev/null \
    || fail "un jeu de fichiers communautaires valide a été refusé"

printf '[]\n' > "$TMP_DIR/.github/ISSUE_TEMPLATE/new-rule.yml"
if COMMUNITY_ROOT="$TMP_DIR" "$TMP_DIR/scripts/check-community-files.sh" >/dev/null 2>&1; then
    fail "un formulaire dont la racine YAML n'est pas un objet a été accepté"
fi

cat > "$TMP_DIR/.github/ISSUE_TEMPLATE/new-rule.yml" <<'EOF'
name: Test
description: Test form
body:
  - type: textarea
    id: details
    attributes:
      label: Details
    validations:
      required: true
EOF

printf '[]\n' > "$TMP_DIR/.github/ISSUE_TEMPLATE/config.yml"
if COMMUNITY_ROOT="$TMP_DIR" ruby "$TMP_DIR/scripts/validate-issue-forms.rb" >/dev/null 2>&1; then
    fail "une configuration dont la racine YAML n'est pas un objet a été acceptée"
fi
cat > "$TMP_DIR/.github/ISSUE_TEMPLATE/config.yml" <<'EOF'
blank_issues_enabled: false
contact_links:
  - name: Security
    url: https://github.com/example/project/security/advisories/new
    about: Private reports
EOF

cat >> "$TMP_DIR/.github/ISSUE_TEMPLATE/new-rule.yml" <<'EOF'
  - type: input
    id: details
    attributes:
      label: Duplicate
    validations:
      required: true
EOF
if COMMUNITY_ROOT="$TMP_DIR" "$TMP_DIR/scripts/check-community-files.sh" >/dev/null 2>&1; then
    fail "un formulaire contenant deux ids identiques a été accepté"
fi

echo "OK - validations communautaires vérifiées"
