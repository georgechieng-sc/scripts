#!/bin/sh

# =============================================================================
# DATABRICKS PAT FUNCTIONS (sourced)
# =============================================================================
# Mint a short-lived Databricks PAT for omp and opt-in tooling.
#
# What `dbx-pat` does:
#   - mints a Databricks PAT (default 24h) via your Databricks CLI profile
#   - writes DATABRICKS_OMP_API_KEY to ~/.omp/agent/.env (omp loads this on startup)
#   - writes DATABRICKS_TOKEN to ~/.databricks-pat.env for opt-in `source` (dbt/JDBC)
#   - revokes the previously-minted PAT
#
# This PAT exists solely for omp (and any non-CLI tool you point at it). The
# Databricks CLI authenticates via profile OAuth (`auth_type = databricks-cli`
# in ~/.databrickscfg) and does NOT use this PAT, so it is never exported into
# the shell — that would only shadow the CLI's own auth with a 24h-dying token.
#
# omp reads the provider apiKey from ~/.omp/agent/.env (its own env var,
# DATABRICKS_OMP_API_KEY), which models.yml references by env-name. This keeps
# omp's token fully decoupled from DATABRICKS_TOKEN, so neither can break the
# other.
#
# Usage:
#   dbx-pat                      # mint with defaults
#   PAT_LIFETIME_SECONDS=43200 dbx-pat
#   DATABRICKS_PROFILE=<name> dbx-pat
#   source ~/.databricks-pat.env # opt-in: load PAT as DATABRICKS_TOKEN for dbt/JDBC

DBX_WORKSPACE="${DATABRICKS_HOST:-https://safetyculture-safetyculture-production.cloud.databricks.com}"
DBX_WORKSPACE="${DBX_WORKSPACE%/}"
DBX_PAT_LIFETIME_SECONDS="${PAT_LIFETIME_SECONDS:-86400}"
DBX_PAT_COMMENT="coding-agents (dbx-pat)"
DBX_PAT_ID_FILE="$HOME/.databricks-pat.id"
DBX_OMP_ENV_FILE="$HOME/.omp/agent/.env"
DBX_PAT_ENV_FILE="$HOME/.databricks-pat.env"

_dbx_resolve_profile() {
  if [[ -n "${DATABRICKS_PROFILE:-}" ]]; then printf '%s' "$DATABRICKS_PROFILE"; return; fi
  databricks auth profiles --output json 2>/dev/null \
    | jq -r --arg h "$DBX_WORKSPACE" 'first(.profiles[]? | select(.host==$h) | .name) // empty'
}

dbx-pat() {
  command -v jq >/dev/null 2>&1 || { echo -e "${RED}ERROR: jq not found${RESET}" >&2; return 1; }
  command -v databricks >/dev/null 2>&1 || { echo -e "${RED}ERROR: databricks CLI not found${RESET}" >&2; return 1; }

  local profile; profile="$(_dbx_resolve_profile)"
  [[ -n "$profile" ]] || { echo -e "${RED}ERROR: no Databricks profile for $DBX_WORKSPACE${RESET} (set DATABRICKS_PROFILE)" >&2; return 1; }

  echo "Minting PAT (lifetime $((DBX_PAT_LIFETIME_SECONDS/3600))h) via profile '$profile'..."
  local resp pat new_id
  resp="$(databricks tokens create --comment "$DBX_PAT_COMMENT" \
            --lifetime-seconds "$DBX_PAT_LIFETIME_SECONDS" --profile "$profile" --output json)" \
    || { echo -e "${RED}ERROR: token creation failed${RESET}" >&2; return 1; }
  pat="$(printf '%s' "$resp" | jq -r '.token_value // empty')"
  new_id="$(printf '%s' "$resp" | jq -r '.token_info.token_id // empty')"
  [[ -n "$pat" ]] || { echo -e "${RED}ERROR: token creation returned no token_value${RESET}" >&2; return 1; }

  # omp reads this on startup: bare KEY=value, no export, no shell syntax.
  # Opt-in env for non-CLI tools (dbt/JDBC): `source ~/.databricks-pat.env`.
  umask 077
  printf 'DATABRICKS_OMP_API_KEY=%s\n' "$pat" > "$DBX_OMP_ENV_FILE"
  printf 'export DATABRICKS_TOKEN=%s\n' "$pat" > "$DBX_PAT_ENV_FILE"

  local old_id=""; [[ -f "$DBX_PAT_ID_FILE" ]] && old_id="$(cat "$DBX_PAT_ID_FILE" 2>/dev/null || true)"
  printf '%s\n' "$new_id" > "$DBX_PAT_ID_FILE"
  echo -e "${GREEN}✔${RESET} minted token $new_id"

  if [[ -n "$old_id" && "$old_id" != "$new_id" ]]; then
    if databricks tokens delete "$old_id" --profile "$profile" >/dev/null 2>&1; then
      echo -e "${GREEN}✔${RESET} revoked previous token $old_id"
    else
      echo -e "${YELLOW}!${RESET} could not revoke previous token $old_id (may already be expired)" >&2
    fi
  fi

  echo ""
  echo -e "${B}Databricks PAT ready${RESET}"
  echo "  token id : ${CYAN}$new_id${RESET}"
  echo "  omp env  : $DBX_OMP_ENV_FILE  (DATABRICKS_OMP_API_KEY)"
  echo "  opt-in  : source $DBX_PAT_ENV_FILE  (DATABRICKS_TOKEN for dbt/JDBC)"
  echo ""
  echo "Restart omp (or any running omp session) to pick up the new token."
}
