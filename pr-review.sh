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
# Usage: rr [--approve] [pr_url] (uses clipboard if no URL)
function rr() {
	local auto_approve=false

	if [[ "$1" == "--approve" ]]; then
		auto_approve=true
		shift
	fi

	local pr_url="${1:-$(pbpaste)}"

	if [[ -z "$pr_url" ]]; then
		echo -e "${RED}ERROR: No PR URL in clipboard or argument${RESET}"
		return 1
	fi

	local go_tmpl='{{.title}}{{.body}}'
	gh pr view --json title,body --template "$go_tmpl" "$pr_url"
	echo "opening PR diff to review..."
	prd "$pr_url"

	if [[ "$auto_approve" == true ]]; then
		echo "approving PR: $pr_url"
		gh pr review "$pr_url" -a
	fi
}

# Post or preview PR review text
# Usage: review [-c] <review_text> (reads PR URL from clipboard)
review() {
  local leave_comment=false
  local pr_url
  local review_output=""

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case $1 in
      -c|--comment)
        leave_comment=true
        shift
        ;;
      *)
        review_output="$1"
        shift
        ;;
    esac
  done

  pr_url="$(pbpaste)"

  if [[ -z "$pr_url" ]]; then
    echo -e "${RED}ERROR: No PR URL in clipboard${RESET}"
    echo "Usage: Copy PR URL to clipboard and run review [-c] <review_text>"
    return 1
  fi

  if [[ -z "$review_output" ]]; then
    echo -e "${RED}ERROR: Review text is required${RESET}"
    echo "Usage: review [-c] <review_text>"
    return 1
  fi

  if [[ "$leave_comment" == true ]]; then
    echo "$review_output" | gh pr comment "$pr_url" --body-file -
    echo -e "${GREEN}Review comment posted to PR${RESET}"
  else
    echo "$review_output" | glow
  fi
}
