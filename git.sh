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

	echo "pushing it to remote  ☁️ 🐙 ..."
	gpsup
}

# Create draft PR, optionally move JIRA status and mark ready
# Usage: pr [-v] [--move-jira <status>] [--ready] [-t <title>] [-d <description>]
function pr() {
    if [[ $1 == '-v' ]]; then
        gh pr view --web;
        return;
    fi

    local title=""
    local description=""
    local branch=`git symbolic-ref --short -q HEAD`
    local mergeDst="$(git_main_branch)"
    local move_jira=""
    local mark_ready=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            --move-jira)
                move_jira="$2"
                shift 2
                ;;
            --ready)
                mark_ready=true
                shift
                ;;
            -t)
                title="$2"
                shift 2
                ;;
            -d)
                description="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    if [[ -z "$title" ]]; then
        title="$(git log -1 --oneline --format=%s)"
    fi

    echo "let's pull from remote"
    git pull --no-rebase

    echo "let's push this to remote first 😉"
    git push --set-upstream origin "$branch"

    if [[ -n "$description" ]]; then
        gh pr create -d -t "[$branch] $title" -B "$mergeDst" -b "$description"
    else
        gh pr create -d -t "[$branch] $title" -B "$mergeDst" --fill-first
    fi

    if [[ -n "$move_jira" ]]; then
        echo "moving JIRA issue to ${move_jira}"
        jira issue move $branch "$move_jira"
    fi

    if [[ "$mark_ready" == true ]]; then
        echo "moving PR to ready"
        gh pr ready
    fi

    gh pr view --web;
}

# Interactive branch checkout
# Usage: gbi [branch_name]
function gbi() {
	git checkout "${1:-$(git branch | fzf | xargs)}"
}

# Git branch delete with optional JIRA/slate cleanup
# Usage: gbdi [--delete-slate] [--move-done] [branch_name]
function gbdi() {
	local delete_slate=false
	local move_done=false

	while [[ $# -gt 0 ]]; do
		case $1 in
			--delete-slate) delete_slate=true; shift ;;
			--move-done) move_done=true; shift ;;
			*) break ;;
		esac
	done

	local branch="${1:-$(git branch | fzf | xargs)}"

	if [[ -n "$branch" ]]; then
		gbd $branch

		if [[ "$delete_slate" == true ]]; then
			slate delete "$branch" || echo "WARN: slate delete failed" >&2
		fi

		if [[ "$move_done" == true ]]; then
			echo "moving JIRA issue to Done"
			jira issue move $branch "Done"
		fi
	fi
}

# Add, commit, and push with shorthand flags
# Usage: gacp <message|flag>
# Flags: -rri, -gmt, -gga, -gmm, -vb, -ut, -fmt (use -h for details)
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
        return 0
    fi

    if [[ -z "$gcflag" ]]; then
        echo -e "${RED}ERROR: No commit message provided${RESET}"
        echo "Usage: gacp \"your commit message\""
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


