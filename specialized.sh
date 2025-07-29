#!/bin/sh

# =============================================================================
# SPECIALIZED UTILITY FUNCTIONS
# =============================================================================

# Convert S12ID to UUID format
# Usage: s12id <s12id_string>
function s12id() {
	if [[ -z "$1" ]]; then
		echo -e "${RED}ERROR: S12ID required${RESET}"
		echo "Usage: s12id <s12id_string>"
		return 1
	fi

	local id="$(echo "$1" | sed -e 's/role_//g' -e 's/user_//g' -e 's/action_//g' -e 's/audit_//g')"
	local uuid=''

	for (( i=0; i<${#id}; i++ )); do
		if [[ $i == 7 || $i == 11 || $i == 15 || $i == 19 ]]; then
			uuid="${uuid}${id:$i:1}-"
		else
			uuid="${uuid}${id:$i:1}"
		fi
	done

	echo "$uuid"
}

# Convert UUID to S12ID format
# Usage: ids12 <uuid> [prefix]
function ids12() {
    if [[ -z "$1" ]]; then
        echo -e "${RED}ERROR: UUID required${RESET}"
        echo "Usage: ids12 <uuid> [prefix]"
        return 1
    fi

    # Remove all hyphens from UUID
    local clean_uuid="$(echo "$1" | tr -d '-')"

    # Add prefix if specified as second argument
    local prefix=""
    if [[ -n "$2" ]]; then
        case "$2" in
            "role"|"user"|"action"|"audit")
                prefix="${2}_"
                ;;
            *)
                echo -e "${RED}ERROR: Invalid prefix${RESET}"
                echo "Valid prefixes: role, user, action, audit"
                return 1
                ;;
        esac
    fi

    echo "${prefix}${clean_uuid}"
}

# Generate password from seed
# Usage: pw <input>
function pw() {
	if [[ -z "$1" ]]; then
		echo -e "${RED}ERROR: Input required${RESET}"
		echo "Usage: pw <input>"
		return 1
	fi
	
	local sv="Yoog5ahpohThee0Ohk7ohSooquaivohj"
	echo "Seed Value: $sv"
	echo "$(echo -n "Yoog5ahpohThee0Ohk7ohSooquaivohj/$1" | md5sum | head -c 32)"
}

# Auto-generate SQL migration file
# Usage: auto-sql
function auto-sql() {
	local latest_file="$(ls ./V[0-9]*__*.sql 2>/dev/null | sort -V | tail -n 1)"

	if [[ -z "$latest_file" ]]; then
	  echo "⚠️ No existing migrations found. Exiting."
	  return 1
	fi

	local latest_version="$(basename "$latest_file" | sed -E 's/^V([0-9]+)__.*/\1/')"
	local next_version=$((latest_version + 1))
	
	echo "📌 Latest version: V${latest_version}"

	echo -n "📄 Enter migration description (use_underscores): "
	read DESC

	if [[ -z "$DESC" ]]; then
	  echo "❌ Description cannot be empty. Exiting."
	  return 1
	fi

	local filename="V${next_version}__${DESC}.sql"
	touch "$filename"
	echo "Created: $filename"
}
