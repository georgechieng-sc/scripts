#!/bin/sh

# =============================================================================
# JIRA FUNCTIONS
# =============================================================================

# Dynamic board syncing function
# Usage: sync_board [board_code] 
# If no board_code provided, prompts user to select
function sync_board() {
	local board=""
	
	# If board code is provided as argument, use it
	if [[ -n "$1" ]]; then
		# Validate the provided board code
		case "$1" in
			"RESM") board="$1" ;;
			"PEOPLE") board="$1" ;;
			*) 
				echo "Invalid board code: $1. Valid options: RESM, PEOPLE"
				return 1
				;;
    
		esac
	else
		# No argument provided, prompt user to select
		board=$(select_board)
		if [[ -z "$board" ]]; then
			echo "Board selection cancelled"
			return 1
		fi
	fi
	
	echo "syncing JIRA $board board issues, assigned to you"
	
	# Convert board name to lowercase for filename
	local board_lower=$(echo "$board" | tr '[:upper:]' '[:lower:]')
	
	jira issue list -p "$board" -a$(jira me) -s~"Done" -s~"Won't Do" --plain --columns "KEY" --columns "SUMMARY" --no-headers -t~"Epic" > "${SCRIPTS_DIR}/${JIRA_FILE_PREFIX}${board_lower}.txt"
	echo "sync done"
}

function resm() {
	sync_board "RESM"
}

function peop() {
    sync_board "PEOPLE"
}

# Create a new git branch based on jira ticket ID
# Usage: jbr
function jbr() {
	local board="$(select_board)"
	
	if [[ -z "$board" ]]; then
		echo "Board selection cancelled"
		return 1
	fi
	
	# Convert board name to lowercase for filename
	local board_lower=$(echo "$board" | tr '[:upper:]' '[:lower:]')

	local name="$(cat "${SCRIPTS_DIR}/${JIRA_FILE_PREFIX}${board_lower}.txt" | fzf --cycle --color=dark | cut -f1 | xargs)"

	if [[ -n "$name" ]]; then
		echo "creating branch with the name: $name"
		branch "$name"

		echo "Do you want to move the JIRA ticket to In Progress as well? [yn]"
		local yn="$(yesno)"
		if [[ $yn =~ ^[Yy]$ ]]; then
			echo "moving JIRA issue to In-Progress"
			jira issue move "$name" "In Progress"
		fi
	fi
}

# Move JIRA ticket to different status
# Usage: mvj
function mvj() {
	local board="$(select_board)"
	
	if [[ -z "$board" ]]; then
		echo "Board selection cancelled"
		return 1
	fi

	# Convert board name to lowercase for filename
	local board_lower=$(echo "$board" | tr '[:upper:]' '[:lower:]')

	local name="$(cat "${SCRIPTS_DIR}/${JIRA_FILE_PREFIX}${board_lower}.txt" | fzf --cycle --color=dark | cut -f1 | xargs)"
	if [[ -n "$name" ]]; then
		echo "moving JIRA ticket: $name"
		local pr_status="$(select_status)"
		jira issue move "$name" "$pr_status"
	fi
}

# AI-powered JIRA ticket creation based on git diff
# Usage: jdiff
jdiff() {
    echo -e "${BLUE}Step 1: Checking required tools...${RESET}"
    command -v git >/dev/null 2>&1 || { echo -e "${RED}git is required but not installed. Aborting.${RESET}" >&2; return 1; }
    command -v chatgpt >/dev/null 2>&1 || { echo -e "${RED}chatgpt CLI is required but not installed. Aborting.${RESET}" >&2; return 1; }
    command -v jira >/dev/null 2>&1 || { echo -e "${RED}jira-cli is required but not installed. Aborting.${RESET}" >&2; return 1; }
    command -v branch >/dev/null 2>&1 || { echo -e "${YELLOW}br command not found. Will skip branch creation.${RESET}" >&2; }

    echo -e "${BLUE}Step 2: Prompting user to choose project...${RESET}"
    local PROJECT_CODE=$(select_board)
    [[ -z "$PROJECT_CODE" ]] && return 1

    echo -e "${BLUE}Step 3: Generating title and description using ChatGPT from git diff...${RESET}"
    local git_diff=$(git diff HEAD)
    local chatgpt_output=$(echo "$git_diff" | chatgpt -q "Based on this git diff, generate a concise Jira ticket title (max 50 chars) and description (max 200 words, do not use any formatting or bullet point just a paragraph will do). Format the output as 'Title: <title>\nDescription: <description>'")

    # Extract and sanitize title
    local curr_dir=$(basename "$PWD")
    local original_title=$(echo "$chatgpt_output" | grep "Title:" | sed 's/Title: //' | tr -d '\n' | sed 's/:space:+/ /g')
    local title="[${curr_dir}] ${original_title}"
    title=$(echo "$title" | cut -c 1-255)
    local description=$(echo "$chatgpt_output" | grep "Description:" | sed 's/Description: //')
    
    local current_user=$(jira me)
    local issue_type="Task"
    local custom_field="team=b7aa1ee4-0d96-4e7f-9014-4268bf86008a"
    local priority="Low"

    local component=""
    if [[ "$PROJECT_CODE" == "PEOPLE" ]]; then
        component=$(select_component)
        [[ -z "$component" ]] && return 1
    fi

    echo -e "${BLUE}Step 4: Creating Jira ticket...${RESET}"
    local jira_output=$(jira issue create -p "$PROJECT_CODE" -s "$title" -t "$issue_type" -b "$description" -a "$current_user" -C "$component" --custom "$custom_field" -y "$priority" --no-input --web)
    local ticket_number=$(echo "$jira_output" | grep -oE "${PROJECT_CODE}-[0-9]+")

    echo -e "${BLUE}Step 5: Creating branch for ticket...${RESET}"
    jira issue move $ticket_number "In Progress"
    branch "$ticket_number"

    echo -e "${BLUE}Step 6: Committing changes to the new branch...${RESET}"
    gacp -ai

    echo -e "${BLUE}Step 7: Creating pull request...${RESET}"
    pr -ai
}
