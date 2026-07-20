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
cp -r "$SCRIPT_DIR/skill/green-claude/." "$SKILLS_DIR/"
chmod +x "$SKILLS_DIR/scripts/"*.sh
print_success "Skill installé"

if ! command -v jq >/dev/null 2>&1; then
    print_warning "jq n'est pas installé : le script d'audit (scripts/eco-audit.sh) en a besoin."
    print_warning "  brew install jq        (macOS)"
    print_warning "  sudo apt install jq    (Debian/Ubuntu)"
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
    print_warning "Câblage à faire à la main dans $SETTINGS_FILE (les clés exactes dépendent"
    print_warning "de ta version de Claude Code — vérifie la doc hooks avant de coller) :"
    cat << 'EOF'

  {
    "hooks": {
      "UserPromptSubmit": [
        { "hooks": [{ "type": "command", "command": "~/.claude/hooks/green-claude-cache.sh" }] }
      ],
      "Stop": [
        { "hooks": [{ "type": "command", "command": "~/.claude/hooks/green-claude-cache-save.sh" }] }
      ]
    }
  }

EOF
else
    print_info "Hook ignoré — installable plus tard depuis $SCRIPT_DIR/hooks/"
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
