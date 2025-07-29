#!/bin/sh

# =============================================================================
# REPOSITORY FUNCTIONS
# =============================================================================

# Sync repository list from SafetyCulture
# Usage: repo
function repo() {
	cd "$SAFETYCULTURE_DIR"
	echo "syncing safetyculture repo list into repo.txt..."
	gh repo list safetyculture --no-archived -L 10000 > repo.txt
	echo "sync done!"
	cd -
}

# Git repo clone interactive
# Usage: grc
function grc() {
	echo "if you haven't sync the repo list please run repo"
	cd "$SAFETYCULTURE_DIR"
	local repo="$(cat "repo.txt" | fzf --cycle --color=dark | cut -f1 | xargs)"

	if [[ -n "$repo" ]]; then
		gh repo clone "$repo"
		cd "$repo"
	fi
}
