#!/bin/bash
# Shared routing for the CLI, hooks and repository score (Bash 3.2 compatible).
ext_of() {
    local base="${1##*/}"
    printf '%s' "${base##*.}" | tr '[:upper:]' '[:lower:]'
}

load_audit_extensions() {
    local rules_dir
    rules_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../rules" && pwd)" || return 1
    # Keep prose/catalog files out of automatic audits. Explicit CLI audits
    # remain available for Markdown and JSON.
    AUDIT_EXTENSIONS="$(jq -rs '
        [ .[] | (.metadata.extensions[]?, .categories[].rules[].extensions[]?) ]
        | unique | map(select(. != "md" and . != "json")) | join(" ")
    ' "$rules_dir/ecoconception.json" "$rules_dir/langages/"*.json)" || return 1
}

is_auditable_file() {
    local ext
    ext="$(ext_of "$1")"
    case " $AUDIT_EXTENSIONS " in
        *" $ext "*) return 0 ;;
        *) return 1 ;;
    esac
}

# Mode économe : GREEN_CLAUDE_LEAN liste ce qu'on coupe (report, brief, audit),
# ou « all ». À régler dans le bloc "env" de ~/.claude/settings.json.
lean_on() {
    case ",$(printf '%s' "${GREEN_CLAUDE_LEAN:-}" | tr -d ' ' | tr '[:upper:]' '[:lower:]')," in
        *,all,*|*,1,*|*,"$1",*) return 0 ;;
    esac
    return 1
}
