#!/bin/sh

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Reusable board selection function
# Usage: select_board
function select_board() {
	# Define available boards
	typeset -A boards
	boards=(
		p "PEOPLE"
	)
	
	# Display options
	echo "Available boards:" >&2
	echo "  p: PEOPLE board" >&2
	
	# Get user selection
	local choice board_code
	while true; do
		read -r "choice?Choose board (p): "
		
		board_code="${boards[$choice]}"
		if [[ -n "$board_code" ]]; then
			echo "$board_code"
			return 0
		else
			echo "Invalid choice. Please try again." >&2
		fi
	done
}

function select_component() {
	# Define available components
	typeset -A components
	components=(
		d "Documents"
		h "Heads Up"
	)
	
	# Display options
	echo "Available components:" >&2
	echo "  d: Documents" >&2
	echo "  h: Heads Up" >&2
	
	# Get user selection
	local choice component_code
	while true; do
		read -r "choice?Choose component (d, h): "
		
		component_code="${components[$choice]}"
		if [[ -n "$component_code" ]]; then
			echo "$component_code"
			return 0
		else
			echo "Invalid choice. Please try again." >&2
		fi
	done
}

function select_status() {
	# Define available statuses
	typeset -A statuses
	statuses=(
		cr "Code Review"
		ip "In Progress"
		d "Done"
	)
	
	# Display options
	echo "Available statuses:" >&2
	echo "  cr: Code Review" >&2
	echo "  ip: In Progress" >&2
	echo "  d: Done" >&2
	
	# Get user selection
	local choice status_code
	while true; do
		read -r "choice?Choose status (cr, ip, d): "
		
		status_code="${statuses[$choice]}"
		if [[ -n "$status_code" ]]; then
			echo "$status_code"
			return 0
		else
			echo "Invalid choice. Please try again." >&2
		fi
	done
}

# Clean up persistent ports
# Usage: cleanpipe <port_number>
function cleanpipe() {
	if [[ -z "$1" ]]; then
		echo -e "${RED}ERROR: Port number required${RESET}"
		echo "Usage: cleanpipe <port>"
		return 1
	fi
	
	if ! [[ "$1" =~ ^[0-9]+$ ]]; then
		echo -e "${RED}ERROR: Invalid port number${RESET}"
		return 1
	fi
	
	portcheck "$1"
	lsof -t -i "$1" | xargs kill
	echo "$1 pipe cleaned"
}

# Performance check for zsh shell
# Usage: timezsh [shell_path]
function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

# Create a gif from .mov or .mp4 files
# Usage: giffy <input_file>
function giffy() {
	if [[ -z "$1" ]]; then
		echo -e "${RED}ERROR: Input file required${RESET}"
		echo "Usage: giffy <input_file.mov|mp4>"
		return 1
	fi

	local filename="$(echo "$1" | cut -d '.' -f 1)"
	local ext="$(echo "$1" | cut -d '.' -f 2)"
	
	echo "converting $1..."
	
	if [[ "$ext" == "mp4" || "$ext" == "mov" ]]; then
		ffmpeg -i "$filename.$ext" -r 24 "$filename.gif" && gifsicle --no-conserve-memory -O3 "$filename.gif" -o "$filename.gif"
	else
		echo -e "${RED}ERROR: Invalid file format!${RESET}"
		echo "Only .mov and .mp4 files are supported!"
		return 1
	fi
}

# Interactive directory change using fzf
# Usage: cdi [dir_name]
function cdi() {
	local dir="${1:-$(ls | fzf --cycle --color=dark | xargs)}"

	if [[ -n "$dir" ]]; then
		cd "$dir"
	fi
}

# SafetyCulture directory + interactive cd
# Usage: sci [dir_name]
function sci() {
	cd "$SAFETYCULTURE_DIR"
	cdi "$1"
}
