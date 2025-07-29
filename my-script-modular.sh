#!/bin/sh

# =============================================================================
# SafetyCulture Development Scripts - Main Loader
# =============================================================================
# This script loads all modular components of the SafetyCulture development
# environment. Each module can be loaded independently if needed.

# Get the directory where this script is located
# Use BASH_SOURCE for bash, $0 for zsh/sh
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
SCRIPTS_DIR="${SCRIPT_DIR}"

# Check for verbose flag
VERBOSE=false
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
    VERBOSE=true
fi

# Function to safely source a script file
source_script() {
    local script_file="$1"
    local script_path="${SCRIPTS_DIR}/${script_file}"
    
    if [[ -f "$script_path" ]]; then
        source "$script_path"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "✅ Loaded: $script_file"
        fi
    else
        echo "❌ Failed to load: $script_file (file not found)" >&2
        return 1
    fi
}

# Load all modules in order of dependency
if [[ "$VERBOSE" == "true" ]]; then
    echo "🚀 Loading SafetyCulture Development Environment..."
fi

# Core modules (loaded first - no dependencies)
source_script "constants.sh"        # Constants and color codes
source_script "aliases.sh"          # All aliases
source_script "installation.sh"     # Installation functions

# Utility modules (depend on constants)
source_script "utilities.sh"        # Utility functions (including select_board)

# Feature modules (depend on utilities and constants)
source_script "git.sh"              # Git workflow functions
source_script "jira.sh"             # JIRA integration functions
source_script "repository.sh"       # Repository management
source_script "pr-review.sh"        # PR review workflow
source_script "specialized.sh"      # Specialized utility functions

if [[ "$VERBOSE" == "true" ]]; then
    echo "✨ All modules loaded successfully!"
    echo ""
    echo "📋 Available function categories:"
    echo "   • Installation: install-hb, install-omzsh, install-deps, set-kubeconf"
    echo "   • Git Workflow: branch, pr, gacp, gbdi"
    echo "   • JIRA: sync_board, ats, resm, jbr, mvj, jdiff"
    echo "   • Repository: repo, grc"
    echo "   • PR Review: stamp, prd, rr, review"
    echo "   • Utilities: tpa, cleanpipe, timezsh, giffy, cdi, sci"
    echo "   • Specialized: s12id, ids12, pw, auto-sql"
    echo ""
    echo "💡 Tip: Each script can be sourced individually from the same directory"
fi
