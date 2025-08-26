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
			*) 
				echo "Invalid board code: $1. Valid options: RESM"
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

		echo "Move JIRA ticket to?"
		echo "ip: In Progress"
		echo "ir: In Review"
		echo "d: Done"

		read -r b
		case "$b" in
			"ip")
				echo "moving JIRA issue to In Progress"
				jira issue move "$name" "In Progress"
				;;
			"ir")
				echo "moving JIRA issue to In Review"
				jira issue move "$name" "In Review"
				;;
			"d")
				echo "moving JIRA issue to Done"
				jira issue move "$name" "Done"
				;;
			*)
				echo -e "${RED}ERROR: Invalid choice${RESET}"
				return 1
				;;
		esac
	fi
}

# AI-powered JIRA ticket creation based on git diff
# Usage: jdiff [options]
jdiff() {
    local dry_run=false
    local chat_only=false
    local quiet_mode=false
    local use_color=true

    # Define flags and their descriptions
    typeset -A flags
    flags=(
        "-h, --help" "Show this help message and exit"
        "--dry-run" "Run in dry run mode (no actual changes)"
        "-c, --chat" "Run only up to the ChatGPT step"
        "-q" "Quiet mode (minimal output)"
        "--no-color" "Disable colored output"
    )

    # Function to display help
    show_help() {
        echo_color "${BLUE}JDIFF HELP${RESET}"
        echo_color "${CYAN}Usage: jdiff [OPTIONS]${RESET}"
        echo "Create a Jira ticket based on git diff and optionally create a branch."
        echo
        echo_color "${YELLOW}Options:${RESET}"
        for flag in "${(@k)flags}"; do
            printf "${GREEN}  %-20s${RESET} %s\n" "$flag" "${flags[$flag]}"
        done
    }

    echo_color() {
        if [ "$use_color" = true ]; then
            echo -e "$@"
        else
            echo -e "$@" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g"
        fi
    }

    # Parse command line arguments
    while (( $# > 0 )); do
        case $1 in
            (-h|--help) show_help; return 0 ;;
            (--dry-run) dry_run=true ;;
            (-c|--chat) chat_only=true ;;
            (-q) quiet_mode=true ;;
            (--no-color) use_color=false ;;
            (*) echo_color "${RED}Unknown parameter passed: $1${RESET}"; show_help; return 1 ;;
        esac
        shift
    done

    if [ "$dry_run" = true ] && [ "$quiet_mode" = false ]; then
        echo_color "${YELLOW}Running in dry run mode. No actual changes will be made.${RESET}"
    fi

    if [ "$chat_only" = true ] && [ "$quiet_mode" = false ]; then
        echo_color "${YELLOW}Running in chat-only mode. Will stop after ChatGPT step.${RESET}"
    fi

    if [ "$quiet_mode" = false ]; then
        echo_color "${BLUE}Step 1: Checking required tools...${RESET}"
    fi
    # Ensure required tools are installed
    command -v git >/dev/null 2>&1 || { echo_color "${RED}git is required but not installed. Aborting.${RESET}" >&2; return 1; }
    command -v chatgpt >/dev/null 2>&1 || { echo_color "${RED}chatgpt CLI is required but not installed. Aborting.${RESET}" >&2; return 1; }
    if [ "$chat_only" = false ]; then
        command -v jira >/dev/null 2>&1 || { echo_color "${RED}jira-cli is required but not installed. Aborting.${RESET}" >&2; return 1; }
        command -v branch >/dev/null 2>&1 || { echo_color "${YELLOW}br command not found. Will skip branch creation.${RESET}" >&2; }
    fi
    if [ "$quiet_mode" = false ]; then
        echo_color "${GREEN}All required tools are available.${RESET}"
    fi

    if [ "$quiet_mode" = false ]; then
        echo_color "${BLUE}Step 2: Prompting user to choose project...${RESET}"
    fi
    
    # Use the reusable board selection function
    local PROJECT_CODE
    PROJECT_CODE=$(select_board)
    
    if [[ -z "$PROJECT_CODE" ]]; then
        echo_color "${RED}Board selection cancelled. Aborting.${RESET}"
        return 1
    fi
    
    if [ "$quiet_mode" = false ]; then
        echo_color "${GREEN}Selected project: $PROJECT_CODE${RESET}"
    fi

    if [ "$quiet_mode" = false ]; then
        echo_color "${BLUE}Step 3: Getting git diff...${RESET}"
    fi
    # Get the git diff
    local git_diff=$(git diff HEAD)
    if [ "$quiet_mode" = false ]; then
        echo_color "${GREEN}Git diff obtained. Length: ${#git_diff} characters${RESET}"
    fi

    if [ "$quiet_mode" = false ]; then
        echo_color "${BLUE}Step 4: Generating title and description using ChatGPT...${RESET}"
    fi
    # Use ChatGPT to generate a title and description
    if [ "$dry_run" = true ]; then
        local chatgpt_output="Title: Sample Title\nDescription: This is a sample description."
    else
        local chatgpt_output=$(echo "$git_diff" | chatgpt -q "Based on this git diff, generate a concise Jira ticket title (max 50 chars) and description (max 200 words). Format the output as 'Title: <title>\nDescription: <description>'")
    fi
    if [ "$quiet_mode" = false ]; then
        echo_color "${CYAN}ChatGPT output:${RESET}"
        echo "$chatgpt_output"
    fi

    # Extract and sanitize title
    local curr_dir=$(basename "$PWD")
    local original_title=$(echo "$chatgpt_output" | grep "Title:" | sed 's/Title: //' | tr -d '\n' | sed 's/:space:+/ /g')
    local title="[${curr_dir}] ${original_title}"
    title=$(echo "$title" | cut -c 1-255) 
    if [ "$quiet_mode" = false ]; then
        echo_color "${GREEN}Extracted title: $title${RESET}"
    fi

    # Extract description
    local description=$(echo "$chatgpt_output" | grep "Description:" | sed 's/Description: //')
    if [ "$quiet_mode" = false ]; then
        echo_color "${GREEN}Extracted description (first 50 chars): ${description:0:50}...${RESET}"
    fi

    if [ "$chat_only" = true ]; then
        if [ "$quiet_mode" = false ]; then
            echo_color "${YELLOW}Chat-only mode: Stopping after ChatGPT step.${RESET}"
        fi
        return 0
    fi

    if [ "$quiet_mode" = false ]; then
        echo_color "${BLUE}Step 5: Getting current user from jira-cli...${RESET}"
    fi
    # Get the current user's username from jira-cli
    if [ "$dry_run" = true ]; then
        local current_user="dryrun_user"
    else
        local current_user=$(jira me)
    fi
    if [ "$quiet_mode" = false ]; then
        echo_color "${GREEN}Current user: $current_user${RESET}"
    fi

    # Set issue type to Task
    local issue_type="Task"
    if [ "$quiet_mode" = false ]; then
        echo_color "${GREEN}Issue type set to: $issue_type${RESET}"
    fi

    if [ "$quiet_mode" = false ]; then
        echo_color "${BLUE}Step 6: Creating Jira ticket...${RESET}"
    fi
    # Create a Jira ticket in the selected project and capture the output
    if [ "$dry_run" = true ]; then
        local jira_output="Issue created: https://your-domain.atlassian.net/browse/${PROJECT_CODE}-123"
    else
        local jira_output=$(jira issue create -p "$PROJECT_CODE" -s "$title" -t "$issue_type" -b "$description" -a "$current_user" --no-input --web)
    fi
    if [ "$quiet_mode" = false ]; then
        echo_color "${CYAN}Jira CLI output: $jira_output${RESET}"
    fi

    # Extract the ticket number from the jira output
    local ticket_number=$(echo "$jira_output" | grep -oE "${PROJECT_CODE}-[0-9]+")
    if [ "$quiet_mode" = false ]; then
        echo_color "${GREEN}Extracted ticket number: $ticket_number${RESET}"
    fi

    echo_color "${MAGENTA}Jira ticket $ticket_number created successfully in project $PROJECT_CODE!${RESET}"

    if [ "$quiet_mode" = false ]; then
        echo_color "${BLUE}Step 7: Creating branch for ticket...${RESET}"
    fi
    if [ "$dry_run" = true ]; then
        if [ "$quiet_mode" = false ]; then
            echo_color "${YELLOW}Would create branch for ticket $ticket_number${RESET}"
        fi
    else
	    jira issue move $ticket_number "In Progress"
        branch "$ticket_number"
    fi
}
