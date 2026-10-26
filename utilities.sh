#!/bin/sh

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Interactive directory change using fzf
# Usage: cdi [dir_name]
function cdi() {
	local dir="${1:-$(ls | fzf --cycle --color=dark | xargs)}"

	if [[ -n "$dir" ]]; then
		cd "$dir"
	fi
}

# SafetyCulture directory + interactive cd
# Usage: sci [dir_name]
function sci() {
	cd "$SAFETYCULTURE_DIR"
	cdi "$1"
}
