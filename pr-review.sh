#!/bin/sh

# =============================================================================
# PR REVIEW FUNCTIONS
# =============================================================================

# Auto stamp PR approval
# Usage: stamp (uses clipboard content)
function stamp() {
	local pr_url="$(pbpaste)"
	
	if [[ -n "$pr_url" ]]; then
		gh pr review "$pr_url" -a
	else
		echo -e "${RED}ERROR: No PR URL in clipboard${RESET}"
		return 1
	fi
}

# Show PR diff
# Usage: prd [pr_url] (uses clipboard if no URL provided)
function prd() {
	local pr_url="${1:-$(pbpaste)}"
	
	if [[ -n "$pr_url" ]]; then
		gh pr diff "$pr_url"
	else
		gh pr diff
	fi
}
