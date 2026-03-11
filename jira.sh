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
			"PEOPLE") board="$1" ;;
			*) 
				echo "Invalid board code: $1. Valid options: PEOPLE"
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

function peop() {
    sync_board "PEOPLE"
}

# Create a new git branch based on jira ticket ID
# Usage: jbr [--move-progress] [ticket_id]
function jbr() {
	local move_progress=false

	if [[ "$1" == "--move-progress" ]]; then
		move_progress=true
		shift
	fi

	local name="$1"

	if [[ -z "$name" ]]; then
		local board="$(select_board)"

		if [[ -z "$board" ]]; then
			echo "Board selection cancelled"
			return 1
		fi

		local board_lower=$(echo "$board" | tr '[:upper:]' '[:lower:]')
		name="$(cat "${SCRIPTS_DIR}/${JIRA_FILE_PREFIX}${board_lower}.txt" | fzf --cycle --color=dark | cut -f1 | xargs)"
	fi

	if [[ -n "$name" ]]; then
		echo "creating branch with the name: $name"
		branch "$name"

		if [[ "$move_progress" == true ]]; then
			echo "moving JIRA issue to In-Progress"
			jira issue move "$name" "In Progress"
		fi
	fi
}

# Move JIRA ticket to different status
# Usage: mvj [ticket_id] [status]
function mvj() {
	local name="$1"
	local pr_status="$2"

	if [[ -z "$name" ]]; then
		local board="$(select_board)"

		if [[ -z "$board" ]]; then
			echo "Board selection cancelled"
			return 1
		fi

		local board_lower=$(echo "$board" | tr '[:upper:]' '[:lower:]')
		name="$(cat "${SCRIPTS_DIR}/${JIRA_FILE_PREFIX}${board_lower}.txt" | fzf --cycle --color=dark | cut -f1 | xargs)"
	fi

	if [[ -n "$name" ]]; then
		echo "moving JIRA ticket: $name"
		if [[ -z "$pr_status" ]]; then
			pr_status="$(select_status)"
		fi
		jira issue move "$name" "$pr_status"
	fi
}

# Create JIRA ticket, branch, commit, and PR from current changes
# Usage: jdiff <title> <description>
jdiff() {
    local original_title="$1"
    local description="$2"

    if [[ -z "$original_title" || -z "$description" ]]; then
        echo -e "${RED}ERROR: Title and description are required${RESET}"
        echo "Usage: jdiff <title> <description>"
        return 1
    fi

    echo -e "${BLUE}Step 1: Checking required tools...${RESET}"
    command -v git >/dev/null 2>&1 || { echo -e "${RED}git is required but not installed. Aborting.${RESET}" >&2; return 1; }
    command -v jira >/dev/null 2>&1 || { echo -e "${RED}jira-cli is required but not installed. Aborting.${RESET}" >&2; return 1; }

    echo -e "${BLUE}Step 2: Prompting user to choose project...${RESET}"
    local PROJECT_CODE=$(select_board)
    [[ -z "$PROJECT_CODE" ]] && return 1

    local curr_dir=$(basename "$PWD")
    local title="[${curr_dir}] ${original_title}"
    title=$(echo "$title" | cut -c 1-255)

    echo "$title"
    echo "$description"

    local current_user=$(jira me)
    local issue_type="Task"
    local custom_field="team=b7aa1ee4-0d96-4e7f-9014-4268bf86008a"
    local priority="Low"

    local component=""
    if [[ "$PROJECT_CODE" == "PEOPLE" ]]; then
        component=$(select_component)
        [[ -z "$component" ]] && return 1
    fi

    echo -e "${BLUE}Step 3: Creating Jira ticket...${RESET}"
    local jira_output=$(jira issue create -p "$PROJECT_CODE" -s "$title" -t "$issue_type" -b "$description" -a "$current_user" -C "$component" --custom "$custom_field" -y "$priority" --no-input --web)
    local ticket_number=$(echo "$jira_output" | grep -oE "${PROJECT_CODE}-[0-9]+")

    echo -e "${BLUE}Step 4: Creating branch for ticket...${RESET}"
    jira issue move $ticket_number "In Progress"
    branch "$ticket_number"

    echo -e "${BLUE}Step 5: Committing changes to the new branch...${RESET}"
    gacp "$original_title"

    echo -e "${BLUE}Step 6: Creating pull request...${RESET}"
    pr "$original_title"
}
