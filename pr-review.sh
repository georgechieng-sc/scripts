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

# Review then approve PR workflow
# Usage: rr (uses clipboard content)
function rr() {
	local pr_url="$(pbpaste)"
	
	if [[ -z "$pr_url" ]]; then
		echo -e "${RED}ERROR: No PR URL in clipboard${RESET}"
		return 1
	fi

	local go_tmpl='{{.title}}{{.body}}'
	gh pr view --json title,body --template "$go_tmpl" "$pr_url"
	echo "opening PR diff to review..."
	prd "$pr_url"

	echo "Are you sure you want to approve? [yn]"
	local yn="$(yesno)"
	if [[ $yn =~ ^[Yy]$ ]]; then
		echo "approving PR: $pr_url"
		stamp
		return
	fi

	if [[ $yn =~ ^[Nn]$ ]]; then
		echo "Do you want to open the PR in web? [yn]"
		local c="$(yesno)"
		if [[ $c =~ ^[Yy]$ ]]; then
			gh pr view --web "$pr_url"
		fi
	fi
}

# AI-powered PR review
# Usage: review (uses clipboard content)
review() {
  local pr_url="$(pbpaste)"
  local md_prompt="$(cat "${PROMPTS_DIR}/analyze_pull-request.md")"
  
  if [[ -z "$pr_url" ]]; then
    echo -e "${RED}ERROR: No PR URL in clipboard${RESET}"
    echo "Usage: Copy PR URL to clipboard and run review"
    return 1
  fi

  local diff
  diff="$(gh pr diff "$pr_url")"
  
  if [[ -z "$diff" ]]; then
    echo -e "${RED}ERROR: Could not retrieve diff for $pr_url${RESET}"
    return 1
  fi

  local prompt="$diff \n === \n $md_prompt"
  echo "$prompt" | chatgpt -q | mdless
}
