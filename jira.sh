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
# Usage: jdiff -t <title> -d <description> -p <project> [-c <component>] [--priority <priority>] [--type <type>]
jdiff() {
    local original_title="" description="" PROJECT_CODE="" component="" priority="Low" issue_type="Task"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t) original_title="$2"; shift 2 ;;
            -d) description="$2"; shift 2 ;;
            -p) PROJECT_CODE="$2"; shift 2 ;;
            -c) component="$2"; shift 2 ;;
            --priority) priority="$2"; shift 2 ;;
            --type) issue_type="$2"; shift 2 ;;
            *)
                echo -e "${RED}ERROR: Unknown flag: $1${RESET}"
                echo "Usage: jdiff -t <title> -d <description> -p <project> [-c <component>] [--priority <priority>] [--type <type>]"
                echo "Projects: PEOPLE"
                echo "Components (PEOPLE): Documents, \"Heads Up\""
                return 1
                ;;
        esac
    done

    if [[ -z "$original_title" || -z "$description" || -z "$PROJECT_CODE" ]]; then
        echo -e "${RED}ERROR: Title (-t), description (-d), and project (-p) are required${RESET}"
        echo "Usage: jdiff -t <title> -d <description> -p <project> [-c <component>] [--priority <priority>] [--type <type>]"
        return 1
    fi

    case "$PROJECT_CODE" in
        PEOPLE) ;;
        *)
            echo -e "${RED}ERROR: Invalid project: $PROJECT_CODE. Valid options: PEOPLE${RESET}"
            return 1
            ;;
    esac

    if [[ "$PROJECT_CODE" == "PEOPLE" && -z "$component" ]]; then
        echo -e "${RED}ERROR: Component (-c) is required for PEOPLE project. Valid options: Documents, \"Heads Up\"${RESET}"
        return 1
    fi

    echo -e "${BLUE}Step 1: Checking required tools...${RESET}"
    command -v git >/dev/null 2>&1 || { echo -e "${RED}git is required but not installed. Aborting.${RESET}" >&2; return 1; }
    command -v jira >/dev/null 2>&1 || { echo -e "${RED}jira-cli is required but not installed. Aborting.${RESET}" >&2; return 1; }

    local curr_dir=$(basename "$PWD")
    local title="[${curr_dir}] ${original_title}"
    title=$(echo "$title" | cut -c 1-255)

    local current_user=$(jira me)
    local custom_field="team=b7aa1ee4-0d96-4e7f-9014-4268bf86008a"

    echo -e "${BLUE}Step 2: Creating Jira ticket...${RESET}"
    local jira_output=$(jira issue create -p "$PROJECT_CODE" -s "$title" -t "$issue_type" -b "$description" -a "$current_user" -C "$component" --custom "$custom_field" -y "$priority" --no-input --web)
    local ticket_number=$(echo "$jira_output" | grep -oE "${PROJECT_CODE}-[0-9]+")

    echo -e "${BLUE}Step 3: Creating branch for ticket...${RESET}"
    jira issue move $ticket_number "In Progress"
    branch "$ticket_number"

    echo -e "${BLUE}Step 4: Committing changes to the new branch...${RESET}"
    gacp "$original_title"

    echo -e "${BLUE}Step 5: Creating pull request...${RESET}"
    pr "$original_title"
}
