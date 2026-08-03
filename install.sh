#!/bin/bash

# =============================================================================
# Green Claude — Installation
# Installe le skill éco-conception dans ~/.claude/skills/green-claude
# et propose le hook de cache/heures creuses (~/.claude/hooks/).
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills/green-claude"
HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"
CACHE_HOOK="~/.claude/hooks/green-claude-cache.sh"
SAVE_HOOK="~/.claude/hooks/green-claude-cache-save.sh"
AUDIT_HOOK="~/.claude/hooks/green-claude-audit.sh"

# Idempotent : un hook déjà déclaré, sous n'importe quelle forme de chemin,
# n'est pas réajouté. Les hooks existants sont préservés. $4 (facultatif) est
# le matcher, requis pour les événements liés à un outil comme PostToolUse.
wire_hook() { # $1 = événement, $2 = commande, $3 = fichier source, $4 = matcher
    jq --arg e "$1" --arg c "$2" --arg s "/${2##*/}" --arg m "${4:-}" '
      if [.. | objects | .command? // empty] | any(. == $c or endswith($s)) then .
      else
        (if $m == "" then {hooks: [{type: "command", command: $c}]}
         else {matcher: $m, hooks: [{type: "command", command: $c}]}
         end) as $entry
        | .hooks[$e] = ((.hooks[$e] // []) + [$entry])
      end' "$3"
}

print_error()   { echo -e "${RED}[ERREUR]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[ATTENTION]${NC} $1"; }

if [ "$EUID" -eq 0 ]; then
    print_warning "L'installation en root n'est pas recommandée. Utilise ton utilisateur normal."
fi

# =============================================================================
# Étape 1 : Skill (éco-conception du code + pratiques Boris)
# =============================================================================
print_info "Installation du skill dans $SKILLS_DIR..."
mkdir -p "$SKILLS_DIR"
cp -r "$SCRIPT_DIR/skills/green-claude/." "$SKILLS_DIR/"
chmod +x "$SKILLS_DIR/scripts/"*.sh
print_success "Skill installé"

if ! command -v jq >/dev/null 2>&1; then
    print_warning "jq n'est pas installé : le script d'audit (scripts/eco-audit.sh) et les hooks en ont besoin."
    print_warning "  brew install jq        (macOS)"
    print_warning "  sudo apt install jq    (Debian/Ubuntu)"
fi
if ! command -v shasum >/dev/null 2>&1; then
    print_warning "shasum n'est pas installé : les hooks de cache en ont besoin (paquet perl)."
fi

# =============================================================================
# Étape 2 : Hooks (cache local + avertissement heures creuses)
# Optionnel : ce que le skill ne peut pas faire lui-même (interception avant
# l'appel au modèle). Proposé, pas imposé.
# =============================================================================
print_info ""
read -p "Installer aussi le hook de cache local / heures creuses ? (o/n) : " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    mkdir -p "$HOOKS_DIR"
    cp "$SCRIPT_DIR/hooks/green-claude-cache.sh" "$HOOKS_DIR/"
    cp "$SCRIPT_DIR/hooks/green-claude-cache-save.sh" "$HOOKS_DIR/"
    chmod +x "$HOOKS_DIR/green-claude-cache.sh" "$HOOKS_DIR/green-claude-cache-save.sh"
    print_success "Scripts de hook copiés dans $HOOKS_DIR"

    WIRED=0
    if command -v jq >/dev/null 2>&1; then
        [ -s "$SETTINGS_FILE" ] || echo '{}' > "$SETTINGS_FILE"
        # Écriture atomique : le fichier n'est remplacé que si jq a réussi.
        TMP="$(mktemp)"
        if wire_hook "UserPromptSubmit" "$CACHE_HOOK" "$SETTINGS_FILE" > "$TMP" \
           && wire_hook "Stop" "$SAVE_HOOK" "$TMP" > "$TMP.2" \
           && [ -s "$TMP.2" ]; then
            # État d'origine seulement : une réinstallation ne l'écrase pas.
            [ -f "$SETTINGS_FILE.green-claude.bak" ] || cp "$SETTINGS_FILE" "$SETTINGS_FILE.green-claude.bak"
            mv "$TMP.2" "$SETTINGS_FILE"
            WIRED=1
            print_success "Hooks câblés dans $SETTINGS_FILE (sauvegarde : $SETTINGS_FILE.green-claude.bak)"
            print_info "Redémarre Claude Code pour les activer."
        else
            print_error "jq n'a pas pu traiter $SETTINGS_FILE, fichier laissé intact."
        fi
        rm -f "$TMP" "$TMP.2"
    fi

    if [ "$WIRED" -eq 0 ]; then
        print_warning "Câblage à faire à la main dans $SETTINGS_FILE :"
        printf '\n  {\n    "hooks": {\n      "UserPromptSubmit": [\n        { "hooks": [{ "type": "command", "command": "%s" }] }\n      ],\n      "Stop": [\n        { "hooks": [{ "type": "command", "command": "%s" }] }\n      ]\n    }\n  }\n\n' "$CACHE_HOOK" "$SAVE_HOOK"
    fi
else
    print_info "Hook ignoré — installable plus tard depuis $SCRIPT_DIR/hooks/"
fi

# =============================================================================
# Étape 3 : hook d'audit (PostToolUse)
# Le skill est chargé sur décision du modèle, donc appliqué souvent mais jamais
# garanti. Ce hook, lui, est exécuté par Claude Code après chaque écriture de
# fichier de code, sans passer par cette décision.
# =============================================================================
print_info ""
read -p "Installer le hook d'audit après chaque écriture de code (PostToolUse) ? (o/n) : " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    mkdir -p "$HOOKS_DIR"
    cp "$SCRIPT_DIR/hooks/green-claude-audit.sh" "$HOOKS_DIR/"
    chmod +x "$HOOKS_DIR/green-claude-audit.sh"
    print_success "Script d'audit copié dans $HOOKS_DIR"

    AUDIT_WIRED=0
    if command -v jq >/dev/null 2>&1; then
        [ -s "$SETTINGS_FILE" ] || echo '{}' > "$SETTINGS_FILE"
        TMP="$(mktemp)"
        if wire_hook "PostToolUse" "$AUDIT_HOOK" "$SETTINGS_FILE" "Write|Edit|MultiEdit" > "$TMP" \
           && [ -s "$TMP" ]; then
            [ -f "$SETTINGS_FILE.green-claude.bak" ] || cp "$SETTINGS_FILE" "$SETTINGS_FILE.green-claude.bak"
            mv "$TMP" "$SETTINGS_FILE"
            AUDIT_WIRED=1
            print_success "Hook d'audit câblé dans $SETTINGS_FILE"
            print_info "Redémarre Claude Code pour l'activer."
        else
            print_error "jq n'a pas pu traiter $SETTINGS_FILE, fichier laissé intact."
        fi
        rm -f "$TMP"
    fi

    if [ "$AUDIT_WIRED" -eq 0 ]; then
        print_warning "Câblage à faire à la main dans $SETTINGS_FILE :"
        printf '\n  {\n    "hooks": {\n      "PostToolUse": [\n        {\n          "matcher": "Write|Edit|MultiEdit",\n          "hooks": [{ "type": "command", "command": "%s" }]\n        }\n      ]\n    }\n  }\n\n' "$AUDIT_HOOK"
    fi
else
    print_info "Hook d'audit ignoré — installable plus tard depuis $SCRIPT_DIR/hooks/"
fi

# =============================================================================
# Résumé
# =============================================================================
print_info ""
print_success "=========================================="
print_success "✅ Installation de Green Claude terminée !"
print_success "=========================================="
print_info ""
print_info "Le skill s'applique automatiquement dès que Claude Code écrit ou revoit du code."
print_info "Pour la checklist complète : /green-claude"
print_info "Pour un audit ciblé : demande à Claude \"audit éco-conception de ce fichier\""
print_info ""
print_info "Dossier du skill : $SKILLS_DIR"
print_info ""
