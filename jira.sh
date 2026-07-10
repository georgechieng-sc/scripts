#!/bin/sh

# =============================================================================
# JIRA FUNCTIONS
# =============================================================================

# Dynamic board syncing function
# Usage: sync_board <board_code>
function sync_board() {
	local board="$1"

	if [[ -z "$board" ]]; then
		echo -e "${RED}ERROR: Board code required${RESET}"
		echo "Usage: sync_board <board_code>"
		return 1
	fi

	echo "syncing JIRA $board board issues, assigned to you"

	local board_lower=$(echo "$board" | tr '[:upper:]' '[:lower:]')

	jira issue list -p "$board" -a$(jira me) -s~"Done" -s~"Won't Do" --plain --columns "KEY" --columns "SUMMARY" --no-headers -t~"Epic" > "${SCRIPTS_DIR}/${JIRA_FILE_PREFIX}${board_lower}.txt"
	echo "sync done"
}

# Create a new git branch based on jira ticket ID
# Usage: jbr [--move-progress] <ticket_id|board_code>
# If a board code is given (no hyphen), fzf over that board's synced tickets.
function jbr() {
	local move_progress=false

	if [[ "$1" == "--move-progress" ]]; then
		move_progress=true
		shift
	fi

	local name="$1"

	if [[ -z "$name" ]]; then
		echo -e "${RED}ERROR: Ticket ID or board code required${RESET}"
		echo "Usage: jbr [--move-progress] <ticket_id|board_code>"
		return 1
	fi

	# If arg has no hyphen, treat as board code and fzf over its synced tickets
	if [[ "$name" != *-* ]]; then
		local board_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
		local board_file="${SCRIPTS_DIR}/${JIRA_FILE_PREFIX}${board_lower}.txt"
		if [[ ! -f "$board_file" ]]; then
			echo -e "${RED}ERROR: No synced tickets for board '$name'. Run: sync_board $name${RESET}"
			return 1
		fi
		name="$(cat "$board_file" | fzf --cycle --color=dark | cut -f1 | xargs)"
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
# Usage: mvj <ticket_id|board_code> [status]
# If a board code is given (no hyphen), fzf over that board's synced tickets.
function mvj() {
	local name="$1"
	local pr_status="$2"

	if [[ -z "$name" ]]; then
		echo -e "${RED}ERROR: Ticket ID or board code required${RESET}"
		echo "Usage: mvj <ticket_id|board_code> [status]"
		return 1
	fi

	if [[ "$name" != *-* ]]; then
		local board_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
		local board_file="${SCRIPTS_DIR}/${JIRA_FILE_PREFIX}${board_lower}.txt"
		if [[ ! -f "$board_file" ]]; then
			echo -e "${RED}ERROR: No synced tickets for board '$name'. Run: sync_board $name${RESET}"
			return 1
		fi
		name="$(cat "$board_file" | fzf --cycle --color=dark | cut -f1 | xargs)"
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
# Usage: jdiff -t <title> -d <description> -p <project> [--priority <priority>] [--type <type>]
jdiff() {
    local original_title="" description="" PROJECT_CODE="" priority="Low" issue_type="Task"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t) original_title="$2"; shift 2 ;;
            -d) description="$2"; shift 2 ;;
            -p) PROJECT_CODE="$2"; shift 2 ;;
            --priority) priority="$2"; shift 2 ;;
            --type) issue_type="$2"; shift 2 ;;
            *)
                echo -e "${RED}ERROR: Unknown flag: $1${RESET}"
                echo "Usage: jdiff -t <title> -d <description> -p <project> [--priority <priority>] [--type <type>]"
                return 1
                ;;
        esac
    done

    if [[ -z "$original_title" || -z "$description" || -z "$PROJECT_CODE" ]]; then
        echo -e "${RED}ERROR: Title (-t), description (-d), project (-p) are required${RESET}"
        echo "Usage: jdiff -t <title> -d <description> -p <project> [--priority <priority>] [--type <type>]"
        return 1
    fi

    echo -e "${BLUE}Step 1: Checking required tools...${RESET}"
    command -v git >/dev/null 2>&1 || { echo -e "${RED}git is required but not installed. Aborting.${RESET}" >&2; return 1; }
    command -v jira >/dev/null 2>&1 || { echo -e "${RED}jira-cli is required but not installed. Aborting.${RESET}" >&2; return 1; }

    local curr_dir=$(basename "$PWD")
    local title="[${curr_dir}] ${original_title}"
    title=$(echo "$title" | cut -c 1-255)

    local current_user=$(jira me)

    echo -e "${BLUE}Step 2: Creating Jira ticket...${RESET}"
    local jira_output=$(jira issue create -p "$PROJECT_CODE" -s "$title" -t "$issue_type" -b "$description" -a "$current_user" -y "$priority" --no-input --web)
    local ticket_number=$(echo "$jira_output" | grep -oE "${PROJECT_CODE}-[0-9]+")

    echo -e "${BLUE}Step 3: Creating branch for ticket...${RESET}"
    jira issue move $ticket_number "In Progress"
    branch "$ticket_number"

    echo -e "${BLUE}Step 4: Committing changes to the new branch...${RESET}"
    gacp "$original_title"

    echo -e "${BLUE}Step 5: Creating pull request...${RESET}"
    pr "$original_title"
}
