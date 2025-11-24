#!/bin/sh

# =============================================================================
# GIT FUNCTIONS
# =============================================================================

# Switch to main, pull latest, create dev branch and push to remote
# Usage: branch <branch_name>
function branch() {
	local branch="$1"
	
	if [[ -z "$branch" ]]; then
		echo -e "${RED}ERROR: Branch name required${RESET}"
		echo "Usage: branch <branch_name>"
		return 1
	fi

	local illegalChar="="
	if [[ "$branch" == *"$illegalChar"* ]]; then
		echo -e "${RED}ERROR: Branch name cannot contain '$illegalChar'${RESET}"
		return 1
	fi

	echo "let's switch to main and pull the latest changes first  😉"
	gco $(git_main_branch)
	gl
	echo "creating $branch  🐙 ..."
	gcb $branch

    echo "🔐 Initializing Slate session for $branch"
    slate session "$branch"
	echo "pushing it to remote  ☁️ 🐙 ..."
	gpsup
}

# Auto PR creation with AI support
# Usage: pr [-v|-ai] [title] [merge_destination]
function pr() {
    if [[ $1 == '-v' ]]; then
        gh pr view --web;
        return;
    fi

    local title=""
    local body=""
    local branch=`git symbolic-ref --short -q HEAD`
    local mergeDst="$(git_main_branch)"

    # New AI-powered PR title and body generation
    if [[ $1 == '-ai' ]]; then
    	local prompt="$(cat "${PROMPTS_DIR}/generate_pull-request.md")"
        # Capture the diff from the main branch
        local diff="$(git diff $(git_main_branch))"

        # Use ChatGPT CLI to generate PR title and description
        local pr_details="$(echo "$diff" | chatgpt -q "$prompt")"

        # Extract title and body
        title="$(echo "$pr_details" | head -n 1)"
        body="$(echo "$pr_details" | tail -n +2)"

        echo "-----------------TITLE-----------------"
        echo "$title"
		echo "--------------DESCRIPTION--------------"
        echo "$body"
        echo "--------------END OF LINE--------------"
    else
        # Existing logic for manual title
        title="$(git log -1 --oneline --format=%s)"

        if [[ $1 != '' && $1 != '-ai' ]]; then
            title="$1"
        fi
    fi

    if [[ $2 != '' ]]; then
        mergeDst="$2"
    fi

    echo "let's pull from remote"
    git pull --no-rebase

    echo "let's push this to remote first 😉"
    git push --set-upstream origin "$branch"

    # Use the generated or manual title
    if [[ $1 == '-ai' && -n "$body" ]]; then
        # If we have AI-generated content, use both title and body
        gh pr create -d -t "[$branch] $title" -B "$mergeDst" -b "$body"
    else
        # Otherwise use the template file as before
        gh pr create -d -t "[$branch] $title" -B "$mergeDst" -T 'PULL_REQUEST_TEMPLATE.md'
    fi

    echo "Do you want to move the JIRA ticket to In Review as well? [yn]"
    local yn=$(yesno)
    if [[ $yn =~ ^[Yy]$ ]]; then
        echo "moving JIRA issue to In-Review"
        jira issue move $branch "In Review"
    fi

    echo "Do you want to move PR from draft to ready as well? [yn]"
    local pryn=$(yesno)
    if [[ $pryn =~ ^[Yy]$ ]]; then
        echo "moving PR to ready"
        gh pr ready
    fi

    gh pr view --web;
}

# Git branch delete interactive with JIRA integration
# Usage: gbdi
function gbdi() {
	local branch="$(git branch | fzf | xargs)"

	if [[ -n "$branch" ]]; then
		gbd $branch

		echo "Do you want to move the JIRA ticket to Done as well? [yn]"
		local yn="$(yesno)"
		if [[ $yn =~ ^[Yy]$ ]]; then
			echo "moving JIRA issue to Done"
			jira issue move $branch "Done"
		fi
	fi
}

# Add, commit, and push with enhanced features
# Usage: gacp <message|flag>
function gacp() {
    local gcflag="$1"

    # Check if on main branch
    if [[ "$(git_current_branch)" == "$(git_main_branch)" ]]; then
        echo -e "${RED}ERROR: You are on the main branch!${RESET}"
        echo "Please switch to a feature branch before committing."
        return 1
    fi

    if [[ "$gcflag" == "-h" ]]; then
        echo "Available flags:"
        echo "  -rri : remove redundant import"
        echo "  -gmt : go mod tidy"
        echo "  -gga : go get all"
        echo "  -gmm : merged main"
        echo "  -vb  : version bump"
        echo "  -ut  : updated unit tests"
        echo "  -fmt : formatted code"
        echo "  -ai  : generate commit message using AI based on staged changes"
        echo "  -m   : generate commit message using AI based on diff with main branch"
        return 0
    fi

    if [[ -z "$gcflag" ]]; then
        echo -e "${RED}ERROR: No commit message provided${RESET}"
        echo "Usage: gacp \"your commit message\" or gacp -ai"
        echo "Use 'gacp -h' for available flags"
        return 1
    fi

    # Handle predefined commit messages
    case "$gcflag" in
        "-rri") gcflag="remove redundant import" ;;
        "-gmt") gcflag="go mod tidy" ;;
        "-gga") gcflag="go get all" ;;
        "-gmm"|"-gm") gcflag="merged main" ;;
        "-vb") gcflag="version bump" ;;
        "-ut"|"-uut") gcflag="updated unit tests" ;;
        "-fmt") gcflag="formatted code" ;;
        "-ai")
            echo "Generating commit message using AI based on staged changes..."
            gcflag="$(git diff | chatgpt -q "Generate a concise git commit message (max 50 chars) based on these changes. Use present tense, be specific but brief. reply with a nothing changed if no git diff is given.")"
            if [[ -z "$gcflag" ]]; then
                echo -e "${RED}ERROR: Failed to generate commit message!${RESET}"
                return 1
            fi
            echo "Generated commit message: $gcflag"
            ;;
        "-m")
            echo "Generating commit message using AI based on diff with main branch..."
            gcflag="$(git diff $(git_main_branch) | chatgpt -q "Generate a concise git commit message (max 50 chars) based on these changes. Use present tense, be specific but brief. reply with a nothing changed if no git diff is given.")"
            if [[ -z "$gcflag" ]]; then
                echo -e "${RED}ERROR: Failed to generate commit message!${RESET}"
                return 1
            fi
            echo "Generated commit message: $gcflag"
            ;;
    esac

    echo "let's pull the latest changes first  😉"
    gl
    echo "adding tracked files changes"
    gau
    echo "commiting with message '$gcflag'"
    gcmsg "$gcflag"
    echo "pushing it to remote  ☁️ 🐙 ..."
    gp
}

# Analyze changed files for bugs using ChatGPT
# Usage: bugs [-m]
# -m: compare against main branch instead of HEAD
function bugs() {
    local use_main=false
    
    # Parse flags
    if [[ "$1" == "-m" ]]; then
        use_main=true
        shift
    fi
    
    echo -e "${BLUE}🔍 Analyzing changed files for potential bugs...${RESET}"
    
    # Check if chatgpt CLI is available
    if ! command -v chatgpt >/dev/null 2>&1; then
        echo -e "${RED}ERROR: chatgpt CLI is required but not installed${RESET}"
        echo "Install it with: brew install chatgpt-cli"
        return 1
    fi
    
    # Get changed files based on flag
    local all_files=""
    if [[ "$use_main" == true ]]; then
        # Compare against main branch
        all_files="$(git diff --name-only $(git_main_branch))"
        echo -e "${CYAN}Comparing against main branch: $(git_main_branch)${RESET}"
    else
        # Get all changed files (staged and unstaged)
        local changed_files="$(git diff --name-only HEAD)"
        local staged_files="$(git diff --cached --name-only)"
        
        # Combine and deduplicate files
        all_files="$(echo -e "$changed_files\n$staged_files" | sort | uniq | grep -v '^$')"
        echo -e "${CYAN}Analyzing working directory and staged changes${RESET}"
    fi
    
    if [[ -z "$all_files" ]]; then
        echo -e "${YELLOW}No changed files found${RESET}"
        echo "Make sure you have changes in your working directory or staging area"
        return 0
    fi
    
    echo -e "${GREEN}Found changed files:${RESET}"
    echo "$all_files" | sed 's/^/  - /'
    echo ""
    
    # Concatenate all file contents
    local file_contents=""
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            echo -e "${CYAN}Processing: $file${RESET}"
            file_contents="$file_contents\n\n=== FILE: $file ===\n"
            file_contents="$file_contents$(cat "$file")"
        else
            echo -e "${YELLOW}Warning: $file not found (might be deleted)${RESET}"
        fi
    done <<< "$all_files"
    
    if [[ -z "$file_contents" ]]; then
        echo -e "${RED}ERROR: No file contents to analyze${RESET}"
        return 1
    fi
    echo "$file_contents"
    echo -e "${BLUE}🤖 Sending to ChatGPT for analysis...${RESET}"
    
    # Send to ChatGPT with the specific prompt
    local analysis="$(echo -e "$file_contents" | chatgpt -q "Are there any bugs?")"
    
    echo -e "${GREEN}🔍 Bug Analysis Results:${RESET}"
    echo "========================="
    echo "$analysis"
    echo "========================="
}
