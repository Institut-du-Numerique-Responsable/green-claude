# Security Audit: Secret Scanning and Token Leak Protection

## Current Status (as of 2026-09-05)

### Secret Scanning
- **Status**: ✅ **ENABLED**
- **API Response**: `{"status": "enabled"}`
- **Activated**: Immediately via GitHub API by gridboy

### Secret Scanning Push Protection
- **Status**: ✅ **ENABLED**
- **API Response**: `{"status": "enabled"}`
- **Activated**: Immediately via GitHub API by gridboy

### Organization Defaults (Institut-du-Numerique-Responsable)
- `secret_scanning_enabled_for_new_repositories: false`
- `secret_scanning_push_protection_enabled_for_new_repositories: false`

**Note**: Organization defaults remain disabled, but this repository has been individually configured with Secret Scanning + Push Protection enabled.

## Recommendations

### 1. Enable Secret Scanning

**For this repository:**
1. Go to: https://github.com/Institut-du-Numerique-Responsable/green-claude/settings/security_analysis
2. Check "Secret scanning"
3. Save

**For the organization (to apply to all repositories):**
1. Go to: https://github.com/organizations/Institut-du-Numerique-Responsable/settings/security-analysis
2. Enable "Secret scanning" for all repositories
3. Enable "Push protection" to block pushes containing secrets
4. Save

### 2. Enable Push Protection

**For this repository:**
1. Go to: https://github.com/Institut-du-Numerique-Responsable/green-claude/settings/security_analysis
2. Check "Secret scanning push protection"
3. Save

**Note**: Push protection requires Secret Scanning to be enabled first.

### 3. Additional Security Measures

- ✅ Repository is **public** - secret scanning is available for public repos
- ✅ Branch protection is enabled for `main` (requires PR for changes)
- ⚠️ Consider enabling "Require status checks to pass before merging" to include security checks

## Verification

After enabling, verify with:

```bash
# Check security status
gh api repos/Institut-du-Numerique-Responsable/green-claude | jq '.security_and_analysis'

# Should return:
# {
#   "secret_scanning": {"status": "enabled"},
#   "secret_scanning_push_protection": {"status": "enabled"}
# }
```

## Why This Matters

This repository contains:
- API tokens in workflows (GitHub tokens for CI/CD)
- Potentially AI model API keys in examples
- Organization secrets that could be accidentally committed

Without secret scanning:
- **Commit leaks** go undetected
- **Push protection** doesn't block secrets from being pushed
- **Tokens in PRs** can be merged without warning

With secret scanning + push protection:
- ✅ Commits with secrets are **flagged**
- ✅ Pushes with secrets are **blocked**
- ✅ GitHub **notifies** maintainers
- ✅ **Automatic revocation** of leaked tokens (for supported providers)

## References

- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning)
- [GitHub Push Protection](https://docs.github.com/en/code-security/secret-scanning/secret-scanning-push-protection)
- [Secret Scanning Patterns](https://docs.github.com/en/code-security/secret-scanning/secret-scanning-patterns)
