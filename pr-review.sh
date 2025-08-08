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
# Usage: review [-c] (uses clipboard content, -c to leave comment)
review() {
  local leave_comment=false
  local pr_url
  local md_prompt
  
  # Parse flags
  while [[ $# -gt 0 ]]; do
    case $1 in
      -c|--comment)
        leave_comment=true
        shift
        ;;
      *)
        echo -e "${RED}ERROR: Unknown flag $1${RESET}"
        echo "Usage: review [-c] (uses clipboard content, -c to leave comment)"
        return 1
        ;;
    esac
  done
  
  pr_url="$(pbpaste)"
  md_prompt="$(cat "${PROMPTS_DIR}/analyze_pull-request.md")"
  
  if [[ -z "$pr_url" ]]; then
    echo -e "${RED}ERROR: No PR URL in clipboard${RESET}"
    echo "Usage: Copy PR URL to clipboard and run review [-c]"
    return 1
  fi

  local diff
  diff="$(gh pr diff "$pr_url")"
  
  if [[ -z "$diff" ]]; then
    echo -e "${RED}ERROR: Could not retrieve diff for $pr_url${RESET}"
    return 1
  fi

  local prompt="$diff \n === \n $md_prompt"
  local review_output
  review_output="$(echo "$prompt" | chatgpt -q)"
  
  if [[ "$leave_comment" == true ]]; then
    echo "$review_output" | gh pr comment "$pr_url" --body-file -
    echo -e "${GREEN}Review comment posted to PR${RESET}"
  else
    echo "$review_output" | glow
  fi
}
