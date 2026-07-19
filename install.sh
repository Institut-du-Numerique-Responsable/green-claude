#!/bin/bash

# =============================================================================
# Green Claude — Script d'installation
# Installe le wrapper éco-responsable pour Claude Code dans ~/green-claude
# =============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/green-claude"

# Fonctions d'affichage
print_error()   { echo -e "${RED}[ERREUR]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[ATTENTION]${NC} $1"; }

# =============================================================================
# Vérification root
# =============================================================================
if [ "$EUID" -eq 0 ]; then
    print_warning "L'installation en root n'est pas recommandée. Utilise ton utilisateur normal."
fi

# =============================================================================
# Étape 1 : Dossier d'installation
# =============================================================================
print_info "Création du dossier $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
print_success "Dossier créé"

# =============================================================================
# Étape 2 : Copie des fichiers
# =============================================================================
print_info "Copie des fichiers..."
cp "$SCRIPT_DIR/green-claude" "$INSTALL_DIR/"
cp -r "$SCRIPT_DIR/rules" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/green-claude"
print_success "Fichiers copiés"

# =============================================================================
# Étape 3 : Configuration du PATH
# =============================================================================
print_info "Configuration du PATH..."

if grep -q "green-claude" "$HOME/.bashrc" "$HOME/.zshrc" 2>/dev/null; then
    print_info "PATH déjà configuré"
else
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] || continue
        {
            echo ""
            echo "# Green Claude — wrapper éco-responsable pour Claude Code"
            echo 'export PATH="$HOME/green-claude:$PATH"'
        } >> "$rc"
    done
    print_success "PATH configuré"
    print_info "Ouvre un nouveau terminal ou exécute : source ~/.zshrc (ou ~/.bashrc)"
fi

# =============================================================================
# Résumé final
# =============================================================================
print_info ""
print_success "=========================================="
print_success "✅ Installation de Green Claude terminée !"
print_success "=========================================="
print_info ""
print_info "Pour commencer :"
print_info "  green-claude --help"
print_info "  green-claude --file mon_fichier.js --eco-check"
print_info "  green-claude --complexity simple \"Ta question\""
print_info ""
print_info "Dossier d'installation : $INSTALL_DIR"
print_info ""
print_info "Prérequis pour les requêtes IA :"
print_info "  npm install -g @anthropic-ai/claude-code"
print_info ""
print_info "Astuce : installe jq pour activer l'audit avancé (RGESN/GR491/GSF) :"
print_info "  brew install jq        (macOS)"
print_info "  sudo apt install jq    (Debian/Ubuntu)"
print_info ""
